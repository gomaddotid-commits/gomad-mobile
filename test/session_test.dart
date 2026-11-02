import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomad_mobile/src/api_config.dart';
import 'package:gomad_mobile/src/session.dart';
import 'package:gomad_mobile/src/token_store.dart';

/// Adapter HTTP palsu: mencatat setiap permintaan dan membalas sesuai skrip.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.responder);

  final ResponseBody Function(RequestOptions options, int callIndex) responder;
  final List<RequestOptions> calls = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = calls.length;
    calls.add(options);

    return responder(options, index);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Map<String, dynamic> body, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Map<String, dynamic> userPayload([String name = 'Penumpang Uji']) {
  return {
    'id': 7,
    'name': name,
    'phone': '+6281234567890',
    'email': 'uji@gomad.test',
    'phone_verified_at': null,
    'membership': null,
  };
}

void main() {
  late InMemoryTokenStore store;
  late FakeAdapter adapter;
  late Session session;

  Session buildSession(FakeAdapter fakeAdapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://uji.local/api'))
      ..httpClientAdapter = fakeAdapter;

    return Session(
      config: const ApiConfig(baseUrl: 'http://uji.local/api'),
      store: store,
      dio: dio,
    );
  }

  setUp(() {
    store = InMemoryTokenStore();
  });

  test('login menyimpan token dan mengirim nama perangkat', () async {
    adapter = FakeAdapter(
      (options, _) => jsonResponse({
        'data': {
          'token': 'token-awal',
          'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'user': userPayload(),
        },
      }),
    );
    session = buildSession(adapter);

    await session.login(identity: 'uji@gomad.test', password: 'rahasia-panjang');

    expect(session.isAuthenticated, isTrue);
    expect(session.user?.name, 'Penumpang Uji');
    expect((await store.read())?.token, 'token-awal');
    expect(adapter.calls.single.path, '/v1/auth/login');
    final sent = jsonDecode(adapter.calls.single.data as String) as Map<String, dynamic>;
    expect(sent['device_name'], Session.deviceName);
  });

  test('permintaan 401 diulang setelah token diperpanjang', () async {
    adapter = FakeAdapter((options, index) {
      if (options.path == '/v1/auth/login') {
        return jsonResponse({
          'data': {
            'token': 'token-awal',
            'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
            'user': userPayload(),
          },
        });
      }

      if (options.path == '/v1/auth/refresh') {
        return jsonResponse({
          'data': {
            'token': 'token-baru',
            'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
            'device_name': Session.deviceName,
            'user': userPayload(),
          },
        });
      }

      if (options.path == '/v1/me') {
        // Permintaan pertama ditolak, percobaan kedua berhasil.
        return index < 3
            ? jsonResponse({'message': 'Autentikasi diperlukan.', 'code': 'UNAUTHENTICATED'}, status: 401)
            : jsonResponse({'data': {'user': userPayload('Nama Terbaru')}});
      }

      return jsonResponse({'message': 'tidak dikenal'}, status: 404);
    });
    session = buildSession(adapter);

    await session.login(identity: 'uji@gomad.test', password: 'rahasia-panjang');
    await session.loadProfile();

    expect(
      adapter.calls.map((call) => call.path).toList(),
      ['/v1/auth/login', '/v1/me', '/v1/auth/refresh', '/v1/me'],
    );
    expect(session.isAuthenticated, isTrue);
    expect((await store.read())?.token, 'token-baru');
    expect(adapter.calls.last.headers['Authorization'], 'Bearer token-baru');
    expect(session.user?.name, 'Nama Terbaru');
  });

  test('refresh gagal membuat pengguna keluar', () async {
    adapter = FakeAdapter((options, _) {
      if (options.path == '/v1/auth/login') {
        return jsonResponse({
          'data': {
            'token': 'token-awal',
            'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
            'user': userPayload(),
          },
        });
      }

      return jsonResponse({'message': 'Autentikasi diperlukan.', 'code': 'UNAUTHENTICATED'}, status: 401);
    });
    session = buildSession(adapter);

    await session.login(identity: 'uji@gomad.test', password: 'rahasia-panjang');
    await session.loadProfile();

    expect(session.isAuthenticated, isFalse);
    expect(await store.read(), isNull);
  });

  test('token yang hampir kedaluwarsa ditandai perlu diperpanjang', () {
    final soon = AuthTokens(
      token: 'x',
      expiresAt: DateTime.now().add(const Duration(hours: 5)),
    );
    final later = AuthTokens(
      token: 'y',
      expiresAt: DateTime.now().add(const Duration(days: 20)),
    );

    expect(soon.needsRefresh, isTrue);
    expect(later.needsRefresh, isFalse);
  });
}
