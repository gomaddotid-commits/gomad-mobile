import 'package:flutter/material.dart';

import '../session.dart';
import '../theme/uds.dart';
import '../workspace.dart';
import 'kit/gm_kit.dart';

/// Layar akun: siapa yang sedang masuk, di peran apa, dan jalan keluar.
///
/// Sengaja sederhana: aplikasi native hanya menampilkan data yang sudah ada di
/// sesi (tidak ada endpoint baru), dan menunjuk ke web untuk pengaturan yang
/// lebih panjang seperti keamanan akun dan data usaha.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    final workspace = Workspace.fromAccountType(user?.accountType);

    return ListView(
      padding: EdgeInsets.all(Uds.gutter(context)),
      children: [
        Text('Akun', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: Uds.space4),
        GmSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Uds.lime,
                    child: Text(
                      _initials(user?.name),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Uds.black900,
                      ),
                    ),
                  ),
                  const SizedBox(width: Uds.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Tidak dikenal',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.phone ?? user?.email ?? '-',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Uds.space4),
              const Divider(),
              const SizedBox(height: Uds.space3),
              GmKeyValue('Peran', workspace.label),
              if (user?.accountType != null) GmKeyValue('Jenis akun', user!.accountType),
              GmKeyValue('Server', session.baseUrl),
            ],
          ),
        ),
        const SizedBox(height: Uds.space4),
        GmSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ruang kerja lain', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Uds.space2),
              Text(
                'Pengaturan usaha, undangan anggota, dan laporan lengkap ada di web. '
                'Aplikasi ini hanya memuat pekerjaan yang benar-benar dilakukan di ponsel.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: Uds.space4),
        OutlinedButton.icon(
          onPressed: session.signOut,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Keluar'),
        ),
      ],
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) {
      return '?';
    }

    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';

    return (first + last).toUpperCase();
  }
}
