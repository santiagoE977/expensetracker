// Modelo de datos para representar un gasto dentro de la aplicación
class Expense {
  // Atributos (propiedades) del gasto
  final int id; // Identificador único (lo asigna el backend)
  final String titulo; // Título o nombre del gasto
  final String categoria; // Categoría del gasto (Comida, Transporte, etc.)
  final double monto; // Valor del gasto
  final String fecha; // Fecha del gasto (en formato "YYYY-MM-DD")
  final String? descripcion; // Descripción opcional del gasto

  // Constructor: se usa para crear una nueva instancia de Expense
  Expense({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.monto,
    required this.fecha,
    this.descripcion, // Puede ser nula porque es opcional
  });

  // Método de fábrica que crea un objeto Expense a partir de un JSON (por ejemplo, respuesta del backend)
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'], // Extrae el campo "id" del JSON
      titulo: json['titulo'], // Extrae el campo "titulo"
      categoria: json['categoria'], // Extrae la categoría
      monto: (json['monto'] as num).toDouble(), // Asegura que el valor se convierta a double
      fecha: json['fecha'], // Extrae la fecha
      descripcion: json['descripcion'], // Puede ser null
    );
  }

  // Convierte el objeto Expense a un mapa JSON (para enviarlo al backend)
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