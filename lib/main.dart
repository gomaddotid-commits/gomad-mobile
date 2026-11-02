import 'package:flutter/material.dart';

import 'src/api_config.dart';
import 'src/session.dart';
import 'src/ui/home_page.dart';
import 'src/ui/login_page.dart';

void main() {
  runApp(const GomadApp());
}

/// Kerangka aplikasi: satu sesi untuk seluruh aplikasi, halaman beranda
/// bergantung pada status masuk.
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
    return MaterialApp(
      title: 'GoMad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
        useMaterial3: true,
      ),
      home: ListenableBuilder(
        listenable: _session,
        builder: (context, _) {
          if (_session.isAuthenticated) {
            return HomePage(session: _session);
          }

          return LoginPage(session: _session);
        },
      ),
    );
  }
}
