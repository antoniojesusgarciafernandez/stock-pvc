import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/perfil.dart';
import '../models/retal.dart';
import '../providers/inventario_provider.dart';
import '../theme/app_theme.dart';

class RegistrarCorteScreen extends StatefulWidget {
  final Perfil? perfilPreseleccionado;

  const RegistrarCorteScreen({super.key, this.perfilPreseleccionado});

  @override
  State<RegistrarCorteScreen> createState() => _RegistrarCorteScreenState();
}

class _RegistrarCorteScreenState extends State<RegistrarCorteScreen> {
  Perfil? _perfil;
  final _longitudCtrl = TextEditingController();
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _perfil = widget.perfilPreseleccionado;
    _longitudCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _longitudCtrl.dispose();
    super.dispose();
  }

  int? get _longitudMm => int.tryParse(_longitudCtrl.text);

  // ─── Vista previa del algoritmo (sin tocar la base de datos) ────────────────
  _PreviewCorte? _calcularPreview(InventarioProvider provider) {
    final lon = _longitudMm;
    if (lon == null || lon <= 0 || _perfil == null) return null;

    if (lon > _perfil!.longitudInicial) {
      return _PreviewCorte.error(
        'El corte (${lon}mm) supera la longitud de la barra (${_perfil!.longitudInicial}mm)',
      );
    }

    final retales = provider.getRetales(_perfil!.id!);
    final validos = retales.where((r) => r.longitud >= lon).toList()
      ..sort((a, b) => a.longitud.compareTo(b.longitud));

    if (validos.isNotEmpty) {
      final retal = validos.first;
      final sobrante = retal.longitud - lon;
      return _PreviewCorte.retal(retal, sobrante);
    }

    if (_perfil!.barrasEnteras > 0) {
      final sobrante = _perfil!.longitudInicial - lon;
      return _PreviewCorte.barraEntera(_perfil!.longitudInicial, sobrante);
    }

    return _PreviewCorte.error('Stock insuficiente. No hay barras ni retales disponibles.');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    final preview = _calcularPreview(provider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Corte')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
        children: [
          // ── Selección de perfil ──────────────────────────────────────────────
          _Tarjeta(
            titulo: 'Perfil a cortar',
            icon: Icons.inventory_2_outlined,
            child: _perfil == null
                ? _SelectorPerfiles(
                    perfiles: provider.perfiles,
                    onSeleccionado: (p) => setState(() {
                      _perfil = p;
                      _longitudCtrl.clear();
                    }),
                  )
                : _PerfilElegido(
                    perfil: _perfil!,
                    retales: provider.getRetales(_perfil!.id!),
                    onCambiar: () => setState(() {
                      _perfil = null;
                      _longitudCtrl.clear();
                    }),
                  ),
          ),

          const SizedBox(height: 10),

          // ── Medida del corte ─────────────────────────────────────────────────
          _Tarjeta(
            titulo: 'Medida del corte',
            icon: Icons.content_cut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _longitudCtrl,
                  enabled: _perfil != null,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Longitud a cortar (mm)',
                    hintText: 'Ej. 1200',
                    suffixText: 'mm',
                    prefixIcon: const Icon(Icons.straighten),
                    helperText: _perfil != null
                        ? 'Barra: ${_perfil!.longitudInicial} mm  |  Barras disponibles: ${_perfil!.barrasEnteras}'
                        : 'Selecciona primero un perfil',
                  ),
                ),
                if (preview != null) ...[
                  const SizedBox(height: 12),
                  _BannerPreview(preview: preview),
                ],
              ],
            ),
          ),

          // ── Retales disponibles ──────────────────────────────────────────────
          if (_perfil != null) ...[
            const SizedBox(height: 10),
            _Tarjeta(
              titulo: 'Retales disponibles',
              icon: Icons.linear_scale,
              child: _ListaRetales(
                retales: provider.getRetales(_perfil!.id!),
                longitudCorte: _longitudMm,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Botón confirmar ──────────────────────────────────────────────────
          SizedBox(
            height: 62,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: (preview?.esExito ?? false) ? AppTheme.success : Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: (preview?.esExito ?? false) && !_procesando ? _confirmarCorte : null,
              icon: _procesando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.content_cut, size: 26),
              label: const Text(
                'CONFIRMAR CORTE',
                style: TextStyle(fontSize: 18, letterSpacing: 0.8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarCorte() async {
    final lon = _longitudMm!;
    final preview = _calcularPreview(context.read<InventarioProvider>())!;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.content_cut, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Confirmar Corte'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DialogFila('Perfil', _perfil!.nombre),
            _DialogFila('Medida', '$lon mm  (${(lon / 1000).toStringAsFixed(3)} m)'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(preview.descripcion, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _procesando = true);

    final resultado = await context.read<InventarioProvider>().registrarCorte(_perfil!.id!, lon);

    if (!mounted) return;
    setState(() => _procesando = false);

    if (resultado.exito) {
      _longitudCtrl.clear();

      // Refrescar el perfil con datos actualizados
      final updatedPerfil = context.read<InventarioProvider>().perfiles.firstWhere(
            (p) => p.id == _perfil!.id,
            orElse: () => _perfil!,
          );
      setState(() => _perfil = updatedPerfil);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Corte registrado', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(resultado.mensaje),
          ],
        ),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 4),
      ));

      if (context.read<InventarioProvider>().isStockBajo(updatedPerfil)) {
        _mostrarAlertaStockBajo(updatedPerfil);
      }
    } else {
      _mostrarError(resultado.mensaje);
    }
  }

  void _mostrarAlertaStockBajo(Perfil perfil) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.warning),
            const SizedBox(width: 8),
            const Text('Stock Bajo'),
          ],
        ),
        content: Text(
          '${perfil.nombre} tiene ahora ${perfil.barrasEnteras} barras, '
          'por debajo del mínimo configurado (${perfil.stockMinimo}).\n\n'
          '¡Considera hacer un pedido próximamente!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.danger),
            const SizedBox(width: 8),
            const Text('Sin Stock'),
          ],
        ),
        content: Text(mensaje),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

// ─── Modelo de vista previa ──────────────────────────────────────────────────

class _PreviewCorte {
  final bool esExito;
  final bool usaRetal;
  final String descripcion;
  final int? sobrante;

  const _PreviewCorte._({
    required this.esExito,
    required this.usaRetal,
    required this.descripcion,
    this.sobrante,
  });

  factory _PreviewCorte.retal(Retal retal, int sobrante) {
    final sobranteStr = sobrante > 0 ? 'Sobrante: ${sobrante}mm' : 'Sin sobrante (retal aprovechado)';
    return _PreviewCorte._(
      esExito: true,
      usaRetal: true,
      descripcion: 'Usará retal de ${retal.longitud}mm\n$sobranteStr',
      sobrante: sobrante,
    );
  }

  factory _PreviewCorte.barraEntera(int longitudBarra, int sobrante) {
    return _PreviewCorte._(
      esExito: true,
      usaRetal: false,
      descripcion: 'Abrirá una barra nueva de ${longitudBarra}mm\nSobrante: ${sobrante}mm',
      sobrante: sobrante,
    );
  }

  factory _PreviewCorte.error(String msg) {
    return _PreviewCorte._(esExito: false, usaRetal: false, descripcion: msg);
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _Tarjeta extends StatelessWidget {
  final String titulo;
  final IconData icon;
  final Widget child;

  const _Tarjeta({required this.titulo, required this.icon, required this.child});

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
                Icon(icon, size: 17, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SelectorPerfiles extends StatelessWidget {
  final List<Perfil> perfiles;
  final ValueChanged<Perfil> onSeleccionado;

  const _SelectorPerfiles({required this.perfiles, required this.onSeleccionado});

  @override
  Widget build(BuildContext context) {
    if (perfiles.isEmpty) {
      return const Text('No hay perfiles. Crea uno desde el inventario.');
    }

    return Column(
      children: perfiles
          .map(
            (p) => InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSeleccionado(p),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text(
                            p.colorPrincipal,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${p.barrasEnteras} barras',
                            style: TextStyle(
                              fontSize: 12,
                              color: p.barrasEnteras <= p.stockMinimo
                                  ? AppTheme.danger
                                  : Colors.grey.shade500,
                              fontWeight: p.barrasEnteras <= p.stockMinimo
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            )),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PerfilElegido extends StatelessWidget {
  final Perfil perfil;
  final List<Retal> retales;
  final VoidCallback onCambiar;

  const _PerfilElegido({
    required this.perfil,
    required this.retales,
    required this.onCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(perfil.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '${perfil.colorPrincipal}  ·  ${perfil.barrasEnteras} barras  ·  ${retales.length} retales',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onCambiar, child: const Text('Cambiar')),
        ],
      ),
    );
  }
}

class _BannerPreview extends StatelessWidget {
  final _PreviewCorte preview;

  const _BannerPreview({required this.preview});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;

    if (!preview.esExito) {
      color = AppTheme.danger;
      icon = Icons.error_outline;
    } else if (preview.usaRetal) {
      color = AppTheme.success;
      icon = Icons.check_circle_outline;
    } else {
      color = AppTheme.warning;
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              preview.descripcion,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaRetales extends StatelessWidget {
  final List<Retal> retales;
  final int? longitudCorte;

  const _ListaRetales({required this.retales, this.longitudCorte});

  @override
  Widget build(BuildContext context) {
    if (retales.isEmpty) {
      return Text('Sin retales disponibles', style: TextStyle(color: Colors.grey.shade400));
    }

    // Determinar cuál retal se usaría (best-fit: el más pequeño que sea suficiente)
    final lon = longitudCorte;
    Retal? retalElegido;
    if (lon != null && lon > 0) {
      final validos = retales.where((r) => r.longitud >= lon).toList()
        ..sort((a, b) => a.longitud.compareTo(b.longitud));
      if (validos.isNotEmpty) retalElegido = validos.first;
    }

    return Column(
      children: retales.map((r) {
        final esElegido = retalElegido?.id == r.id;
        final suficiente = lon != null && r.longitud >= lon;

        return Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: esElegido
                ? AppTheme.success.withOpacity(0.1)
                : suficiente
                    ? Colors.blue.withOpacity(0.05)
                    : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: esElegido
                  ? AppTheme.success.withOpacity(0.5)
                  : suficiente
                      ? Colors.blue.shade200
                      : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                esElegido ? Icons.star_rounded : Icons.straighten,
                size: 15,
                color: esElegido ? AppTheme.success : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                '${r.longitud} mm',
                style: TextStyle(
                  fontWeight: esElegido ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                  color: esElegido ? AppTheme.success : Colors.black87,
                ),
              ),
              Text(
                '  (${(r.longitud / 1000).toStringAsFixed(3)} m)',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              if (esElegido) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'SE USARÁ',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DialogFila extends StatelessWidget {
  final String label;
  final String value;

  const _DialogFila(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text('$label:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
