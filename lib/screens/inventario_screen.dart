import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventario_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/perfil_card.dart';
import 'anadir_perfil_screen.dart';
import 'registrar_corte_screen.dart';

class InventarioScreen extends StatelessWidget {
  const InventarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PVC Stock Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtros',
            onPressed: () => _mostrarFiltros(context),
          ),
        ],
      ),
      body: const Column(
        children: [
          _SearchBar(),
          _StatsBar(),
          Expanded(child: _ListaPerfiles()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'btn_corte',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegistrarCorteScreen()),
            ),
            icon: const Icon(Icons.content_cut),
            label: const Text('Registrar Corte'),
            backgroundColor: AppTheme.success,
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'btn_add',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnadirPerfilScreen()),
            ),
            tooltip: 'Nuevo perfil',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _mostrarFiltros(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<InventarioProvider>(),
        child: const _FiltrosSheet(),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Buscar por nombre o color...',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: context.read<InventarioProvider>().setSearch,
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();
    final total = provider.perfiles.length;
    final bajoStock = provider.perfiles.where(provider.isStockBajo).length;
    final hayFiltro = provider.filterColor.isNotEmpty || provider.filterBicolor != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          _Chip('$total perfiles', Icons.inventory_2_outlined, Colors.blueGrey),
          if (bajoStock > 0) ...[
            const SizedBox(width: 8),
            _Chip('$bajoStock bajo stock', Icons.warning_amber, AppTheme.warning),
          ],
          if (hayFiltro) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: context.read<InventarioProvider>().clearFilters,
              child: _Chip('Limpiar filtros', Icons.filter_alt_off, Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Chip(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ListaPerfiles extends StatelessWidget {
  const _ListaPerfiles();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.perfiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Sin perfiles registrados',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              'Pulsa + para añadir tu primer perfil',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 140),
        itemCount: provider.perfiles.length,
        itemBuilder: (_, i) => PerfilCard(perfil: provider.perfiles[i]),
      ),
    );
  }
}

class _FiltrosSheet extends StatelessWidget {
  const _FiltrosSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventarioProvider>();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Filtros', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  provider.clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Limpiar todo'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Color:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: provider.filterColor.isEmpty,
                onSelected: (_) => provider.setFilterColor(''),
              ),
              ...provider.coloresDisponibles.map(
                (c) => FilterChip(
                  label: Text(c),
                  selected: provider.filterColor == c,
                  onSelected: (_) => provider.setFilterColor(c),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: provider.filterBicolor == null,
                onSelected: (_) => provider.setFilterBicolor(null),
              ),
              FilterChip(
                label: const Text('Monocolor'),
                selected: provider.filterBicolor == false,
                onSelected: (_) => provider.setFilterBicolor(false),
              ),
              FilterChip(
                label: const Text('Bicolor'),
                selected: provider.filterBicolor == true,
                onSelected: (_) => provider.setFilterBicolor(true),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aplicar'),
            ),
          ),
        ],
      ),
    );
  }
}
