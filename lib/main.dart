import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/inventario_provider.dart';
import 'screens/inventario_screen.dart';
import 'screens/detalle_perfil_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
