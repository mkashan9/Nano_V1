import 'package:flutter/material.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:nano_design_system/nano_design_system.dart';

/// Independent student self-service signup (AUTH-04).
class SignUpPage extends StatefulWidget {
  const SignUpPage({
    super.key,
    required this.authRepository,
    required this.onSignedUp,
    this.onBackToSignIn,
  });

  final AuthRepository authRepository;
  final ValueChanged<AuthBootstrap> onSignedUp;
  final VoidCallback? onBackToSignIn;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  String? _error;
  var _confirmationSent = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validation = SignUpValidator.displayNameError(_name.text) ??
        SignUpValidator.emailError(_email.text) ??
        SignUpValidator.passwordError(_password.text);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.authRepository.signUpIndependent(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
      );
      if (!mounted) return;
      final bootstrap = result.bootstrap;
      if (bootstrap != null) {
        widget.onSignedUp(bootstrap);
        return;
      }
      setState(() {
        _confirmationSent = true;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = describeAuthError(e);
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
                  'Create your Nano account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: NanoSpacing.sm),
                Text(
                  'For learners without a school code',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: NanoSpacing.lg),
                if (_confirmationSent) ...[
                  Text(
                    'Check your email to confirm your account, then sign in.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: NanoSpacing.lg),
                  FilledButton(
                    onPressed: widget.onBackToSignIn,
                    child: const Text('Back to sign in'),
                  ),
                ] else ...[
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    enabled: !_busy,
                  ),
                  const SizedBox(height: NanoSpacing.md),
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
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      helperText: 'At least 8 characters, letters and numbers',
                    ),
                    enabled: !_busy,
                    onSubmitted: (_) => _busy ? null : _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: NanoSpacing.md),
                    Text(
                      _error!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: NanoSpacing.lg),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? 'Creating account…' : 'Create account'),
                  ),
                  if (widget.onBackToSignIn != null)
                    TextButton(
                      onPressed: _busy ? null : widget.onBackToSignIn,
                      child: const Text('I already have an account'),
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
