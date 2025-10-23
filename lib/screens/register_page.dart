import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _isLoading = true);

      try {
        final response = await ApiService.register(_name, _email, _password);

        if (response['status'] == 'success') {
          if (!mounted) return;

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("✅ Registro exitoso")));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? "Error al registrarse"),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("⚠️ Error al registrarse: $e")));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 50),
              const Icon(Icons.person_add, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),

              // 🔹 Nombre
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Nombre completo",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Ingrese su nombre" : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              const SizedBox(height: 15),

              // 🔹 Correo
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

              // 🔹 Contraseña
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) =>
                    v == null || v.isEmpty ? "Ingrese su contraseña" : null,
                onSaved: (v) => _password = v!.trim(),
              ),
              const SizedBox(height: 25),

              // 🔹 Botón de registro
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _register,
                      icon: const Icon(Icons.app_registration),
                      label: const Text("Registrarse"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
              const SizedBox(height: 10),

              // 🔹 Link para iniciar sesión
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text("¿Ya tienes cuenta? Inicia sesión"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}