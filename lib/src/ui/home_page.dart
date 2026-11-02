import 'package:flutter/material.dart';
import 'package:gomad_api/gomad_api.dart' as gomad;

import '../format.dart';
import '../session.dart';
import 'seat_page.dart';

/// Alur pilot: cari jadwal, pilih jadwal, pesan, bayar.
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

    return Scaffold(
      appBar: AppBar(
        title: Text(user == null ? 'GoMad' : 'Halo, ${user.name}'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: widget.session.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('origin'),
                        controller: _origin,
                        decoration: const InputDecoration(
                          labelText: 'Kota asal',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        key: const Key('destination'),
                        controller: _destination,
                        decoration: const InputDecoration(
                          labelText: 'Kota tujuan',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(asDate(_date)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const Key('search'),
                        onPressed: _loading ? null : _search,
                        child: Text(_loading ? 'Mencari…' : 'Cari jadwal'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _message!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: _schedules.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final schedule = _schedules[index];
                final title = '${schedule.route.origin} → ${schedule.route.destination}';

                return ListTile(
                  title: Text(title),
                  subtitle: Text(
                    '${schedule.agency.name} · ${asClock(schedule.departureTime)} · '
                    '${schedule.vehicle} · sisa ${schedule.reservedSeats}/${schedule.capacity}',
                  ),
                  trailing: Text(
                    asMoney(schedule.pricePerSeat),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SeatPage(session: widget.session, schedule: schedule),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
