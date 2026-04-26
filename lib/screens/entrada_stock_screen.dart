import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/perfil.dart';
import '../providers/inventario_provider.dart';
import '../theme/app_theme.dart';

class EntradaStockScreen extends StatefulWidget {
  final Perfil perfil;

  const EntradaStockScreen({super.key, required this.perfil});

  @override
  State<EntradaStockScreen> createState() => _EntradaStockScreenState();
}

class _EntradaStockScreenState extends State<EntradaStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barrasCtrl = TextEditingController();
  bool _guardando = false;

  int get _barrasNuevas => int.tryParse(_barrasCtrl.text) ?? 0;
  int get _nuevoTotal => widget.perfil.barrasEnteras + _barrasNuevas;

  @override
  void dispose() {
    _barrasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir Stock')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.perfil.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.perfil.colorPrincipal,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _InfoItem('Stock actual', '${widget.perfil.barrasEnteras} barras',
                            Icons.inventory_2_outlined),
                        const SizedBox(width: 20),
                        _InfoItem(
                          'Longitud/barra',
                          '${widget.perfil.longitudInicial} mm',
                          Icons.straighten,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _barrasCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Barras a añadir *',
                hintText: 'Ej. 10',
                prefixIcon: Icon(Icons.add_box_outlined),
                suffixText: 'barras',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 20),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Introduce la cantidad';
                final n = int.tryParse(v);
                if (n == null || n <= 0) return 'Debe ser mayor que 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (_barrasNuevas > 0)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          children: [
                            const TextSpan(text: 'Nuevo total: '),
                            TextSpan(
                              text: '$_nuevoTotal barras',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success,
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '  (+$_barrasNuevas)',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                onPressed: _guardando ? null : _confirmar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Confirmar Entrada de Stock'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final ok = await context.read<InventarioProvider>().addStock(
          widget.perfil.id!,
          int.parse(_barrasCtrl.text),
        );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '+${_barrasCtrl.text} barras añadidas a ${widget.perfil.nombre}',
        ),
        backgroundColor: AppTheme.success,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al añadir stock'),
        backgroundColor: Colors.red,
      ));
    }
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoItem(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
