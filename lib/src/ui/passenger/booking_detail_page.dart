import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gomad_api/gomad_api.dart' as gomad;

import '../../format.dart';
import '../../session.dart';
import '../../theme/uds.dart';
import '../kit/gm_kit.dart';
import 'bookings_page.dart' show bookingBadge;

/// Rincian satu pesanan penumpang.
///
/// Menampilkan apa yang dikirim server apa adanya: rincian harga sudah dihitung
/// backend, aplikasi tidak menjumlah ulang. Pembatalan hanya muncul untuk status
/// yang masih mungkin dibatalkan; bila server menolak, alasannya ditampilkan.
class BookingDetailPage extends StatefulWidget {
  const BookingDetailPage({super.key, required this.session, required this.bookingId});

  final Session session;
  final int bookingId;

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  bool _loading = true;
  bool _acting = false;
  String? _error;
  gomad.TravelBookingResource? _booking;

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
      final response = await widget.session.api
          .getMadTransApi()
          .v1MadTransBookingsShow(booking: widget.bookingId);
      if (mounted) {
        setState(() => _booking = response.data?.data);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = _messageOf(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: const Text(
          'Kursi akan dilepas dan dikembalikan ke jadwal. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Uds.error),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _acting = true;
      _error = null;
    });

    try {
      await widget.session.api.getMadTransApi().v1MadTransBookingsCancel(booking: widget.bookingId);
      await _load();
    } catch (error) {
      if (mounted) {
        setState(() => _error = _messageOf(error));
      }
    } finally {
      if (mounted) {
        setState(() => _acting = false);
      }
    }
  }

  String _messageOf(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }

    return '$error';
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;

    return Scaffold(
      backgroundColor: Uds.gray50,
      appBar: AppBar(title: const Text('Pesanan')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && booking == null
            ? ListView(children: const [GmLoading(label: 'Memuat pesanan…')])
            : ListView(
                padding: EdgeInsets.all(Uds.gutter(context)),
                children: [
                  if (_error != null) ...[
                    GmNotice(_error!, onRetry: _load),
                    const SizedBox(height: Uds.space3),
                  ],
                  if (booking != null) ...[
                    _summary(context, booking),
                    const SizedBox(height: Uds.space3),
                    _passengers(context, booking),
                    const SizedBox(height: Uds.space3),
                    _prices(context, booking),
                    const SizedBox(height: Uds.space4),
                    if (_canCancel(booking.status))
                      OutlinedButton.icon(
                        onPressed: _acting ? null : _cancel,
                        style: OutlinedButton.styleFrom(foregroundColor: Uds.error),
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(_acting ? 'Memproses…' : 'Batalkan pesanan'),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  bool _canCancel(String status) => status == 'pending' || status == 'confirmed';

  Widget _summary(BuildContext context, gomad.TravelBookingResource booking) {
    final (label, tone) = bookingBadge(booking.status);

    return GmSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${booking.route.origin} → ${booking.route.destination}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              GmBadge(label, tone: tone),
            ],
          ),
          const SizedBox(height: Uds.space1),
          Text(
            '${booking.departureDate} · ${asClock(booking.departureTime)} · ${booking.agency}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Uds.space3),
          const Divider(),
          const SizedBox(height: Uds.space3),
          GmKeyValue('Kode pesanan', booking.code),
          GmKeyValue('Kelas', booking.travelClass),
          GmKeyValue(
            'Pembayaran',
            booking.paymentMethod == 'cod' ? 'Bayar di jalan (COD)' : booking.paymentMethod,
          ),
        ],
      ),
    );
  }

  Widget _passengers(BuildContext context, gomad.TravelBookingResource booking) {
    return GmSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Penumpang', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Uds.space2),
          for (final passenger in booking.passengers)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      passenger.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    'Kursi ${passenger.seatNumber}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (passenger.boardedAt != null) ...[
                    const SizedBox(width: Uds.space2),
                    const GmBadge('Naik', tone: GmTone.success),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _prices(BuildContext context, gomad.TravelBookingResource booking) {
    return GmSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rincian harga', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Uds.space2),
          GmKeyValue('Harga tiket', asMoney(booking.basePrice)),
          if (_nonZero(booking.pickupFee)) GmKeyValue('Antar-jemput', asMoney(booking.pickupFee)),
          if (_nonZero(booking.serviceFee)) GmKeyValue('Biaya layanan', asMoney(booking.serviceFee)),
          if (_nonZero(booking.platformFee)) GmKeyValue('Biaya platform', asMoney(booking.platformFee)),
          if (_nonZero(booking.ppnAmount)) GmKeyValue('PPN', asMoney(booking.ppnAmount)),
          const Divider(height: Uds.space5),
          GmKeyValue('Total', asMoney(booking.totalPrice), emphasis: true),
        ],
      ),
    );
  }

  bool _nonZero(String value) {
    final amount = double.tryParse(value);

    return amount != null && amount > 0;
  }
}
