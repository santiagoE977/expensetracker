import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/category_page.dart';
import 'screens/reports_page.dart';
import 'screens/setting_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rastreador de gastos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}

/// 🔹 MainPage recibe el userId y lo pasa a cada sección
class MainPage extends StatefulWidget {
  final int userId; // ✅ Agregado
  const MainPage({super.key, required this.userId});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // ✅ Se pasan las páginas con el userId del usuario autenticado
    _pages = [
      HomePage(userId: widget.userId),
      CategoryPage(userId: widget.userId),
      ReportsPage(userId: widget.userId),
      SettingPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categorías"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Informes"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Ajustes"),
        ],
      ),
    );
  }
}
