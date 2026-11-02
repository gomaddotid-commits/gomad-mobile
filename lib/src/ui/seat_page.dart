import 'package:flutter/material.dart';
import 'package:gomad_api/gomad_api.dart' as gomad;

import '../format.dart';
import '../session.dart';
import 'payment_page.dart';

/// Pilih kursi, isi data penumpang, lalu buat pesanan.
class SeatPage extends StatefulWidget {
  const SeatPage({super.key, required this.session, required this.schedule});

  final Session session;
  final gomad.V1MadTransSchedulesIndex200ResponseDataInner schedule;

  @override
  State<SeatPage> createState() => _SeatPageState();
}

class _SeatPageState extends State<SeatPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();

  bool _loading = true;
  bool _booking = false;
  String? _message;
  List<String> _layout = const [];
  List<String> _taken = const [];
  String? _selected;

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadSeats() async {
    final scheduleId = asInt(widget.schedule.id);
    if (scheduleId == null) {
      setState(() {
        _loading = false;
        _message = 'Jadwal tidak memiliki id.';
      });
      return;
    }

    try {
      final response = await widget.session.api.getMadTransApi().v1MadTransSchedulesSeats(
            schedule: scheduleId,
            originStopId: widget.schedule.originStop.id,
            destinationStopId: widget.schedule.destinationStop.id,
          );
      final data = response.data?.data;

      setState(() {
        _layout = asStrings(data?.layout);
        _taken = asStrings(data?.taken);
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _message = '$error';
        });
      }
    }
  }

  Future<void> _book() async {
    final seat = _selected;
    if (seat == null) {
      setState(() => _message = 'Pilih satu kursi dulu.');
      return;
    }

    final scheduleId = asInt(widget.schedule.id);
    if (scheduleId == null) {
      setState(() => _message = 'Jadwal tidak memiliki id.');
      return;
    }

    setState(() {
      _booking = true;
      _message = null;
    });

    try {
      final response = await widget.session.api.getMadTransApi().v1MadTransBookingsStore(
            v1MadTransBookingsStoreRequest: gomad.V1MadTransBookingsStoreRequest(
              scheduleId: scheduleId,
              originStopId: widget.schedule.originStop.id,
              destinationStopId: widget.schedule.destinationStop.id,
              paymentMethod: gomad.V1MadTransBookingsStoreRequestPaymentMethodEnum.midtrans,
              passengers: {
                gomad.V1MadTransBookingsStoreRequestPassengersInner(
                  seatNumber: seat,
                  name: _name.text.trim(),
                  phone: _phone.text.trim(),
                ),
              },
            ),
            headers: {'Idempotency-Key': _idempotencyKey()},
          );
      final booking = response.data?.data;
      if (booking == null || !mounted) {
        return;
      }

      final bookingId = asInt(booking.id);
      if (bookingId == null) {
        setState(() => _message = 'Respons pemesanan tidak lengkap.');
        return;
      }
      final code = booking.code;

      final payment = await widget.session.api.getMadTransApi().v1MadTransBookingsPay(
            booking: bookingId,
            headers: {'Idempotency-Key': _idempotencyKey()},
          );
      final paymentData = payment.data?.data;

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PaymentPage(
            bookingCode: code,
            amount: asMoney(paymentData?.amount),
            redirectUrl: paymentData?.redirectUrl,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _message = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _booking = false);
      }
    }
  }

  /// Idempotency-Key sederhana per percobaan: cukup unik, bukan rahasia.
  String _idempotencyKey() =>
      'mobile-${DateTime.now().microsecondsSinceEpoch}';

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;

    return Scaffold(
      appBar: AppBar(title: Text('${schedule.agency.name} · ${asClock(schedule.departureTime)}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${schedule.route.origin} → ${schedule.route.destination} · '
                  '${asMoney(schedule.pricePerSeat)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _layout.map((seat) {
                    final taken = _taken.contains(seat);
                    final selected = _selected == seat;

                    return ChoiceChip(
                      label: Text(seat),
                      selected: selected,
                      onSelected: taken || _booking
                          ? null
                          : (_) => setState(() => _selected = seat),
                      avatar: taken ? const Icon(Icons.block, size: 16) : null,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('passenger-name'),
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nama penumpang',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('passenger-phone'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor telepon',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('book'),
                  onPressed: _booking ? null : _book,
                  child: Text(_booking ? 'Memproses…' : 'Pesan & bayar'),
                ),
              ],
            ),
    );
  }
}
