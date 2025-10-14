import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  String _titulo = '';
  String _categoria = 'Comida';
  double _monto = 0.0;
  String _descripcion = '';
  DateTime _fecha = DateTime.now();

  final List<String> _categorias = [
    'Comida',
    'Transporte',
    'Entretenimiento',
    'Facturas',
    'Otros',
  ];

  void _guardarGasto() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final nuevoGasto = Expense(
        id: 0, // El backend asigna el id
        titulo: _titulo,
        categoria: _categoria,
        monto: _monto,
        fecha: _fecha.toIso8601String().split('T').first,
        descripcion: _descripcion,
      );
      print('JSON que se enviará: ${nuevoGasto.toJson()}');

      try {
        await ApiService.addExpense(nuevoGasto);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto agregado con éxito')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar gasto: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Gasto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese un título' : null,
                onSaved: (value) => _titulo = value!,
              ),
              DropdownButtonFormField<String>(
                value: _categoria,
                items: _categorias
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _categoria = val!),
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese el monto' : null,
                onSaved: (value) => _monto = double.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descripción'),
                onSaved: (value) => _descripcion = value ?? '',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarGasto,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
