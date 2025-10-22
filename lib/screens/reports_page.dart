import 'dart:convert'; // Permite decodificar JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart'; // Librería para gráficos

// Pantalla principal del reporte
class ReportsPage extends StatefulWidget {
  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool isLoading = true; // Indicador de carga
  Map<String, double> categoryTotals = {}; // Totales por categoría
  final String baseUrl = 'http://127.0.0.1:5000'; // Dirección del backend Flask local
  int touchedIndex = -1; // Índice de la sección tocada en el gráfico

  // Lista de colores para las secciones del gráfico
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
    fetchReportData(); // Llamamos a la función que obtiene los datos al iniciar
  }

  // Función para obtener los gastos desde el backend
  Future<void> fetchReportData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/expenses')); // Petición GET al backend
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body); // Decodifica el JSON recibido

        // Calcula el total de gastos por categoría
        final Map<String, double> totals = {};
        for (var expense in data) {
          final categoria = expense['categoria'] ?? 'Sin categoría'; // Si no hay categoría, usa un valor por defecto
          final monto = double.tryParse(expense['monto'].toString()) ?? 0;
          totals[categoria] = (totals[categoria] ?? 0) + monto; // Suma los montos de la misma categoría
        }

        // Actualiza el estado del widget con los nuevos datos
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

  // Genera las secciones del gráfico circular
  List<PieChartSectionData> getPieChartSections() {
    final totalAmount = categoryTotals.values.fold(0.0, (sum, val) => sum + val); // Suma total de gastos
    final List<PieChartSectionData> sections = [];
    int index = 0;

    // Recorre las categorías y genera una sección para cada una
    categoryTotals.forEach((category, amount) {
      final isTouched = index == touchedIndex; // Verifica si la sección fue tocada
      final double fontSize = isTouched ? 16 : 12; // Aumenta el texto si está seleccionada
      final double radius = isTouched ? 80 : 70; // Agranda el radio al tocar
      final percent = ((amount / totalAmount) * 100).toStringAsFixed(1); // Calcula el porcentaje

      // Crea la sección del gráfico
      sections.add(PieChartSectionData(
        value: amount,
        title: '$percent%\n$category', // Muestra porcentaje y nombre de categoría
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
          // Si está cargando, muestra un spinner
          ? const Center(child: CircularProgressIndicator())
          // Si no hay datos
          : categoryTotals.isEmpty
              ? const Center(child: Text("No hay datos para mostrar"))
              // Si hay datos, muestra el gráfico y la lista
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

                      // === Gráfico circular ===
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
                                sections: getPieChartSections(), // Secciones dinámicas
                                centerSpaceRadius: 50, // Espacio vacío en el centro
                                sectionsSpace: 4, // Separación entre secciones
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    // Detecta qué parte del gráfico fue tocada
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        touchedIndex = -1;
                                        return;
                                      }
                                      touchedIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                              ),
                              swapAnimationDuration: Duration(milliseconds: 500), // Animación suave
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // === Lista con detalles de las categorías ===
                      Expanded(
                        child: ListView.builder(
                          itemCount: categoryTotals.length,
                          itemBuilder: (context, index) {
                            String category = categoryTotals.keys.elementAt(index);
                            double amount = categoryTotals[category]!;
                            double percent = (amount /
                                    categoryTotals.values.fold(0.0, (sum, val) => sum + val)) *
                                100;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    sectionColors[index % sectionColors.length],
                              ),
                              title: Text(category),
                              trailing: Text(
                                "\$${amount.toStringAsFixed(2)} (${percent.toStringAsFixed(1)}%)",
                              ),
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