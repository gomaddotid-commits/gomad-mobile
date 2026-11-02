import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gomad_api/gomad_api.dart' as gomad;

import 'api_config.dart';
import 'token_store.dart';

/// Sesi aplikasi: pemilik token, penyegar otomatis, dan klien API.
///
/// Semua aturan bisnis ada di server (kelas Core Laravel). Kelas ini hanya
/// mengurus tiga hal: menyimpan token, memperpanjangnya saat hampir kedaluwarsa,
/// dan mengulang satu permintaan yang gagal karena token tidak lagi berlaku.
class Session extends ChangeNotifier {
  Session({required ApiConfig config, TokenStore? store, Dio? dio})
      : _store = store ?? InMemoryTokenStore(),
        _config = config {
    _dio = dio ?? config.buildDio();
    _api = config.buildClient(_dio);

    _dio.interceptors.add(
      // Bukan QueuedInterceptorsWrapper: refresh mengirim permintaan baru dari dalam
      // onError, dan antrean akan mengunci permintaan itu sampai handler selesai.
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokens?.token;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (!_shouldRefresh(error)) {
            handler.next(error);
            return;
          }

          try {
            await refresh();
          } catch (_) {
            await signOut();
            handler.next(error);
            return;
          }

          final retryOptions = error.requestOptions;
          retryOptions.extra['gomad_retried'] = true;
          retryOptions.headers['Authorization'] = 'Bearer ${_tokens?.token}';

          try {
            handler.resolve(await _dio.fetch<dynamic>(retryOptions));
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  /// Nama perangkat yang dicatat pada token. Nama sama = perangkat yang sama,
  /// sehingga refresh merotasi token perangkat ini saja.
  static const deviceName = 'gomad-android';

  final ApiConfig _config;
  final TokenStore _store;

  late final Dio _dio;
  late final gomad.GomadApi _api;

  AuthTokens? _tokens;
  gomad.UserResource? _user;
  bool _busy = false;
  String? _error;
  MfaChallenge? _pendingMfa;

  gomad.GomadApi get api => _api;

  gomad.UserResource? get user => _user;

  bool get isAuthenticated => _tokens != null;

  bool get isBusy => _busy;

  String? get error => _error;

  /// Terisi bila server meminta kode verifikasi dua langkah (HTTP 428).
  ///
  /// Server menjawab 428 — bukan 200 dengan bentuk berbeda — supaya kontrak dan
  /// klien hanya punya satu bentuk jawaban sukses. Aplikasi membaca tantangan
  /// dari galat itu, lalu menukarnya lewat `/v1/auth/mfa/verify`.
  MfaChallenge? get pendingMfa => _pendingMfa;

  String get baseUrl => _config.baseUrl;

  /// Memulihkan token dari penyimpanan dan menyegarkannya bila hampir habis.
  Future<void> restore() async {
    _tokens = await _store.read();
    if (_tokens == null) {
      notifyListeners();
      return;
    }

    if (_tokens!.needsRefresh && !isBusy) {
      try {
        await refresh();
      } on DioException {
        // Token tersimpan sudah tidak berlaku — paksa pengguna masuk ulang.
        await signOut();
        return;
      }
    }

    await loadProfile();
  }

  Future<void> login({required String identity, required String password}) async {
    _busy = true;
    _error = null;
    _pendingMfa = null;
    notifyListeners();

    try {
      final response = await _api.getAuthApi().v1AuthLogin(
            v1AuthLoginRequest: gomad.V1AuthLoginRequest(
              identity: identity,
              password: password,
              deviceName: deviceName,
            ),
            extra: const {'gomad_skip_refresh': true},
          );
      final data = response.data?.data;
      if (data == null) {
        throw const SessionFailure('Respons login tidak dikenali.');
      }

      _user = data.user;
      await _applyTokens(AuthTokens(token: data.token, expiresAt: _parseDate(data.expiresAt)));
    } on DioException catch (error) {
      final challenge = _mfaChallengeOf(error);
      if (challenge != null) {
        // Bukan kegagalan: kata sandi benar, tinggal kode. Layar masuk akan
        // berganti ke formulir kode.
        _pendingMfa = challenge;
        return;
      }

      _error = _messageOf(error);
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Menukar kode 6 angka dengan token akses.
  Future<void> verifyMfa(String code) async {
    final challenge = _pendingMfa;
    if (challenge == null) {
      return;
    }

    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getAuthApi().v1AuthMfaVerify(
            v1AuthMfaVerifyRequest: gomad.V1AuthMfaVerifyRequest(
              mfaToken: challenge.token,
              code: code.trim(),
              deviceName: deviceName,
            ),
            extra: const {'gomad_skip_refresh': true},
          );
      final data = response.data?.data;
      if (data == null) {
        throw const SessionFailure('Respons verifikasi tidak dikenali.');
      }

      _user = data.user;
      _pendingMfa = null;
      await _applyTokens(AuthTokens(token: data.token, expiresAt: _parseDate(data.expiresAt)));
    } on DioException catch (error) {
      _error = _messageOf(error);
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Membatalkan tantangan MFA: kembali ke formulir masuk.
  void cancelMfa() {
    _pendingMfa = null;
    _error = null;
    notifyListeners();
  }

  /// Tantangan MFA diambil dari jawaban 428 (`code = MFA_REQUIRED`).
  MfaChallenge? _mfaChallengeOf(DioException error) {
    if (error.response?.statusCode != 428) {
      return null;
    }

    final data = error.response?.data;
    if (data is! Map) {
      return null;
    }

    final payload = data['data'];
    if (payload is! Map || payload['mfa_token'] is! String) {
      return null;
    }

    return MfaChallenge(
      token: payload['mfa_token'] as String,
      expiresAt: _parseDate(payload['expires_at'] as String?),
    );
  }

  /// Memperpanjang token tanpa meminta kata sandi. Token lama untuk perangkat
  /// ini dihapus oleh server.
  Future<void> refresh() async {
    if (_tokens == null) {
      return;
    }

    final response = await _api.getAuthApi().v1AuthRefresh(
          extra: const {'gomad_skip_refresh': true},
        );
    final data = response.data?.data;
    if (data == null) {
      throw const SessionFailure('Respons refresh tidak dikenali.');
    }

    _user = data.user;
    await _applyTokens(AuthTokens(token: data.token, expiresAt: _parseDate(data.expiresAt)));
    notifyListeners();
  }

  Future<void> loadProfile() async {
    if (_tokens == null) {
      return;
    }

    try {
      final response = await _api.getIdentityApi().v1MeShow();
      _user = response.data?.data.user;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await signOut();
        return;
      }
      _error = _messageOf(error);
    }

    notifyListeners();
  }

  /// Keluar: hapus token di server lalu bersihkan penyimpanan lokal.
  Future<void> signOut() async {
    if (_tokens != null) {
      try {
        await _api.getAuthApi().v1AuthLogout(extra: const {'gomad_skip_refresh': true});
      } on DioException {
        // Token mungkin sudah tidak berlaku; keluar tetap dilanjutkan.
      }
    }

    await _forget();
  }

  Future<void> _applyTokens(AuthTokens tokens) async {
    _tokens = tokens;
    _dio.options.headers['Authorization'] = 'Bearer ${tokens.token}';
    await _store.write(tokens);
    notifyListeners();
  }

  Future<void> _forget() async {
    _tokens = null;
    _user = null;
    _pendingMfa = null;
    _dio.options.headers.remove('Authorization');
    await _store.clear();
    notifyListeners();
  }

  bool _shouldRefresh(DioException error) {
    final options = error.requestOptions;

    return error.response?.statusCode == 401 &&
        _tokens != null &&
        options.extra['gomad_skip_refresh'] != true &&
        options.extra['gomad_retried'] != true;
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static String _messageOf(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Tidak dapat menghubungi server (${error.requestOptions.baseUrl}).';
    }

    return error.message ?? 'Permintaan gagal.';
  }
}

class SessionFailure implements Exception {
  const SessionFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Tantangan verifikasi dua langkah yang menunggu kode dari email.
///
/// `token` adalah tiket sementara (bukan token akses) yang hanya bisa ditukar
/// dengan kode yang dikirim server — tidak bisa dipakai memanggil endpoint lain.
class MfaChallenge {
  const MfaChallenge({required this.token, this.expiresAt});

  final String token;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}
