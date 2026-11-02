import 'package:flutter/material.dart';

import '../session.dart';
import '../theme/uds.dart';
import 'kit/gm_kit.dart';

/// Layar masuk, termasuk langkah verifikasi dua langkah.
///
/// Dua keadaan, satu layar:
/// 1. formulir nomor/email + kata sandi
/// 2. formulir kode 6 angka — muncul bila server menjawab `428 MFA_REQUIRED`
///
/// Kode dikirim server ke email; aplikasi tidak pernah menyimpannya dan tidak
/// bisa melewati langkah ini. Kredensial demo lokal: `penumpang@gomad.test` /
/// `GomadDemo2026!`.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.session});

  final Session session;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identity = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _identity.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _message = null);

    try {
      await widget.session.login(
        identity: _identity.text.trim(),
        password: _password.text,
      );
      // Bila server meminta kode, `pendingMfa` terisi dan layar berganti sendiri.
      if (mounted) {
        setState(() => _code.clear());
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = widget.session.error ?? '$error');
    }
  }

  Future<void> _verify() async {
    setState(() => _message = null);

    try {
      await widget.session.verifyMfa(_code.text);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _message = widget.session.error ?? '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final busy = session.isBusy;
    final challenge = session.pendingMfa;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Uds.gray50, Uds.white, Color(0xFFF0F9E4)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Uds.space5),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Brand(),
                    const SizedBox(height: Uds.space5),
                    GmSurface(
                      child: challenge == null
                          ? _loginForm(context, busy)
                          : _mfaForm(context, busy, challenge),
                    ),
                    const SizedBox(height: Uds.space4),
                    Text(
                      'Server: ${session.baseUrl}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginForm(BuildContext context, bool busy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Masuk', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: Uds.space1),
        Text(
          'Pakai nomor telepon atau email yang terdaftar.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Uds.space4),
        TextField(
          key: const Key('identity'),
          controller: _identity,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Nomor telepon atau email'),
        ),
        const SizedBox(height: Uds.space3),
        TextField(
          key: const Key('password'),
          controller: _password,
          enabled: !busy,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Kata sandi'),
          onSubmitted: (_) => busy ? null : _submit(),
        ),
        if (_message != null) ...[
          const SizedBox(height: Uds.space3),
          GmNotice(_message!),
        ],
        const SizedBox(height: Uds.space4),
        FilledButton(
          key: const Key('login-submit'),
          onPressed: busy ? null : _submit,
          child: busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Uds.white),
                )
              : const Text('Masuk'),
        ),
      ],
    );
  }

  Widget _mfaForm(BuildContext context, bool busy, MfaChallenge challenge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.verified_user_outlined, size: 20, color: Uds.greenDeep),
            const SizedBox(width: Uds.space2),
            Expanded(
              child: Text('Verifikasi dua langkah', style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: Uds.space1),
        Text(
          'Kami mengirim kode 6 angka ke email akun ini. Kode berlaku sebentar, '
          'jadi masukkan yang paling baru.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Uds.space4),
        TextField(
          key: const Key('mfa-code'),
          controller: _code,
          enabled: !busy,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            labelText: 'Kode verifikasi',
            counterText: '',
          ),
          onSubmitted: (_) => busy ? null : _verify(),
        ),
        if (_message != null) ...[
          const SizedBox(height: Uds.space3),
          GmNotice(_message!),
        ],
        const SizedBox(height: Uds.space4),
        FilledButton(
          key: const Key('mfa-submit'),
          onPressed: busy ? null : _verify,
          child: Text(busy ? 'Memeriksa…' : 'Verifikasi'),
        ),
        const SizedBox(height: Uds.space2),
        TextButton(
          onPressed: busy ? null : widget.session.cancelMfa,
          child: const Text('Kembali ke formulir masuk'),
        ),
      ],
    );
  }
}

/// Tanda merek sederhana: huruf G di atas lime, nama, dan satu kalimat janji.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: Uds.lime,
            borderRadius: BorderRadius.circular(Uds.radiusLg),
          ),
          alignment: Alignment.center,
          child: const Text(
            'G',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Uds.black900),
          ),
        ),
        const SizedBox(height: Uds.space3),
        Text('GoMad', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 2),
        Text(
          'mad warung, mad trans',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
