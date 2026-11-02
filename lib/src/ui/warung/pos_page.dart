import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gomad_api/gomad_api.dart' as gomad;

import '../../format.dart';
import '../../session.dart';
import '../../theme/uds.dart';
import '../kit/gm_kit.dart';
import 'warung_business.dart';

/// Kasir warung untuk penjaga.
///
/// Alur mengikuti layar web `/mad-warung/{business}/kasir`: pilih barang, lihat
/// total, terima uang, selesai. Yang tidak dilakukan di sini: menghitung total,
/// memilih harga, atau menyentuh stok — semuanya milik `RecordRetailSale` di
/// server. Aplikasi hanya mengirim `product_id` + `quantity`.
///
/// Warung yang dipakai ditentukan dari keanggotaan akun (`/v1/me/memberships`),
/// bukan dari input bebas. Kalau penjaga punya lebih dari satu warung, ia
/// memilih lebih dulu.
class PosPage extends StatefulWidget {
  const PosPage({super.key, required this.session});

  final Session session;

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  bool _loading = true;
  String? _error;
  gomad.BusinessResource? _business;
  gomad.PosCatalogResource? _catalog;
  final Map<int, int> _cart = {};

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
      _business ??= await guardWarung(widget.session);
      final business = _business;
      if (business == null) {
        if (mounted) {
          setState(() => _error = 'Akun ini belum menjadi penjaga warung mana pun. '
              'Minta pemilik mengundang nomormu lewat menu anggota di web.');
        }
        return;
      }

      final response = await widget.session.api
          .getWarungPosApi()
          .v1WarungPosListings(business: business.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = response.data?.data;
        _cart.clear();
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

  String _messageOf(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }

    return '$error';
  }

  int get _total {
    final listings = _catalog?.listings ?? const <gomad.RetailListingResource>[];
    var total = 0.0;

    for (final listing in listings) {
      final quantity = _cart[listing.productId] ?? 0;
      if (quantity <= 0) {
        continue;
      }
      total += (double.tryParse(listing.price) ?? 0) * quantity;
    }

    return total.round();
  }

  int get _itemCount => _cart.values.where((quantity) => quantity > 0).length;

  void _add(gomad.RetailListingResource listing) {
    setState(() => _cart[listing.productId] = (_cart[listing.productId] ?? 0) + 1);
  }

  void _remove(gomad.RetailListingResource listing) {
    final current = _cart[listing.productId] ?? 0;
    setState(() {
      if (current <= 1) {
        _cart.remove(listing.productId);
      } else {
        _cart[listing.productId] = current - 1;
      }
    });
  }

  Future<void> _checkout() async {
    final business = _business;
    if (business == null || _cart.isEmpty) {
      return;
    }

    final lines = _cart.entries
        .where((entry) => entry.value > 0)
        .map((entry) => gomad.V1WarungPosSalesStoreRequestItemsInner(
              productId: entry.key,
              quantity: entry.value,
            ))
        .toList(growable: false);

    final paid = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PaymentSheet(total: _total),
    );

    if (paid == null || !mounted) {
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await widget.session.api.getWarungPosApi().v1WarungPosSalesStore(
            business: business.id,
            v1WarungPosSalesStoreRequest: gomad.V1WarungPosSalesStoreRequest(
              items: lines,
              paidAmount: paid,
            ),
          );
      final sale = response.data?.data;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nota ${sale?.code ?? ''} tersimpan · kembali ${asMoney(sale?.changeAmount)}',
          ),
        ),
      );
      await _load();
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

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    final listings = catalog?.listings ?? const <gomad.RetailListingResource>[];

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
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
                            catalog?.business.name ?? 'Kasir',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Hari ini ${catalog?.today.count ?? 0} nota · '
                            '${asMoney(catalog?.today.amount)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Muat ulang',
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: Uds.space3),
                if (_error != null) ...[
                  GmNotice(_error!, onRetry: _load),
                  const SizedBox(height: Uds.space3),
                ],
                if (_loading && catalog == null)
                  const GmLoading(label: 'Memuat barang…')
                else if (listings.isEmpty)
                  const GmEmpty(
                    title: 'Belum ada barang',
                    message: 'Barang muncul setelah pemilik menandai produk untuk dijual di warung.',
                    icon: Icons.storefront_outlined,
                  )
                else
                  Wrap(
                    spacing: Uds.space3,
                    runSpacing: Uds.space3,
                    children: [
                      for (final listing in listings)
                        _ProductTile(
                          listing: listing,
                          quantity: _cart[listing.productId] ?? 0,
                          onAdd: () => _add(listing),
                          onRemove: () => _remove(listing),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        _CheckoutBar(
          total: _total,
          itemCount: _itemCount,
          busy: _loading,
          onCheckout: _itemCount == 0 ? null : _checkout,
        ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.listing,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final gomad.RetailListingResource listing;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;

    return SizedBox(
      width: 160,
      child: Material(
        color: selected ? Uds.lime.withValues(alpha: 0.18) : Uds.white,
        borderRadius: BorderRadius.circular(Uds.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(Uds.radiusLg),
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.all(Uds.space3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Uds.radiusLg),
              border: Border.all(color: selected ? Uds.lime : Uds.gray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${asMoney(listing.price)} / ${listing.unit.isEmpty ? 'pcs' : listing.unit}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: Uds.space2),
                if (!selected)
                  Text(
                    'Ketuk untuk tambah',
                    style: Theme.of(context).textTheme.labelMedium,
                  )
                else
                  Row(
                    children: [
                      _StepButton(
                        icon: Icons.remove,
                        tooltip: 'Kurangi ${listing.name}',
                        onPressed: onRemove,
                      ),
                      Expanded(
                        child: Text(
                          '$quantity',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      _StepButton(
                        icon: Icons.add,
                        tooltip: 'Tambah ${listing.name}',
                        onPressed: onAdd,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 18,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
      icon: Icon(icon),
    );
  }
}

/// Bilah total + tombol bayar. Selalu terlihat; kasir tidak boleh menggulir
/// untuk menemukan tombolnya.
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.total,
    required this.itemCount,
    required this.busy,
    required this.onCheckout,
  });

  final int total;
  final int itemCount;
  final bool busy;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Uds.gutter(context),
        Uds.space3,
        Uds.gutter(context),
        Uds.space3,
      ),
      decoration: const BoxDecoration(
        color: Uds.white,
        border: Border(top: BorderSide(color: Uds.gray200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$itemCount barang', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  asMoney(total.toString()),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(width: Uds.space4),
            Expanded(
              child: FilledButton(
                onPressed: busy ? null : onCheckout,
                child: const Text('Bayar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lembar pembayaran: uang diterima dan kembalian.
///
/// Kembalian dihitung di klien hanya untuk ditampilkan; jumlah yang disimpan
/// tetap dihitung ulang server dari harga di database.
class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.total});

  final int total;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _paid => int.tryParse(_controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final enough = _paid >= widget.total;

    return Padding(
      padding: EdgeInsets.only(
        left: Uds.space5,
        right: Uds.space5,
        top: Uds.space5,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Uds.space5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pembayaran', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Uds.space3),
          GmKeyValue('Total belanja', asMoney(widget.total.toString()), emphasis: true),
          const SizedBox(height: Uds.space3),
          TextField(
            key: const Key('paid-amount'),
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Uang diterima'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Uds.space3),
          if (_paid > 0)
            Row(
              children: [
                Expanded(
                  child: Text('Kembalian', style: Theme.of(context).textTheme.bodyMedium),
                ),
                GmMoney(
                  (enough ? _paid - widget.total : 0).toString(),
                  size: 18,
                  emphasis: true,
                ),
              ],
            ),
          if (_paid > 0 && !enough) ...[
            const SizedBox(height: Uds.space2),
            GmNotice(
              'Uang diterima kurang ${asMoney((widget.total - _paid).toString())} dari total.',
              tone: GmTone.warning,
            ),
          ],
          const SizedBox(height: Uds.space4),
          FilledButton(
            key: const Key('confirm-payment'),
            onPressed: enough ? () => Navigator.of(context).pop(_paid.toString()) : null,
            child: Text(_paid == 0 ? 'Masukkan uang diterima' : 'Simpan penjualan'),
          ),
          const SizedBox(height: Uds.space2),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
}
