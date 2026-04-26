import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/perfil.dart';
import '../providers/inventario_provider.dart';

class AnadirPerfilScreen extends StatefulWidget {
  final Perfil? perfil;

  const AnadirPerfilScreen({super.key, this.perfil});

  @override
  State<AnadirPerfilScreen> createState() => _AnadirPerfilScreenState();
}

class _AnadirPerfilScreenState extends State<AnadirPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _colorPrincipalCtrl;
  late final TextEditingController _colorInteriorCtrl;
  late final TextEditingController _colorExteriorCtrl;
  late final TextEditingController _longitudCtrl;
  late final TextEditingController _barrasCtrl;
  late final TextEditingController _stockMinimoCtrl;
  late bool _esBicolor;
  bool _guardando = false;

  bool get _editando => widget.perfil != null;

  @override
  void initState() {
    super.initState();
    final p = widget.perfil;
    _esBicolor = p?.esBicolor ?? false;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _colorPrincipalCtrl = TextEditingController(text: p?.esBicolor == false ? (p?.colorPrincipal ?? '') : '');
    _colorInteriorCtrl = TextEditingController(text: p?.colorInterior ?? '');
    _colorExteriorCtrl = TextEditingController(text: p?.colorExterior ?? '');
    _longitudCtrl = TextEditingController(text: p?.longitudInicial.toString() ?? '6000');
    _barrasCtrl = TextEditingController(text: p?.barrasEnteras.toString() ?? '0');
    _stockMinimoCtrl = TextEditingController(text: p?.stockMinimo.toString() ?? '5');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _colorPrincipalCtrl.dispose();
    _colorInteriorCtrl.dispose();
    _colorExteriorCtrl.dispose();
    _longitudCtrl.dispose();
    _barrasCtrl.dispose();
    _stockMinimoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar Perfil' : 'Nuevo Perfil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _SeccionTitulo('Identificación'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre / Referencia *',
                hintText: 'Ej. Marco 60mm, Hoja Puerta, Junquillo',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 20),
            _SeccionTitulo('Color'),
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              child: SwitchListTile(
                title: const Text('Perfil Bicolor'),
                subtitle: const Text('Dos colores diferentes (interior/exterior)'),
                value: _esBicolor,
                onChanged: (v) => setState(() => _esBicolor = v),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _esBicolor ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: TextFormField(
                controller: _colorPrincipalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Color *',
                  hintText: 'Ej. Blanco, Roble Dorado, Gris Antracita',
                  prefixIcon: Icon(Icons.palette_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (!_esBicolor && (v == null || v.trim().isEmpty))
                    ? 'Campo obligatorio'
                    : null,
              ),
              secondChild: Column(
                children: [
                  TextFormField(
                    controller: _colorInteriorCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Color Interior *',
                      hintText: 'Ej. Blanco',
                      prefixIcon: Icon(Icons.looks_one_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (_esBicolor && (v == null || v.trim().isEmpty))
                        ? 'Campo obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _colorExteriorCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Color Exterior *',
                      hintText: 'Ej. Roble Dorado, Gris Antracita',
                      prefixIcon: Icon(Icons.looks_two_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (_esBicolor && (v == null || v.trim().isEmpty))
                        ? 'Campo obligatorio'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SeccionTitulo('Medidas y Stock'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _longitudCtrl,
              decoration: const InputDecoration(
                labelText: 'Longitud de barra (mm) *',
                hintText: '6000',
                suffixText: 'mm',
                prefixIcon: Icon(Icons.straighten),
                helperText: '6000 mm = 6 metros',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo obligatorio';
                final n = int.tryParse(v);
                if (n == null || n <= 0) return 'Longitud inválida';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _barrasCtrl,
              decoration: const InputDecoration(
                labelText: 'Barras iniciales en stock',
                suffixText: 'barras',
                prefixIcon: Icon(Icons.view_week_outlined),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final n = int.tryParse(v);
                if (n == null || n < 0) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stockMinimoCtrl,
              decoration: const InputDecoration(
                labelText: 'Stock mínimo (alerta roja)',
                hintText: '5',
                suffixText: 'barras',
                prefixIcon: Icon(Icons.notification_important_outlined),
                helperText: 'Se mostrará alerta si hay menos barras de este número',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_editando ? Icons.save_outlined : Icons.add_circle_outline),
                label: Text(_editando ? 'Guardar Cambios' : 'Crear Perfil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final colorPrincipal = _esBicolor
        ? '${_colorInteriorCtrl.text.trim()} / ${_colorExteriorCtrl.text.trim()}'
        : _colorPrincipalCtrl.text.trim();

    final perfil = Perfil(
      id: _editando ? widget.perfil!.id : null,
      nombre: _nombreCtrl.text.trim(),
      colorPrincipal: colorPrincipal,
      esBicolor: _esBicolor,
      colorInterior: _esBicolor ? _colorInteriorCtrl.text.trim() : null,
      colorExterior: _esBicolor ? _colorExteriorCtrl.text.trim() : null,
      longitudInicial: int.parse(_longitudCtrl.text),
      barrasEnteras: int.tryParse(_barrasCtrl.text) ?? 0,
      stockMinimo: int.tryParse(_stockMinimoCtrl.text) ?? 5,
    );

    final provider = context.read<InventarioProvider>();
    final ok = _editando ? await provider.updatePerfil(perfil) : await provider.addPerfil(perfil);

    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_editando ? 'Perfil actualizado correctamente' : 'Perfil creado correctamente'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al guardar. Inténtalo de nuevo.'),
        backgroundColor: Colors.red,
      ));
    }
  }
}

class _SeccionTitulo extends StatelessWidget {
  final String title;

  const _SeccionTitulo(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    );
  }
}
