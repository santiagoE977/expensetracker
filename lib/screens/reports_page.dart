import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class ReportsPage extends StatefulWidget {
  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool isLoading = true;
  Map<String, double> categoryTotals = {};
  final String baseUrl = 'http://127.0.0.1:5000';
  int touchedIndex = -1;

  final List<Color> sectionColors = [
    Colors.blueAccent,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.cyan,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    fetchReportData();
  }

  Future<void> fetchReportData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/expenses'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final Map<String, double> totals = {};
        for (var expense in data) {
          final categoria = expense['categoria'] ?? 'Sin categoría';
          final monto = double.tryParse(expense['monto'].toString()) ?? 0;
          totals[categoria] = (totals[categoria] ?? 0) + monto;
        }

        setState(() {
          categoryTotals = totals;
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener datos del reporte');
      }
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  List<PieChartSectionData> getPieChartSections() {
    final totalAmount = categoryTotals.values.fold(0.0, (sum, val) => sum + val);
    final List<PieChartSectionData> sections = [];
    int index = 0;

    categoryTotals.forEach((category, amount) {
      final isTouched = index == touchedIndex;
      final double fontSize = isTouched ? 16 : 12;
      final double radius = isTouched ? 80 : 70;
      final percent = ((amount / totalAmount) * 100).toStringAsFixed(1);

      sections.add(PieChartSectionData(
        value: amount,
        title: '$percent%\n$category',
        color: sectionColors[index % sectionColors.length],
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
      index++;
    });

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categoryTotals.isEmpty
              ? const Center(child: Text("No hay datos para mostrar"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Distribución de gastos por categoría",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: PieChart(
                              PieChartData(
                                sections: getPieChartSections(),
                                centerSpaceRadius: 50,
                                sectionsSpace: 4,
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                        touchedIndex = -1;
                                        return;
                                      }
                                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                              ),
                              swapAnimationDuration: Duration(milliseconds: 500), // animación suave
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: categoryTotals.length,
                          itemBuilder: (context, index) {
                            String category = categoryTotals.keys.elementAt(index);
                            double amount = categoryTotals[category]!;
                            double percent = (amount / categoryTotals.values.fold(0.0, (sum, val) => sum + val)) * 100;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: sectionColors[index % sectionColors.length],
                              ),
                              title: Text(category),
                              trailing: Text("\$${amount.toStringAsFixed(2)} (${percent.toStringAsFixed(1)}%)"),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
