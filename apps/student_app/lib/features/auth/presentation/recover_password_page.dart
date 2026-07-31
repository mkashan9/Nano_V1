import 'package:flutter/material.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:nano_design_system/nano_design_system.dart';

/// Password recovery request (AUTH-04).
class RecoverPasswordPage extends StatefulWidget {
  const RecoverPasswordPage({
    super.key,
    required this.authRepository,
    this.onBackToSignIn,
    this.initialEmail = '',
  });

  final AuthRepository authRepository;
  final VoidCallback? onBackToSignIn;
  final String initialEmail;

  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends State<RecoverPasswordPage> {
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);
  var _busy = false;
  var _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validation = SignUpValidator.emailError(_email.text);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.authRepository.requestPasswordRecovery(_email.text);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _busy = false;
      });
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
                  'Reset your password',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: NanoSpacing.lg),
                if (_sent) ...[
                  Text(
                    'If that email has a Nano account, a reset link is on its way.',
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
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
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
                    child: Text(_busy ? 'Sending…' : 'Send reset link'),
                  ),
                  if (widget.onBackToSignIn != null)
                    TextButton(
                      onPressed: _busy ? null : widget.onBackToSignIn,
                      child: const Text('Back to sign in'),
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
