import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart'; // Modelo que tiene id, titulo, categoria, monto, fecha, descripcion
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Expense> _expenses = [];

  double get totalThisMonth {
    return _expenses.fold(0, (sum, item) => sum + item.monto);
  }

  // --- Mostrar formulario para agregar gasto ---
  void _showAddExpenseForm() {
    final montoController = TextEditingController();
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    String selectedCategory = "Comida";
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tituloController,
                    decoration: InputDecoration(labelText: "Título"),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: montoController,
                    decoration: InputDecoration(labelText: "Cantidad (\$)"),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text("${selectedDate.toLocal()}".split(' ')[0]),
                      Spacer(),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setModalState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: Text("Seleccionar fecha"),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: ["Comida", "Transporte", "Entretenimiento", "Facturas", "Otros"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedCategory = value!;
                      });
                    },
                    decoration: InputDecoration(labelText: "Categoría"),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: descripcionController,
                    decoration: InputDecoration(labelText: "Descripción"),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (tituloController.text.isEmpty || montoController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ingrese título y monto')),
                        );
                        return;
                      }

                      // Crear objeto Expense para enviar al backend
                      final nuevoGasto = Expense(
                        id: 0, // el backend asigna el id
                        titulo: tituloController.text,
                        categoria: selectedCategory,
                        monto: double.tryParse(montoController.text) ?? 0,
                        fecha: selectedDate.toIso8601String().split('T').first,
                        descripcion: descripcionController.text,
                      );

                      try {
                        // Debug: mostrar JSON que se enviará
                        print('JSON que se enviará: ${nuevoGasto.toJson()}');

                        // Enviar al backend
                        await ApiService.addExpense(nuevoGasto);

                        // Agregar a la lista local para actualizar UI
                        setState(() {
                          _expenses.add(nuevoGasto);
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gasto agregado con éxito')),
                        );
                      } catch (e) {
                        print('Error al guardar gasto: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al guardar gasto: $e')),
                        );
                      }
                    },
                    child: Text("Guardar"),
                  ),
                  SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // --- Sumar totales por categoría ---
  Map<String, double> get categoryTotals {
    Map<String, double> data = {};
    for (var exp in _expenses) {
      data[exp.categoria] = (data[exp.categoria] ?? 0) + exp.monto;
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rastreador de gastos")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Este mes: \$${totalThisMonth.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showAddExpenseForm,
              child: Text("+ Agregar gasto"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: categoryTotals.isEmpty
                      ? Center(child: Text("Sin gastos todavía"))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final categories = categoryTotals.keys.toList();
                                    if (value.toInt() < categories.length) {
                                      return Text(categories[value.toInt()]);
                                    }
                                    return Text("");
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: categoryTotals.entries
                                .toList()
                                .asMap()
                                .entries
                                .map(
                                  (entry) => BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: entry.value.value,
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
