import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../models/models.dart';
import '../services/doubt_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';

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
    final newBadges = AppScope.read(context).markAskedDoubt();
    if (newBadges.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Badge unlocked: ${newBadges.first.title} ${newBadges.first.emoji}'),
      ));
    }
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
    return GameScaffold(
      scene: SceneKind.menu,
      title: 'Doubt Buddy',
      body: PageBody(
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  _LangChip(label: 'Any language', selected: _lang == null, onTap: () => setState(() => _lang = null)),
                  for (final lang in Lang.values)
                    _LangChip(
                      label: '${lang.emoji} ${lang.label}',
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
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ByteAvatar(size: 46),
                          const SizedBox(width: 4),
                          Flexible(
                            child: SpeechBubble(
                              child: Semantics(
                                liveRegion: true,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 3, color: g.ink),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Byte is thinking...'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 10, left: 50),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _suggestions)
                          ActionChip(
                            label: Text(s),
                            onPressed: () => _send(s),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        style: TextStyle(color: g.parchmentText, fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: 'Ask your doubt, e.g. What does i++ mean?',
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: RoundIconButton(
                        icon: Icons.send_rounded,
                        tooltip: 'Send question',
                        tone: ButtonTone.gold,
                        onPressed: _busy ? null : _send,
                      ),
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
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user)
          SelectableText(message.text, style: TextStyle(fontSize: 16, color: g.ink))
        else
          RichAnswer(message.text),
        if (message.source != null) ...[
          const SizedBox(height: 6),
          Text(
            message.source == AnswerSource.ai
                ? 'AI tutor answer - double-check important facts'
                : 'Offline buddy answer',
            style: TextStyle(fontSize: 13, color: g.parchmentDim),
          ),
        ],
      ],
    );
    return Semantics(
      liveRegion: announce,
      label: user ? 'You asked' : 'Byte answered',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: user
            ? Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SpeechBubble(tailLeft: false, color: g.gold, child: content),
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ByteAvatar(size: 46, bob: false),
                  const SizedBox(width: 4),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: SpeechBubble(child: content),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
