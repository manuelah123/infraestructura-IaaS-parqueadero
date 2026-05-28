from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from jose import jwt
import requests
import psycopg2
import psycopg2.extras


app = FastAPI(title="API Sistema de Parqueadero")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:5173", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

KEYCLOAK_URL = "http://10.245.23.168:8080"
REALM = "parqueadero"
JWKS_URL = f"{KEYCLOAK_URL}/realms/{REALM}/protocol/openid-connect/certs"

DATABASE_URL = "postgresql://root@10.245.23.52:26257/parqueadero?sslmode=disable"


class VehiculoCreate(BaseModel):
    placa: str
    tipo: str
    estado: str = "parqueado"


class VehiculoUpdate(BaseModel):
    tipo: str
    estado: str


def get_db_connection():
    return psycopg2.connect(DATABASE_URL)


def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials

    try:
        header = jwt.get_unverified_header(token)
        jwks = requests.get(JWKS_URL).json()

        key = None
        for jwk in jwks["keys"]:
            if jwk["kid"] == header["kid"]:
                key = jwk
                break

        if key is None:
            raise HTTPException(status_code=401, detail="Clave JWT no encontrada")

        payload = jwt.decode(
            token,
            key,
            algorithms=["RS256"],
            options={
                "verify_aud": False,
                "verify_iss": False
            }
        )

        return payload

    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=401, detail="Token invalido")


@app.get("/")
def root():
    return {
        "mensaje": "API del sistema de parqueadero funcionando"
    }


@app.get("/protegido")
def protegido(user=Depends(verify_token)):
    return {
        "mensaje": "Acceso autorizado",
        "usuario": user.get("preferred_username")
    }


@app.get("/vehiculos")
def listar_vehiculos(user=Depends(verify_token)):
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cur.execute("""
            SELECT placa, tipo, estado
            FROM vehiculos
            ORDER BY creado_en DESC
        """)

        vehiculos = cur.fetchall()

        cur.close()
        conn.close()

        return vehiculos

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error consultando CockroachDB: {str(e)}")


@app.post("/vehiculos")
def crear_vehiculo(data: VehiculoCreate, user=Depends(verify_token)):
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cur.execute(
            """
            INSERT INTO vehiculos (placa, tipo, estado)
            VALUES (%s, %s, %s)
            RETURNING placa, tipo, estado
            """,
            (data.placa.upper(), data.tipo, data.estado)
        )

        vehiculo = cur.fetchone()
        conn.commit()

        cur.close()
        conn.close()

        return vehiculo

    except psycopg2.errors.UniqueViolation:
        raise HTTPException(status_code=409, detail="Ya existe un vehiculo con esa placa")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creando vehiculo: {str(e)}")


@app.put("/vehiculos/{placa}")
def actualizar_vehiculo(placa: str, data: VehiculoUpdate, user=Depends(verify_token)):
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cur.execute(
            """
            UPDATE vehiculos
            SET tipo = %s, estado = %s
            WHERE placa = %s
            RETURNING placa, tipo, estado
            """,
            (data.tipo, data.estado, placa.upper())
        )

        vehiculo = cur.fetchone()
        conn.commit()

        cur.close()
        conn.close()

        if vehiculo is None:
            raise HTTPException(status_code=404, detail="Vehiculo no encontrado")

        return vehiculo

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error actualizando vehiculo: {str(e)}")


@app.delete("/vehiculos/{placa}")
def eliminar_vehiculo(placa: str, user=Depends(verify_token)):
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute(
            "DELETE FROM vehiculos WHERE placa = %s",
            (placa.upper(),)
        )

        eliminados = cur.rowcount
        conn.commit()

        cur.close()
        conn.close()

        if eliminados == 0:
            raise HTTPException(status_code=404, detail="Vehiculo no encontrado")

        return {
            "mensaje": "Vehiculo eliminado",
            "placa": placa.upper()
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error eliminando vehiculo: {str(e)}")
