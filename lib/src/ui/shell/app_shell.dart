import 'package:flutter/material.dart';

import '../../session.dart';
import '../../theme/uds.dart';
import '../../workspace.dart';
import '../account_page.dart';
import '../driver/tasks_page.dart';
import '../home_page.dart';
import '../passenger/bookings_page.dart';
import '../warung/pos_page.dart';
import '../warung/sales_report_page.dart';

/// Kerangka aplikasi setelah masuk: satu bilah navigasi, isi berbeda per peran.
///
/// Shell ini yang memilih bahasa desain. Penumpang mendapat latar bergradasi
/// dan navigasi mengambang; peran kerja mendapat permukaan solid supaya terbaca
/// di bawah matahari terminal atau di meja kasir.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.session});

  final Session session;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  Workspace get _workspace => Workspace.fromAccountType(widget.session.user?.accountType);

  @override
  void initState() {
    super.initState();
    // Peran bisa berubah setelah profil dimuat ulang; jaga indeks tetap sah.
    widget.session.addListener(_clampIndex);
  }

  @override
  void dispose() {
    widget.session.removeListener(_clampIndex);
    super.dispose();
  }

  void _clampIndex() {
    final count = _destinations().length;
    if (_index >= count && mounted) {
      setState(() => _index = 0);
    }
  }

  List<_Destination> _destinations() {
    switch (_workspace) {
      case Workspace.passenger:
        return [
          _Destination(
            label: 'Beranda',
            icon: Icons.search_outlined,
            selectedIcon: Icons.search,
            page: HomePage(session: widget.session),
          ),
          _Destination(
            label: 'Pesanan',
            icon: Icons.confirmation_number_outlined,
            selectedIcon: Icons.confirmation_number,
            page: BookingsPage(session: widget.session),
          ),
          _Destination(
            label: 'Akun',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            page: AccountPage(session: widget.session),
          ),
        ];
      case Workspace.driver:
        return [
          _Destination(
            label: 'Tugas',
            icon: Icons.route_outlined,
            selectedIcon: Icons.route,
            page: TasksPage(session: widget.session),
          ),
          _Destination(
            label: 'Akun',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            page: AccountPage(session: widget.session),
          ),
        ];
      case Workspace.warungGuard:
        return [
          _Destination(
            label: 'Kasir',
            icon: Icons.point_of_sale_outlined,
            selectedIcon: Icons.point_of_sale,
            page: PosPage(session: widget.session),
          ),
          _Destination(
            label: 'Akun',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            page: AccountPage(session: widget.session),
          ),
        ];
      case Workspace.warungOwner:
        return [
          _Destination(
            label: 'Penjualan',
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            page: SalesReportPage(session: widget.session),
          ),
          _Destination(
            label: 'Akun',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            page: AccountPage(session: widget.session),
          ),
        ];
      case Workspace.webOnly:
        return [
          _Destination(
            label: 'Akun',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            page: AccountPage(session: widget.session),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations();
    final workspace = _workspace;
    final consumer = workspace.language.isConsumer;

    return Scaffold(
      extendBodyBehindAppBar: consumer,
      backgroundColor: consumer ? Colors.transparent : Uds.gray50,
      body: _Background(
        consumer: consumer,
        child: SafeArea(
          bottom: false,
          child: destinations[_index.clamp(0, destinations.length - 1)].page,
        ),
      ),
      bottomNavigationBar: destinations.length > 1
          ? DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Uds.gray200)),
              ),
              child: NavigationBar(
                selectedIndex: _index.clamp(0, destinations.length - 1),
                onDestinationSelected: (value) => setState(() => _index = value),
                destinations: [
                  for (final destination in destinations)
                    NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                ],
              ),
            )
          : null,
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

/// Latar konsumen: gradasi tipis dari putih ke hijau muda.
/// Peran kerja tetap memakai `gray50` polos agar kontras stabil di luar ruangan.
class _Background extends StatelessWidget {
  const _Background({required this.consumer, required this.child});

  final bool consumer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!consumer) {
      return ColoredBox(color: Uds.gray50, child: child);
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Uds.gray50, Uds.white, Color(0xFFF0F9E4)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: child,
    );
  }
}
