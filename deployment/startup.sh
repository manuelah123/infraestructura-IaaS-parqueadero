#!/bin/bash

echo "🚀 Iniciando Sistema de Parqueadero..."

# Iniciar contenedores Incus
echo "📦 Iniciando contenedores..."
incus start --all

# Esperar a que Keycloak esté listo
echo "⏳ Esperando a Keycloak..."
sleep 30

# Obtener IPs
echo "🔍 Obteniendo IPs de contenedores..."
DB1=$(incus exec db-node1 -- hostname -I | awk '{print $1}')
echo "DB1: $DB1"

# Iniciar CockroachDB
echo "🗄️ Iniciando CockroachDB..."
incus exec db-node1 -- cockroach start --insecure \
  --store=/var/lib/cockroach \
  --listen-addr=$DB1:26257 \
  --advertise-addr=$DB1:26257 \
  --http-addr=$DB1:8080 \
  --background

# Iniciar FastAPI
echo "⚡ Iniciando FastAPI..."
incus shell api-server << 'SHELL'
cd /opt/parking-api
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000 &
SHELL

# Iniciar Frontend
echo "🎨 Iniciando Frontend..."
cd ~/parking-front
npm run dev -- --host 0.0.0.0 --port 5173 &

echo "✅ Sistema iniciado!"
echo ""
echo "URLs de acceso:"
echo "  Frontend:        http://localhost:5173"
echo "  API Swagger:     http://localhost:8000/docs"
echo "  Keycloak Admin:  http://localhost:8082/admin"
echo "  CockroachDB:     http://localhost:8081"
