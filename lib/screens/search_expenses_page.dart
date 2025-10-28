import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class SearchExpensesPage extends StatefulWidget {
  final int userId;
  const SearchExpensesPage({super.key, required this.userId});

  @override
  State<SearchExpensesPage> createState() => _SearchExpensesPageState();
}

class _SearchExpensesPageState extends State<SearchExpensesPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _expenses = [];
  List<String> _allCategories = [];
  List<String> _selectedCategories = [];
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await getCategories(widget.userId);
      setState(() => _allCategories = categories);
    } catch (e) {
      debugPrint('Error al cargar categorías: $e');
    }
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final searchText = _searchController.text.trim();

      final expenses = await getExpenses(
        widget.userId,
        search: searchText.isEmpty ? null : searchText,
        dateFrom: _selectedDateRange?.start.toIso8601String().split('T')[0],
        dateTo: _selectedDateRange?.end.toIso8601String().split('T')[0],
        categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
      );

      setState(() => _expenses = expenses);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al buscar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _search();
    }
  }

  Future<void> _selectCategories() async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        final tempSelected = List<String>.from(_selectedCategories);
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Filtrar por categorías'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _allCategories.map((category) {
                    return CheckboxListTile(
                      title: Text(category),
                      value: tempSelected.contains(category),
                      onChanged: (checked) {
                        setStateDialog(() {
                          if (checked == true) {
                            tempSelected.add(category);
                          } else {
                            tempSelected.remove(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, tempSelected),
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected != null) {
      setState(() => _selectedCategories = selected);
      _search();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedDateRange = null;
      _selectedCategories.clear();
      _expenses.clear();
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar gastos'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por título o descripción',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _search();
                      },
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range, size: 18),
                        label: Text(
                          _selectedDateRange == null
                              ? 'Rango de fechas'
                              : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectCategories,
                        icon: const Icon(Icons.filter_list, size: 18),
                        label: Text(
                          _selectedCategories.isEmpty
                              ? 'Categorías'
                              : '${_selectedCategories.length} seleccionadas',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Limpiar filtros'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _search,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Buscar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _expenses.isEmpty && _hasSearched
                ? const Center(
                    child: Text(
                      'No se encontraron gastos',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : _expenses.isEmpty
                ? const Center(
                    child: Text(
                      'Usa los filtros para buscar gastos',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final expense = _expenses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              '\$',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            expense['titulo'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${expense['categoria']} • ${expense['fecha']}',
                          ),
                          trailing: Text(
                            '\$${(expense['monto'] as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
