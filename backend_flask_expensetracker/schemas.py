# schemas.py
from flask_marshmallow import Marshmallow
from marshmallow import fields, validate, validates_schema, ValidationError
from datetime import datetime

ma = Marshmallow()

# ======================================================
# 🔹 Esquema para Registro de Usuario
# ======================================================
class UserRegisterSchema(ma.Schema):
    nombre = fields.Str(required=True, validate=validate.Length(min=1))
    correo = fields.Email(required=True)
    password = fields.Str(required=True, validate=validate.Length(min=6))


# ======================================================
# 🔹 Esquema para Login de Usuario
# ======================================================
class UserLoginSchema(ma.Schema):
    correo = fields.Email(required=True)
    password = fields.Str(required=True)


# ======================================================
# 🔹 Esquema para Gastos
# ======================================================
class ExpenseSchema(ma.Schema):
    id = fields.Int(dump_only=True)
    titulo = fields.Str(required=True, validate=validate.Length(min=1))
    categoria = fields.Str(required=True, validate=validate.Length(min=1))
    monto = fields.Float(required=True)
    fecha = fields.Str(required=True)  # 🔄 Se cambia a Str para aceptar ISO o simple
    descripcion = fields.Str(allow_none=True)
    user_id = fields.Int(required=True)

    # 🔍 Validación personalizada flexible para fecha
    @validates_schema
    def validate_fecha(self, data, **kwargs):
        fecha = data.get("fecha")
        if fecha is None:
            raise ValidationError("El campo 'fecha' es obligatorio")

        if isinstance(fecha, str):
            try:
                # ✅ Acepta formato ISO-8601 (con 'T' y 'Z')
                if "T" in fecha:
                    datetime.fromisoformat(fecha.replace("Z", ""))
                else:
                    datetime.strptime(fecha, "%Y-%m-%d")
            except Exception:
                raise ValidationError(
                    "La fecha debe tener formato 'YYYY-MM-DD' o ISO-8601 válido"
                )
        else:
            raise ValidationError("El campo 'fecha' debe ser una cadena de texto")

    class Meta:
        ordered = True  # Mantiene el orden de los campos