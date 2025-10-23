class User {
  final int? id;
  final String nombre;
  final String correo;
  final String contrasena;

  User({
    this.id,
    required this.nombre,
    required this.correo,
    required this.contrasena,
  });

  // Convierte el objeto a JSON
  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
      };

  // Crea un objeto User desde un JSON
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        nombre: json['nombre'],
        correo: json['correo'],
        contrasena: json['contrasena'] ?? '',
      );
}