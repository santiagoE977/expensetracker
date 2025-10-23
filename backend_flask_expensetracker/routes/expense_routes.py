from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, Expense
from sqlalchemy import select, func
from schemas import ExpenseSchema
from datetime import datetime

# Blueprint para rutas de gastos
expense_bp = Blueprint("expense", __name__)
expense_schema = ExpenseSchema()
expense_schema_many = ExpenseSchema(many=True)


# ======================================================
# 🔹 Crear nuevo gasto (con depuración visual activada)
# ======================================================
@expense_bp.route("/expenses", methods=["POST"])
@jwt_required()
def create_expense():
    # 📦 Mostrar los datos JSON que llegan desde Flutter
    data = request.get_json() or {}
    print("\n=======================")
    print("📦 JSON recibido desde Flutter:")
    print(data)
    print("=======================\n")

    user_id = get_jwt_identity()
    data["user_id"] = user_id

    # Validar datos con el esquema
    errors = expense_schema.validate(data)
    if errors:
        print("❌ Errores de validación:", errors)
        return jsonify({"status": "error", "errors": errors}), 400

    # Validar formato de fecha (en caso de que venga mal)
    fecha_str = data.get("fecha")
    if isinstance(fecha_str, str) and "T" in fecha_str:
        print("⚠️ Corrigiendo formato de fecha con 'T':", fecha_str)
        fecha_str = fecha_str.split("T")[0]

    try:
        datetime.strptime(fecha_str, "%Y-%m-%d")
    except ValueError:
        return jsonify({
            "status": "error",
            "message": "La fecha debe tener formato YYYY-MM-DD",
        }), 400

    # Crear el gasto
    expense = Expense(
        titulo=data["titulo"],
        categoria=data["categoria"],
        monto=float(data["monto"]),
        fecha=fecha_str,
        descripcion=data.get("descripcion", ""),
        user_id=user_id,
    )

    db.session.add(expense)
    db.session.commit()

    print(f"✅ Gasto creado correctamente con ID {expense.id}")
    return jsonify({"status": "success", "expense": expense.to_dict()}), 201


# ======================================================
# 🔹 Obtener lista de gastos
# ======================================================
@expense_bp.route("/expenses", methods=["GET"])
@jwt_required()
def get_expenses():
    user_id = get_jwt_identity()

    category = request.args.get("category")
    start = request.args.get("start")
    end = request.args.get("end")

    try:
        page = max(int(request.args.get("page", 1)), 1)
        per_page = min(int(request.args.get("limit", 20)), 100)
    except ValueError:
        return jsonify({"status": "error", "message": "page y limit deben ser enteros"}), 400

    stmt = select(Expense).filter_by(user_id=user_id)

    if category:
        stmt = stmt.filter(Expense.categoria == category)

    if start:
        stmt = stmt.filter(Expense.fecha >= start)

    if end:
        stmt = stmt.filter(Expense.fecha <= end)

    stmt = stmt.order_by(Expense.fecha.desc())

    total = db.session.scalar(select(func.count()).select_from(stmt.subquery()))
    items = db.session.scalars(stmt.offset((page - 1) * per_page).limit(per_page)).all()

    return jsonify({
        "status": "success",
        "page": page,
        "per_page": per_page,
        "total": total,
        "expenses": [e.to_dict() for e in items]
    }), 200


# ======================================================
# 🔹 Obtener gasto individual
# ======================================================
@expense_bp.route("/expenses/<int:expense_id>", methods=["GET"])
@jwt_required()
def get_expense(expense_id):
    user_id = get_jwt_identity()
    expense = db.session.get(Expense, expense_id)
    if not expense or expense.user_id != user_id:
        return jsonify({"status": "error", "message": "Gasto no encontrado"}), 404
    return jsonify({"status": "success", "expense": expense.to_dict()}), 200


# ======================================================
# 🔹 Actualizar gasto
# ======================================================
@expense_bp.route("/expenses/<int:expense_id>", methods=["PUT"])
@jwt_required()
def update_expense(expense_id):
    user_id = get_jwt_identity()
    expense = db.session.get(Expense, expense_id)
    if not expense or expense.user_id != user_id:
        return jsonify({"status": "error", "message": "Gasto no encontrado"}), 404

    data = request.get_json() or {}
    print("📦 Datos de actualización recibidos:", data)

    for field in ["titulo", "categoria", "monto", "fecha", "descripcion"]:
        if field in data:
            if field == "monto":
                expense.monto = float(data["monto"])
            elif field == "fecha":
                fecha_str = data["fecha"].split("T")[0]
                expense.fecha = fecha_str
            else:
                setattr(expense, field, data[field])

    db.session.commit()
    print(f"✅ Gasto {expense_id} actualizado correctamente")
    return jsonify({"status": "success", "expense": expense.to_dict()}), 200


# ======================================================
# 🔹 Eliminar gasto
# ======================================================
@expense_bp.route("/expenses/<int:expense_id>", methods=["DELETE"])
@jwt_required()
def delete_expense(expense_id):
    user_id = get_jwt_identity()
    expense = db.session.get(Expense, expense_id)
    if not expense or expense.user_id != user_id:
        return jsonify({"status": "error", "message": "Gasto no encontrado"}), 404

    db.session.delete(expense)
    db.session.commit()
    print(f"🗑️ Gasto eliminado (ID: {expense_id})")
    return jsonify({"status": "success", "message": "Gasto eliminado"}), 200


# ======================================================
# 🔹 Obtener categorías
# ======================================================
@expense_bp.route("/categories", methods=["GET"])
@jwt_required()
def get_categories():
    user_id = get_jwt_identity()
    stmt = select(Expense.categoria).filter(Expense.user_id == user_id).distinct().order_by(Expense.categoria)
    categories = db.session.scalars(stmt).all()
    return jsonify({"status": "success", "categories": categories}), 200


# ======================================================
# 🔹 Restablecer todos los gastos
# ======================================================
@expense_bp.route("/expenses/reset", methods=["DELETE"])
@jwt_required()
def reset_expenses():
    user_id = get_jwt_identity()
    try:
        deleted = db.session.query(Expense).filter_by(user_id=user_id).delete()
        db.session.commit()
        print(f"🧹 Se eliminaron {deleted} gastos del usuario {user_id}")
        return jsonify({"status": "success", "message": f"Se eliminaron {deleted} gastos."}), 200
    except Exception as e:
        db.session.rollback()
        print(f"⚠️ Error al restablecer gastos: {e}")
        return jsonify({"status": "error", "message": "No se pudieron eliminar los gastos."}), 500