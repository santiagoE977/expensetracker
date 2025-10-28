import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class ReportsPage extends StatefulWidget {
  final int userId;
  const ReportsPage({super.key, required this.userId});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late Future<List<Map<String, dynamic>>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = getReportByCategory(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte por Categoría'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('No hay gastos registrados.'));
          }

          // Calcular el total general
          final totalGeneral = data.fold<double>(
            0,
            (sum, item) => sum + (item['total'] as num).toDouble(),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Gráfica circular
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 50,
                      sections: data.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final porcentaje = ((item['total'] / totalGeneral) * 100)
                            .toStringAsFixed(1);
                        final colors = [
                          Colors.blue,
                          Colors.orange,
                          Colors.purple,
                          Colors.green,
                          Colors.amber,
                          Colors.cyan
                        ];
                        return PieChartSectionData(
                          color: colors[i % colors.length],
                          value: item['total'],
                          title: '${porcentaje}% ${item['categoria']}',
                          radius: 70,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Lista de categorías y totales
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Detalle por Categoría',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(item['categoria']),
                        trailing: Text(
                          '\$${item['total'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlueAccent,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}