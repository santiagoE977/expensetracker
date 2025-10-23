import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/Category_page.dart';
import 'screens/reports_page.dart';
import 'screens/Setting_page.dart';
import 'screens/login_page.dart'; // 👈 Importamos la pantalla de login

// Función principal: punto de entrada de la aplicación
void main() {
  runApp(const ExpenseTrackerApp()); // Ejecuta la app principal
}

// Widget principal de la aplicación
class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rastreador de gastos', // Título general de la app
      debugShowCheckedModeBanner: false, // Oculta la etiqueta "debug" del emulador
      theme: ThemeData(
        primarySwatch: Colors.blue, // Paleta de color principal
        useMaterial3: true, // Activa el diseño Material 3 (más moderno)
      ),
      // 👇 Empieza en la pantalla de Login
      home: const LoginPage(),
    );
  }
}

// Widget que controla la navegación principal de la app (después de iniciar sesión)
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

// Estado de la página principal
class _MainPageState extends State<MainPage> {
  int _currentIndex = 0; // Índice actual de la pestaña seleccionada

  // Lista de pantallas que se mostrarán en cada pestaña
  final List<Widget> _pages =[
    HomePage(),      // Pantalla principal (resumen de gastos, gráfico, etc.)
    CategoryPage(),  // Pantalla de categorías y gastos por categoría
    ReportsPage(),   // Pantalla de reportes (gráfico circular)
    SettingPage(),   // Pantalla de ajustes o configuración
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Muestra la pantalla seleccionada

      // Barra de navegación inferior (BottomNavigationBar)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
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