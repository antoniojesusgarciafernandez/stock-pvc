import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/perfil.dart';
import '../providers/inventario_provider.dart';
import '../theme/app_theme.dart';

class PerfilCard extends StatelessWidget {
  final Perfil perfil;

  const PerfilCard({super.key, required this.perfil});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    final retales = provider.getRetales(perfil.id!);
    final totalMm = provider.totalMm(perfil);
    final totalM = (totalMm / 1000).toStringAsFixed(2);
    final stockBajo = provider.isStockBajo(perfil);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pushNamed(
          context,
          '/detalle',
          arguments: perfil.id,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perfil.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          perfil.esBicolor
                              ? '${perfil.colorInterior} / ${perfil.colorExterior}'
                              : perfil.colorPrincipal,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (perfil.esBicolor)
                    _Badge('BICOLOR', Colors.purple.shade600, Colors.purple.shade50),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StockChip(
                    icon: Icons.view_week,
                    label: 'Barras',
                    value: '${perfil.barrasEnteras}',
                    color: stockBajo ? AppTheme.danger : AppTheme.primary,
                  ),
                  const SizedBox(width: 14),
                  _StockChip(
                    icon: Icons.linear_scale,
                    label: 'Retales',
                    value: '${retales.length}',
                    color: AppTheme.primary,
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$totalM m',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: stockBajo ? AppTheme.danger : Colors.black87,
                        ),
                      ),
                      Text(
                        'disponible',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
              if (stockBajo) ...[
                const SizedBox(height: 10),
                _AlertaBanner(
                  'Stock bajo (mín. ${perfil.stockMinimo} barras)',
                  AppTheme.danger,
                  Icons.warning_amber_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Badge(this.label, this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StockChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ],
    );
  }
}

class _AlertaBanner extends StatelessWidget {
  final String mensaje;
  final Color color;
  final IconData icon;

  const _AlertaBanner(this.mensaje, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            mensaje,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
