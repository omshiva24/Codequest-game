// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../logic/session.dart';
import '../services/account_service.dart';
import '../services/sound.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';
import 'home_screen.dart';
import 'navigation.dart';

final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
final RegExp _namePattern = RegExp(r'^[\p{L}\p{N}][\p{L}\p{M}\p{N} ._-]*$', unicode: true);

/// Checks used by the form (the server checks the same rules again).
String? validatePlayerName(String? value) {
  final name = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  if (name.length < 2 || name.length > 20) return 'Use 2 to 20 letters or numbers.';
  if (!_namePattern.hasMatch(name)) return 'Use letters, numbers, spaces, dots, - or _.';
  return null;
}

String? validateEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) return 'Enter your email.';
  if (email.length > 254 || !_emailPattern.hasMatch(email)) return 'That email does not look right.';
  return null;
}

String? validateNewPassword(String? value) {
  final password = value ?? '';
  if (password.length < 8) return 'Use at least 8 characters.';
  if (password.length > 128) return 'Use at most 128 characters.';
  return null;
}

/// "Who's playing?" - pick guest, log in or create an account.
/// Every player gets their own progress; nobody can see anyone else's.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.startWithSignUp = false});

  final bool startWithSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  late bool _signUp = widget.startWithSignUp;
  bool _showPassword = false;
  bool _busy = false;
  bool _bringGuest = true;
  String? _error;
  GuestSummary? _guest;

  SessionController get _session => SessionScope.maybeRead(context)!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final summary = await SessionScope.maybeRead(context)?.guestSummary();
      if (mounted) setState(() => _guest = summary);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(gameRoute<void>(const HomeScreen()), (_) => false);
  }

  Future<void> _playGuest({required bool fresh}) async {
    if (fresh && _guest != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start a new guest game?'),
          content: const Text(
            'The old guest progress on this device will be deleted. '
            'To keep progress safe, create your own account instead.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Start new')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await _session.playAsGuest(fresh: fresh);
    if (mounted) _goHome();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      if (_signUp) {
        await _session.register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          bringGuestProgress: _guest != null && _bringGuest,
        );
      } else {
        await _session.login(email: _email.text, password: _password.text);
      }
      TextInput.finishAutofillContext();
      SoundFx.play(Sfx.powerUp);
      if (mounted) _goHome();
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleMode() => setState(() {
        _signUp = !_signUp;
        _error = null;
        _formKey.currentState?.reset();
      });

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.maybeWatch(context);
    return GameScaffold(
      scene: SceneKind.menu,
      title: "Who's playing?",
      body: PageBody(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Row(
              children: [
                const ByteAvatar(size: 64),
                const SizedBox(width: 8),
                Expanded(
                  child: SpeechBubble(
                    child: Text(
                      'Every player gets their own progress. Nobody else can see yours!',
                      style: displayStyle(18, color: GameColors.of(context).ink, height: 1.25),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _guestPanel(context),
            const SizedBox(height: 14),
            if (session?.accountsEnabled ?? false)
              _accountPanel(context)
            else
              const ParchmentPanel(
                child: Text(
                  'Log in and accounts work in the web version of CodeQuest. '
                  'Here you can play as a guest.',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _guestPanel(BuildContext context) {
    final g = GameColors.of(context);
    final guest = _guest;
    return ParchmentPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelBanner(text: 'Play as guest', tone: ButtonTone.mint, icon: Icons.person_outline_rounded),
          const SizedBox(height: 8),
          const Text('No email needed. Guest progress stays only in this browser on this device, '
              'so anyone using this device can continue it.'),
          const SizedBox(height: 12),
          if (guest == null)
            GameButton(
              label: 'Play as guest',
              icon: Icons.play_arrow_rounded,
              tone: ButtonTone.mint,
              expand: true,
              onPressed: () => _playGuest(fresh: false),
            )
          else ...[
            GameButton(
              label: 'Continue guest game',
              semanticLabel: 'Continue guest game: player level ${guest.playerLevel}, ${guest.stars} stars',
              icon: Icons.play_arrow_rounded,
              tone: ButtonTone.mint,
              expand: true,
              onPressed: () => _playGuest(fresh: false),
            ),
            const SizedBox(height: 4),
            ExcludeSemantics(
              child: Text(
                'Saved guest game: level ${guest.playerLevel}, ${guest.stars} stars',
                style: TextStyle(color: g.parchmentDim, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            GameButton(
              label: 'New guest game',
              icon: Icons.fiber_new_rounded,
              tone: ButtonTone.parchment,
              size: GameButtonSize.small,
              expand: true,
              onPressed: () => _playGuest(fresh: true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _accountPanel(BuildContext context) {
    final g = GameColors.of(context);
    final guest = _guest;
    return ParchmentPanel(
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: PanelBanner(
                  text: _signUp ? 'Create your account' : 'Log in',
                  tone: ButtonTone.sky,
                  icon: _signUp ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
                ),
              ),
              const SizedBox(height: 8),
              Text(_signUp
                  ? 'Save your progress online and continue on any device. Only you can see it.'
                  : 'Welcome back! Log in to load your own progress.'),
              const SizedBox(height: 14),
              if (_signUp) ...[
                TextFormField(
                  controller: _name,
                  enabled: !_busy,
                  maxLength: 20,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.nickname],
                  style: TextStyle(color: g.parchmentText, fontSize: 16),
                  decoration: const InputDecoration(labelText: 'Player name', counterText: ''),
                  validator: validatePlayerName,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.email],
                style: TextStyle(color: g.parchmentText, fontSize: 16),
                decoration: const InputDecoration(labelText: 'Email'),
                validator: validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                enabled: !_busy,
                obscureText: !_showPassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
                style: TextStyle(color: g.parchmentText, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: _signUp ? 'At least 8 characters. Not your email.' : null,
                  helperStyle: TextStyle(color: g.parchmentDim, fontSize: 13),
                  suffixIcon: IconButton(
                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                    icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: g.ink),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                validator: _signUp
                    ? validateNewPassword
                    : (v) => (v == null || v.isEmpty) ? 'Enter your password.' : null,
              ),
              if (_signUp && guest != null) ...[
                const SizedBox(height: 8),
                Material(
                  type: MaterialType.transparency,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _bringGuest,
                    onChanged: _busy ? null : (v) => setState(() => _bringGuest = v ?? false),
                    title: Text(
                      'Bring my guest game into this account '
                      '(level ${guest.playerLevel}, ${guest.stars} stars)',
                      style: TextStyle(color: g.parchmentText, fontSize: 15),
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  container: true,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: g.coral,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: g.ink, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: g.ink),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!, style: TextStyle(color: g.ink, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              GameButton(
                label: _busy ? 'Please wait...' : (_signUp ? 'Create account' : 'Log in'),
                icon: _signUp ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
                tone: ButtonTone.sky,
                expand: true,
                onPressed: _busy ? null : _submit,
              ),
              const SizedBox(height: 10),
              GameButton(
                label: _signUp ? 'I already have an account' : 'New here? Create an account',
                tone: ButtonTone.parchment,
                size: GameButtonSize.small,
                expand: true,
                onPressed: _busy ? null : _toggleMode,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_rounded, size: 18, color: g.parchmentDim),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your password is stored only as a scrambled code (a hash) and your '
                      'email only as a coded ID. There is no password reset yet, so please '
                      'remember your password.',
                      style: TextStyle(color: g.parchmentDim, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
