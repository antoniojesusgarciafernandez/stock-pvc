import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Añade esta línea
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Añade esta línea
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Añade esta línea
import 'providers/inventario_provider.dart';
import 'screens/inventario_screen.dart';
import 'screens/detalle_perfil_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // --- INICIALIZACIÓN PARA WEB ---
  if (kIsWeb) {
    // Esto prepara el motor de base de datos en el navegador
    databaseFactory = databaseFactoryFfiWeb;
  }
  // -------------------------------

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const PvcStockApp());
}

class PvcStockApp extends StatelessWidget {
  const PvcStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InventarioProvider()..loadData(),
      child: MaterialApp(
        title: 'PVC Stock Manager',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const InventarioScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/detalle') {
            final perfilId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (_) => DetallePerfilScreen(perfilId: perfilId),
            );
          }
          return null;
        },
      ),
    );
  }
}
