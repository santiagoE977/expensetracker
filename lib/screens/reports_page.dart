import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Informes")),
      body: Center(
        child: Text(
          "Informes (el gráfico circular y la lista irán aquí)",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
