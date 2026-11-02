import 'package:flutter/material.dart';
import 'package:gomad_api/gomad_api.dart' as gomad;

import '../../format.dart';
import '../../session.dart';
import '../../theme/uds.dart';
import '../kit/gm_kit.dart';
import 'booking_detail_page.dart';

/// Daftar pesanan penumpang.
///
/// Urutannya dari yang terbaru, sama dengan API. Status ditampilkan sebagai
/// lencana berteks — bukan warna saja (UDS §12.1).
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key, required this.session});

  final Session session;

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  bool _loading = true;
  String? _error;
  List<gomad.TravelBookingResource> _bookings = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await widget.session.api.getMadTransApi().v1MadTransBookingsIndex();
      if (!mounted) {
        return;
      }
      setState(() => _bookings = response.data?.data ?? const []);
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _open(gomad.TravelBookingResource booking) async {
    final id = asInt(booking.id);
    if (id == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingDetailPage(session: widget.session, bookingId: id),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(Uds.gutter(context)),
        children: [
          Text('Pesanan saya', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: Uds.space1),
          Text(
            'Tiket yang sudah kamu pesan.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Uds.space4),
          if (_loading)
            const GmLoading(label: 'Memuat pesanan…')
          else if (_error != null)
            GmNotice(_error!, onRetry: _load)
          else if (_bookings.isEmpty)
            GmEmpty(
              title: 'Belum ada pesanan',
              message: 'Cari jadwal di tab Beranda untuk memesan tiket pertama.',
              icon: Icons.confirmation_number_outlined,
              action: FilledButton(
                onPressed: _load,
                child: const Text('Muat ulang'),
              ),
            )
          else
            for (final booking in _bookings) ...[
              _BookingCard(booking: booking, onTap: () => _open(booking)),
              const SizedBox(height: Uds.space3),
            ],
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final gomad.TravelBookingResource booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = bookingBadge(booking.status);

    return GmSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${booking.route.origin} → ${booking.route.destination}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              GmBadge(label, tone: tone),
            ],
          ),
          const SizedBox(height: Uds.space1),
          Text(
            '${booking.departureDate} · ${asClock(booking.departureTime)} · '
            '${booking.totalPassengers} penumpang',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Uds.space3),
          Row(
            children: [
              Text(booking.code, style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              GmMoney(booking.totalPrice, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

/// Label dan nada lencana untuk status pesanan. Satu tempat untuk semua layar
/// supaya "Paid" di daftar dan di rincian tidak pernah berbeda sebutan.
(String, GmTone) bookingBadge(String status) {
  return switch (status) {
    'pending' => ('Menunggu bayar', GmTone.warning),
    'confirmed' => ('Terkonfirmasi', GmTone.info),
    'paid' => ('Sudah dibayar', GmTone.success),
    'on_going' => ('Sedang jalan', GmTone.info),
    'completed' => ('Selesai', GmTone.neutral),
    'cancelled' => ('Dibatalkan', GmTone.danger),
    'expired' => ('Kedaluwarsa', GmTone.danger),
    _ => (status, GmTone.neutral),
  };
}
