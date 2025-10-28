import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'category_page.dart';
import 'reports_page.dart';
import 'add_expense_page.dart';

class HomePage extends StatefulWidget {
  final int userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, double> _categoryTotals = {};

  @override
  void initState() {
    super.initState();
    _loadCategoryTotals();
  }

  Future<void> _loadCategoryTotals() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await getExpenses(widget.userId);
      final Map<String, double> totals = {};

      for (var e in expenses) {
        final categoria = e['categoria'] ?? 'Otros';
        final monto = (e['monto'] as num?)?.toDouble() ?? 0.0;
        totals[categoria] = (totals[categoria] ?? 0) + monto;
      }

      setState(() {
        _categoryTotals = totals;
      });
    } catch (e) {
      debugPrint('Error al cargar totales: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<BarChartGroupData> _generateBarGroups() {
    final keys = _categoryTotals.keys.toList();
    final values = _categoryTotals.values.toList();

    return List.generate(keys.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: values[i],
            color: Colors.blue,
            width: 22,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  double _calculateInterval() {
    if (_categoryTotals.isEmpty) return 10;
    final maxValue = _categoryTotals.values.reduce((a, b) => a > b ? a : b);
    return maxValue <= 100 ? 20 : maxValue / 5;
  }

  Widget _buildBarChart() {
    if (_categoryTotals.isEmpty) {
      return const Center(
        child: Text(
          'No hay gastos registrados aún',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final categories = _categoryTotals.keys.toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _categoryTotals.values.reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.blue,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
               final category = categories[group.x.toInt()];
                final value = rod.toY.toStringAsFixed(2);
               return BarTooltipItem(
                  '$category\n\$ $value',
                  const TextStyle(color: Colors.white, fontSize: 14),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: _calculateInterval(),
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final category = categories[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      category,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
          barGroups: _generateBarGroups(),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadCategoryTotals,
      child: ListView(
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Resumen de Gastos por Categoría',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 300, child: _buildBarChart()),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Agregar nuevo gasto',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white
                ),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddExpensePage(userId: widget.userId),
                  ),
                );
                _loadCategoryTotals();
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeContent(),
      CategoryPage(userId: widget.userId),
      ReportsPage(userId: widget.userId),
      const Center(child: Text('Ajustes próximamente...')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreador de Gastos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _loadCategoryTotals,
          ),
        ],
      ),
      backgroundColor:Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.category), label: 'Categorías'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Informes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}