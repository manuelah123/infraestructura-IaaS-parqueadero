# Sistema de Parqueadero - Laboratorio IaaS

Sistema completo de gestión de parqueaderos con autenticación JWT, API REST protegida, base de datos distribuida y frontend dinámico.

## Descripción General

- **Windows** anfitrión → **VirtualBox** → **Debian 13.5.0** → **Incus** (5 contenedores)
- **Keycloak**: Autenticación con JWT
- **FastAPI**: Backend REST protegido (Python)
- **CockroachDB**: Base de datos distribuida (3 nodos)
- **React + Vite**: Frontend dinámico

Estado: FUNCIONAL - Backend, autenticación, base de datos distribuida y CRUD operativos.

---

## Estructura del Repositorio

```
infraestructura-IaaS-parqueadero/
├── README.md                          (este archivo)
├── LICENSE                            (MIT License)
├── .gitignore
├── backend/                           (API FastAPI)
│   ├── main.py                        (código principal)
│   ├── requirements.txt                (dependencias Python)
│   ├── config.py                       (configuración)
│   ├── models.py                       (modelos de datos)
│   ├── Dockerfile                      (para deployment)
│   └── .env.example                    (variables de entorno)
├── frontend/                          (React + Vite)
│   ├── src/
│   ├── package.json
│   ├── vite.config.js
│   └── .env.example
├── database/                          (Scripts CockroachDB)
│   ├── init.sql                        (crear DB y tablas)
│   └── seed.sql                        (datos iniciales)
├── infrastructure/
│   ├── opentofu/                       (Infraestructura como código)
│   │   ├── main.tf                     (provider Incus)
│   │   ├── network.tf                  (configuración de red)
│   │   ├── containers.tf               (definición de contenedores)
│   │   ├── outputs.tf                  (outputs)
│   │   ├── variables.tf                (variables)
│   │   ├── terraform.tfvars            (valores)
│   │   └── .gitignore                  (archivos locales)
│   └── incus-exports/                  (Backups de configuración)
│       ├── network.yaml                (config red incusbr0)
│       ├── api-server.yaml             (config contenedor API)
│       ├── keycloak-server.yaml        (config contenedor Keycloak)
│       ├── db-node1.yaml               (config nodo DB 1)
│       ├── db-node2.yaml               (config nodo DB 2)
│       ├── db-node3.yaml               (config nodo DB 3)
│       └── profile-default.yaml        (perfil Incus)
├── deployment/                        (Scripts de operación)
│   ├── startup.sh                      (levantar todo)
│   ├── shutdown.sh                     (detener todo)
│   └── reset.sh                        (reiniciar limpio)
├── docs/                              (Documentación)
│   └── ARQUITECTURA.md                 (detalles técnicos)
└── docker-compose.yml                 (alternativa Docker Compose)
```

---

## Requisitos Mínimos

| Elemento | Valor |
|----------|-------|
| RAM | 8 GB anfitrión, 4-6 GB para VM |
| CPU | 2+ núcleos |
| Disco | 60 GB dinámico |
| SO | Windows 10/11 + VirtualBox 7.0+ |
| Internet | Para descargar imágenes |

---

## Inicio Rápido

### 1. Clonar Repositorio

```bash
git clone https://github.com/manuelah123/infraestructura-IaaS-parqueadero.git
cd infraestructura-IaaS-parqueadero
```

### 2. Descargar e Instalar Requisitos

- VirtualBox: https://www.virtualbox.org/wiki/Downloads
- Debian 13: https://www.debian.org/download (amd64 netinst)

### 3. Crear VM Debian

```bash
En VirtualBox: Nueva VM
Nombre: proyecto
Tipo: Linux, Debian 64-bit
RAM: 4096 MB
CPU: 2 núcleos
Disco: 80 GB dinámico VDI
```

### 4. Configurar SSH (en VM Debian)

```bash
su -
apt update && apt install -y sudo openssh-server
usermod -aG sudo vboxuser
systemctl enable ssh && systemctl start ssh
exit
```

### 5. Port Forwarding (VirtualBox)

En Settings → Network → Port Forwarding:

```
SSH:        127.0.0.1:2222   → 22
FastAPI:    127.0.0.1:8000   → 8000
Keycloak:   127.0.0.1:8082   → 8080
Frontend:   127.0.0.1:5173   → 5173
CockroachDB:127.0.0.1:8081   → 8081
```

### 6. Instalar Incus (en VM)

```bash
# Desde Windows:
ssh -L 8082:127.0.0.1:8080 vboxuser@127.0.0.1 -p 2222

# En la VM:
sudo apt install -y incus
sudo usermod -aG incus-admin vboxuser
exit

# Reconectar:
ssh -L 8082:127.0.0.1:8080 vboxuser@127.0.0.1 -p 2222
incus admin init
```

### 7. Crear Contenedores

```bash
incus launch images:debian/13 keycloak-server
incus launch images:debian/13 api-server
incus launch images:debian/13 db-node1
incus launch images:debian/13 db-node2
incus launch images:debian/13 db-node3
incus list
```

### 8. Ejecutar Script de Despliegue

```bash
chmod +x deployment/startup.sh
./deployment/startup.sh
```

---

## Manejo de Archivos por Directorio

### Backend (`backend/`)

**main.py** - Aplicación FastAPI principal
```bash
# Copiar a contenedor
scp backend/main.py <host>:/opt/parking-api/

# Instalar dependencias
pip install -r backend/requirements.txt

# Ejecutar
uvicorn main:app --host 0.0.0.0 --port 8000
```

**requirements.txt** - Dependencias Python
```bash
# Generar (si cambias librerías):
pip freeze > backend/requirements.txt

# Instalar desde archivo:
pip install -r backend/requirements.txt
```

**config.py, models.py** - Configuración y modelos de datos
```bash
# Actualizar si cambias estructura de DB
# Estos archivos se cargan automáticamente por main.py
```

### Frontend (`frontend/`)

**package.json** - Dependencias Node.js
```bash
# Instalar dependencias
cd frontend && npm install

# Generar versión compilada para producción
npm run build

# Ejecutar en desarrollo
npm run dev -- --host 0.0.0.0 --port 5173
```

**Copiar archivos al servidor**
```bash
# Desde Windows hacia VM
scp -r frontend/* vboxuser@127.0.0.1:/home/vboxuser/parking-front/ -P 2222
```

### Base de Datos (`database/`)

**init.sql** - Crear estructura
```bash
# Aplicar cambios de estructura
incus exec db-node1 -- cockroach sql --insecure --host=$DB1:26257 < database/init.sql

# O directamente:
incus exec db-node1 -- cockroach sql --insecure --host=$DB1:26257 -e "
$(cat database/init.sql)
"
```

**seed.sql** - Datos iniciales
```bash
# Cargar datos de prueba
incus exec db-node1 -- cockroach sql --insecure --host=$DB1:26257 --database=parqueadero < database/seed.sql
```

### Infraestructura como Código (`infrastructure/opentofu/`)

**main.tf, network.tf, containers.tf** - Definición Incus
```bash
# Inicializar OpenTofu (requiere internet en Debian)
cd infrastructure/opentofu
tofu init

# Ver cambios
tofu plan

# Aplicar configuración
tofu apply

# Destruir infraestructura
tofu destroy
```

**terraform.tfvars** - Variables de configuración
```bash
# Editar valores si necesitas cambiar IPs o configuración
nano infrastructure/opentofu/terraform.tfvars

# Aplicar cambios
tofu apply
```

### Backups de Configuración (`infrastructure/incus-exports/`)

**network.yaml, *-server.yaml** - Configuración exportada
```bash
# Exportar configuración actual
incus config show api-server > infrastructure/incus-exports/api-server.yaml
incus network show incusbr0 > infrastructure/incus-exports/network.yaml

# Restaurar desde backup
incus launch images:debian/13 api-server < infrastructure/incus-exports/api-server.yaml

# Versionar en Git
git add infrastructure/incus-exports/
git commit -m "Backup de configuración Incus"
```

### Scripts de Operación (`deployment/`)

**startup.sh** - Levantar todo
```bash
chmod +x deployment/startup.sh
./deployment/startup.sh

# O manualmente:
incus start --all
# ... iniciar FastAPI, Frontend, CockroachDB
```

**shutdown.sh** - Detener gracefully
```bash
chmod +x deployment/shutdown.sh
./deployment/shutdown.sh

# O manualmente:
incus stop --all
```

**reset.sh** - Limpiar y reiniciar
```bash
chmod +x deployment/reset.sh
./deployment/reset.sh

# Elimina contenedores y recrea desde cero
```

---

## Flujo de Trabajo Git

### Descargar cambios del repositorio

```bash
git clone https://github.com/manuelah123/infraestructura-IaaS-parqueadero.git
cd infraestructura-IaaS-parqueadero
git pull origin main
```

### Hacer cambios locales

```bash
# Modificar archivos de backend, frontend, etc.
vim backend/main.py

# Ver cambios
git status
git diff backend/main.py
```

### Subir cambios

```bash
# Agregar archivos
git add backend/main.py

# Commit
git commit -m "Agregar nuevo endpoint para obtener estadísticas"

# Push a GitHub
git push origin main
```

### Sincronizar infraestructura

```bash
# Si cambias configuración Incus, exporta:
incus config show api-server > infrastructure/incus-exports/api-server.yaml

# Versiona en Git:
git add infrastructure/incus-exports/
git commit -m "Actualizar configuración contenedor api-server"
git push origin main
```

---

## Variables de Entorno

Cada componente necesita configuración. Usar archivos `.env.example`:

### Backend (`.env.example`)

```bash
KEYCLOAK_URL=http://10.245.23.168:8080
REALM=parqueadero
DATABASE_URL=postgresql://root@10.245.23.52:26257/parqueadero?sslmode=disable
```

Crear `.env` real:
```bash
cp backend/.env.example backend/.env
nano backend/.env  # Editar IPs reales
```

### Frontend (`.env.example`)

```bash
VITE_API_URL=http://127.0.0.1:8000
VITE_KEYCLOAK_URL=http://127.0.0.1:8082
```

Crear `.env`:
```bash
cp frontend/.env.example frontend/.env
nano frontend/.env
```

---

## Credenciales de Prueba

```
Keycloak Admin:    admin / admin
Usuario Operador:  operador1 / Operador123*
Usuario Admin:     admin.parqueadero / Admin123*
Incus Web UI: http://127.0.0.1:35175/ui (ejecutar `incus webui`)
```

Acceso a servicios:
- Frontend: http://127.0.0.1:5173
- FastAPI Docs: http://127.0.0.1:8000/docs
- Keycloak: http://127.0.0.1:8082/admin/
- CockroachDB UI: http://127.0.0.1:8081

---

## Solución de Problemas Comunes

| Error | Solución |
|-------|----------|
| No conecta por SSH | Verificar Port Forwarding 2222→22 en VirtualBox |
| Incus certificate restricted | `sudo usermod -aG incus-admin vboxuser` + reiniciar SSH |
| Keycloak no abre | `docker ps` en keycloak-server, verificar docker logs |
| API no conecta DB | Verificar IP actual: `incus list`, actualizar DATABASE_URL |
| Frontend no carga | Verificar `npm run dev` está ejecutando, PORT 5173 |
| Contenedor no inicia | `incus logs <contenedor>` para ver errores |

---

## Documentación Completa

Para más detalles técnicos, ver:
- `docs/ARQUITECTURA.md` - Detalles de arquitectura de 4 capas
- `infrastructure/opentofu/` - Código IaC completo
- `backend/requirements.txt` - Todas las dependencias
- `frontend/package.json` - Paquetes Node.js

---

## Stack Tecnológico

| Componente | Versión | Función |
|-----------|---------|---------|
| Windows | 10/11 | Anfitrión |
| VirtualBox | 7.0+ | Virtualización |
| Debian | 13.5.0 | SO Base |
| Incus | latest | Contenedores |
| Keycloak | latest | Auth JWT |
| FastAPI | 0.100+ | Backend |
| CockroachDB | v26.2.0 | Base Datos |
| React | 18+ | Frontend |
| Vite | 5+ | Build Tool |

---
## Incus Web UI

Interfaz gráfica para administrar contenedores:

```bash
# En la VM, ejecutar:
incus webui

# Salida:
# Web server running at: http://127.0.0.1:35175/ui?auth_token=<token>
```

Abrir la URL en navegador. Desde la interfaz puedes:
- Ver estado de todos los contenedores (api-server, db-node1, db-node2, db-node3, keycloak-server)
- Monitorear recursos (CPU, RAM, Disco)
- Ver logs de cada contenedor
- Gestionar perfiles de red
- Estadísticas en tiempo real


---

## Licencia

MIT License - Ver archivo `LICENSE`

---

## Autor

- **Manuela Henao Bedoya** (m.henao10@utp.edu.co) 
- Universidad Tecnológica de Pereira

---

