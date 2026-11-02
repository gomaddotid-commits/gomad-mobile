import 'package:flutter/material.dart';
import 'package:gomad_api/gomad_api.dart' as gomad;

import '../format.dart';
import '../session.dart';
import '../theme/uds.dart';
import 'kit/gm_kit.dart';
import 'seat_page.dart';

/// Beranda penumpang: cari jadwal, pilih jadwal, pesan, bayar.
///
/// Bentuknya mengikuti alur pilot yang sudah terbukti (blueprint 14 §4). Yang
/// berubah hanya tampilan: kartu permukaan, nominal rata kanan, dan keadaan
/// kosong/galat yang menjelaskan apa yang harus dilakukan.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.session});

  final Session session;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _origin = TextEditingController(text: 'Sumenep');
  final _destination = TextEditingController(text: 'Surabaya');
  DateTime _date = DateTime.now().add(const Duration(days: 1));

  bool _loading = false;
  String? _message;
  bool _searched = false;
  List<gomad.V1MadTransSchedulesIndex200ResponseDataInner> _schedules = const [];

  @override
  void dispose() {
    _origin.dispose();
    _destination.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _message = null;
      _searched = true;
    });

    try {
      final response = await widget.session.api.getMadTransApi().v1MadTransSchedulesIndex(
            originCity: _origin.text.trim(),
            destinationCity: _destination.text.trim(),
            departureDate: _date,
            passengers: 1,
          );
      final schedules = response.data?.data ?? const [];

      setState(() {
        _schedules = schedules;
        if (schedules.isEmpty) {
          _message = 'Tidak ada jadwal untuk rute dan tanggal ini.';
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() => _message = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.user;

    return ListView(
      padding: EdgeInsets.all(Uds.gutter(context)),
      children: [
        Text(
          user == null ? 'Mau ke mana?' : 'Halo, ${user.name.split(' ').first}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: Uds.space1),
        Text(
          'Tiket travel Mad Trans, pesan dari mana saja.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Uds.space4),
        GmSurface(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('origin'),
                      controller: _origin,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Kota asal'),
                    ),
                  ),
                  const SizedBox(width: Uds.space2),
                  Expanded(
                    child: TextField(
                      key: const Key('destination'),
                      controller: _destination,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Kota tujuan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Uds.space3),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(asDate(_date)),
                    ),
                  ),
                  const SizedBox(width: Uds.space2),
                  Expanded(
                    child: FilledButton(
                      key: const Key('search'),
                      onPressed: _loading ? null : _search,
                      child: Text(_loading ? 'Mencari…' : 'Cari'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Uds.space4),
        if (_message != null) ...[
          GmNotice(_message!, tone: _schedules.isEmpty ? GmTone.warning : GmTone.danger),
          const SizedBox(height: Uds.space3),
        ],
        if (_searched && !_loading && _schedules.isEmpty && _message != null)
          const GmEmpty(
            title: 'Coba tanggal lain',
            message: 'Jadwal biasanya dibuka seminggu sebelum keberangkatan.',
            icon: Icons.event_busy_outlined,
          )
        else ...[
          if (_schedules.isNotEmpty) const GmSectionTitle('Jadwal tersedia'),
          for (final schedule in _schedules) ...[
            _ScheduleCard(
              schedule: schedule,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SeatPage(session: widget.session, schedule: schedule),
                ),
              ),
            ),
            const SizedBox(height: Uds.space3),
          ],
        ],
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.onTap});

  final gomad.V1MadTransSchedulesIndex200ResponseDataInner schedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final remaining = schedule.capacity - schedule.reservedSeats;

    return GmSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${schedule.route.origin} → ${schedule.route.destination}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${schedule.agency.name} · ${schedule.vehicle}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Uds.space2),
              GmMoney(schedule.pricePerSeat, size: 16, emphasis: true),
            ],
          ),
          const SizedBox(height: Uds.space3),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Uds.gray500),
              const SizedBox(width: 6),
              Text(asClock(schedule.departureTime), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: Uds.space3),
              GmBadge(
                remaining > 0 ? 'Sisa $remaining kursi' : 'Penuh',
                tone: remaining > 0 ? GmTone.success : GmTone.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
