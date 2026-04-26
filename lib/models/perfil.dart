class Perfil {
  final int? id;
  final String nombre;
  final String colorPrincipal;
  final bool esBicolor;
  final String? colorInterior;
  final String? colorExterior;
  final int longitudInicial; // en mm
  final int barrasEnteras;
  final int stockMinimo;

  const Perfil({
    this.id,
    required this.nombre,
    required this.colorPrincipal,
    required this.esBicolor,
    this.colorInterior,
    this.colorExterior,
    required this.longitudInicial,
    required this.barrasEnteras,
    this.stockMinimo = 5,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'color_principal': colorPrincipal,
      'es_bicolor': esBicolor ? 1 : 0,
      'color_interior': colorInterior,
      'color_exterior': colorExterior,
      'longitud_inicial': longitudInicial,
      'barras_enteras': barrasEnteras,
      'stock_minimo': stockMinimo,
    };
  }

  factory Perfil.fromMap(Map<String, dynamic> map) {
    return Perfil(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      colorPrincipal: map['color_principal'] as String,
      esBicolor: (map['es_bicolor'] as int) == 1,
      colorInterior: map['color_interior'] as String?,
      colorExterior: map['color_exterior'] as String?,
      longitudInicial: map['longitud_inicial'] as int,
      barrasEnteras: map['barras_enteras'] as int,
      stockMinimo: (map['stock_minimo'] as int?) ?? 5,
    );
  }

  Perfil copyWith({
    int? id,
    String? nombre,
    String? colorPrincipal,
    bool? esBicolor,
    String? colorInterior,
    String? colorExterior,
    int? longitudInicial,
    int? barrasEnteras,
    int? stockMinimo,
  }) {
    return Perfil(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      colorPrincipal: colorPrincipal ?? this.colorPrincipal,
      esBicolor: esBicolor ?? this.esBicolor,
      colorInterior: colorInterior ?? this.colorInterior,
      colorExterior: colorExterior ?? this.colorExterior,
      longitudInicial: longitudInicial ?? this.longitudInicial,
      barrasEnteras: barrasEnteras ?? this.barrasEnteras,
      stockMinimo: stockMinimo ?? this.stockMinimo,
    );
  }
}
