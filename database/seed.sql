-- Script para llenar datos de prueba

-- Insertar usuarios de prueba
INSERT INTO usuarios (username, email, nombre, rol, contraseña_hash) VALUES
    ('operador1', 'operador1@parqueadero.local', 'Operador Uno', 'operador', 'hash_aqui'),
    ('operador2', 'operador2@parqueadero.local', 'Operador Dos', 'operador', 'hash_aqui'),
    ('admin.parqueadero', 'admin@parqueadero.local', 'Admin Parqueadero', 'admin', 'hash_aqui')
ON CONFLICT (username) DO NOTHING;

-- Insertar más vehículos
INSERT INTO vehiculos (placa, tipo, marca, modelo, color, estado) VALUES
    ('LMN456', 'carro', 'Toyota', 'Corolla', 'Blanco', 'parqueado'),
    ('OPQ789', 'moto', 'Honda', 'CB500', 'Negro', 'parqueado'),
    ('RST012', 'carro', 'Nissan', 'Sentra', 'Gris', 'retirado')
ON CONFLICT (placa) DO NOTHING;
