# init_db.py
"""
Script para inicializar la base de datos de Expense Tracker.
Crea todas las tablas definidas en los modelos SQLAlchemy.
"""

from app import create_app
from models import db, User, Expense
from sqlalchemy import inspect

app = create_app()

with app.app_context():
    inspector = inspect(db.engine)
    existing_tables = inspector.get_table_names()

    if existing_tables:
        print("⚠️  La base de datos ya contiene las siguientes tablas:")
        for table in existing_tables:
            print(f"   • {table}")
        print("\n👉 Si deseas reiniciar completamente la base de datos, elimina el archivo 'database.db'.")
    else:
        db.create_all()
        print("✅ Base de datos inicializada correctamente.")
        print("   Tablas creadas: user, expense")

    # Mostrar estadísticas
    user_count = db.session.query(User).count()
    expense_count = db.session.query(Expense).count()
    print(f"\n📊 Registros actuales -> Usuarios: {user_count} | Gastos: {expense_count}")