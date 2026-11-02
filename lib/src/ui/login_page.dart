import 'package:flutter/material.dart';

import '../session.dart';

/// Halaman masuk. Kredensial demo lokal: `penumpang@gomad.test` / `GomadDemo2026!`.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.session});

  final Session session;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identity = TextEditingController();
  final _password = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _message = null);

    try {
      await widget.session.login(
        identity: _identity.text.trim(),
        password: _password.text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = widget.session.error ?? '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.session.isBusy;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('GoMad', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(
                  'Masuk untuk memesan tiket Mad Trans.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('identity'),
                  controller: _identity,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Nomor telepon atau email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('password'),
                  controller: _password,
                  enabled: !busy,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata sandi',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => busy ? null : _submit(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('login-submit'),
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Masuk'),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Server: ${widget.session.baseUrl}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
