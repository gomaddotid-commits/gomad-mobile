import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomad_mobile/src/theme/gomad_theme.dart';
import 'package:gomad_mobile/src/theme/uds.dart';
import 'package:gomad_mobile/src/ui/kit/gm_kit.dart';
import 'package:gomad_mobile/src/workspace.dart';

/// Peta peran → ruang kerja. Salah di sini berarti pengguna masuk ke layar
/// yang bukan pekerjaannya, jadi pemetaannya dikunci dengan tes.
void main() {
  test('account_type dipetakan ke ruang kerja yang benar', () {
    expect(Workspace.fromAccountType('customer'), Workspace.passenger);
    expect(Workspace.fromAccountType('driver'), Workspace.driver);
    expect(Workspace.fromAccountType('warung_guard'), Workspace.warungGuard);
    expect(Workspace.fromAccountType('warung_owner'), Workspace.warungOwner);
    expect(Workspace.fromAccountType('agency_owner'), Workspace.webOnly);
    expect(Workspace.fromAccountType('ops'), Workspace.webOnly);
    expect(Workspace.fromAccountType(null), Workspace.webOnly);
  });

  test('hanya penumpang memakai bahasa desain konsumen', () {
    expect(Workspace.passenger.language, DesignLanguage.consumer);
    expect(Workspace.driver.language, DesignLanguage.operational);
    expect(Workspace.warungGuard.language, DesignLanguage.operational);
    expect(DesignLanguage.fromAccountType('customer'), DesignLanguage.consumer);
    expect(DesignLanguage.fromAccountType('driver'), DesignLanguage.operational);
  });

  testWidgets('kit widget tampil dengan tema UDS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GomadTheme.of(DesignLanguage.operational),
        home: const Scaffold(
          body: Column(
            children: [
              GmSurface(child: Text('Kartu')),
              GmBadge('Lunas', tone: GmTone.success),
              GmMoney('15000.00'),
              GmKeyValue('Total', 'Rp 15.000', emphasis: true),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Kartu'), findsOneWidget);
    expect(find.text('Lunas'), findsOneWidget);
    expect(find.text('Rp 15000.00'), findsNothing);
    expect(find.text('Rp 15.000'), findsWidgets);
  });

  test('token kontras utama sesuai UDS', () {
    // Nilai dari docs/blueprint/15-design-system.md §4.2 — bukan dikarang di sini.
    expect(Uds.greenDeep, const Color(0xFF174D38));
    expect(Uds.lime, const Color(0xFFA8E62E));
    expect(Uds.gray500, const Color(0xFF6B776C));
  });
}
