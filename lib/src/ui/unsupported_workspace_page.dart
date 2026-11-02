import 'package:flutter/material.dart';

import '../session.dart';
import '../theme/uds.dart';
import '../workspace.dart';
import 'kit/gm_kit.dart';

/// Peran yang belum dibawa ke aplikasi.
///
/// Bukan jalan buntu: pengguna diberi tahu perannya apa, kenapa pekerjaannya
/// lebih cocok di web, dan tetap bisa keluar dari akun. Menyembunyikan layar
/// ini akan membuat aplikasi terasa rusak.
class UnsupportedWorkspacePage extends StatelessWidget {
  const UnsupportedWorkspacePage({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final workspace = Workspace.fromAccountType(session.user?.accountType);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(Uds.gutter(context)),
        child: GmSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.desktop_windows_outlined, size: 32, color: Uds.gray500),
              const SizedBox(height: Uds.space3),
              Text(workspace.label, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Uds.space2),
              Text(workspace.description, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: Uds.space3),
              Text(
                'Aplikasi ponsel baru memuat tiga peran: penumpang, supir, dan penjaga warung. '
                'Sisanya dikerjakan di web karena butuh tabel dan layar lebar.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: Uds.space4),
              OutlinedButton.icon(
                onPressed: session.signOut,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
