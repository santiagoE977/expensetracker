import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/expense.dart';
import 'add_expense_page.dart';

class HomePage extends StatefulWidget {
  final int userId; // 👈 Recibimos el ID del usuario logueado

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<dynamic>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    setState(() {
      _expensesFuture = ApiService().getExpenses();
    });
  }

  Future<void> _deleteExpense(int id) async {
    try {
      await ApiService.deleteExpense(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto eliminado')),
      );
      _loadExpenses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar gasto: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis gastos"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final expenses = snapshot.data ?? [];
          if (expenses.isEmpty) {
            return const Center(child: Text("No hay gastos registrados."));
          }
          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(expense['title'] ?? 'Sin título'),
                  subtitle: Text(
                    "${expense['description'] ?? ''}\nFecha: ${expense['date'] ?? ''}",
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "\$${expense['amount']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteExpense(expense['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 👇 Pasamos el userId al agregar gasto
          final bool? refresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpensePage(userId: widget.userId),
            ),
          );

          // 👇 Recargar lista si se agregó un gasto
          if (refresh == true) {
            _loadExpenses();
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}