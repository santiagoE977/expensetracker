# Backend for ExpenseTracker (Flask + SQLite)

## Contenido
- `app.py` : API REST con endpoints CRUD para gastos.
- `database.db` : SQLite database (se crea al ejecutar `app.py`).
- `requirements.txt` : dependencias.

## Endpoints
- `GET /expenses` : obtener todos los gastos.
- `GET /expenses/<id>` : obtener un gasto por id.
- `POST /expenses` : crear gasto. JSON body: `{ "titulo": "...", "categoria":"...", "monto": 12.5, "fecha": "2025-10-04", "descripcion": "..." }`
- `PUT /expenses/<id>` : actualizar gasto. JSON con los campos a actualizar.
- `DELETE /expenses/<id>` : eliminar gasto.

## Ejecución
1. Crear y activar un entorno virtual (recomendado).
2. `pip install -r requirements.txt`
3. `python app.py`
4. API disponible en `http://127.0.0.1:5000`

## Notas para conectar con Flutter
- Si pruebas desde el emulador Android, usa `10.0.2.2` en lugar de `127.0.0.1`.
- Asegúrate de permitir CORS (ya incluido).
