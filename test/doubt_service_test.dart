import 'dart:convert';

import 'package:codequest/models/models.dart';
import 'package:codequest/services/doubt_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('sanitizeInput', () {
    test('removes control characters, trims and limits length', () {
      expect(sanitizeInput('  hi\u0000 there\u0007 '), 'hi there');
      expect(sanitizeInput('a\nb'), 'a\nb');
      expect(sanitizeInput('x' * 900).length, maxQuestionLength);
    });
  });

  group('detectLang', () {
    test('finds the language a question is about', () {
      expect(detectLang('How do loops work in Python?'), Lang.python);
      expect(detectLang('what is a pointer in C?'), Lang.c);
      expect(detectLang('C++ classes please'), Lang.cpp);
      expect(detectLang('java arrays'), Lang.java);
      expect(detectLang('is javascript the same?'), isNull);
      expect(detectLang('what is a loop'), isNull);
    });
  });

  group('OfflineTutor', () {
    const tutor = OfflineTutor();

    test('matches common beginner questions to the right topic', () {
      final cases = {
        'What is a variable?': 'variable',
        'what is the difference between for and while?': 'for-vs-while',
        'What is a pointer in C?': 'pointer',
        'Why do I need a semicolon?': 'semicolon',
        'explain recursion': 'recursion',
        'what does % do': 'modulus',
        'I got an IndentationError': 'indentation',
        'how do I read input from the user': 'input',
        'hello': 'greeting',
      };
      cases.forEach((question, topic) {
        expect(tutor.bestMatch(question)?.id, topic, reason: question);
      });
    });

    test('adds an example in the chosen language', () {
      final a = tutor.answer('what is a loop', lang: Lang.java);
      expect(a.source, AnswerSource.offline);
      expect(a.text, contains('Example in Java'));
      expect(a.text, contains('```'));
    });

    test('gives friendly guidance for unknown questions', () {
      final a = tutor.answer('zzqx blorp');
      expect(a.topic, isNull);
      expect(a.text, contains('variables'));
    });
  });

  group('DoubtService', () {
    test('uses the AI answer when the server replies', () async {
      late Map<String, dynamic> sent;
      final client = MockClient((req) async {
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'answer': 'A loop repeats code.'}), 200);
      });
      final service = DoubtService(
        remote: RemoteTutor(endpoint: Uri.parse('https://example.test/api/ask'), client: client),
      );
      final a = await service.ask('  What is a loop in python? ');
      expect(a.source, AnswerSource.ai);
      expect(a.text, 'A loop repeats code.');
      expect(sent['question'], 'What is a loop in python?');
      expect(sent['lang'], 'python');
    });

    test('falls back to offline when AI is not configured, and stops asking', () async {
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        return http.Response('{"error":"not configured"}', 503);
      });
      final remote = RemoteTutor(endpoint: Uri.parse('https://example.test/api/ask'), client: client);
      final service = DoubtService(remote: remote);
      final a = await service.ask('What is a variable?');
      expect(a.source, AnswerSource.offline);
      expect(remote.disabled, isTrue);
      await service.ask('What is a class?');
      expect(calls, 1);
    });

    test('falls back to offline on bad responses or network errors', () async {
      final bad = DoubtService(
        remote: RemoteTutor(
          endpoint: Uri.parse('https://example.test/api/ask'),
          client: MockClient((_) async => http.Response('<html>oops</html>', 200)),
        ),
      );
      expect((await bad.ask('what is an array')).source, AnswerSource.offline);

      final broken = DoubtService(
        remote: RemoteTutor(
          endpoint: Uri.parse('https://example.test/api/ask'),
          client: MockClient((_) async => throw http.ClientException('offline')),
        ),
      );
      expect((await broken.ask('what is an array')).source, AnswerSource.offline);
    });

    test('empty questions are not sent anywhere', () async {
      var calls = 0;
      final service = DoubtService(
        remote: RemoteTutor(
          endpoint: Uri.parse('https://example.test/api/ask'),
          client: MockClient((_) async {
            calls++;
            return http.Response('{}', 200);
          }),
        ),
      );
      final a = await service.ask('   \u0000  ');
      expect(a.text, contains('Type your question'));
      expect(calls, 0);
    });
  });
}
