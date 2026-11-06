# GoMad Mobile

Aplikasi Android/iOS untuk tiga peran yang benar-benar bekerja di ponsel:

| Peran (`account_type`) | Ruang kerja | Layar |
|---|---|---|
| `customer` | Penumpang | Beranda (cari jadwal) · Pesanan · Rincian pesanan · Akun |
| `driver` | Supir | Tugas · Rincian tugas + boarding · Akun |
| `warung_guard` | Penjaga warung | Kasir (POS) · Akun — **satu penjaga satu warung** |
| `warung_owner` | Pemilik warung | Penjualan (pantau, bisa berganti warung bila punya beberapa) · Akun |
| lainnya | — | Layar "belum ada di aplikasi" + jalan keluar |

Peran lain tetap memakai web karena pekerjaannya menuntut tabel dan layar lebar
(agency, grosir, ops, admin). Pemetaan peran hanya ada di satu tempat:
`lib/src/workspace.dart`.

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

### Kalau model hasil generate terasa aneh

Scramble membaca kode PHP, bukan niat kita. Empat jebakan yang sudah memakan
waktu dan cara menghindarinya:

| Gejala di Dart | Sebab | Perbaikan |
|---|---|---|
| field boolean jadi `String` | nilai dihitung lewat `in_array()` / kondisi bercabang | tulis perbandingan satu per satu, bungkus `(bool)`, pindahkan ke method bertipe |
| `id` jadi `Object?` | `$this->getKey()` tidak terbaca | `(int) $this->getKey()` |
| respons jadi `anyOf` dan kelas yang terpilih salah | dua `return` berbeda bentuk pada status yang sama | satu status = satu bentuk (contoh: tantangan MFA login → `428`, bukan `200`) || respons berubah bentuk setelah digabung | resource memakai `whenLoaded()` sehingga generator menulis `allOf: [Resource, {required: [...]}]` | jangan pakai `whenLoaded` untuk field yang selalu ada; controller yang memuat relasinya || `GET` tak punya parameter padahal butuh `business_id` | id dibaca dari badan permintaan | jadikan bagian jalur: `/warung/businesses/{business}/pos` |

Setelah mengubah resource/controller: ekspor ulang, regenerasi, lalu
`flutter analyze`. Jangan menambal tipe di sisi Dart.

## Mencoba aplikasi tanpa perangkat (web)

Aplikasi yang sama bisa dijalankan di browser — cara tercepat melihat hasilnya
utuh, tanpa emulator:

```
flutter build web --dart-define=GOMAD_API_BASE_URL=http://localhost:8200/api
cd build/web && python3 -m http.server 8300
# buka http://localhost:8300
```

Atau mode pengembangan dengan hot reload:

```
flutter run -d chrome --dart-define=GOMAD_API_BASE_URL=http://localhost:8200/api
```

Catatan: API harus mengizinkan CORS dari origin aplikasi. Konfigurasi Laravel
sekarang `Access-Control-Allow-Origin: *`, jadi cukup. Untuk produksi, batasi ke
domain aplikasi. Tampilan web ini untuk **verifikasi**, bukan target rilis —
rilisnya tetap APK/ipa.

## Menjalankan aplikasi

```
flutter pub get
flutter run --dart-define=GOMAD_API_BASE_URL=http://10.0.2.2:8200/api
```

`10.0.2.2` adalah alamat host dari emulator Android (pakai `localhost` bila
menjalankan di desktop, atau IP LAN mesin bila memakai perangkat fisik).
Kredensial demo (kata sandi `GomadDemo2026!`): `penumpang@gomad.test`,
`supir@gomad.test`, `penjaga.warung@gomad.test`, `warung.owner@gomad.test`.

Kerangka `android/` sudah ada (dibuat dengan `flutter create . --platforms=android
--org id.gomad`). Build:

```
flutter build apk --debug     # build/debug/app-debug.apk (pakai debug key)
flutter build apk --release   # build/release/app-release.apk (masih debug key)
```

Rilis sungguhan butuh keystore sendiri (`android/key.properties`) — belum
disiapkan.

**Catatan rilis:** `AndroidManifest` memuat `usesCleartextTraffic="true"` supaya
APK bisa memanggil API lokal (`http://`). Saat API sudah di HTTPS, hapus atribut
itu — jangan dibawa ke produksi. Izin `INTERNET` sengaja dipasang di manifest
utama; template Flutter hanya menaruhnya di manifest debug, sehingga APK rilis
gagal menghubungi server.

## Struktur

```
mobile/
├── api_client/              # hasil generate — JANGAN diedit
├── contracts/               # salinan kontrak OpenAPI (di-commit)
├── lib/
│   ├── main.dart            # tema ikut berubah bersama peran
│   └── src/
│       ├── api_config.dart  # base URL + Dio + klien
│       ├── session.dart     # token, refresh otomatis, retry 401
│       ├── workspace.dart   # account_type → ruang kerja native
│       ├── format.dart      # Rupiah, jam, tanggal
│       ├── theme/
│       │   ├── uds.dart          # token UDS v1.0 (salinan dari web)
│       │   └── gomad_theme.dart  # dua bahasa desain → ThemeData
│       └── ui/
│           ├── kit/gm_kit.dart   # padanan Flutter dari komponen `x-gm.*`
│           ├── shell/app_shell.dart
│           ├── home_page.dart  seat_page.dart  payment_page.dart
│           ├── account_page.dart  unsupported_workspace_page.dart
│           ├── passenger/  driver/  warung/
└── tool/pilot_smoke.dart     # uji alur langsung ke server lokal
```

## Pemeriksaan

```
flutter analyze                  # harus tanpa issue
flutter test                     # 12 tes: sesi, MFA, format, tema, peta peran
dart run tool/pilot_smoke.dart   # alur penumpang langsung ke server lokal
```

Catatan kontrak: `bin/export-api-contract` masih menyisakan **2 peringatan
Scramble** (JR001) pada `PosCatalogResource` dan `PosSalesResource`. Keduanya
bukan pembungkus satu model (isinya halaman/katalog), dan skema yang dihasilkan
tetap bertipe — sudah diperiksa: `data` = larik `RetailSaleResource`, katalog =
objek `business`/`today`/`listings`. Peringatan itu tidak memengaruhi klien.

## Yang sengaja belum ada

| Item | Alasan |
|---|---|
| `flutter_secure_storage` | butuh plugin native; `TokenStore` sudah jadi titik ganti |
| Push notification (FCM) | menunggu kredensial Firebase |
| Membuka tautan Snap langsung | butuh `url_launcher` |
| Bundling font Inter | web pun jatuh ke font sistem; berkas font belum ada di repo |
