import 'package:flutter/material.dart';

import 'src/api_config.dart';
import 'src/session.dart';
import 'src/theme/gomad_theme.dart';
import 'src/ui/login_page.dart';
import 'src/ui/shell/app_shell.dart';
import 'src/workspace.dart';

void main() {
  runApp(const GomadApp());
}

/// Kerangka aplikasi: satu sesi untuk seluruh aplikasi.
///
/// Tema ikut berubah bersama peran: penumpang memakai bahasa desain konsumen,
/// peran kerja memakai operasional. Karena itu `MaterialApp` dibangun ulang saat
/// sesi berubah — bukan hanya halaman di dalamnya.
class GomadApp extends StatefulWidget {
  const GomadApp({super.key, this.session});

  /// Dipakai tes untuk menyuntikkan sesi dengan klien palsu.
  final Session? session;

  @override
  State<GomadApp> createState() => _GomadAppState();
}

class _GomadAppState extends State<GomadApp> {
  late final Session _session;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? Session(config: ApiConfig.fromEnvironment());

    if (widget.session == null) {
      _session.restore();
    }
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final workspace = Workspace.fromAccountType(_session.user?.accountType);

        return MaterialApp(
          title: 'GoMad',
          debugShowCheckedModeBanner: false,
          theme: GomadTheme.of(workspace.language),
          home: _session.isAuthenticated
              ? AppShell(session: _session)
              : LoginPage(session: _session),
        );
      },
    );
  }
}
