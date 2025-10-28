from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from datetime import datetime
import os
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy.exc import IntegrityError

app = Flask(__name__)
CORS(app)

db_path = os.path.join(os.path.dirname(__file__), 'database.db')
app.config['SQLALCHEMY_DATABASE_URI'] = f"sqlite:///{db_path}"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# =====================================================
# MODELOS
# =====================================================

class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    correo = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(200), nullable=False)
    expenses = db.relationship('Expense', backref='user', lazy=True, cascade='all, delete-orphan')
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class Expense(db.Model):
    __tablename__ = 'expenses'
    id = db.Column(db.Integer, primary_key=True)
    titulo = db.Column(db.String(200), nullable=False)
    categoria = db.Column(db.String(100), nullable=False, index=True)
    monto = db.Column(db.Float, nullable=False)
    fecha = db.Column(db.String(10), nullable=False, index=True)  # YYYY-MM-DD
    descripcion = db.Column(db.Text, nullable=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    
    def to_dict(self):
        return {
            "id": self.id,
            "titulo": self.titulo,
            "categoria": self.categoria,
            "monto": self.monto,
            "fecha": self.fecha,
            "descripcion": self.descripcion,
            "user_id": self.user_id
        }

# =====================================================
# AUTENTICACIÓN
# =====================================================

@app.route('/register', methods=['POST'])
def register_user():
    if not request.is_json:
        return jsonify({'status': 'error', 'message': 'Content-Type debe ser application/json'}), 400
    
    data = request.get_json(silent=True) or {}
    nombre = data.get('name')
    correo = data.get('email')
    password = data.get('password')
    
    if not nombre or not correo or not password:
        return jsonify({'status': 'error', 'message': 'Campos incompletos'}), 400
    
    # Validación básica de email
    if '@' not in correo or '.' not in correo:
        return jsonify({'status': 'error', 'message': 'Email inválido'}), 400
    
    if User.query.filter_by(correo=correo).first():
        return jsonify({'status': 'error', 'message': 'Correo ya registrado'}), 400
    
    user = User(nombre=nombre, correo=correo)
    user.set_password(password)
    
    try:
        db.session.add(user)
        db.session.commit()
        return jsonify({'status': 'success', 'message': 'Usuario registrado correctamente'}), 201
    except IntegrityError:
        db.session.rollback()
        return jsonify({'status': 'error', 'message': 'Error al registrar usuario'}), 500

@app.route('/login', methods=['POST'])
def login_user():
    if not request.is_json:
        return jsonify({'status': 'error', 'message': 'Content-Type debe ser application/json'}), 400
    
    data = request.get_json(silent=True) or {}
    correo = data.get('email')
    password = data.get('password')
    
    if not correo or not password:
        return jsonify({'status': 'error', 'message': 'Email y contraseña requeridos'}), 400
    
    user = User.query.filter_by(correo=correo).first()
    
    if user and user.check_password(password):
        return jsonify({
            'status': 'success',
            'message': 'Inicio de sesión exitoso',
            'user': {
                'id': user.id,
                'nombre': user.nombre,
                'correo': user.correo
            }
        }), 200
    
    return jsonify({'status': 'error', 'message': 'Correo o contraseña incorrectos'}), 401

# =====================================================
# GASTOS (EXPENSES)
# =====================================================

@app.route('/expenses', methods=['GET'])
def get_expenses():
    user_id = request.args.get('user_id', type=int)
    if not user_id:
        return jsonify({"error": "user_id requerido"}), 400
    
    # Parámetros de búsqueda y filtros
    search = request.args.get('search', '').strip()
    date_from = request.args.get('date_from')
    date_to = request.args.get('date_to')
    categories = request.args.getlist('categories[]')
    category = request.args.get('category')
    
    # Query base
    query = Expense.query.filter(Expense.user_id == user_id)
    
    # Filtro de búsqueda por título o descripción
    if search:
        search_pattern = f'%{search}%'
        query = query.filter(
            db.or_(
                Expense.titulo.ilike(search_pattern),
                Expense.descripcion.ilike(search_pattern)
            )
        )
    
    # Filtro por rango de fechas
    if date_from:
        query = query.filter(Expense.fecha >= date_from)
    if date_to:
        query = query.filter(Expense.fecha <= date_to)
    
    # Filtro por categorías
    if categories:
        query = query.filter(Expense.categoria.in_(categories))
    elif category:
        query = query.filter(Expense.categoria == category)
    
    expenses = query.order_by(Expense.fecha.desc()).all()
    return jsonify([e.to_dict() for e in expenses]), 200


@app.route('/expenses', methods=['POST'])
def create_expense():
    if not request.is_json:
        return jsonify({'error': 'Content-Type debe ser application/json'}), 400
    
    data = request.get_json(silent=True) or {}
    required = ['titulo', 'categoria', 'monto', 'fecha', 'user_id']
    
    for r in required:
        if r not in data:
            return jsonify({"error": f"Missing field: {r}"}), 400
    
    try:
        datetime.strptime(data['fecha'], '%Y-%m-%d')
    except Exception:
        return jsonify({"error": "fecha must be in YYYY-MM-DD format"}), 400
    
    try:
        monto = float(data['monto'])
        if monto <= 0:
            return jsonify({"error": "monto debe ser mayor a 0"}), 400
    except ValueError:
        return jsonify({"error": "monto must be a number"}), 400
    
    e = Expense(
        titulo=data['titulo'],
        categoria=data['categoria'],
        monto=monto,
        fecha=data['fecha'],
        descripcion=data.get('descripcion'),
        user_id=int(data['user_id'])
    )
    
    db.session.add(e)
    db.session.commit()
    return jsonify(e.to_dict()), 201

@app.route('/expenses/<int:expense_id>', methods=['GET'])
def get_expense(expense_id):
    e = Expense.query.get_or_404(expense_id)
    return jsonify(e.to_dict()), 200

@app.route('/expenses/<int:expense_id>', methods=['PUT'])
def update_expense(expense_id):
    e = Expense.query.get_or_404(expense_id)
    data = request.get_json() or {}
    
    if 'titulo' in data:
        e.titulo = data['titulo']
    if 'categoria' in data:
        e.categoria = data['categoria']
    if 'monto' in data:
        try:
            monto = float(data['monto'])
            if monto <= 0:
                return jsonify({"error": "monto debe ser mayor a 0"}), 400
            e.monto = monto
        except ValueError:
            return jsonify({"error": "monto must be a number"}), 400
    if 'fecha' in data:
        try:
            datetime.strptime(data['fecha'], '%Y-%m-%d')
            e.fecha = data['fecha']
        except Exception:
            return jsonify({"error": "fecha must be in YYYY-MM-DD format"}), 400
    if 'descripcion' in data:
        e.descripcion = data['descripcion']
    
    db.session.commit()
    return jsonify(e.to_dict()), 200

@app.route('/expenses/<int:expense_id>', methods=['DELETE'])
def delete_expense(expense_id):
    e = Expense.query.get_or_404(expense_id)
    db.session.delete(e)
    db.session.commit()
    return jsonify({"status": "deleted", "id": expense_id}), 200

# =====================================================
# CATEGORÍAS Y REPORTES
# =====================================================

@app.route('/categories', methods=['GET'])
def get_categories():
    user_id = request.args.get('user_id', type=int)
    if not user_id:
        return jsonify({"error": "Missing user_id"}), 400
    
    categories = (
        db.session.query(Expense.categoria)
        .filter(Expense.user_id == user_id)
        .distinct()
        .all()
    )
    return jsonify([c[0] for c in categories if c[0] is not None]), 200

@app.route('/report_by_category', methods=['GET'])
def report_by_category():
    user_id = request.args.get('user_id', type=int)
    if not user_id:
        return jsonify({"error": "user_id requerido"}), 400
    
    results = (
        db.session.query(Expense.categoria, db.func.sum(Expense.monto))
        .filter(Expense.user_id == user_id)
        .group_by(Expense.categoria)
        .all()
    )
    
    report = [{"categoria": r[0], "total": float(r[1])} for r in results]
    return jsonify(report), 200

# =====================================================
# USUARIO - OPCIONAL: Editar perfil y eliminar cuenta
# =====================================================

@app.route('/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    user = User.query.get_or_404(user_id)
    data = request.get_json() or {}
    
    if 'nombre' in data:
        user.nombre = data['nombre']
    if 'email' in data:
        # Verifica que el nuevo email no esté en uso
        if data['email'] != user.correo:
            existing = User.query.filter_by(correo=data['email']).first()
            if existing:
                return jsonify({'error': 'Email ya en uso'}), 400
            user.correo = data['email']
    if 'password' in data:
        user.set_password(data['password'])
    
    db.session.commit()
    return jsonify({
        'status': 'success',
        'user': {'id': user.id, 'nombre': user.nombre, 'correo': user.correo}
    }), 200

@app.route('/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    user = User.query.get_or_404(user_id)
    db.session.delete(user)  # cascade='all, delete-orphan' eliminará sus gastos
    db.session.commit()
    return jsonify({"status": "deleted", "id": user_id}), 200

# =====================================================
# CAMBIAR CONTRASEÑA
# =====================================================

@app.route('/users/<int:user_id>/password', methods=['PUT'])
def change_password(user_id):
    user = User.query.get_or_404(user_id)
    data = request.get_json() or {}
    
    current_password = data.get('current_password')
    new_password = data.get('new_password')
    
    if not current_password or not new_password:
        return jsonify({'status': 'error', 'message': 'Campos incompletos'}), 400
    
    # Verifica que la contraseña actual sea correcta
    if not user.check_password(current_password):
        return jsonify({'status': 'error', 'message': 'Contraseña actual incorrecta'}), 401
    
    # Actualiza a la nueva contraseña
    user.set_password(new_password)
    db.session.commit()
    
    return jsonify({'status': 'success', 'message': 'Contraseña actualizada correctamente'}), 200


# =====================================================
# INICIALIZACIÓN
# =====================================================

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000, debug=True)
