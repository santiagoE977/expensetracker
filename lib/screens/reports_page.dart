import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reports")),
      body: Center(
        child: Text(
          "Reports (Pie chart and list will go here)",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
