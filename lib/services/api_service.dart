import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000';

  // 🔹 Obtener todos los gastos
  Future<List<dynamic>> getExpenses({String? category}) async {
    String url = '$baseUrl/expenses';
    if (category != null) {
      url += '?category=$category';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener gastos: ${response.statusCode}');
    }
  }

  // 🔹 Agregar un nuevo gasto
  static Future<void> addExpense(Expense expense) async {
    final response = await http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(expense.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al agregar gasto');
    }
  }

  // 🔹 Eliminar un gasto
  static Future<void> deleteExpense(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/expenses/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar gasto');
    }
  }

  // 🔹 Obtener categorías
  static Future<List<String>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<String>();
    } else {
      throw Exception('Error al obtener categorías');
    }
  }

  // 🔹 Actualizar un gasto
  static Future<void> updateExpense(
    int id,
    Map<String, dynamic> updatedData,
  ) async {
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

  // 🔹 Registro de usuario
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        return {'status': 'success', 'data': jsonDecode(response.body)};
      } else {
        final decoded = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': decoded['message'] ?? 'Error al registrar usuario'
        };
      }
    } catch (e) {
      print('⚠️ Error de conexión en registro: $e');
      return {
        'status': 'error',
        'message': 'No se pudo conectar con el servidor',
      };
    }
  }

  // 🔹 Login de usuario
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'status': 'success', 'data': data};
      } else {
        final decoded = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': decoded['message'] ?? 'Credenciales incorrectas'
        };
      }
    } catch (e) {
      print('⚠️ Error de conexión en login: $e');
      return {
        'status': 'error',
        'message': 'No se pudo conectar con el servidor',
      };
    }
  }
}