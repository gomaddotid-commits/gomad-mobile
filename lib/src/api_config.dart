import 'package:dio/dio.dart';
import 'package:gomad_api/gomad_api.dart' as gomad;

/// Konfigurasi runtime aplikasi.
///
/// `baseUrl` diisi lewat `--dart-define` supaya build staging dan produksi
/// memakai build yang sama:
///
/// ```
/// flutter run --dart-define=GOMAD_API_BASE_URL=http://10.0.2.2:8200/api
/// ```
///
/// `10.0.2.2` adalah alamat host bila dijalankan dari emulator Android.
class ApiConfig {
  const ApiConfig({required this.baseUrl});

  factory ApiConfig.fromEnvironment() {
    const override = String.fromEnvironment('GOMAD_API_BASE_URL');

    return ApiConfig(
      baseUrl: override.isEmpty ? 'http://10.0.2.2:8200/api' : override,
    );
  }

  /// Basis tanpa garis miring di akhir, mis. `http://10.0.2.2:8200/api`.
  final String baseUrl;

  /// [Dio] bersama — dipakai `Session` untuk menyisipkan token.
  Dio buildDio() {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );
  }

  /// Klien hasil generate dari kontrak OpenAPI.
  ///
  /// Token tidak disimpan di klien; `Session` menambahkannya sebagai header.
  gomad.GomadApi buildClient(Dio dio) => gomad.GomadApi(dio: dio);
}
