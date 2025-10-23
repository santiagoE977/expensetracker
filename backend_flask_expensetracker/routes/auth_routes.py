# routes/auth_routes.py
from flask import Blueprint, request, jsonify
from models import db, User
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy import select
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from schemas import UserRegisterSchema, UserLoginSchema
from datetime import timedelta

# ======================================================
# 🔹 Blueprint de autenticación
# ======================================================
auth_bp = Blueprint("auth", __name__)
register_schema = UserRegisterSchema()
login_schema = UserLoginSchema()


# ======================================================
# 🔹 Registro de usuario
# ======================================================
@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json() or {}
    errors = register_schema.validate(data)
    if errors:
        return jsonify({"status": "error", "errors": errors}), 400

    nombre = data["nombre"].strip()
    correo = data["correo"].strip().lower()
    password = data["password"]

    # Comprobar si el correo ya existe
    existing = db.session.scalar(select(User).filter_by(correo=correo))
    if existing:
        return jsonify({"status": "error", "message": "Correo ya registrado"}), 400

    # Crear nuevo usuario con contraseña cifrada
    user = User(
        nombre=nombre,
        correo=correo,
        password_hash=generate_password_hash(password)
    )

    db.session.add(user)
    db.session.commit()

    return jsonify({
        "status": "success",
        "message": "Usuario registrado correctamente",
        "user": user.to_dict()
    }), 201


# ======================================================
# 🔹 Inicio de sesión (login)
# ======================================================
@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json() or {}
    errors = login_schema.validate(data)
    if errors:
        return jsonify({"status": "error", "errors": errors}), 400

    correo = data["correo"].strip().lower()
    password = data["password"]

    user = db.session.scalar(select(User).filter_by(correo=correo))
    if not user or not check_password_hash(user.password_hash, password):
        return jsonify({"status": "error", "message": "Credenciales incorrectas"}), 401

    # Crear token JWT con duración configurable
    access_token = create_access_token(
        identity=user.id,
        expires_delta=timedelta(hours=12)
    )

    return jsonify({
        "status": "success",
        "message": "Inicio de sesión exitoso",
        "access_token": access_token,
        "user": user.to_dict()
    }), 200


# ======================================================
# 🔹 Ruta protegida opcional (verificar token)
# ======================================================
@auth_bp.route("/check-token", methods=["GET"])
@jwt_required()
def check_token():
    """
    Endpoint opcional: usado por Flutter para verificar
    si el token JWT sigue siendo válido.
    """
    user_id = get_jwt_identity()
    user = db.session.get(User, user_id)
    if not user:
        return jsonify({"status": "error", "message": "Usuario no encontrado"}), 404

    return jsonify({
        "status": "success",
        "message": "Token válido",
        "user": user.to_dict()
    }), 200