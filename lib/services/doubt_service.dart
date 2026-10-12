// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/doubt_kb.dart';
import '../models/models.dart';

enum AnswerSource { ai, offline }

class DoubtAnswer {
  const DoubtAnswer(this.text, this.source, {this.topic});

  final String text;
  final AnswerSource source;

  /// The offline topic that matched, if any.
  final String? topic;
}

const int maxQuestionLength = 500;
const int maxContextLength = 800;

/// Removes control characters and limits length before a question is used
/// anywhere (matching, display or the network).
String sanitizeInput(String raw, {int maxLength = maxQuestionLength}) {
  final cleaned = raw
      .replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]'), '')
      .trim();
  return cleaned.length > maxLength ? cleaned.substring(0, maxLength) : cleaned;
}

/// Guesses which language a question is about.
Lang? detectLang(String text) {
  final t = text.toLowerCase();
  if (RegExp(r'c\+\+|\bcpp\b').hasMatch(t)) return Lang.cpp;
  if (RegExp(r'\bjava\b').hasMatch(t)) return Lang.java;
  if (RegExp(r'\bpython\b|\bpy\b').hasMatch(t)) return Lang.python;
  if (RegExp(r'\b(in|using|with|for|learn) c\b(?!\+)|\bc (language|program|code)\b|^c\b(?!\+)')
      .hasMatch(t)) {
    return Lang.c;
  }
  return null;
}

/// Answers doubts from the built-in knowledge base. Works fully offline.
class OfflineTutor {
  const OfflineTutor({this.entries = doubtKb});

  final List<KbEntry> entries;

  static final RegExp _wordSplit = RegExp(r'[^a-z0-9_+#]+');

  int _score(KbEntry entry, String text, Set<String> words) {
    var score = 0;
    for (final keyword in entry.keywords) {
      final isPhraseOrSymbol = keyword.contains(' ') ||
          RegExp(r'[^a-z0-9_]').hasMatch(keyword);
      if (isPhraseOrSymbol) {
        if (text.contains(keyword)) {
          score += 2 + 2 * (keyword.split(' ').length - 1);
        }
      } else if (words.contains(keyword)) {
        score += 2;
      }
    }
    // The greeting should only win when nothing else matches.
    if (entry.id == 'greeting' && score > 0) score = 1;
    return score;
  }

  KbEntry? bestMatch(String question) {
    final text = question.toLowerCase();
    final words = <String>{};
    for (final w in text.split(_wordSplit)) {
      if (w.isEmpty) continue;
      words.add(w);
      if (w.length > 3 && w.endsWith('s')) words.add(w.substring(0, w.length - 1));
    }
    KbEntry? best;
    var bestScore = 0;
    for (final entry in entries) {
      final s = _score(entry, text, words);
      if (s > bestScore) {
        best = entry;
        bestScore = s;
      }
    }
    return best;
  }

  DoubtAnswer answer(String question, {Lang? lang}) {
    final entry = bestMatch(question);
    if (entry == null) {
      return const DoubtAnswer(
        "Hmm, I don't know that one yet. Try asking about a topic like: "
        'variables, data types, if/else, for or while loops, functions, '
        'arrays, strings, classes, pointers, errors, recursion or input. '
        'Tip: short questions like "What is a pointer in C?" work best.',
        AnswerSource.offline,
      );
    }
    final buffer = StringBuffer()
      ..writeln(entry.title)
      ..writeln()
      ..write(entry.answer);

    Lang? exampleLang;
    if (lang != null && entry.examples.containsKey(lang)) {
      exampleLang = lang;
    } else if (entry.examples.isNotEmpty) {
      exampleLang = entry.examples.keys.first;
    }
    if (exampleLang != null) {
      buffer
        ..writeln()
        ..writeln()
        ..writeln('Example in ${exampleLang.label}:')
        ..writeln('```')
        ..writeln(entry.examples[exampleLang])
        ..write('```');
    }
    return DoubtAnswer(buffer.toString(), AnswerSource.offline, topic: entry.id);
  }
}

/// Talks to our own `/api/ask` endpoint. The AI key lives only on the
/// server - the app never sees it.
class RemoteTutor {
  RemoteTutor({
    required this.endpoint,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final Uri endpoint;
  final Duration timeout;
  final http.Client _client;
  bool _disabled = false;

  /// True once the server said AI is not configured, so we stop asking.
  bool get disabled => _disabled;

  /// Web: same-origin `/api/ask`. Mobile: `--dart-define=TUTOR_API_BASE=https://...`.
  static RemoteTutor? fromEnvironment() {
    const base = String.fromEnvironment('TUTOR_API_BASE');
    if (base.isNotEmpty) {
      final uri = Uri.tryParse(base);
      if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
        return RemoteTutor(endpoint: uri.resolve('/api/ask'));
      }
      return null;
    }
    if (kIsWeb) return RemoteTutor(endpoint: Uri.base.resolve('/api/ask'));
    return null;
  }

  Future<String?> ask(String question, {Lang? lang, String? context}) async {
    if (_disabled) return null;
    try {
      final response = await _client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'question': question,
              if (lang != null) 'lang': lang.name,
              if (context != null && context.isNotEmpty) 'context': context,
            }),
          )
          .timeout(timeout);
      if (response.statusCode == 404 ||
          response.statusCode == 405 ||
          response.statusCode == 503) {
        _disabled = true;
        return null;
      }
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['answer'] is String) {
        final answer = (decoded['answer'] as String).trim();
        if (answer.isEmpty) return null;
        return answer.length > 4000 ? answer.substring(0, 4000) : answer;
      }
      return null;
    } on Exception {
      return null;
    }
  }
}

/// Answers a doubt: tries the AI tutor first (if available), then falls
/// back to the offline knowledge base, so the player always gets help.
class DoubtService {
  DoubtService({this.remote, this.offline = const OfflineTutor()});

  final RemoteTutor? remote;
  final OfflineTutor offline;

  Future<DoubtAnswer> ask(String raw, {Lang? lang, String? context}) async {
    final question = sanitizeInput(raw);
    if (question.isEmpty) {
      return const DoubtAnswer('Type your question first, then press Send.', AnswerSource.offline);
    }
    final effectiveLang = lang ?? detectLang(question);
    final safeContext = context == null ? null : sanitizeInput(context, maxLength: maxContextLength);
    final r = remote;
    if (r != null && !r.disabled) {
      final ai = await r.ask(question, lang: effectiveLang, context: safeContext);
      if (ai != null) return DoubtAnswer(ai, AnswerSource.ai);
    }
    return offline.answer(question, lang: effectiveLang);
  }
}
