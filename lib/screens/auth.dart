import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

// ---------------------------------------------------------------------------
// Sign in
// ---------------------------------------------------------------------------

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return Scaffold(
      backgroundColor: C.canvas,
      body: wide
          ? const Row(
              children: [
                Expanded(flex: 5, child: _BrandPanel()),
                Expanded(flex: 6, child: _FormSide()),
              ],
            )
          : const _FormSide(compactHeader: true),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: C.ink,
        child: Stack(
        children: [
          Positioned(
            right: -150,
            bottom: -150,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: C.brand, width: 64),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wordmark(size: 26),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Text(
                    'Every story, every call, every sprint — in one place.',
                    style: dx(42, color: C.onInk),
                  ),
                ),
                const SizedBox(height: 28),
                const _BrandPoint(
                  color: C.youtube,
                  title: 'YouTube',
                  text: 'See where each video is, from idea to published.',
                ),
                const _BrandPoint(
                  color: C.marketing,
                  title: 'Marketing',
                  text: 'Log calls in seconds and never miss a follow-up.',
                ),
                const _BrandPoint(
                  color: C.development,
                  title: 'Development',
                  text: 'Plan sprints, assign tasks and track progress.',
                ),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: C.onInkMuted,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: backToWebsite,
                  icon: const Icon(Icons.arrow_back_rounded,
                      size: 16, color: C.onInkMuted),
                  label: const Text('Back to website'),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _BrandPoint extends StatelessWidget {
  const _BrandPoint(
      {required this.color, required this.title, required this.text});

  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Dot(color, size: 9),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: '$title  ',
                      style: tx(15, w: FontWeight.w800, color: C.onInk)),
                  TextSpan(
                      text: text,
                      style: tx(15, color: C.onInkMuted, h: 1.45)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSide extends StatelessWidget {
  const _FormSide({this.compactHeader = false});

  final bool compactHeader;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (compactHeader)
          Container(
            width: double.infinity,
            color: C.ink,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                child: Row(
                  children: [
                    const Wordmark(size: 22),
                    const Spacer(),
                    TextButton(
                      style:
                          TextButton.styleFrom(foregroundColor: C.onInkMuted),
                      onPressed: backToWebsite,
                      child: const Text('Website'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: const _SignInForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignInForm extends StatefulWidget {
  const _SignInForm();

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = authMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    final store = StoreScope.read(context);
    final email = _email.text.trim();
    final password = _password.text;
    if (_creating && _name.text.trim().isEmpty) {
      setState(() => _error = 'Tell us your name so the team knows who you are.');
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    _guard(() => _creating
        ? store.signUpWithEmail(_name.text, email, password)
        : store.signInWithEmail(email, password));
  }

  void _forgot() {
    final store = StoreScope.read(context);
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() {
        _notice = null;
        _error = 'Enter your email above and we’ll send a reset link.';
      });
      return;
    }
    _guard(() async {
      await store.sendPasswordReset(email);
      if (mounted) {
        setState(() => _notice = 'Password reset link sent to $email.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.read(context);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: kMotion,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, if (current != null) current],
            ),
            child: Column(
              key: ValueKey(_creating),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_creating ? 'Create your account' : 'Welcome back',
                    style: dx(32)),
                const SizedBox(height: 8),
                Text(
                  _creating
                      ? 'An admin approves new accounts before you get access.'
                      : 'Sign in to the OMorals Media workspace.',
                  style: tx(14.5, color: C.muted, h: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (kIsWeb) ...[
            OutlinedButton(
              onPressed:
                  _busy ? null : () => _guard(store.signInWithGoogle),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('G',
                      style: dx(18,
                          w: FontWeight.w800, color: const Color(0xFF4285F4))),
                  const SizedBox(width: 10),
                  const Text('Continue with Google'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or with email',
                      style: tx(12.5, color: C.faint)),
                ),
                const Expanded(child: Divider()),
              ]),
            ),
          ],
          AnimatedSize(
            duration: kMotion,
            alignment: Alignment.topCenter,
            child: _creating
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration:
                          const InputDecoration(labelText: 'Your name'),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: [
              _creating ? AutofillHints.newPassword : AutofillHints.password
            ],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: kMotion,
            alignment: Alignment.topCenter,
            child: _error == null && _notice == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _Banner(
                      text: _error ?? _notice!,
                      color: _error != null ? C.danger : C.success,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: C.muted),
                  )
                : Text(_creating ? 'Create account' : 'Sign in'),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _creating = !_creating;
                          _error = null;
                          _notice = null;
                        }),
                child: Text(_creating
                    ? 'Have an account? Sign in'
                    : 'New here? Create an account'),
              ),
              if (!_creating)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: C.muted),
                  onPressed: _busy ? null : _forgot,
                  child: const Text('Forgot password?'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint(color, 0.08),
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border.all(color: tint(color, 0.35)),
      ),
      child: Text(text,
          style: tx(13.5,
              w: FontWeight.w600, color: Color.lerp(color, C.ink, 0.25)!)),
    );
  }
}

// ---------------------------------------------------------------------------
// Status screens
// ---------------------------------------------------------------------------

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: C.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wordmark(size: 28),
            SizedBox(height: 24),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: C.inkLine,
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusScreen extends StatelessWidget {
  const _StatusScreen({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.footnote,
    this.primary,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget? footnote;
  final Widget? primary;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final email = store.authUser?.email;
    return Scaffold(
      backgroundColor: C.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Wordmark(onInk: false, size: 24),
                  const SizedBox(height: 28),
                  Panel(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: tint(color, 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, color: color, size: 28),
                        ),
                        const SizedBox(height: 20),
                        Text(title,
                            textAlign: TextAlign.center, style: dx(26)),
                        const SizedBox(height: 10),
                        Text(message,
                            textAlign: TextAlign.center,
                            style: tx(14.5, color: C.muted, h: 1.55)),
                        if (footnote != null) ...[
                          const SizedBox(height: 20),
                          footnote!,
                        ],
                        const SizedBox(height: 24),
                        if (primary != null) ...[
                          SizedBox(width: double.infinity, child: primary),
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: store.signOut,
                            child: const Text('Sign out'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (email != null && email.isNotEmpty)
                    Text('Signed in as $email',
                        style: tx(12.5, color: C.muted)),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: C.muted),
                    onPressed: backToWebsite,
                    child: const Text('Back to website'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = StoreScope.of(context).me;
    return _StatusScreen(
      icon: Icons.hourglass_top_rounded,
      color: C.warn,
      title: 'Waiting for approval',
      message:
          'Thanks, ${me?.firstName ?? 'there'}. Your account is ready — an admin '
          'just needs to approve it and pick your team. You can leave this '
          'page open; it unlocks by itself the moment you’re in.',
      footnote: const _LiveHint(),
    );
  }
}

class _LiveHint extends StatefulWidget {
  const _LiveHint();

  @override
  State<_LiveHint> createState() => _LiveHintState();
}

class _LiveHintState extends State<_LiveHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: C.canvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.3, end: 1).animate(_c),
            child: const Dot(C.success),
          ),
          const SizedBox(width: 8),
          Text('Checking for approval automatically',
              style: tx(12.5, w: FontWeight.w600, color: C.muted)),
        ],
      ),
    );
  }
}

class DisabledScreen extends StatelessWidget {
  const DisabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StatusScreen(
      icon: Icons.lock_outline_rounded,
      color: C.danger,
      title: 'Access removed',
      message:
          'Your access to the OMorals workspace has been switched off. If you '
          'think this is a mistake, please speak to the workspace owner.',
    );
  }
}

class FailedScreen extends StatelessWidget {
  const FailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return _StatusScreen(
      icon: Icons.cloud_off_rounded,
      color: C.muted,
      title: 'Couldn’t open the workspace',
      message: store.failure ?? 'Something went wrong. Please try again.',
      primary: FilledButton(
        onPressed: store.retry,
        child: const Text('Try again'),
      ),
    );
  }
}
