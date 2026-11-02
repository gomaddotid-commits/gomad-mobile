import 'package:gomad_api/gomad_api.dart' as gomad;

import '../../session.dart';

/// Warung yang boleh dipakai akun ini, sesuai perannya di usaha.
///
/// Aturan yang dijaga server (dan dicerminkan di sini):
///
/// - **penjaga** berdiri di belakang satu meja kasir → paling banyak satu warung
///   (`AcceptBusinessInvitation` menolak undangan kedua)
/// - **pemilik** boleh punya beberapa warung → aplikasi wajib memberi pilihan,
///   bukan diam-diam memakai yang pertama
///
/// Daftar diambil dari `/v1/me/memberships`, bukan input bebas: aplikasi tidak
/// pernah mengarang id usaha.
Future<List<gomad.BusinessResource>> warungBusinesses(
  Session session, {
  required String role,
}) async {
  final response = await session.api.getIdentityApi().v1MeMemberships();
  final memberships = response.data?.data ?? const [];

  return memberships
      .where((business) => business.type == 'warung' && business.role == role)
      .toList(growable: false);
}

/// Warung tunggal untuk penjaga. `null` berarti akun ini belum terhubung ke
/// warung mana pun — layar menampilkan penjelasan, bukan layar kosong.
Future<gomad.BusinessResource?> guardWarung(Session session) async {
  final warungs = await warungBusinesses(session, role: 'penjaga');

  return warungs.isEmpty ? null : warungs.first;
}
