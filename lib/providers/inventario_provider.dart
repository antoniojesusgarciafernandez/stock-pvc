import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/perfil.dart';
import '../models/retal.dart';

class InventarioProvider extends ChangeNotifier {
  List<Perfil> _perfiles = [];
  final Map<int, List<Retal>> _retalesMap = {};
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterColor = '';
  bool? _filterBicolor;

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get filterColor => _filterColor;
  bool? get filterBicolor => _filterBicolor;

  List<Perfil> get perfiles {
    return _perfiles.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nombreMatch = p.nombre.toLowerCase().contains(q);
        final colorMatch = p.colorPrincipal.toLowerCase().contains(q);
        if (!nombreMatch && !colorMatch) return false;
      }
      if (_filterColor.isNotEmpty && p.colorPrincipal != _filterColor) return false;
      if (_filterBicolor != null && p.esBicolor != _filterBicolor) return false;
      return true;
    }).toList();
  }

  List<Retal> getRetales(int perfilId) => _retalesMap[perfilId] ?? [];

  // Total mm disponibles (barras enteras + retales)
  int totalMm(Perfil p) {
    if (p.id == null) return 0;
    final mmRetales = (_retalesMap[p.id!] ?? []).fold<int>(0, (s, r) => s + r.longitud);
    return p.barrasEnteras * p.longitudInicial + mmRetales;
  }

  bool isStockBajo(Perfil p) => p.barrasEnteras <= p.stockMinimo;

  List<String> get coloresDisponibles =>
      _perfiles.map((p) => p.colorPrincipal).toSet().toList()..sort();

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _perfiles = await DatabaseHelper.instance.getAllPerfiles();
    for (final p in _perfiles) {
      if (p.id != null) {
        _retalesMap[p.id!] = await DatabaseHelper.instance.getRetalesByPerfil(p.id!);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterColor(String color) {
    _filterColor = color;
    notifyListeners();
  }

  void setFilterBicolor(bool? value) {
    _filterBicolor = value;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterColor = '';
    _filterBicolor = null;
    notifyListeners();
  }

  Future<bool> addPerfil(Perfil perfil) async {
    try {
      final id = await DatabaseHelper.instance.insertPerfil(perfil);
      _perfiles.add(perfil.copyWith(id: id));
      _retalesMap[id] = [];
      _perfiles.sort((a, b) => a.nombre.compareTo(b.nombre));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updatePerfil(Perfil perfil) async {
    try {
      await DatabaseHelper.instance.updatePerfil(perfil);
      final i = _perfiles.indexWhere((p) => p.id == perfil.id);
      if (i != -1) _perfiles[i] = perfil;
      _perfiles.sort((a, b) => a.nombre.compareTo(b.nombre));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePerfil(int id) async {
    try {
      await DatabaseHelper.instance.deletePerfil(id);
      _perfiles.removeWhere((p) => p.id == id);
      _retalesMap.remove(id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addStock(int perfilId, int barras) async {
    try {
      final i = _perfiles.indexWhere((p) => p.id == perfilId);
      if (i == -1) return false;
      final updated = _perfiles[i].copyWith(barrasEnteras: _perfiles[i].barrasEnteras + barras);
      await DatabaseHelper.instance.updatePerfil(updated);
      _perfiles[i] = updated;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ResultadoCorte> registrarCorte(int perfilId, int longitudMm) async {
    final resultado = await DatabaseHelper.instance.registrarCorte(perfilId, longitudMm);
    if (resultado.exito) await loadData();
    return resultado;
  }

  Future<bool> deleteRetal(int retalId, int perfilId) async {
    try {
      await DatabaseHelper.instance.deleteRetal(retalId);
      _retalesMap[perfilId]?.removeWhere((r) => r.id == retalId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
