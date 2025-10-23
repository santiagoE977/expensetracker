// Importa librerías necesarias para hacer peticiones HTTP y manejar JSON
import 'dart:convert'; // Permite codificar y decodificar JSON
import 'package:http/http.dart' as http; // Librería para realizar solicitudes HTTP
import '../models/expense.dart'; // Modelo de gastos
import '../models/user.dart'; // Modelo de usuario (debes crearlo en models/user.dart)

// Clase que centraliza todas las operaciones con la API (gastos y usuarios)
class ApiService {
  // Dirección base del backend (puedes cambiarla según tu servidor o IP local)
  static const String baseUrl = 'http://127.0.0.1:5000';

  // ============================================================
  // 🔹 SECCIÓN GASTOS
  // ============================================================

  // Obtener todos los gastos (o filtrar por categoría)
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

  // Agregar un nuevo gasto
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

  // Eliminar un gasto por su ID
  static Future<void> deleteExpense(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/expenses/$id'));

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar gasto');
    }
  }

  // Obtener la lista de categorías únicas
  static Future<List<String>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<String>();
    } else {
      throw Exception('Error al obtener categorías');
    }
  }

  // Actualizar un gasto
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

  // ============================================================
  // 🔹 SECCIÓN USUARIOS
  // ============================================================

  // Obtener todos los usuarios
  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener usuarios: ${response.statusCode}');
    }
  }

  // Obtener un usuario por su ID
  static Future<Map<String, dynamic>> getUserById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$id'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener usuario: ${response.statusCode}');
    }
  }

  // Crear un nuevo usuario
  static Future<void> addUser(User user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(user.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al crear usuario: ${response.statusCode}');
    }
  }

  // Actualizar usuario
  static Future<void> updateUser(int id, Map<String, dynamic> updatedData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updatedData),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar usuario: ${response.statusCode}');
    }
  }

  // Eliminar usuario por ID
  static Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/users/$id'));

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar usuario: ${response.statusCode}');
    }
  }
  
  // 🔹 Iniciar sesión (login)
  static Future<Map<String, dynamic>?> login(String correo, String contrasena) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'correo': correo,
        'contrasena': contrasena,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body); // Ej: {"status":"success", "message":"Bienvenido"}
    } else if (response.statusCode == 401) {
      return {"status": "error", "message": "Credenciales incorrectas"};
    } else {
      throw Exception('Error al iniciar sesión: ${response.statusCode}');
    }
  }
  
  // 🔹 Registrar nuevo usuario
  static Future<Map<String, dynamic>> register(String nombre, String correo, String contrasena) async {
    final url = Uri.parse('$baseUrl/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body); // Ejemplo: {"status":"success", "message":"Usuario creado"}
    } else {
      // Si el backend devuelve un error (400, 409, etc.)
      return json.decode(response.body);
    }
  }
}