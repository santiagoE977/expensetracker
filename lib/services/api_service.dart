import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense.dart';



class ApiService {
static const String baseUrl = 'http://127.0.0.1:5000';



// Obtener todos los gastos o por categoría
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

  // Eliminar gasto
  static Future<void> deleteExpense(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/expenses/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar gasto');
    }
  }
  // Obtener categorías únicas
  static Future<List<String>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<String>();
    } else {
      throw Exception('Error al obtener categorías');
    }
  }

}

