import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gomad_api/gomad_api.dart' as gomad;

import '../../format.dart';
import '../../session.dart';
import '../../theme/uds.dart';
import '../kit/gm_kit.dart';
import 'warung_business.dart';

/// Pemantauan penjualan untuk pemilik warung.
///
/// Hanya membaca: pemilik tidak menjual dari layar ini (`pos.report`, bukan
/// `pos.sell`). Pemilik boleh punya lebih dari satu warung, jadi warung yang
/// sedang dilihat selalu terlihat namanya dan bisa diganti — bukan diam-diam
/// memakai warung pertama.
class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key, required this.session});

  final Session session;

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  bool _loading = true;
  String? _error;
  List<gomad.BusinessResource> _warungs = const [];
  gomad.BusinessResource? _selected;
  List<gomad.RetailSaleResource> _sales = const [];
  int _total = 0;

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
      final warungs = await warungBusinesses(widget.session, role: 'pemilik');
      if (!mounted) {
        return;
      }

      if (warungs.isEmpty) {
        setState(() {
          _warungs = const [];
          _selected = null;
          _sales = const [];
          _total = 0;
          _error = 'Akun ini tidak tercatat sebagai pemilik warung mana pun.';
        });
        return;
      }

      final selected = _selected != null && warungs.any((warung) => warung.id == _selected!.id)
          ? _selected!
          : warungs.first;

      final response = await widget.session.api
          .getWarungPosApi()
          .v1WarungPosSalesIndex(business: selected.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _warungs = warungs;
        _selected = selected;
        _sales = response.data?.data ?? const [];
        _total = response.data?.meta.total ?? 0;
      });
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

  Future<void> _choose() async {
    final chosen = await showModalBottomSheet<gomad.BusinessResource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Uds.space4),
              child: Text('Pilih warung', style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final warung in _warungs)
              ListTile(
                leading: Icon(
                  warung.id == _selected?.id ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: warung.id == _selected?.id ? Uds.greenDeep : Uds.gray400,
                ),
                title: Text(warung.name),
                subtitle: Text(warung.code),
                onTap: () => Navigator.of(context).pop(warung),
              ),
            const SizedBox(height: Uds.space3),
          ],
        ),
      ),
    );

    if (chosen != null && chosen.id != _selected?.id) {
      setState(() => _selected = chosen);
      await _load();
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(Uds.gutter(context)),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selected?.name ?? 'Penjualan',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_total nota kasir tercatat.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_warungs.length > 1)
                OutlinedButton.icon(
                  onPressed: _loading ? null : _choose,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: Uds.space3),
                  ),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('Ganti'),
                ),
            ],
          ),
          const SizedBox(height: Uds.space4),
          if (_loading && _sales.isEmpty)
            const GmLoading(label: 'Memuat penjualan…')
          else if (_error != null)
            GmNotice(_error!, onRetry: _load)
          else if (_sales.isEmpty)
            const GmEmpty(
              title: 'Belum ada penjualan',
              message: 'Nota muncul setelah penjaga mencatat penjualan di kasir.',
              icon: Icons.receipt_long_outlined,
            )
          else
            for (final sale in _sales) ...[
              _SaleCard(sale: sale),
              const SizedBox(height: Uds.space3),
            ],
        ],
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale});

  final gomad.RetailSaleResource sale;

  @override
  Widget build(BuildContext context) {
    final createdAt = sale.createdAt;
    final time = createdAt == null || createdAt.length < 16 ? '-' : asClock(createdAt.substring(11));

    return GmSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(sale.code, style: Theme.of(context).textTheme.titleMedium),
              ),
              GmMoney(sale.totalAmount, size: 16),
            ],
          ),
          const SizedBox(height: Uds.space1),
          Text(
            '$time · ${sale.sellerName ?? 'kasir'} · ${sale.items.length} barang',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Uds.space2),
          for (final item in sale.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}× ${item.productName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    asMoney(item.subtotal),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
