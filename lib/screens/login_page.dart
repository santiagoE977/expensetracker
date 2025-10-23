import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_page.dart';
import '../main.dart'; // Para poder navegar hacia MainPage

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final response = await ApiService.login(_email, _password);

       if (response != null && response['status'] == 'success') {
          final userData = response['data']['user']; // 👈 CORREGIDO

          if (userData == null || userData['id'] == null) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Error: no se recibió el ID del usuario'),
              ),
            );
           setState(() => _isLoading = false);
           return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
             builder: (_) => MainPage(userId: userData['id']),
           ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Error al iniciar sesión: $e")),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Iniciar Sesión")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 50),
              const Icon(Icons.lock_outline, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),

              // Correo electrónico
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Correo electrónico",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? "Ingrese su correo" : null,
                onSaved: (v) => _email = v!.trim(),
              ),
              const SizedBox(height: 15),

              // Contraseña
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? "Ingrese su contraseña" : null,
                onSaved: (v) => _password = v!.trim(),
              ),
              const SizedBox(height: 25),

              // Botón de login
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _login,
                      icon: const Icon(Icons.login),
                      label: const Text("Iniciar Sesión"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
              const SizedBox(height: 10),

              // Ir a registro
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text("¿No tienes cuenta? Regístrate aquí"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}