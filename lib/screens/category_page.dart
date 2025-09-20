import 'package:flutter/material.dart';

class CategoryPage extends StatelessWidget {
  final List<String> categories = ["Comida", "Transporte", "Entretenimento", "Facturas"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Categories")),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.label),
            title: Text(categories[index]),
          );
        },
      ),
    );
  }
}

