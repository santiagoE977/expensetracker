import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddExpensePage extends StatefulWidget {
  final int userId;
  final String? category; // Puede venir vacía o seleccionarse manualmente

  const AddExpensePage({
    super.key,
    required this.userId,
    this.category,
  });

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // 🔹 Categorías disponibles
  final List<String> _categorias = [
    'Comida',
    'Transporte',
    'Entretenimiento',
    'Facturas',
    'Otros',
  ];

  // 🔹 Categoría seleccionada (por defecto la recibida o la primera del listado)
  String? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();

    // ✅ Si viene una categoría y existe en la lista, la selecciona.
    // Si no, usa la primera ("Comida").
    if (widget.category != null && _categorias.contains(widget.category)) {
      _categoriaSeleccionada = widget.category;
    } else {
      _categoriaSeleccionada = _categorias.first;
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una categoría')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final expense = {
      "titulo": _tituloController.text.trim(),
      "categoria": _categoriaSeleccionada,
      "monto": double.tryParse(_montoController.text.trim()) ?? 0.0,
      "fecha": _selectedDate.toIso8601String().substring(0, 10),
      "descripcion": _descripcionController.text.trim(),
      "user_id": widget.userId,
    };

    try {
      await createExpense(expense);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto guardado correctamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar gasto: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Gasto'),
        backgroundColor: Colors.blue,
        elevation: 2,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese un título' : null,
              ),
              const SizedBox(height: 12),

              // 🔹 Dropdown de categorías
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                value: _categoriaSeleccionada,
                items: _categorias
                    .map((cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSeleccionada = value;
                  });
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese un monto' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // 🔹 Selector de fecha
              Row(
                children: [
                  const Text(
                    'Fecha:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Text(
                      '${_selectedDate.toLocal()}'.split(' ')[0],
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 🔹 Botón Guardar
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveExpense,
                icon: const Icon(Icons.save),
                label: Text(_isLoading ? 'Guardando...' : 'Guardar Gasto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}