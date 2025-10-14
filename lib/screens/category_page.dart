import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoryPage extends StatefulWidget {
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<String> categories = [];
  Map<String, List<dynamic>> expensesByCategory = {};
  bool isLoading = true;

  final List<Color> categoryColors = [
    Colors.blueAccent,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.teal,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await ApiService.getCategories();
      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error al cargar categorías: $e');
    }
  }

  Future<void> _loadExpenses(String category) async {
    try {
      final expenses = await ApiService().getExpenses(category: category);
      setState(() {
        expensesByCategory[category] = expenses;
      });
    } catch (e) {
      print('Error al cargar gastos de $category: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Categorías",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 39, 97),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
              ? const Center(child: Text("No hay categorías registradas"))
              : ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final expenses = expensesByCategory[category] ?? [];
                    final color = categoryColors[index % categoryColors.length];

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.label, color: Colors.white),
                          ),
                          title: Text(
                            category,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                            ),
                          ),
                          
                          children: expenses.isEmpty
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: TextButton.icon(
                                      onPressed: () => _loadExpenses(category),
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text("Cargar gastos"),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blueAccent,
                                        textStyle: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ),
                                ]
                              : expenses.asMap().entries.map((entry) {
                                  final e = entry.value;
                                  final monto = e['monto'] ?? 0.0;

                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    color: entry.key % 2 == 0 ? Colors.grey[50] : Colors.white,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e['titulo'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Fecha: ${e['fecha']}",
                                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Monto: \$${monto.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500, fontSize: 13),
                                        ),
                                        if (e['descripcion'] != null && e['descripcion'].isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              "Descripcion: ${e['descripcion']}",
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                          ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () {
                                                // Lógica para actualizar
                                                //_updateExpense(e);
                                              },
                                              icon: const Icon(Icons.edit, size: 18, color: Color.fromARGB(255, 0, 155, 57)),
                                              label: const Text(
                                                "Actualizar",
                                                style: TextStyle(color: Color.fromARGB(255, 0, 155, 57)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton.icon(
                                              onPressed: () {
                                                // Lógica para eliminar
                                                //_deleteExpense(e);
                                              },
                                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                              label: const Text(
                                                "Eliminar",
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),

                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

