from uuid import UUID
from datetime import datetime
from typing import Optional

class Vehiculo:
    id: Optional[UUID] = None
    placa: str
    tipo: str  # carro, moto
    estado: str  # parqueado, retirado
    creado_en: datetime

class Usuario:
    id: Optional[UUID] = None
    username: str
    email: str
    nombre: str
    rol: str  # admin, operador
    creado_en: datetime

class Parqueo:
    id: Optional[UUID] = None
    id_vehiculo: UUID
    id_usuario: UUID
    puesto: str
    fecha_entrada: datetime
    fecha_salida: Optional[datetime] = None
    tiempo_minutos: Optional[int] = None
    valor_pagado: Optional[float] = None
