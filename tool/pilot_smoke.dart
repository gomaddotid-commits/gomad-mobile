// Uji cepat alur pilot langsung ke server (bukan tes unit).
//
//   dart run tool/pilot_smoke.dart
//   GOMAD_API_BASE_URL=http://localhost:8200/api dart run tool/pilot_smoke.dart
//
// Skrip ini memakai klien Dart hasil generate — bukti bahwa kontrak OpenAPI,
// auth token, dan alur pesan tiket benar-benar jalan dari klien, bukan hanya di tes.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gomad_api/gomad_api.dart' as gomad;

const baseUrl = String.fromEnvironment(
  'GOMAD_API_BASE_URL',
  defaultValue: 'http://localhost:8200/api',
);

// Dibaca saat runtime agar bisa diubah tanpa build ulang.
final identity = Platform.environment['GOMAD_IDENTITY'] ?? 'penumpang@gomad.test';
final password = Platform.environment['GOMAD_PASSWORD'] ?? 'GomadDemo2026!';
final originCity = Platform.environment['GOMAD_ORIGIN'] ?? 'Jakarta';
final destinationCity = Platform.environment['GOMAD_DEST'] ?? 'Bandung';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    ),
  );
  final api = gomad.GomadApi(dio: dio);
  var failed = false;

  void step(String message) => stdout.writeln('• $message');

  Future<void> check(String name, Future<void> Function() body) async {
    try {
      await body();
      step('OK   $name');
    } catch (error) {
      failed = true;
      stderr.writeln('GAGAL $name: $error');
    }
  }

  String? token;

  await check('login', () async {
    final response = await api.getAuthApi().v1AuthLogin(
          v1AuthLoginRequest: gomad.V1AuthLoginRequest(
            identity: identity,
            password: password,
            deviceName: 'pilot-smoke',
          ),
        );
    token = response.data?.data.token;
    if (token == null || token!.isEmpty) {
      throw StateError('token kosong');
    }
    dio.options.headers['Authorization'] = 'Bearer $token';
    step('     token ${token!.substring(0, 12)}… untuk ${response.data?.data.user.name}');
  });

  await check('profil /me', () async {
    final response = await api.getIdentityApi().v1MeShow();
    step('     pengguna: ${response.data?.data.user.name}');
  });

  await check('refresh token', () async {
    final response = await api.getAuthApi().v1AuthRefresh();
    final fresh = response.data?.data.token;
    if (fresh == null || fresh.isEmpty || fresh == token) {
      throw StateError('token tidak berotasi');
    }
    token = fresh;
    dio.options.headers['Authorization'] = 'Bearer $fresh';
    step('     token baru ${fresh.substring(0, 12)}… kedaluwarsa ${response.data?.data.expiresAt}');
  });

  gomad.V1MadTransSchedulesIndex200ResponseDataInner? schedule;

  await check('cari jadwal $originCity → $destinationCity', () async {
    for (var offset = 1; offset <= 7; offset++) {
      final date = DateTime.now().add(Duration(days: offset));
      final response = await api.getMadTransApi().v1MadTransSchedulesIndex(
            originCity: originCity,
            destinationCity: destinationCity,
            departureDate: date,
            passengers: 1,
          );
      final found = response.data?.data ?? const [];

      if (found.isNotEmpty) {
        schedule = found.first;
        final picked = schedule!;
        step(
          '     ${found.length} jadwal pada ${date.year}-${date.month}-${date.day}; '
          'contoh ${picked.agency.name} ${picked.departureTime} ${picked.pricePerSeat}',
        );
        return;
      }
    }

    step('     (tidak ada jadwal dalam 7 hari — data demo belum berisi rute ini)');
  });

  if (schedule == null) {
    stdout.writeln('\nSebagian alur terverifikasi. Buat jadwal demo untuk menguji pesan tiket.');
    exit(failed ? 1 : 0);
  }

  final picked = schedule!;
  final scheduleId = int.parse('${picked.id}');

  await check('peta kursi', () async {
    final response = await api.getMadTransApi().v1MadTransSchedulesSeats(
          schedule: scheduleId,
          originStopId: picked.originStop.id,
          destinationStopId: picked.destinationStop.id,
        );
    final data = response.data?.data;
    step('     tersedia ${data?.available} dari tata letak ${data?.layout}');
  });

  await check('buat pesanan + bayar', () async {
    final seats = await api.getMadTransApi().v1MadTransSchedulesSeats(
          schedule: scheduleId,
          originStopId: picked.originStop.id,
          destinationStopId: picked.destinationStop.id,
        );
    final available = (seats.data?.data.available ?? const []).map((seat) => '$seat').toList();
    if (available.isEmpty) {
      throw StateError('tidak ada kursi tersedia pada jadwal ini');
    }

    final key = 'pilot-${DateTime.now().microsecondsSinceEpoch}';
    final booking = await api.getMadTransApi().v1MadTransBookingsStore(
          v1MadTransBookingsStoreRequest: gomad.V1MadTransBookingsStoreRequest(
            scheduleId: scheduleId,
            originStopId: picked.originStop.id,
            destinationStopId: picked.destinationStop.id,
            paymentMethod: gomad.V1MadTransBookingsStoreRequestPaymentMethodEnum.midtrans,
            passengers: {
              gomad.V1MadTransBookingsStoreRequestPassengersInner(
                seatNumber: available.first,
                name: 'Penumpang Pilot',
                phone: '+628111222333',
              ),
            },
          ),
          headers: {'Idempotency-Key': key},
        );
    final created = booking.data?.data;
    step('     pesanan ${created?.code} total ${created?.totalPrice} kursi ${available.first}');

    final payment = await api.getMadTransApi().v1MadTransBookingsPay(
          booking: int.parse('${created?.id}'),
          headers: {'Idempotency-Key': '$key-pay'},
        );
    step('     pembayaran ${payment.data?.data.paymentCode} status ${payment.data?.data.status} '
        'snap ${payment.data?.data.snapToken?.substring(0, 10)}…');

    // Pesanan yang sudah punya payment intent tidak dapat dibatalkan lewat API;
    // server menandainya lewat `gomad:money-health` bila pembayaran menggantung.
    try {
      final cancelled = await api.getMadTransApi().v1MadTransBookingsCancel(
            booking: int.parse('${created?.id}'),
          );
      step('     pesanan dibatalkan, status ${cancelled.data?.data.status}');
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) {
        step('     catatan: pesanan pending dengan payment intent dibiarkan menggantung');
      } else {
        rethrow;
      }
    }
  });

  stdout.writeln(failed ? '\nAda langkah yang gagal.' : '\nSemua langkah pilot berhasil.');
  exit(failed ? 1 : 0);
}
