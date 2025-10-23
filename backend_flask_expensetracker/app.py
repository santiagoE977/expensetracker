from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from datetime import datetime
import os
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy import select, func

# =====================================================
# ⚙️ CONFIGURACIÓN BASE
# =====================================================
app = Flask(__name__)
CORS(app)

# Base de datos SQLite
db_path = os.path.join(os.path.dirname(__file__), 'database.db')
app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{db_path}"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)

# =====================================================
# 🧱 MODELOS
# =====================================================

class User(db.Model):
    __tablename__ = "user"

    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    correo = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(200), nullable=False)

    expenses = db.relationship("Expense", backref="user", lazy=True)

    def set_password(self, password: str):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password: str) -> bool:
        return check_password_hash(self.password_hash, password)


class Expense(db.Model):
    __tablename__ = "expense"

    id = db.Column(db.Integer, primary_key=True)
    titulo = db.Column(db.String(200), nullable=False)
    categoria = db.Column(db.String(100), nullable=False)
    monto = db.Column(db.Float, nullable=False)
    fecha = db.Column(db.String(10), nullable=False)
    descripcion = db.Column(db.Text, nullable=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "titulo": self.titulo,
            "categoria": self.categoria,
            "monto": self.monto,
            "fecha": self.fecha,
            "descripcion": self.descripcion,
            "user_id": self.user_id,
        }

# =====================================================
# 🔐 AUTENTICACIÓN
# =====================================================

@app.route("/register", methods=["POST"])
def register_user():
    data = request.get_json() or {}
    nombre = data.get("name")
    correo = data.get("email")
    password = data.get("password")

    if not all([nombre, correo, password]):
        return jsonify({"status": "error", "message": "Campos incompletos"}), 400

    existing_user = db.session.scalar(select(User).filter_by(correo=correo))
    if existing_user:
        return jsonify({"status": "error", "message": "Correo ya registrado"}), 400

    user = User(nombre=nombre, correo=correo)
    user.set_password(password)
    db.session.add(user)
    db.session.commit()

    return (
        jsonify(
            {
                "status": "success",
                "user": {"id": user.id, "name": user.nombre, "email": user.correo},
            }
        ),
        201,
    )


@app.route("/login", methods=["POST"])
def login():
    data = request.get_json() or {}
    email = data.get("email")
    password = data.get("password")

    user = db.session.scalar(select(User).filter_by(correo=email))

    if user and user.check_password(password):
        return (
            jsonify(
                {
                    "status": "success",
                    "user": {"id": user.id, "name": user.nombre, "email": user.correo},
                }
            ),
            200,
        )

    return jsonify({"status": "error", "message": "Credenciales incorrectas"}), 401

# =====================================================
# 💰 ENDPOINTS DE GASTOS
# =====================================================

@app.route("/expenses", methods=["GET"])
def get_expenses():
    user_id = request.args.get("user_id", type=int)
    if not user_id:
        return jsonify({"error": "Missing user_id"}), 400

    category = request.args.get("category")

    stmt = select(Expense).filter_by(user_id=user_id)
    if category:
        stmt = stmt.filter(Expense.categoria == category)

    expenses = db.session.scalars(stmt.order_by(Expense.fecha.desc())).all()
    return jsonify([e.to_dict() for e in expenses])


@app.route("/expenses/<int:expense_id>", methods=["GET"])
def get_expense(expense_id):
    expense = db.session.get(Expense, expense_id)
    if not expense:
        return jsonify({"error": "Gasto no encontrado"}), 404
    return jsonify(expense.to_dict())


@app.route("/expenses", methods=["POST"])
def create_expense():
    data = request.get_json() or {}
    required = ["titulo", "categoria", "monto", "fecha", "user_id"]

    for field in required:
        if field not in data:
            return jsonify({"error": f"Missing field: {field}"}), 400

    try:
        datetime.strptime(data["fecha"], "%Y-%m-%d")
    except Exception:
        return jsonify({"error": "fecha must be in YYYY-MM-DD format"}), 400

    expense = Expense(
        titulo=data["titulo"],
        categoria=data["categoria"],
        monto=float(data["monto"]),
        fecha=data["fecha"],
        descripcion=data.get("descripcion"),
        user_id=data["user_id"],
    )
    db.session.add(expense)
    db.session.commit()
    return jsonify(expense.to_dict()), 201


@app.route("/expenses/<int:expense_id>", methods=["PUT"])
def update_expense(expense_id):
    expense = db.session.get(Expense, expense_id)
    if not expense:
        return jsonify({"error": "Gasto no encontrado"}), 404

    data = request.get_json() or {}

    if "titulo" in data:
        expense.titulo = data["titulo"]
    if "categoria" in data:
        expense.categoria = data["categoria"]
    if "monto" in data:
        try:
            expense.monto = float(data["monto"])
        except Exception:
            return jsonify({"error": "monto must be a number"}), 400
    if "fecha" in data:
        try:
            datetime.strptime(data["fecha"], "%Y-%m-%d")
            expense.fecha = data["fecha"]
        except Exception:
            return jsonify({"error": "fecha must be in YYYY-MM-DD format"}), 400
    if "descripcion" in data:
        expense.descripcion = data["descripcion"]

    db.session.commit()
    return jsonify(expense.to_dict())


@app.route("/expenses/<int:expense_id>", methods=["DELETE"])
def delete_expense(expense_id):
    expense = db.session.get(Expense, expense_id)
    if not expense:
        return jsonify({"error": "Gasto no encontrado"}), 404

    db.session.delete(expense)
    db.session.commit()
    return jsonify({"status": "deleted"})


@app.route("/categories", methods=["GET"])
def get_categories():
    user_id = request.args.get("user_id", type=int)
    if not user_id:
        return jsonify({"error": "Missing user_id"}), 400

    stmt = (
        select(Expense.categoria)
        .filter(Expense.user_id == user_id)
        .distinct()
        .order_by(Expense.categoria)
    )

    categories = db.session.scalars(stmt).all()
    return jsonify(categories)

# =====================================================
# 🚀 EJECUCIÓN
# =====================================================

if __name__ == "__main__":
    with app.app_context():
        db.create_all()
    app.run(host="0.0.0.0", port=5000, debug=True)