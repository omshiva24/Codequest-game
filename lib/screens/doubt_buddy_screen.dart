import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../models/models.dart';
import '../services/doubt_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class _Message {
  const _Message({required this.fromUser, required this.text, this.source});

  final bool fromUser;
  final String text;
  final AnswerSource? source;
}

/// Chat with "Byte", the Doubt Buddy owl.
class DoubtBuddyScreen extends StatefulWidget {
  const DoubtBuddyScreen({
    super.key,
    this.initialQuestion,
    this.initialLang,
    this.extraContext,
  });

  final String? initialQuestion;
  final Lang? initialLang;
  final String? extraContext;

  @override
  State<DoubtBuddyScreen> createState() => _DoubtBuddyScreenState();
}

class _DoubtBuddyScreenState extends State<DoubtBuddyScreen> {
  static const _suggestions = [
    'What is a variable?',
    'for vs while loop?',
    'What is a pointer in C?',
    'Why do I need a semicolon?',
    'What is a class?',
    'Explain recursion',
  ];

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  final List<_Message> _messages = [
    const _Message(
      fromUser: false,
      text: "Hoot hoot! I'm Byte, your Doubt Buddy. Stuck on something? Ask me "
          'about Python, C, C++ or Java and I will explain it in simple words.',
    ),
  ];

  Lang? _lang;
  bool _busy = false;
  String? _context;

  @override
  void initState() {
    super.initState();
    _lang = widget.initialLang;
    _context = widget.extraContext;
    final q = widget.initialQuestion;
    if (q != null && q.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(q));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = sanitizeInput(preset ?? _input.text);
    if (text.isEmpty || _busy) return;
    final service = AppScope.doubts(context);
    setState(() {
      _messages.add(_Message(fromUser: true, text: text));
      _busy = true;
      _input.clear();
    });
    _scrollToEnd();
    final answer = await service.ask(text, lang: _lang, context: _context);
    // Context is only used for the first question that came with it.
    _context = null;
    if (!mounted) return;
    setState(() {
      _messages.add(_Message(fromUser: false, text: answer.text, source: answer.source));
      _busy = false;
    });
    _scrollToEnd();
    _inputFocus.requestFocus();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final reduceMotion = reduceMotionOf(context, listen: false);
      final target = _scroll.position.maxScrollExtent;
      if (reduceMotion) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Emoji('🦉', size: 26), SizedBox(width: 8), Text('Doubt Buddy')],
        ),
      ),
      body: PageBody(
        maxWidth: 760,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _LangChip(label: 'Any language', selected: _lang == null, onTap: () => setState(() => _lang = null)),
                  for (final lang in Lang.values)
                    _LangChip(
                      label: lang.label,
                      selected: _lang == lang,
                      onTap: () => setState(() => _lang = lang),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                itemCount: _messages.length + (_busy ? 1 : 0) + (_messages.length == 1 ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i < _messages.length) {
                    final isLast = i == _messages.length - 1;
                    return _Bubble(message: _messages[i], announce: isLast && !_messages[i].fromUser);
                  }
                  if (_busy) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Semantics(
                        liveRegion: true,
                        child: Row(
                          children: [
                            const SizedBox(
                                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3)),
                            const SizedBox(width: 12),
                            Text('Byte is thinking...', style: TextStyle(color: g.textDim)),
                          ],
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _suggestions)
                          ActionChip(
                            label: Text(s),
                            onPressed: () => _send(s),
                            backgroundColor: g.cardRaised,
                            side: BorderSide(color: g.border),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        focusNode: _inputFocus,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: maxQuestionLength,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          labelText: 'Ask your doubt',
                          hintText: 'e.g. What does i++ mean?',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Send question',
                      onPressed: _busy ? null : _send,
                      iconSize: 26,
                      style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.announce});

  final _Message message;
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final user = message.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Semantics(
          liveRegion: announce,
          label: user ? 'You asked' : 'Byte answered',
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: user ? g.cardRaised : g.card,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(user ? 18 : 4),
                bottomRight: Radius.circular(user ? 4 : 18),
              ),
              border: Border.all(color: user ? g.coin : g.border, width: user ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user)
                  SelectableText(message.text, style: const TextStyle(fontSize: 16))
                else
                  RichAnswer(message.text),
                if (message.source != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    message.source == AnswerSource.ai ? 'AI tutor answer - double-check important facts' : 'Offline buddy answer',
                    style: TextStyle(fontSize: 12, color: g.textDim),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
