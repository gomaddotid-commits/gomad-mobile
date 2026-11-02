import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Halaman pembayaran: menampilkan tagihan dan tautan Snap.
///
/// Tautan dibuka lewat browser perangkat. Untuk pilot, tautan ditampilkan
/// sekaligus bisa disalin agar tidak bergantung pada plugin tambahan.
class PaymentPage extends StatelessWidget {
  const PaymentPage({
    super.key,
    required this.bookingCode,
    required this.amount,
    this.redirectUrl,
  });

  final String bookingCode;
  final String amount;
  final String? redirectUrl;

  @override
  Widget build(BuildContext context) {
    final url = redirectUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(bookingCode, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Total $amount', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            if (url == null)
              const Text('Tautan pembayaran tidak tersedia. Coba bayar dari daftar pesanan.')
            else ...[
              const Text('Selesaikan pembayaran di Midtrans:'),
              const SizedBox(height: 8),
              SelectableText(url, key: const Key('snap-url')),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tautan pembayaran disalin.')),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Salin tautan'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
