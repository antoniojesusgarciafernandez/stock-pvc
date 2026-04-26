class Retal {
  final int? id;
  final int perfilId;
  final int longitud; // en mm
  final DateTime fechaCreacion;

  Retal({
    this.id,
    required this.perfilId,
    required this.longitud,
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'perfil_id': perfilId,
      'longitud': longitud,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Retal.fromMap(Map<String, dynamic> map) {
    return Retal(
      id: map['id'] as int?,
      perfilId: map['perfil_id'] as int,
      longitud: map['longitud'] as int,
      fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
    );
  }
}
