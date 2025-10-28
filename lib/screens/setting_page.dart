import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajustes")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Perfil"),
            subtitle: Text("Administra tu información"),
            onTap: () {},
          ),
          Divider(),
          Divider(),
          ListTile(
            leading: Icon(Icons.info),
            title: Text("Acerca de"),
            subtitle: Text("Rastreador de gastos v0.9.5"),
          ),
        ],
      ),
    );
  }
}