import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expense> _expenses = [];
  bool _isLoading = true;
  final ApiService apiService = ApiService(); // ✅ Instancia de tu ApiService

  // --------------------------------------------------------------------
  // 🔹 Cargar los gastos desde la API
  // --------------------------------------------------------------------
  Future<void> fetchExpenses() async {
    try {
      final data = await apiService.getExpenses(); // Obtiene lista de Map
      // Convertimos cada elemento del JSON a un objeto Expense
      final List<Expense> loadedExpenses =
          data.map((json) => Expense.fromJson(json)).toList().cast<Expense>();

      setState(() {
        _expenses = loadedExpenses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar gastos: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchExpenses(); // Se ejecuta automáticamente al abrir
  }

  // --------------------------------------------------------------------
  // 🔹 Total de gastos del mes
  // --------------------------------------------------------------------
  double get totalThisMonth {
    return _expenses.fold(0, (sum, item) => sum + item.monto);
  }

  // --------------------------------------------------------------------
  // 🔹 Agrupar los gastos por categoría
  // --------------------------------------------------------------------
  Map<String, double> get categoryTotals {
    Map<String, double> data = {};
    for (var exp in _expenses) {
      data[exp.categoria] = (data[exp.categoria] ?? 0) + exp.monto;
    }
    return data;
  }

  // --------------------------------------------------------------------
  // 🔹 Formulario para agregar nuevo gasto
  // --------------------------------------------------------------------
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
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: [
                      "Comida",
                      "Transporte",
                      "Entretenimiento",
                      "Facturas",
                      "Otros"
                    ]
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedCategory = value!;
                      });
                    },
                    decoration: InputDecoration(labelText: "Categoría"),
                  ),
                  TextField(
                    controller: descripcionController,
                    decoration: InputDecoration(labelText: "Descripción"),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (tituloController.text.isEmpty ||
                          montoController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ingrese título y monto')),
                        );
                        return;
                      }

                      final nuevoGasto = Expense(
                        id: 0,
                        titulo: tituloController.text,
                        categoria: selectedCategory,
                        monto: double.tryParse(montoController.text) ?? 0,
                        fecha: selectedDate.toIso8601String().split('T').first,
                        descripcion: descripcionController.text,
                      );

                      try {
                        await ApiService.addExpense(nuevoGasto);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gasto agregado con éxito')),
                        );
                        // 🔁 Recarga la lista y el gráfico
                        await fetchExpenses();
                      } catch (e) {
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

  // --------------------------------------------------------------------
  // 🖼️ Interfaz principal
  // --------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rastreador de gastos")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta del total mensual
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Este mes: \$${totalThisMonth.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
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
                                          final categories =
                                              categoryTotals.keys.toList();
                                          if (value.toInt() <
                                              categories.length) {
                                            return Text(
                                                categories[value.toInt()]);
                                          }
                                          return Text("");
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: true),
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
