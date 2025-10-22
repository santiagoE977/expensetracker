import 'package:flutter/material.dart'; // Librería principal para construir interfaces en Flutter
import '../models/expense.dart'; // Importa el modelo Expense (estructura de datos del gasto)
import '../services/api_service.dart'; // Importa el servicio para comunicarse con la API (guardar gasto)

// Página para agregar un nuevo gasto
class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});
  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

// Estado de la página (donde se maneja la lógica y los datos)
class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>(); // Llave para validar y guardar el formulario
  // Variables para almacenar los datos del formulario
  String _titulo = '';
  String _categoria = 'Comida';
  double _monto = 0.0;
  String _descripcion = '';
  DateTime _fecha = DateTime.now(); // Fecha actual por defecto

  // Lista de categorías disponibles
  final List<String> _categorias = [
    'Comida',
    'Transporte',
    'Entretenimiento',
    'Facturas',
    'Otros',
  ];

  // Función que guarda el gasto (envía los datos al backend)
  void _guardarGasto() async {
    // Primero valida que todos los campos requeridos estén correctos
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Guarda los valores ingresados en las variables

      // Crea un objeto Expense con los datos del formulario
      final nuevoGasto = Expense(
        id: 0, // El backend se encarga de generar el ID real
        titulo: _titulo,
        categoria: _categoria,
        monto: _monto,
        fecha: _fecha.toIso8601String().split('T').first, // Convierte la fecha a formato "YYYY-MM-DD"
        descripcion: _descripcion,
      );

      // Muestra en consola el JSON que se va a enviar (para depuración)
      print('JSON que se enviará: ${nuevoGasto.toJson()}');

      try {
        // Llama al servicio que guarda el gasto mediante la API
        await ApiService.addExpense(nuevoGasto);

        // Muestra un mensaje de éxito al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto agregado con éxito')),
        );

        // Regresa a la pantalla anterior e indica que se agregó un gasto nuevo
        Navigator.pop(context, true);
      } catch (e) {
        // Si hay un error, muestra un mensaje con la causa
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar gasto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estructura visual de la página
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Gasto')), // Barra superior con título
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Espaciado interno general
        child: Form(
          key: _formKey, // Asocia el formulario con la llave para validación
          child: ListView( // Permite desplazamiento si el contenido es largo
            children: [
              // Campo de texto: Título del gasto
              TextFormField(
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese un título' : null, // Valida que no esté vacío
                onSaved: (value) => _titulo = value!, // Guarda el valor ingresado
              ),

              // Selector de categoría (menú desplegable)
              DropdownButtonFormField<String>(
                value: _categoria, // Valor inicial
                items: _categorias
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat), // Muestra el texto de cada categoría
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _categoria = val!), // Actualiza el valor seleccionado
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),

              // Campo de texto numérico para el monto
              TextFormField(
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number, // Teclado numérico
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese el monto' : null, // Valida que no esté vacío
                onSaved: (value) => _monto = double.parse(value!), // Convierte el valor a double
              ),

              // Campo opcional para descripción
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descripción'),
                onSaved: (value) => _descripcion = value ?? '', // Guarda texto o vacío si no hay nada
              ),

              const SizedBox(height: 20), // Espacio antes del botón

              // Botón para guardar los datos
              ElevatedButton(
                onPressed: _guardarGasto, // Llama a la función de guardado
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}