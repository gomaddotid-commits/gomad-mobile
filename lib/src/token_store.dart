/// Penyimpanan token sesi.
///
/// Implementasi bawaan menyimpan di memori (cukup untuk alur pilot dan tes).
/// Untuk produksi ganti dengan `flutter_secure_storage` / Keystore Android —
/// token tidak boleh ditulis ke `SharedPreferences` biasa.
abstract class TokenStore {
  Future<AuthTokens?> read();

  Future<void> write(AuthTokens tokens);

  Future<void> clear();
}

class AuthTokens {
  const AuthTokens({required this.token, this.expiresAt});

  final String token;
  final DateTime? expiresAt;

  /// Token dianggap perlu diperpanjang bila sisa umurnya di bawah tiga hari.
  bool get needsRefresh {
    final expiry = expiresAt;
    if (expiry == null) {
      return false;
    }

    return expiry.difference(DateTime.now()) < const Duration(days: 3);
  }
}

class InMemoryTokenStore implements TokenStore {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }
}
