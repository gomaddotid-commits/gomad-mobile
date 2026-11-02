# GoMad Mobile

Mobile client for GoMad. Consumes the versioned OpenAPI contract exported from
the `gomad-api` repository into `contracts/openapi.yaml`.

## Klien Dart (hasil generate — jangan ditulis manual)

Kontrak dan klien selalu dibuat dari kode Laravel, bukan ditulis tangan:

```
bash ../api/bin/export-api-contract      # Scramble → api/openapi + contracts/openapi.yaml
bash ../api/bin/generate-dart-client     # openapi-generator (dart-dio) → mobile/api_client
```

Pakai di aplikasi:

```
dependencies:
  gomad_api:
    path: api_client
```

`api_client/` adalah artefak build (regenerasi kapan saja), sedangkan
`contracts/openapi.yaml` di-commit agar perubahan kontrak terlihat saat review.

## Menjalankan aplikasi

```
flutter pub get
flutter run --dart-define=GOMAD_API_BASE_URL=http://10.0.2.2:8200/api
```

`10.0.2.2` adalah alamat host dari emulator Android (pakai `localhost` bila
menjalankan di desktop). Kredensial demo: `penumpang@gomad.test` / `GomadDemo2026!`.

Folder `android/` belum dibuat. Sekali saja, di mesin yang punya Android SDK:

```
flutter create . --platforms=android --org id.gomad
```

## Pemeriksaan

```
flutter analyze          # harus tanpa issue
flutter test             # tes sesi (refresh token) + format
dart run tool/pilot_smoke.dart   # alur pilot langsung ke server lokal
```

`tool/pilot_smoke.dart` masuk sebagai `penumpang@gomad.test`, mencari jadwal,
memesan satu kursi, lalu membuat pembayaran Snap. Pakai
`GOMAD_ORIGIN`/`GOMAD_DEST` untuk mengganti rute.


