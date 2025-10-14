class Expense {
  final int id;
  final String titulo;
  final String categoria;
  final double monto;
  final String fecha;
  final String? descripcion;

  Expense({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.monto,
    required this.fecha,
    this.descripcion,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      titulo: json['titulo'],
      categoria: json['categoria'],
      monto: (json['monto'] as num).toDouble(),
      fecha: json['fecha'],
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'categoria': categoria,
      'monto': monto,
      'fecha': fecha,
      'descripcion': descripcion,
    };
  }
}
