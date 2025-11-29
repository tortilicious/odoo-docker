# Odoo 18 + PostgreSQL Docker Setup

Setup de desarrollo local para Odoo 18 con PostgreSQL usando Docker Compose.

## Requisitos Previos

Docker versión 20.10+ y Docker Compose versión 1.29+ deben estar instalados en el sistema. Verifica la instalación ejecutando:

```bash
docker --version
docker-compose --version
```

## Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/odoo18-docker.git
cd odoo18-docker
```

### 2. Configurar Variables de Entorno

Copia el archivo de plantilla y personaliza según sea necesario:

```bash
cp .env.example .env
```

El archivo `.env` contiene las variables de entorno necesarias. Los valores por defecto (`POSTGRES_USER=odoo`, `POSTGRES_PASSWORD=odoo`, `ODOO_PORT=8069`) son adecuados para desarrollo. Edita según tus requisitos específicos si es necesario.

### 3. Levantar los Servicios

```bash
docker compose up -d
```

Este comando levanta PostgreSQL y Odoo en segundo plano. La primera ejecución descargará las imágenes necesarias, lo que puede tardar algunos minutos. Las ejecuciones posteriores serán más rápidas.

### 4. Verificar Estado de los Servicios

```bash
docker compose ps
```

Deberías ver:

```
NAME                COMMAND             SERVICE        STATUS
odoo18-postgres     postgres            db             Up (healthy)
odoo18-server       odoo                odoo           Up
```

El estado "healthy" en PostgreSQL indica que la base de datos está lista. Si ves "starting" o "unhealthy", espera unos segundos adicionales y repite el comando. PostgreSQL requiere tiempo para completar su inicialización en la primera ejecución.

### 5. Crear Base de Datos

Accede a `http://localhost:8069` en tu navegador. Se te pedirá crear una nueva base de datos. Proporciona:

- **Database name**: Nombre descriptivo para la base de datos
- **Email**: Correo del usuario administrador
- **Password**: Contraseña del administrador de Odoo
- **Language**: Idioma de la interfaz
- **Country**: País
- **Load demo data**: Desmarcar para ambiente limpio (recomendado)

El proceso de creación tarda aproximadamente 60 segundos.

## Estructura del Proyecto

### Estructura Completa Esperada

Esta es la estructura que verás después de clonar el repositorio y ejecutar `docker compose up -d`:

```
odoo18-docker/
├── docker-compose.yml          # Configuración de servicios Docker
├── .env.example                # Plantilla de variables de entorno (público)
├── .env                        # Variables locales (privado, creado con: cp .env.example .env)
├── .gitignore                  # Archivos ignorados por Git
├── README.md                   # Este archivo
│
├── addons/                     # Módulos personalizados de Odoo
│   └── .gitkeep                # Placeholder para mantener la estructura
│
├── postgres_data/              # Base de datos PostgreSQL (creado automáticamente por Docker)
│   └── (archivos de BD)        # NO versionado en Git
│
├── odoo_filestore/             # Archivos subidos por usuarios (creado automáticamente por Docker)
│   └── (archivos subidos)      # NO versionado en Git
│
└── odoo_sessions/              # Información de sesiones (creado automáticamente por Docker)
    └── (datos temporales)      # NO versionado en Git
```

### Explicación de Carpetas

**Versionadas en Git:**
- `addons/` - Contiene tus módulos de Odoo personalizados. Esta carpeta y su contenido están versionados porque representan el código que escribes.

**Generadas Automáticamente por Docker:**
- `postgres_data/` - Se crea al iniciar el contenedor de PostgreSQL. Almacena la base de datos. No se versiona porque contiene datos locales.
- `odoo_filestore/` - Se crea al iniciar Odoo. Almacena archivos que los usuarios suben. No se versiona porque es contenido generado en tiempo de ejecución.
- `odoo_sessions/` - Se crea al iniciar Odoo. Almacena información temporal de sesiones activas. No se versiona porque cambia constantemente.

**Archivo .env:**
- Se crea localmente desde `.env.example` ejecutando `cp .env.example .env`
- Contiene contraseñas y configuración local
- No se versiona en Git (está en `.gitignore`)

## Gestión de Servicios

### Ver Logs en Tiempo Real

```bash
docker compose logs -f odoo      # Logs de Odoo
docker compose logs -f db        # Logs de PostgreSQL
docker compose logs -f           # Todos los logs
```

Presiona `Ctrl+C` para salir del seguimiento de logs. Útil para debugging y monitoreo de errores.

### Reiniciar Servicios

```bash
docker compose restart odoo      # Reinicia solo Odoo
docker compose restart db        # Reinicia solo PostgreSQL
docker compose restart           # Reinicia todos los servicios
```

Reinicia Odoo cuando realices cambios en código Python de tus módulos. Los cambios en XML se detectan automáticamente en modo desarrollo.

### Detener Servicios

```bash
docker compose stop              # Detiene sin eliminar contenedores (datos persistentes)
docker compose start             # Reinicia servicios detenidos
```

Los datos en `postgres_data/` se preservan entre paradas y arranques.

### Eliminar Servicios

```bash
docker compose down              # Elimina contenedores pero preserva volúmenes
docker compose down -v           # Elimina contenedores Y volúmenes (PÉRDIDA IRREVERSIBLE DE DATOS)
```

Usa `down -v` solo cuando necesites limpiar completamente el ambiente.

## Acceso a Contenedores

### Terminal Interactiva en Odoo

```bash
docker compose exec odoo bash
```

Abre una terminal bash dentro del contenedor de Odoo. Útil para inspeccionar archivos, instalar dependencias o ejecutar comandos específicos.

### Ejecutar Comandos Puntuales

```bash
docker compose exec odoo python3 -V
docker compose exec odoo pip list
```

Ejecuta comandos sin necesidad de acceso interactivo.

### Acceso a PostgreSQL

```bash
docker compose exec db psql -U odoo -d postgres -c "\l"
```

Lista todas las bases de datos creadas en Odoo. `psql` es la herramienta de línea de comandos de PostgreSQL integrada en el contenedor.

## Configuración del docker-compose.yml

El archivo define dos servicios:

**PostgreSQL (db)**: Base de datos relacional. Expone el puerto 5432 localmente. El volumen `./postgres_data` persiste los datos entre sesiones. El healthcheck asegura que PostgreSQL esté listo antes de que Odoo intente conectarse.

**Odoo (odoo)**: Servidor de aplicación. Expone el puerto configurado en `.env` (por defecto 8069). El comando incluye `--dev xml,reload,qweb` para desarrollo rápido sin necesidad de reiniciar el servidor para cambios en XML. El volumen `./addons` mapea módulos personalizados ubicados localmente dentro del contenedor.

La red `odoo-network` permite comunicación entre servicios usando nombres de servicio como hostnames (Odoo se conecta a `db` como hostname).

## Notas de Desarrollo

El parámetro `--dev xml,reload,qweb` en el comando de Odoo habilita modo desarrollo. Los cambios en archivos XML (vistas) se detectan automáticamente al refrescar el navegador. Los cambios en código Python requieren reinicio del servicio.

El archivo `.env` nunca debe ser versionado en Git. El archivo `.env.example` proporciona la plantilla. Cada desarrollador crea su propio `.env` desde la plantilla según sus requisitos locales.

## Troubleshooting

**PostgreSQL muestra "unhealthy" después de 30 segundos**: Incrementa el tiempo de espera o verifica logs con `docker-compose logs db`. La inicialización puede tardar más en sistemas lentos.

**Puerto 8069 ya en uso**: Cambia `ODOO_PORT` en `.env` a un puerto disponible y accede a través del nuevo puerto.

**Módulos no aparecen en Aplicaciones**: Ejecuta "Actualizar Lista de Aplicaciones" en la interfaz de Odoo. Si persiste, reinicia con `docker-compose restart odoo`.

**Cambios en XML no se reflejan**: Realiza refresco de navegador con `Ctrl+Shift+R` (hard refresh). Si la página aún muestra caché, reinicia Odoo.

**Docker daemon no accesible**: En Windows/macOS, abre Docker Desktop. En Linux, ejecuta `sudo systemctl start docker`.

## Referencias

Documentación oficial de Odoo: https://www.odoo.com/documentation/18.0/

Documentación de Docker: https://docs.docker.com/