import 'package:flutter/material.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:nano_design_system/nano_design_system.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({
    super.key,
    required this.authRepository,
    required this.onSignedIn,
    this.initialEmail = AuthFixtures.aliEmail,
    this.onCreateAccount,
    this.onForgotPassword,
  });

  final AuthRepository authRepository;
  final ValueChanged<AuthBootstrap> onSignedIn;
  final String initialEmail;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onForgotPassword;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bootstrap = await widget.authRepository.signInWithPassword(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      widget.onSignedIn(bootstrap);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(NanoSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nano',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: NanoSpacing.sm),
                Text(
                  'Student sign-in',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: NanoSpacing.lg),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  enabled: !_busy,
                ),
                const SizedBox(height: NanoSpacing.md),
                TextField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(labelText: 'Password'),
                  enabled: !_busy,
                  onSubmitted: (_) => _busy ? null : _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: NanoSpacing.md),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: NanoSpacing.lg),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? 'Signing in…' : 'Sign in'),
                ),
                if (widget.onForgotPassword != null)
                  TextButton(
                    onPressed: _busy ? null : widget.onForgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                if (widget.onCreateAccount != null)
                  TextButton(
                    onPressed: _busy ? null : widget.onCreateAccount,
                    child: const Text('Create an independent account'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
