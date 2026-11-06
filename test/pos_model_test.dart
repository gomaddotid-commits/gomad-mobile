import 'package:flutter_test/flutter_test.dart';
import 'package:gomad_api/gomad_api.dart' as gomad;

/// Nota kasir yang dikirim server punya beberapa field kosong: penjualan tanpa
/// shift (`shift_id: null`), tanpa uang diterima, tanpa catatan.
///
/// Tes ini lahir dari kegagalan nyata saat uji live 2026-11-06: kontrak sempat
/// menghasilkan `allOf`, generator Dart menggabungkannya menjadi kelas tanpa
/// nullability, lalu aplikasi **gagal membaca nota yang sudah tersimpan** —
/// kasir melihat pesan galat padahal penjualan masuk. Payload di bawah adalah
/// bentuk asli jawaban `/v1/warung/businesses/{id}/pos/sales`.
void main() {
  test('nota kasir dengan shift_id null tetap bisa dibaca', () {
    final sale = gomad.RetailSaleResource.fromJson({
      'id': 4,
      'code': 'MW-PS-2611-BSVJVXCO',
      'business_id': 4,
      'sold_by': 8,
      'seller_name': null,
      'shift_id': null,
      'payment_method': 'cash',
      'total_amount': '19000.00',
      'paid_amount': null,
      'change_amount': '0.00',
      'note': null,
      'created_at': null,
      'items': [
        {
          'product_id': 3,
          'product_name': 'Gula Pasir 1kg',
          'unit': 'pack',
          'quantity': 1,
          'unit_price': '19000.00',
          'subtotal': '19000.00',
        },
      ],
    });

    expect(sale.shiftId, isNull);
    expect(sale.paidAmount, isNull);
    expect(sale.items.single.productName, 'Gula Pasir 1kg');
    expect(sale.totalAmount, '19000.00');
  });

  test('nota kasir dengan shift dan uang diterima terbaca utuh', () {
    final sale = gomad.RetailSaleResource.fromJson({
      'id': 5,
      'code': 'MW-PS-2611-EXIST',
      'business_id': 4,
      'sold_by': 8,
      'seller_name': 'Penjaga Warung Demo',
      'shift_id': 2,
      'payment_method': 'cash',
      'total_amount': '38000.00',
      'paid_amount': '50000.00',
      'change_amount': '12000.00',
      'note': 'titip',
      'created_at': '2026-11-06T10:29:41+07:00',
      'items': [],
    });

    expect(sale.shiftId, 2);
    expect(sale.paidAmount, '50000.00');
    expect(sale.changeAmount, '12000.00');
    expect(sale.sellerName, 'Penjaga Warung Demo');
  });
}
