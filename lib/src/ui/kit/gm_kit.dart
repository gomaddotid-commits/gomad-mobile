import 'package:flutter/material.dart';

import '../../format.dart';
import '../../theme/uds.dart';

/// Kit widget bersama — padanan Flutter dari komponen Blade `x-gm.*`.
///
/// Aturan yang sama dengan web berlaku di sini: satu komponen untuk satu maksud,
/// tidak ada layar yang mereka ulang gayanya sendiri. Semua warna berasal dari
/// [Uds], semua jarak dari skala 4.
///
/// Lihat `docs/blueprint/14-peta-komponen-web-ke-widget.md` untuk peta lengkap
/// komponen web → widget.

/// Permukaan isi: pembungkus standar untuk kartu, tabel ringkasan, dan blok
/// informasi. Di web ini `gm-surface`; bukan `Card` Material polos supaya
/// bayangan dan garisnya sama dengan web.
class GmSurface extends StatelessWidget {
  const GmSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Uds.space4),
    this.onTap,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Sorotan merek (latar lime muda) untuk blok yang butuh perhatian.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final surface = Container(
      decoration: BoxDecoration(
        color: highlight ? Uds.lime.withValues(alpha: 0.16) : Uds.white,
        borderRadius: BorderRadius.circular(Uds.radiusLg),
        border: Border.all(color: highlight ? Uds.lime : Uds.gray200),
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) {
      return surface;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Uds.radiusLg),
        child: surface,
      ),
    );
  }
}

/// Judul bagian dengan aksi opsional di kanan.
class GmSectionTitle extends StatelessWidget {
  const GmSectionTitle(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Uds.space3),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Nada semantik untuk lencana status. Warna tidak pernah berdiri sendiri —
/// selalu ada teksnya (UDS §12.1).
enum GmTone { neutral, success, warning, danger, info, brand }

/// Lencana status kecil: `Paid`, `Menunggu`, `Tidak naik`.
class GmBadge extends StatelessWidget {
  const GmBadge(this.label, {super.key, this.tone = GmTone.neutral});

  final String label;
  final GmTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      GmTone.neutral => (Uds.gray100, Uds.gray600),
      GmTone.success => (Uds.success.withValues(alpha: 0.14), Uds.success),
      GmTone.warning => (Uds.warning.withValues(alpha: 0.16), const Color(0xFF8A5B00)),
      GmTone.danger => (Uds.error.withValues(alpha: 0.12), Uds.error),
      GmTone.info => (Uds.info.withValues(alpha: 0.12), Uds.info),
      GmTone.brand => (Uds.lime, Uds.black900),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Uds.space2, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Uds.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }
}

/// Baris daftar: ikon/awalan, judul, keterangan, dan nilai di kanan.
class GmListRow extends StatelessWidget {
  const GmListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: Uds.minTapTarget),
        padding: EdgeInsets.symmetric(
          horizontal: Uds.space4,
          vertical: dense ? Uds.space2 : Uds.space3,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: Uds.space3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: Uds.space3),
              trailing!,
            ],
            if (onTap != null) ...[
              const SizedBox(width: Uds.space1),
              const Icon(Icons.chevron_right, size: 20, color: Uds.gray400),
            ],
          ],
        ),
      ),
    );
  }
}

/// Kotak angka: label kecil di atas, nilai besar di bawah.
class GmStatTile extends StatelessWidget {
  const GmStatTile({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.tone = GmTone.neutral,
  });

  final String label;
  final String value;
  final String? hint;
  final GmTone tone;

  @override
  Widget build(BuildContext context) {
    final valueColor = switch (tone) {
      GmTone.success => Uds.success,
      GmTone.danger => Uds.error,
      GmTone.warning => Uds.warning,
      _ => Uds.black900,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: Uds.space2),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: valueColor),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// Baris label–nilai untuk rincian harga. Label rata kiri, nominal rata kanan
/// (pola tabel ringkasan di web).
class GmKeyValue extends StatelessWidget {
  const GmKeyValue(this.label, this.value, {super.key, this.emphasis = false});

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final style = emphasis
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: style?.copyWith(
                color: emphasis ? Uds.black900 : Uds.gray600,
                fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: Uds.space3),
          Text(
            value,
            style: style?.copyWith(fontWeight: emphasis ? FontWeight.w700 : FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

/// Keadaan kosong: selalu menjelaskan kenapa kosong dan apa langkah berikutnya.
class GmEmpty extends StatelessWidget {
  const GmEmpty({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Uds.space5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Uds.gray400),
          const SizedBox(height: Uds.space3),
          Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: Uds.space2),
            Text(message!, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
          if (action != null) ...[
            const SizedBox(height: Uds.space4),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Peringatan / galat. Pesan server ditampilkan apa adanya (blueprint 14 §1.4).
class GmNotice extends StatelessWidget {
  const GmNotice(
    this.message, {
    super.key,
    this.tone = GmTone.danger,
    this.onRetry,
  });

  final String message;
  final GmTone tone;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (tone) {
      GmTone.success => (Uds.success.withValues(alpha: 0.10), Uds.success, Icons.check_circle_outline),
      GmTone.warning => (Uds.warning.withValues(alpha: 0.12), const Color(0xFF8A5B00), Icons.error_outline),
      GmTone.info => (Uds.info.withValues(alpha: 0.10), Uds.info, Icons.info_outline),
      _ => (Uds.error.withValues(alpha: 0.08), Uds.error, Icons.warning_amber_rounded),
    };

    return Container(
      padding: const EdgeInsets.all(Uds.space3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Uds.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: Uds.space2),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: foreground, minimumSize: const Size(0, 36)),
              child: const Text('Coba lagi'),
            ),
        ],
      ),
    );
  }
}

/// Pemuat isi: teks pendek, bukan layar kosong tanpa keterangan.
class GmLoading extends StatelessWidget {
  const GmLoading({super.key, this.label = 'Memuat…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Uds.space6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Uds.green),
          ),
          const SizedBox(width: Uds.space3),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Nominal uang besar — dipakai total kasir dan harga tiket.
class GmMoney extends StatelessWidget {
  const GmMoney(this.amount, {super.key, this.size = 20, this.emphasis = false});

  final String? amount;
  final double size;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Text(
      asMoney(amount),
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: emphasis ? Uds.greenDeep : Uds.black900,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
