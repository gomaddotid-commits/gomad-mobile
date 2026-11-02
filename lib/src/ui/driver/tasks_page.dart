import 'package:flutter/material.dart';
import 'package:gomad_api/gomad_api.dart' as gomad;

import '../../format.dart';
import '../../session.dart';
import '../../theme/uds.dart';
import '../kit/gm_kit.dart';
import 'task_detail_page.dart';

/// Daftar tugas supir.
///
/// Dua bagian, sama seperti web: tugas aktif (published + in_progress) dan yang
/// sudah selesai tujuh hari terakhir. Tanpa bagian kedua, supir tidak punya cara
/// memastikan perjalanan mana yang sudah ia tutup saat ada sengketa penumpang.
class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.session});

  final Session session;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  bool _loading = true;
  String? _error;
  List<gomad.DriverScheduleResource> _active = const [];
  List<gomad.DriverScheduleResource> _completed = const [];

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
      final response = await widget.session.api.getDriverScheduleApi().v1MadTransDriverSchedulesIndex();
      final data = response.data?.data;
      if (!mounted) {
        return;
      }
      setState(() {
        _active = data?.active ?? const [];
        _completed = data?.completed ?? const [];
      });
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

  Future<void> _open(gomad.DriverScheduleResource schedule) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailPage(session: widget.session, scheduleId: asInt(schedule.id) ?? 0),
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
          Text('Tugas saya', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: Uds.space1),
          Text(
            'Perjalanan yang ditugaskan kepadamu.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Uds.space4),
          if (_loading)
            const GmLoading(label: 'Memuat tugas…')
          else if (_error != null)
            GmNotice(_error!, onRetry: _load)
          else ...[
            if (_active.isEmpty && _completed.isEmpty)
              const GmEmpty(
                title: 'Belum ada tugas',
                message: 'Tugas muncul setelah agency menugaskanmu ke sebuah jadwal.',
                icon: Icons.route_outlined,
              ),
            for (final schedule in _active) ...[
              _TaskCard(schedule: schedule, onTap: () => _open(schedule)),
              const SizedBox(height: Uds.space3),
            ],
            if (_completed.isNotEmpty) ...[
              const SizedBox(height: Uds.space2),
              const GmSectionTitle('Selesai (7 hari terakhir)'),
              for (final schedule in _completed) ...[
                _TaskCard(schedule: schedule, onTap: () => _open(schedule), muted: true),
                const SizedBox(height: Uds.space3),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.schedule, required this.onTap, this.muted = false});

  final gomad.DriverScheduleResource schedule;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final route = schedule.route;
    final vehicle = schedule.vehicle;
    final running = schedule.status == 'in_progress';

    return GmSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${route?.originCity ?? '-'} → ${route?.destinationCity ?? '-'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              GmBadge(
                running ? 'Berjalan' : (muted ? 'Selesai' : 'Terjadwal'),
                tone: running
                    ? GmTone.info
                    : (muted ? GmTone.neutral : GmTone.brand),
              ),
            ],
          ),
          const SizedBox(height: Uds.space2),
          Text(
            '${asClock(schedule.departureTime)} · ${vehicle?.name ?? '-'} '
            '(${vehicle?.plateNumber ?? '-'})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Uds.space3),
          Row(
            children: [
              const Icon(Icons.event_seat_outlined, size: 16, color: Uds.gray500),
              const SizedBox(width: 6),
              Text(
                '${schedule.bookingCount} pesanan',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              if (schedule.canStart)
                const GmBadge('Bisa dimulai', tone: GmTone.success)
              else if (schedule.canFinish)
                const GmBadge('Perlu ditutup', tone: GmTone.warning),
            ],
          ),
        ],
      ),
    );
  }
}
