import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gomad_api/gomad_api.dart' as gomad;

import '../../format.dart';
import '../../session.dart';
import '../../theme/uds.dart';
import '../kit/gm_kit.dart';

/// Satu tugas perjalanan untuk supir.
///
/// Aturan tampilannya satu aksi utama per keadaan (UDS §7.4):
/// `published` → "Mulai perjalanan", `in_progress` → aksi boarding per penumpang
/// lalu "Selesaikan perjalanan", `completed` → tidak ada aksi.
///
/// Server tetap penjaga terakhir. Tombol boarding bisa dimatikan karena syarat
/// jaminan COD belum terpenuhi; bila itu terjadi, pesan galat server ditampilkan
/// apa adanya, tidak diterjemahkan ulang oleh aplikasi.
class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({super.key, required this.session, required this.scheduleId});

  final Session session;
  final int scheduleId;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  bool _loading = true;
  bool _acting = false;
  String? _error;
  String? _notice;
  gomad.DriverTripResource? _trip;

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
          .getDriverScheduleApi()
          .v1MadTransDriverSchedulesShow(schedule: widget.scheduleId);
      if (mounted) {
        setState(() => _trip = response.data?.data);
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

  /// Semua aksi memakai pola yang sama: jalankan, tampilkan pesan singkat,
  /// muat ulang. Tidak ada perubahan status yang ditebak di sisi aplikasi.
  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() {
      _acting = true;
      _error = null;
      _notice = null;
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      setState(() => _notice = success);
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
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            return '${first.first}';
          }
        }

        return data['message'] as String;
      }
      if (error.response?.statusCode == 403) {
        return 'Kamu tidak berhak atas aksi ini.';
      }
    }

    return '$error';
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;

    return Scaffold(
      backgroundColor: Uds.gray50,
      appBar: AppBar(title: const Text('Tugas')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && trip == null
            ? ListView(children: const [GmLoading(label: 'Memuat perjalanan…')])
            : ListView(
                padding: EdgeInsets.all(Uds.gutter(context)),
                children: [
                  if (_error != null) ...[
                    GmNotice(_error!, onRetry: _load),
                    const SizedBox(height: Uds.space3),
                  ],
                  if (_notice != null) ...[
                    GmNotice(_notice!, tone: GmTone.success),
                    const SizedBox(height: Uds.space3),
                  ],
                  if (trip != null) ...[
                    _header(context, trip),
                    const SizedBox(height: Uds.space3),
                    _actions(context, trip),
                    const SizedBox(height: Uds.space4),
                    for (final booking in trip.bookings) ...[
                      _bookingCard(context, booking),
                      const SizedBox(height: Uds.space3),
                    ],
                  ],
                ],
              ),
      ),
    );
  }

  Widget _header(BuildContext context, gomad.DriverTripResource trip) {
    final vehicle = trip.vehicle;

    return GmSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trip.route?.originCity ?? '-'} → ${trip.route?.destinationCity ?? '-'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              GmBadge(
                _statusLabel(trip.status),
                tone: trip.status == 'in_progress'
                    ? GmTone.info
                    : (trip.status == 'completed' ? GmTone.neutral : GmTone.brand),
              ),
            ],
          ),
          const SizedBox(height: Uds.space2),
          Text(
            '${trip.departureDate} · ${asClock(trip.departureTime)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '${vehicle?.name ?? '-'} · ${vehicle?.plateNumber ?? '-'} · '
            '${vehicle?.capacity ?? '-'} kursi',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Uds.space3),
          const Divider(),
          const SizedBox(height: Uds.space3),
          Row(
            children: [
              Expanded(
                child: GmStatTile(
                  label: 'Naik',
                  value: '${trip.boardedCount}/${trip.passengerCount}',
                  hint: 'penumpang',
                ),
              ),
              Expanded(
                child: GmStatTile(
                  label: 'Tarif',
                  value: asMoney(trip.pricePerSeat),
                  hint: 'per kursi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, gomad.DriverTripResource trip) {
    if (trip.canStart) {
      return FilledButton.icon(
        onPressed: _acting
            ? null
            : () => _run(
                  () async {
                    await widget.session.api
                        .getMadTransAgencyApi()
                        .v1MadTransSchedulesStart(schedule: widget.scheduleId);
                  },
                  'Perjalanan dimulai.',
                ),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(_acting ? 'Memproses…' : 'Mulai perjalanan'),
      );
    }

    if (trip.canFinish) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Uds.green),
        onPressed: _acting
            ? null
            : () => _run(
                  () async {
                    await widget.session.api
                        .getMadTransAgencyApi()
                        .v1MadTransSchedulesFinish(schedule: widget.scheduleId);
                  },
                  'Perjalanan diselesaikan.',
                ),
        icon: const Icon(Icons.flag_outlined),
        label: Text(_acting ? 'Memproses…' : 'Selesaikan perjalanan'),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _bookingCard(BuildContext context, gomad.DriverTripResourceBookingsInner booking) {
    return GmSurface(
      padding: const EdgeInsets.fromLTRB(Uds.space4, Uds.space3, Uds.space4, Uds.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(booking.code, style: Theme.of(context).textTheme.titleMedium),
              ),
              GmBadge(
                booking.paymentMethod == 'cod' ? 'Bayar di jalan' : 'Sudah dibayar',
                tone: booking.paymentMethod == 'cod' ? GmTone.warning : GmTone.success,
              ),
            ],
          ),
          const SizedBox(height: Uds.space2),
          for (final passenger in booking.passengers) ...[
            _passengerRow(context, booking, passenger),
          ],
        ],
      ),
    );
  }

  Widget _passengerRow(
    BuildContext context,
    gomad.DriverTripResourceBookingsInner booking,
    gomad.DriverTripResourceBookingsInnerPassengersInner passenger,
  ) {
    final boarded = passenger.boardedAt != null;
    final noShow = passenger.noShowAt != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Uds.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: boarded ? Uds.success.withValues(alpha: 0.15) : Uds.gray100,
                child: Icon(
                  boarded ? Icons.check : Icons.person_outline,
                  size: 16,
                  color: boarded ? Uds.success : Uds.gray500,
                ),
              ),
              const SizedBox(width: Uds.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(passenger.name, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      'Kursi ${passenger.seat}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (boarded)
                const GmBadge('Naik', tone: GmTone.success)
              else if (noShow)
                const GmBadge('Tidak naik', tone: GmTone.danger),
            ],
          ),
          if (passenger.canBoard) ...[
            const SizedBox(height: Uds.space2),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _acting
                        ? null
                        : () => _run(
                              () async {
                                await widget.session.api.getMadTransApi().v1MadTransBookingsPassengersBoard(
                                      booking: asInt(booking.id) ?? 0,
                                      passenger: asInt(passenger.id) ?? 0,
                                    );
                              },
                              '${passenger.name} dinaikkan.',
                            ),
                    child: const Text('Konfirmasi naik'),
                  ),
                ),
                const SizedBox(width: Uds.space2),
                Expanded(
                  child: TextButton(
                    onPressed: _acting
                        ? null
                        : () => _run(
                              () async {
                                await widget.session.api.getMadTransApi().v1MadTransBookingsPassengersNoShow(
                                      booking: asInt(booking.id) ?? 0,
                                      passenger: asInt(passenger.id) ?? 0,
                                    );
                              },
                              '${passenger.name} ditandai tidak naik.',
                            ),
                    style: TextButton.styleFrom(foregroundColor: Uds.error),
                    child: const Text('Tidak naik'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'published' => 'Terjadwal',
      'in_progress' => 'Berjalan',
      'completed' => 'Selesai',
      'cancelled' => 'Dibatalkan',
      _ => status,
    };
  }
}
