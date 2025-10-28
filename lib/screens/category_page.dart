import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoryPage extends StatefulWidget {
  final int userId;
  const CategoryPage({super.key, required this.userId});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _expenses = [];
  Map<String, List<Map<String, dynamic>>> _groupedExpenses = {};

  final List<String> _categorias = [
    'Comida',
    'Transporte',
    'Entretenimiento',
    'Facturas',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final data = await getExpenses(widget.userId);
      _expenses = data;
      _groupByCategory();
    } catch (e) {
      debugPrint("Error al cargar gastos: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _groupByCategory() {
    _groupedExpenses.clear();
    for (var e in _expenses) {
      final categoria = e['categoria'] ?? 'Sin categoría';
      if (!_groupedExpenses.containsKey(categoria)) {
        _groupedExpenses[categoria] = [];
      }
      _groupedExpenses[categoria]!.add(e);
    }
  }

  Future<void> _deleteExpense(int expenseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: const Text('¿Seguro que deseas eliminar este gasto?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await deleteExpense(expenseId);
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
  }

  Future<void> _editExpenseDialog(Map<String, dynamic> expense) async {
    final tituloController = TextEditingController(text: expense['titulo']);
    final montoController =
        TextEditingController(text: expense['monto'].toString());
    final descripcionController =
        TextEditingController(text: expense['descripcion'] ?? '');
    DateTime selectedDate = DateTime.tryParse(expense['fecha']) ?? DateTime.now();
    String categoriaSeleccionada = expense['categoria'] ?? _categorias.first;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Gasto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                TextField(
                  controller: montoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto'),
                ),
                DropdownButtonFormField<String>(
                  value: categoriaSeleccionada,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: _categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => categoriaSeleccionada = val!,
                ),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Fecha: '),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                        }
                      },
                      child: Text(
                        '${selectedDate.toLocal()}'.split(' ')[0],
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                final updated = {
                  'titulo': tituloController.text.trim(),
                  'categoria': categoriaSeleccionada,
                  'monto': double.tryParse(montoController.text.trim()) ?? 0.0,
                  'fecha': selectedDate.toIso8601String().split('T')[0],
                  'descripcion': descripcionController.text.trim(),
                };

                try {
                  await updateExpense(expense['id'], updated);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gasto actualizado')),
                    );
                    _loadExpenses();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar: $e')),
                  );
                }
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard(String category, List<Map<String, dynamic>> items) {
    double total = items.fold(
        0.0, (sum, e) => sum + (e['monto'] as num?)!.toDouble());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ExpansionTile(
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          'Total: \$${total.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.grey),
        ),
        children: items.map((e) {
          return ListTile(
            title: Text(e['titulo']),
            subtitle: Text('${e['fecha']} - \$${e['monto'].toStringAsFixed(2)}'),
            trailing: Wrap(
              spacing: 10,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.green),
                  tooltip: 'Editar gasto',
                  onPressed: () => _editExpenseDialog(e),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Eliminar gasto',
                  onPressed: () => _deleteExpense(e['id']),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos por Categoría'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedExpenses.isEmpty
              ? const Center(child: Text('No hay gastos registrados'))
              : RefreshIndicator(
                  onRefresh: _loadExpenses,
                  child: ListView(
                    children: _groupedExpenses.entries
                        .map((entry) =>
                            _buildCategoryCard(entry.key, entry.value))
                        .toList(),
                  ),
                ),
    );
  }
}
