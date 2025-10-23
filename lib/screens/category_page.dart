import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoryPage extends StatefulWidget {
  final int userId; // 👈 Se recibe el ID del usuario logueado
  const CategoryPage({super.key, required this.userId});

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<String> _categories = [];
  Map<String, List<dynamic>> _expensesByCategory = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndExpenses();
  }

  // 🔹 Cargar categorías y sus respectivos gastos
  Future<void> _loadCategoriesAndExpenses() async {
    try {
      setState(() => _isLoading = true);
      final categories = await ApiService.getCategories();
      final Map<String, List<dynamic>> expensesMap = {};

      for (String category in categories) {
        final expenses = await ApiService().getExpenses(category: category);
        expensesMap[category] = expenses
            .where((e) => e['user_id'] == widget.userId)
            .toList(); // 🔸 Filtramos por usuario
      }

      setState(() {
        _categories = categories;
        _expensesByCategory = expensesMap;
      });
    } catch (e) {
      print("⚠️ Error al cargar categorías y gastos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar datos: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔹 Actualizar un gasto
  Future<void> _updateExpense(dynamic expense) async {
    final TextEditingController amountController =
        TextEditingController(text: expense['monto'].toString());
    final TextEditingController descController =
        TextEditingController(text: expense['descripcion'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Actualizar gasto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Monto"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Descripción"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedData = {
                'monto': double.tryParse(amountController.text) ?? 0.0,
                'descripcion': descController.text,
              };
              await ApiService.updateExpense(expense['id'], updatedData);
              Navigator.pop(context);
              await _loadCategoriesAndExpenses(); // 🔄 Recarga la lista
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Gasto actualizado")),
              );
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  // 🔹 Eliminar un gasto
  Future<void> _deleteExpense(int expenseId) async {
    await ApiService.deleteExpense(expenseId);
    await _loadCategoriesAndExpenses(); // 🔄 Recarga los datos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🗑️ Gasto eliminado")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Categorías")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(child: Text("No hay categorías registradas"))
              : RefreshIndicator(
                  onRefresh: _loadCategoriesAndExpenses,
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final expenses = _expensesByCategory[category] ?? [];

                      return ExpansionTile(
                        title: Text(category),
                        children: expenses.isEmpty
                            ? [
                                const ListTile(
                                  title: Text("No hay gastos en esta categoría"),
                                )
                              ]
                            : expenses.map((expense) {
                                return ListTile(
                                  title: Text(expense['descripcion'] ?? 'Sin descripción'),
                                  subtitle: Text("Monto: \$${expense['monto']}"),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.green),
                                        onPressed: () => _updateExpense(expense),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _deleteExpense(expense['id']),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                      );
                    },
                  ),
                ),
    );
  }
}