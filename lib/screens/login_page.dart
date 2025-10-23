import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart'; // 👈 Importamos para acceder a MainPage
import 'register_page.dart';

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
          // ✅ Si el login es exitoso, navegamos a la MainPage (con bottom bar)
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainPage()), // Cambio clave
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['message'] ?? "Credenciales incorrectas"),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al iniciar sesión: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Iniciar sesión")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 50),
              const Icon(Icons.lock, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),

              // Campo de correo
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Correo electrónico",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.isEmpty ? "Ingrese su correo" : null,
                onSaved: (v) => _email = v!.trim(),
              ),
              const SizedBox(height: 15),

              // Campo de contraseña
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) =>
                    v == null || v.isEmpty ? "Ingrese su contraseña" : null,
                onSaved: (v) => _password = v!,
              ),
              const SizedBox(height: 25),

              // Botón de inicio de sesión
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.login),
                          SizedBox(width: 8),
                          Text("Entrar"),
                        ],
                      ),
                    ),
              const SizedBox(height: 10),

              // Botón de registro
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterPage()),
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