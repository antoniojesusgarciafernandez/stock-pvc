import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/perfil.dart';
import '../models/retal.dart';
import '../providers/inventario_provider.dart';
import '../theme/app_theme.dart';
import 'anadir_perfil_screen.dart';
import 'entrada_stock_screen.dart';
import 'registrar_corte_screen.dart';

class DetallePerfilScreen extends StatelessWidget {
  final int perfilId;

  const DetallePerfilScreen({super.key, required this.perfilId});

  @override
  Widget build(BuildContext context) {
    return Consumer<InventarioProvider>(
      builder: (ctx, provider, _) {
        final idx = provider.perfiles.indexWhere((p) => p.id == perfilId);
        if (idx == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text('Perfil')),
            body: const Center(child: Text('Perfil no encontrado')),
          );
        }
        final perfil = provider.perfiles[idx];
        final retales = provider.getRetales(perfilId);

        return Scaffold(
          appBar: AppBar(
            title: Text(perfil.nombre),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AnadirPerfilScreen(perfil: perfil)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar',
                onPressed: () => _confirmarEliminar(context, provider),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _TarjetaInfo(perfil: perfil, provider: provider),
              const SizedBox(height: 10),
              _BotonesAccion(perfil: perfil),
              const SizedBox(height: 10),
              _SeccionRetales(perfilId: perfilId, retales: retales, provider: provider),
            ],
          ),
        );
      },
    );
  }

  void _confirmarEliminar(BuildContext context, InventarioProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar perfil'),
        content: const Text(
          '¿Seguro que deseas eliminar este perfil?\nSe eliminarán también todos sus retales.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              await provider.deletePerfil(perfilId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _TarjetaInfo extends StatelessWidget {
  final Perfil perfil;
  final InventarioProvider provider;

  const _TarjetaInfo({required this.perfil, required this.provider});

  @override
  Widget build(BuildContext context) {
    final retales = provider.getRetales(perfil.id!);
    final totalMm = provider.totalMm(perfil);
    final stockBajo = provider.isStockBajo(perfil);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stockBajo)
              _Banner(
                '¡Stock bajo el mínimo configurado (${perfil.stockMinimo} barras)!',
                AppTheme.danger,
                Icons.warning_rounded,
              ),
            if (stockBajo) const SizedBox(height: 12),
            _Fila('Color', perfil.esBicolor
                ? '${perfil.colorInterior} (int.) / ${perfil.colorExterior} (ext.)'
                : perfil.colorPrincipal),
            _Fila('Tipo', perfil.esBicolor ? 'Bicolor' : 'Monocolor'),
            _Fila(
              'Longitud barra',
              '${perfil.longitudInicial} mm  (${(perfil.longitudInicial / 1000).toStringAsFixed(2)} m)',
            ),
            _Fila('Stock mínimo', '${perfil.stockMinimo} barras'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BigStat('${perfil.barrasEnteras}', 'Barras\nenteras',
                    stockBajo ? AppTheme.danger : AppTheme.primary),
                _BigStat('${retales.length}', 'Retales\ndisponibles', AppTheme.primary),
                _BigStat(
                  '${(totalMm / 1000).toStringAsFixed(2)} m',
                  'Total\ndisponible',
                  stockBajo ? AppTheme.danger : AppTheme.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String label;
  final String value;

  const _Fila(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _BigStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final String mensaje;
  final Color color;
  final IconData icon;

  const _Banner(this.mensaje, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _BotonesAccion extends StatelessWidget {
  final Perfil perfil;

  const _BotonesAccion({required this.perfil});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EntradaStockScreen(perfil: perfil)),
            ),
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Añadir Stock'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RegistrarCorteScreen(perfilPreseleccionado: perfil),
              ),
            ),
            icon: const Icon(Icons.content_cut),
            label: const Text('Registrar Corte'),
          ),
        ),
      ],
    );
  }
}

class _SeccionRetales extends StatelessWidget {
  final int perfilId;
  final List<Retal> retales;
  final InventarioProvider provider;

  const _SeccionRetales({
    required this.perfilId,
    required this.retales,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.linear_scale, size: 18, color: AppTheme.primary),
                const SizedBox(width: 6),
                const Text('Retales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text('${retales.length} piezas',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            if (retales.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Sin retales', style: TextStyle(color: Colors.grey.shade400)),
                ),
              )
            else
              ...retales.map((r) => _RetalFila(retal: r, perfilId: perfilId, provider: provider)),
          ],
        ),
      ),
    );
  }
}

class _RetalFila extends StatelessWidget {
  final Retal retal;
  final int perfilId;
  final InventarioProvider provider;

  const _RetalFila({required this.retal, required this.perfilId, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.straighten, size: 15, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '${retal.longitud} mm',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          Text(
            '  (${(retal.longitud / 1000).toStringAsFixed(3)} m)',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _confirmarEliminar(context),
            child: Icon(Icons.delete_outline, color: AppTheme.danger, size: 22),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar retal'),
        content: Text('¿Eliminar retal de ${retal.longitud} mm?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              await provider.deleteRetal(retal.id!, perfilId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
