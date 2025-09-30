import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import '../models/expense.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Expense> _expenses = [];

  double get totalThisMonth {
    return _expenses.fold(0, (sum, item) => sum + item.amount);
  }

  void _showAddExpenseForm() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
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
                    controller: amountController,
                    decoration: InputDecoration(labelText: "Cantidad (\$)"),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
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
                    items: ["Comida", "Transporte", "Entretenimento", "Facturas"]
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
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: "Descripción"),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (amountController.text.isNotEmpty) {
                        setState(() {
                          _expenses.add(Expense(
                            amount: double.tryParse(amountController.text) ?? 0,
                            category: selectedCategory,
                            description: descriptionController.text,
                            date: selectedDate,
                          ));
                        });
                        Navigator.pop(context);
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

  Map<String, double> get categoryTotals {
    Map<String, double> data = {};
    for (var exp in _expenses) {
      data[exp.category] = (data[exp.category] ?? 0) + exp.amount;
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
