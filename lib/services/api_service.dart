// Importa librerías necesarias para hacer peticiones HTTP y manejar JSON
import 'dart:convert'; // Permite codificar y decodificar JSON
import 'package:http/http.dart' as http; // Librería para realizar solicitudes HTTP
import '../models/expense.dart'; // Importa el modelo Expense para enviar/recibir datos del backend

// Clase que centraliza todas las operaciones con la API
class ApiService {
  // Dirección base del backend (puedes cambiarla según tu servidor o IP local)
  static const String baseUrl = 'http://127.0.0.1:5000';

  // 🔹 Obtener todos los gastos (o filtrar por categoría)
  Future<List<dynamic>> getExpenses({String? category}) async {
    String url = '$baseUrl/expenses'; // Endpoint principal de gastos

    // Si se pasa una categoría, se agrega como parámetro a la URL
    if (category != null) {
      url += '?category=$category';
    }

    // Se realiza la solicitud GET
    final response = await http.get(Uri.parse(url));

    // Si la respuesta es exitosa (código 200), decodifica el JSON
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Si hay error, lanza una excepción con el código recibido
      throw Exception('Error al obtener gastos: ${response.statusCode}');
    }
  }

  // 🔹 Agregar un nuevo gasto
  static Future<void> addExpense(Expense expense) async {
    // Se envía una solicitud POST con los datos del gasto en formato JSON
    final response = await http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: {'Content-Type': 'application/json'}, // Indica que se envía JSON
      body: json.encode(expense.toJson()), // Convierte el objeto a JSON
    );

    // Si la respuesta no tiene el código 201 (creado), lanza error
    if (response.statusCode != 201) {
      throw Exception('Error al agregar gasto');
    }
  }

  // 🔹 Eliminar un gasto por su ID
  static Future<void> deleteExpense(int id) async {
    // Se realiza una solicitud DELETE al endpoint /expenses/{id}
    final response = await http.delete(Uri.parse('$baseUrl/expenses/$id'));

    // Si la respuesta no es 200 (éxito), lanza una excepción
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar gasto');
    }
  }

  // 🔹 Obtener la lista de categorías únicas desde el backend
  static Future<List<String>> getCategories() async {
    // Llama al endpoint /categories
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    // Si la respuesta es exitosa
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body); // Decodifica el JSON
      return data.cast<String>(); // Convierte los elementos a tipo String
    } else {
      throw Exception('Error al obtener categorías');
    }
  }
  
  // 🔹 Actualizar un gasto
  static Future<void> updateExpense(int id, Map<String, dynamic> updatedData) async {
    final url = Uri.parse('$baseUrl/expenses/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedData),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar el gasto');
    }
  }

  
}
