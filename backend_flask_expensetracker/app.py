from flask import Flask, request, jsonify, abort
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from datetime import datetime
import os

app = Flask(__name__)
CORS(app)

# SQLite DB in the same folder
db_path = os.path.join(os.path.dirname(__file__), 'database.db')
app.config['SQLALCHEMY_DATABASE_URI'] = f"sqlite:///{db_path}"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

class Expense(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    titulo = db.Column(db.String(200), nullable=False)
    categoria = db.Column(db.String(100), nullable=False)
    monto = db.Column(db.Float, nullable=False)
    fecha = db.Column(db.String(10), nullable=False)  # YYYY-MM-DD
    descripcion = db.Column(db.Text, nullable=True)

    def to_dict(self):
        return {
            "id": self.id,
            "titulo": self.titulo,
            "categoria": self.categoria,
            "monto": self.monto,
            "fecha": self.fecha,
            "descripcion": self.descripcion
        }

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    correo = db.Column(db.String(120), unique=True, nullable=False)
    contrasena = db.Column(db.String(120), nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "nombre": self.nombre,
            "correo": self.correo
        }

# --- CRUD endpoints ---

@app.route('/expenses', methods=['GET'])
def get_expenses():
    category = request.args.get('category')  # Obtener parámetro de query
    query = Expense.query
    if category:
        query = query.filter_by(categoria=category)
    expenses = query.order_by(Expense.fecha.desc()).all()
    return jsonify([e.to_dict() for e in expenses])

@app.route('/expenses/<int:expense_id>', methods=['GET'])
def get_expense(expense_id):
    e = Expense.query.get_or_404(expense_id)
    return jsonify(e.to_dict())

@app.route('/expenses', methods=['POST'])
def create_expense():
    data = request.get_json() or {}
    print("datos recibidos:", data)
    required = ['titulo', 'categoria', 'monto', 'fecha']
    for r in required:
        if r not in data:
            return jsonify({"error": f"Missing field: {r}"}), 400
    try:
        datetime.strptime(data['fecha'], '%Y-%m-%d')
    except Exception:
        return jsonify({"error": "fecha must be in YYYY-MM-DD format"}), 400

    e = Expense(
        titulo=data['titulo'],
        categoria=data['categoria'],
        monto=float(data['monto']),
        fecha=data['fecha'],
        descripcion=data.get('descripcion')
    )
    db.session.add(e)
    db.session.commit()
    return jsonify(e.to_dict()), 201

@app.route('/expenses/<int:expense_id>', methods=['PUT'])
def update_expense(expense_id):
    e = Expense.query.get_or_404(expense_id)
    data = request.get_json() or {}
    if 'titulo' in data: e.titulo = data['titulo']
    if 'categoria' in data: e.categoria = data['categoria']
    if 'monto' in data:
        try:
            e.monto = float(data['monto'])
        except:
            return jsonify({"error":"monto must be a number"}), 400
    if 'fecha' in data:
        try:
            datetime.strptime(data['fecha'], '%Y-%m-%d')
            e.fecha = data['fecha']
        except:
            return jsonify({"error":"fecha must be in YYYY-MM-DD format"}), 400
    if 'descripcion' in data:
        e.descripcion = data['descripcion']
    db.session.commit()
    return jsonify(e.to_dict())

@app.route('/expenses/<int:expense_id>', methods=['DELETE'])
def delete_expense(expense_id):
    e = Expense.query.get_or_404(expense_id)
    db.session.delete(e)
    db.session.commit()
    return jsonify({"status":"deleted"})

# --- New: get unique categories ---
@app.route('/categories', methods=['GET'])
def get_categories():
    categories = db.session.query(Expense.categoria).distinct().all()
    category_list = [c[0] for c in categories if c[0] is not None]
    return jsonify(category_list)

#--- user CRUD---

@app.route('/users', methods=['GET'])
def get_users():
    users = User.query.all()
    return jsonify([u.to_dict() for u in users])

@app.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    u = User.query.get_or_404(user_id)
    return jsonify(u.to_dict())

@app.route('/users', methods=['POST'])
def create_user():
    data = request.get_json() or {}
    required = ['nombre', 'correo', 'contrasena']
    for r in required:
        if r not in data:
            return jsonify({"error": f"Missing field: {r}"}), 400

    if User.query.filter_by(correo=data['correo']).first():
        return jsonify({"error": "El correo ya está registrado"}), 400

    u = User(
        nombre=data['nombre'],
        correo=data['correo'],
        contrasena=data['contrasena']
    )
    db.session.add(u)
    db.session.commit()
    return jsonify(u.to_dict()), 201

@app.route('/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    u = User.query.get_or_404(user_id)
    db.session.delete(u)
    db.session.commit()
    return jsonify({"status": "deleted"})

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    correo = data.get('correo')
    contrasena = data.get('contrasena')

    if not correo or not contrasena:
        return jsonify({"status": "error", "message": "Faltan campos"}), 400

    user = User.query.filter_by(correo=correo).first()
    if user and user.contrasena == contrasena:
        return jsonify({"status": "success", "message": f"Bienvenido, {user.nombre}"}), 200
    else:
        return jsonify({"status": "error", "message": "Credenciales incorrectas"}), 401

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json() or {}
    nombre = data.get('nombre')
    correo = data.get('correo')
    contrasena = data.get('contrasena')

    # Validación básica
    if not nombre or not correo or not contrasena:
        return jsonify({"status": "error", "message": "Faltan campos"}), 400

    # Verificar si el correo ya está registrado
    if User.query.filter_by(correo=correo).first():
        return jsonify({"status": "error", "message": "El correo ya está registrado"}), 409

    # Crear nuevo usuario
    new_user = User(nombre=nombre, correo=correo, contrasena=contrasena)
    db.session.add(new_user)
    db.session.commit()

    return jsonify({"status": "success", "message": "Usuario registrado correctamente"}), 201


if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000, debug=True)
