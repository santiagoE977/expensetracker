# config.py
import os
from dotenv import load_dotenv
from datetime import timedelta

# ======================================================
# 🔹 Cargar variables de entorno desde .env
# ======================================================
load_dotenv()

# Directorio base del proyecto
BASE_DIR = os.path.abspath(os.path.dirname(__file__))

# Base de datos por defecto (SQLite local)
DEFAULT_DB = f"sqlite:///{os.path.join(BASE_DIR, 'database.db')}"


class Config:
    """Configuración general de la aplicación Flask."""

    # ======================================================
    # 🔹 Seguridad
    # ======================================================
    SECRET_KEY = os.getenv("SECRET_KEY", "cambia_esta_clave_en_produccion")
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "clave_jwt_dev_insegura")

    # 🔸 Duración del token JWT (12 horas por defecto)
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=int(os.getenv("JWT_EXPIRES_HOURS", 12)))

    # ======================================================
    # 🔹 Base de datos
    # ======================================================
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL", DEFAULT_DB)
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # ======================================================
    # 🔹 Otros parámetros opcionales
    # ======================================================
    ENV = os.getenv("FLASK_ENV", "development")  # development | production
    DEBUG = ENV == "development"
