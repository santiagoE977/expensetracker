import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Importa las funciones que conectan con la API

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

  // 🔹 Carga los gastos de una categoría (solo si no se han cargado antes)
  Future<void> _loadExpenses(String category) async {
    if (expensesByCategory.containsKey(category)) return;
    try {
      final expenses = await ApiService().getExpenses(category: category);
      setState(() {
        expensesByCategory[category] = expenses;
      });
    } catch (e) {
      print('Error al cargar gastos de $category: $e');
    }
  }

  // 🔹 Actualizar gasto
Future<void> _updateExpense(Map<String, dynamic> expense) async {
  final TextEditingController titleController =
      TextEditingController(text: expense['titulo']);
  final TextEditingController amountController =
      TextEditingController(text: expense['monto'].toString());
  final TextEditingController descriptionController =
      TextEditingController(text: expense['descripcion'] ?? '');

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Actualizar gasto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Título"),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Monto"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: descriptionController,
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
                "titulo": titleController.text,
                "monto": double.tryParse(amountController.text) ?? 0.0,
                "descripcion": descriptionController.text,
              };

              try {
                // 🔹 Actualiza el gasto en el backend
                await ApiService.updateExpense(expense['id'], updatedData);

                // 🔹 Recarga los gastos de la categoría actual
                final category = expense['categoria'];
                expensesByCategory.remove(category); // Limpia los datos viejos
                await _loadExpenses(category); // Vuelve a consultar la API

                Navigator.pop(context); // Cierra el diálogo

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gasto actualizado correctamente')),
                );

                // 🔹 Actualiza la interfaz
                setState(() {});
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al actualizar: $e')),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      );
    },
  );
}

  // 🔹 Eliminar gasto
  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Eliminar gasto"),
          content: const Text("¿Seguro que deseas eliminar este gasto?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await ApiService.deleteExpense(expense['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto eliminado con éxito')),
      );

      // Volver a cargar la lista de gastos de la categoría
      final category = expense['categoria'];
      expensesByCategory.remove(category);
      await _loadExpenses(category);
      setState(() {});
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
                          onExpansionChanged: (expanded) {
                            if (expanded) _loadExpenses(category);
                          },
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
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
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
                                              "Descripción: ${e['descripcion']}",
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                          ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => _updateExpense(e),
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 18,
                                                color: Color.fromARGB(255, 0, 155, 57),
                                              ),
                                              label: const Text(
                                                "Actualizar",
                                                style: TextStyle(
                                                    color: Color.fromARGB(255, 0, 155, 57)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton.icon(
                                              onPressed: () => _deleteExpense(e),
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 18,
                                                color: Colors.red,
                                              ),
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