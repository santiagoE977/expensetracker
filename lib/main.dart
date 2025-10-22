import 'package:flutter/material.dart'; // Importamos las pantallas del proyecto
import 'screens/home_page.dart';
import 'screens/Category_page.dart';
import 'screens/reports_page.dart';
import 'screens/Setting_page.dart';

// Función principal: punto de entrada de la aplicación
void main() {
  runApp(ExpenseTrackerApp()); // Ejecuta la app principal
}

// Widget principal de la aplicación
class ExpenseTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rastreador de gastos', // Título general de la app
      debugShowCheckedModeBanner: false, // Oculta la etiqueta "debug" del emulador
      theme: ThemeData(
        primarySwatch: Colors.blue, // Paleta de color principal
        useMaterial3: true, // Activa el diseño Material 3 (más moderno)
      ),
      home: MainPage(), // Página principal con la barra de navegación inferior
    );
  }
}

// Widget que controla la navegación principal de la app
class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

// Estado de la página principal
class _MainPageState extends State<MainPage> {
  int _currentIndex = 0; // Índice actual de la pestaña seleccionada

  // Lista de pantallas que se mostrarán en cada pestaña
  final List<Widget> _pages = [
    HomePage(),      // Pantalla principal (resumen de gastos, gráfico, etc.)
    CategoryPage(),  // Pantalla de categorías y gastos por categoría
    ReportsPage(),   // Pantalla de reportes (gráfico circular)
    SettingPage(),   // Pantalla de ajustes o configuración
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Muestra la pantalla correspondiente al índice actual
      body: _pages[_currentIndex],

      // Barra de navegación inferior (BottomNavigationBar)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Índice seleccionado actualmente
        type: BottomNavigationBarType.fixed, // Mantiene todos los íconos visibles
        selectedItemColor: Colors.blue, // Color del ítem seleccionado
        unselectedItemColor: Colors.grey, // Color de los ítems no seleccionados

        // Evento cuando el usuario toca una pestaña
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Actualiza el índice seleccionado
          });
        },

        // Ítems que aparecen en la barra inferior
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: "Categorías",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Informes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Ajustes",
          ),
        ],
      ),
    );
  }
}