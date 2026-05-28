-- Crear base de datos
CREATE DATABASE IF NOT EXISTS parqueadero;

-- Usar la base de datos
USE parqueadero;

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username STRING NOT NULL UNIQUE,
    email STRING NOT NULL,
    nombre STRING NOT NULL,
    rol STRING NOT NULL DEFAULT 'operador',
    contraseña_hash STRING NOT NULL,
    creado_en TIMESTAMP DEFAULT now(),
    actualizado_en TIMESTAMP DEFAULT now()
);

-- Tabla de vehículos
CREATE TABLE IF NOT EXISTS vehiculos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    placa STRING NOT NULL UNIQUE,
    tipo STRING NOT NULL,
    marca STRING,
    modelo STRING,
    color STRING,
    estado STRING NOT NULL DEFAULT 'parqueado',
    creado_en TIMESTAMP DEFAULT now(),
    actualizado_en TIMESTAMP DEFAULT now()
);

-- Tabla de parqueos
CREATE TABLE IF NOT EXISTS parqueos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_vehiculo UUID NOT NULL REFERENCES vehiculos(id),
    id_usuario UUID NOT NULL REFERENCES usuarios(id),
    puesto STRING NOT NULL,
    fecha_entrada TIMESTAMP NOT NULL,
    fecha_salida TIMESTAMP,
    tiempo_minutos INT,
    valor_pagado DECIMAL(10, 2),
    creado_en TIMESTAMP DEFAULT now(),
    actualizado_en TIMESTAMP DEFAULT now()
);

-- Tabla de tarifas
CREATE TABLE IF NOT EXISTS tarifas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_vehiculo STRING NOT NULL UNIQUE,
    precio_hora DECIMAL(10, 2) NOT NULL,
    precio_dia DECIMAL(10, 2) NOT NULL,
    creado_en TIMESTAMP DEFAULT now(),
    actualizado_en TIMESTAMP DEFAULT now()
);

-- Tabla de pagos
CREATE TABLE IF NOT EXISTS pagos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_parqueo UUID NOT NULL REFERENCES parqueos(id),
    monto DECIMAL(10, 2) NOT NULL,
    metodo STRING NOT NULL,
    fecha_pago TIMESTAMP DEFAULT now(),
    estado STRING NOT NULL DEFAULT 'completado',
    creado_en TIMESTAMP DEFAULT now()
);

-- Inserts iniciales
INSERT INTO tarifas (tipo_vehiculo, precio_hora, precio_dia) VALUES
    ('carro', 5000.00, 30000.00),
    ('moto', 2500.00, 15000.00),
    ('bicicleta', 1000.00, 5000.00)
ON CONFLICT DO NOTHING;

INSERT INTO vehiculos (placa, tipo, estado) VALUES
    ('ABC123', 'carro', 'parqueado'),
    ('XYZ789', 'moto', 'retirado')
ON CONFLICT DO NOTHING;
