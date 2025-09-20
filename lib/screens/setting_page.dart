import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Profile"),
            subtitle: Text("Manage your info"),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.refresh),
            title: Text("Reset Data"),
            subtitle: Text("Clear all expenses"),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info),
            title: Text("About"),
            subtitle: Text("Expense Tracker v1.0"),
          ),
        ],
      ),
    );
  }
}
