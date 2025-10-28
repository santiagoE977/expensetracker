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

  // Para enviar al backend (no incluye user_id; lo añade ApiService)
  Map<String, dynamic> toJson() => {
    'titulo': titulo,
    'categoria': categoria,
    'monto': monto,
    'fecha': fecha,
    'descripcion': descripcion,
  };

  // ✅ Agrega este factory para construir desde el JSON del backend
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as int,
    titulo: json['titulo'] as String,
    categoria: json['categoria'] as String,
    monto: (json['monto'] as num).toDouble(),
    fecha: json['fecha'] as String,
    descripcion: json['descripcion'] as String?,
  );
}
