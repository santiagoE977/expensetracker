import 'dart:convert';
import 'package:http/http.dart' as http;

// 🔧 Cambia esta URL según tu entorno
// Si usas Android Emulator -> http://10.0.2.2:5000
// Si usas dispositivo físico -> tu IP local (ej: http://192.168.1.100:5000)
const String baseUrl = 'http://127.0.0.1:5000';

// ---------------------------------------------------------------------------
// 🔹 AUTENTICACIÓN
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> registerUser(String name, String email, String password) async {
  final url = Uri.parse('$baseUrl/register');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'name': name, 'email': email, 'password': password}),
  );

  return jsonDecode(response.body);
}

Future<Map<String, dynamic>> loginUser(String email, String password) async {
  final url = Uri.parse('$baseUrl/login');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  return jsonDecode(response.body);
}

// ---------------------------------------------------------------------------
// 🔹 GASTOS
// ---------------------------------------------------------------------------

Future<List<Map<String, dynamic>>> getExpenses(int userId, {String? category}) async {
  final queryParams = {
    'user_id': userId.toString(),
    if (category != null) 'category': category,
  };

  final url = Uri.parse('$baseUrl/expenses').replace(queryParameters: queryParams);
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    throw Exception('Error al obtener gastos');
  }
}

Future<Map<String, dynamic>> createExpense(Map<String, dynamic> expenseData) async {
  final url = Uri.parse('$baseUrl/expenses');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(expenseData),
  );

  if (response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Error al crear gasto');
  }
}

Future<Map<String, dynamic>> updateExpense(int expenseId, Map<String, dynamic> updatedData) async {
  final url = Uri.parse('$baseUrl/expenses/$expenseId');
  final response = await http.put(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(updatedData),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Error al actualizar gasto');
  }
}

Future<void> deleteExpense(int expenseId) async {
  final url = Uri.parse('$baseUrl/expenses/$expenseId');
  final response = await http.delete(url);

  if (response.statusCode != 200) {
    throw Exception('Error al eliminar gasto');
  }
}

// ---------------------------------------------------------------------------
// 🔹 CATEGORÍAS
// ---------------------------------------------------------------------------

Future<List<String>> getCategories(int userId) async {
  final url = Uri.parse('$baseUrl/categories?user_id=$userId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<String>();
  } else {
    throw Exception('Error al obtener categorías');
  }
}

// ---------------------------------------------------------------------------
// 🔹 REPORTE POR CATEGORÍA
// ---------------------------------------------------------------------------

Future<List<Map<String, dynamic>>> getReportByCategory(int userId) async {
  final url = Uri.parse('$baseUrl/report_by_category?user_id=$userId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => {
      "categoria": item["categoria"],
      "total": (item["total"] as num).toDouble(),
    }).toList();
  } else {
    throw Exception('Error al obtener el reporte por categoría');
  }
}