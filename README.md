# Odoo + PostgreSQL Docker Setup

Setup de desarrollo local para Odoo 18 con PostgreSQL usando Docker Compose.

## Requisitos Previos

Docker versión 20.10+ y Docker Compose versión 1.29+ deben estar instalados en el sistema. Verifica la instalación ejecutando:

```bash
docker --version
docker compose version
```

## Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/tortilicious/odoo-docker.git
cd odoo-docker
```

### 2. Configurar Variables de Entorno

Copia el archivo de plantilla y personaliza según sea necesario:

```bash
cp .env.example .env
```

El archivo `.env` contiene las siguientes variables de configuración:

```env
# Configuración de imágenes Docker
ODOO_IMAGE=odoo:18
POSTGRES_IMAGE=postgres:17

# Nombres de contenedores
ODOO_CONTAINER_NAME=odoo-18
POSTGRES_CONTAINER_NAME=postgres-17

# Configuración de PostgreSQL
POSTGRES_DB=odoo
POSTGRES_USER=odoo
POSTGRES_PASSWORD=odoo

# Configuración de Odoo
ODOO_PORT=8069
ODOO_ADMIN_EMAIL=admin@ejemplo.com
ODOO_ADMIN_PASSWORD=admin
```

Las variables `ODOO_IMAGE` y `POSTGRES_IMAGE` definen qué versiones de las imágenes Docker se utilizarán. Esto facilita actualizar las versiones en el futuro sin modificar el archivo `docker-compose.yml`. Las variables `ODOO_CONTAINER_NAME` y `POSTGRES_CONTAINER_NAME` permiten personalizar los nombres de los contenedores para identificarlos fácilmente.

La variable `POSTGRES_DB` define el nombre de la base de datos que se creará e inicializará automáticamente. Esta misma base de datos será utilizada por Odoo para almacenar todos los datos de la aplicación.

Las variables `ODOO_ADMIN_EMAIL` y `ODOO_ADMIN_PASSWORD` permiten configurar las credenciales del usuario administrador que se creará durante la inicialización. Estas credenciales serán las que uses para acceder a Odoo por primera vez. Se recomienda cambiar los valores por defecto, especialmente la contraseña, por valores más seguros antes de levantar los servicios por primera vez.

### 3. Dar Permisos al Script de Inicialización

El proyecto incluye un script `entrypoint.sh` que automatiza la inicialización de la base de datos y la configuración del usuario administrador. Antes de levantar los servicios por primera vez, asegúrate de que tenga permisos de ejecución:

```bash
chmod +x entrypoint.sh
```

### 4. Levantar los Servicios

```bash
docker compose up -d
```

Este comando levanta PostgreSQL y Odoo en segundo plano. Durante la primera ejecución ocurre una secuencia de inicialización automática: Docker descarga las imágenes necesarias, PostgreSQL se inicializa y crea la base de datos vacía definida en `POSTGRES_DB`, el script `entrypoint.sh` detecta que la base de datos está vacía e instala el módulo base de Odoo (esto tarda aproximadamente 60 segundos), el script configura las credenciales del administrador usando los valores de `ODOO_ADMIN_EMAIL` y `ODOO_ADMIN_PASSWORD`, y finalmente Odoo arranca configurado para usar esa base de datos.

En ejecuciones posteriores, el script detecta que la base de datos ya contiene tablas y salta directamente a arrancar Odoo, haciendo el inicio mucho más rápido.

### 5. Verificar Estado de los Servicios

```bash
docker compose ps
```

Deberías ver ambos contenedores corriendo con los nombres definidos en las variables de entorno. El estado "healthy" en PostgreSQL indica que la base de datos está lista.

Para ver el progreso de la inicialización en la primera ejecución, puedes seguir los logs en tiempo real:

```bash
docker compose logs -f odoo
```

Verás mensajes indicando "Base de datos vacía. Inicializando Odoo con módulo base..." seguido de la instalación de módulos, luego "Configurando credenciales del administrador..." y finalmente "Inicialización completada. Usuario: admin@ejemplo.com". Una vez completado, verás "HTTP service (werkzeug) running" indicando que Odoo está listo.

### 6. Acceder a Odoo

Una vez que Odoo esté listo, accede a `http://localhost:8069` en tu navegador (o el puerto que hayas configurado en `ODOO_PORT`). Como la base de datos ya fue creada e inicializada automáticamente, Odoo te mostrará directamente la pantalla de login.

Usa las credenciales que configuraste en el archivo `.env`:

- **Email**: El valor de `ODOO_ADMIN_EMAIL` (por defecto: admin@ejemplo.com)
- **Password**: El valor de `ODOO_ADMIN_PASSWORD` (por defecto: admin)

## Estructura del Proyecto

```
odoo18-docker/
├── docker-compose.yml          # Configuración de servicios Docker
├── entrypoint.sh               # Script de inicialización automática
├── .env.example                # Plantilla de variables de entorno (público)
├── .env                        # Variables locales (privado, no versionado)
├── .gitignore                  # Archivos ignorados por Git
├── README.md                   # Este archivo
│
└── addons/                     # Módulos personalizados de Odoo
    └── placeholder_module/     # Módulo mínimo para validar el directorio
        ├── __init__.py
        └── __manifest__.py
```

### Script de Inicialización (entrypoint.sh)

El archivo `entrypoint.sh` es un script de bash que automatiza la configuración inicial de Odoo. Su funcionamiento es el siguiente: primero espera a que PostgreSQL esté completamente disponible, luego verifica si la base de datos contiene tablas. Si la base de datos está vacía (primera ejecución), ejecuta Odoo con el flag `-i base` para instalar el módulo base y todas sus dependencias. Después de la instalación, el script actualiza el email del usuario administrador mediante una consulta SQL y configura la contraseña usando el shell interactivo de Odoo (ya que las contraseñas se almacenan hasheadas). Si la base de datos ya tiene tablas (ejecuciones posteriores), salta la inicialización y arranca Odoo directamente.

Este enfoque permite una experiencia de "un solo comando" donde ejecutas `docker compose up` y todo se configura automáticamente, incluyendo las credenciales del administrador, sin necesidad de pasos manuales adicionales.

### Carpeta addons

La carpeta `addons/` contiene tus módulos de Odoo personalizados. Aquí crearás módulos como `estate/` siguiendo el tutorial de Odoo.

El `placeholder_module` es un módulo mínimo que existe porque Odoo valida que cada ruta en `--addons-path` sea un directorio de addons válido. Un directorio vacío causa el error "not a valid addons directory". Este módulo tiene `'installable': False` para que no aparezca en la lista de aplicaciones. Puedes eliminarlo una vez que tengas al menos un módulo real en la carpeta `addons/`.

### Volúmenes de Docker

Los datos de PostgreSQL y Odoo se almacenan en volúmenes nombrados de Docker, no en carpetas locales del proyecto. Esto evita problemas de permisos entre tu usuario de Linux y los usuarios internos de los contenedores. Los volúmenes se almacenan en `/var/lib/docker/volumes/` y persisten entre reinicios.

Para ver los volúmenes creados:

```bash
docker volume ls
```

Para inspeccionar la ubicación física de un volumen:

```bash
docker volume inspect odoo18-docker_postgres_data
docker volume inspect odoo18-docker_odoo_data
```

## Gestión de Servicios

### Ver Logs en Tiempo Real

Cuando levantas los servicios en modo detached (`-d`), puedes ver los logs con el comando `docker compose logs`. Añade el flag `-f` para seguir los logs en tiempo real:

```bash
docker compose logs -f           # Todos los logs
docker compose logs -f odoo      # Solo logs de Odoo
docker compose logs -f db        # Solo logs de PostgreSQL
```

Presiona `Ctrl+C` para dejar de seguir los logs. Los contenedores siguen corriendo en segundo plano.

### Reiniciar Servicios

```bash
docker compose restart odoo      # Reinicia solo Odoo
docker compose restart db        # Reinicia solo PostgreSQL
docker compose restart           # Reinicia todos los servicios
```

Reinicia Odoo cuando realices cambios en código Python de tus módulos. Los cambios en XML se detectan automáticamente en modo desarrollo.

### Detener Servicios

```bash
docker compose stop              # Detiene sin eliminar contenedores
docker compose start             # Reinicia servicios detenidos
```

### Eliminar Servicios

```bash
docker compose down              # Elimina contenedores pero preserva volúmenes
docker compose down -v           # Elimina contenedores Y volúmenes (PÉRDIDA DE DATOS)
```

Usa `down -v` solo cuando necesites limpiar completamente el ambiente y empezar desde cero. Esto eliminará la base de datos y todos los datos de Odoo, y la próxima vez que levantes los servicios se ejecutará nuevamente la inicialización automática con las credenciales definidas en `.env`.

## Acceso a Contenedores

### Terminal Interactiva en Odoo

```bash
docker compose exec odoo bash
```

Abre una terminal bash dentro del contenedor de Odoo.

### Acceso a PostgreSQL

Para listar todas las bases de datos:

```bash
docker compose exec db psql -U odoo -d postgres -c "\l"
```

Para conectarte a la base de datos de Odoo y ejecutar consultas:

```bash
docker compose exec db psql -U odoo -d odoo
```

Una vez dentro de psql, puedes ejecutar comandos SQL o usar comandos especiales como `\dt` para listar tablas o `\q` para salir.

## Configuración Técnica

### docker-compose.yml

El archivo define dos servicios que trabajan juntos. Las imágenes y nombres de contenedores se configuran mediante variables de entorno, lo que facilita actualizar versiones sin modificar el archivo de configuración.

**PostgreSQL (db)** es la base de datos relacional. Usa la imagen definida en `POSTGRES_IMAGE` y el nombre de contenedor en `POSTGRES_CONTAINER_NAME`. Expone el puerto 5432 localmente para que puedas conectarte con herramientas externas si lo necesitas. La variable `POSTGRES_DB` hace que PostgreSQL cree automáticamente esa base de datos durante la inicialización. El healthcheck verifica no solo que PostgreSQL esté corriendo, sino que la base de datos específica exista y esté accesible.

**Odoo (odoo)** es el servidor de aplicación. Usa la imagen definida en `ODOO_IMAGE` y el nombre de contenedor en `ODOO_CONTAINER_NAME`. En lugar de usar el comando por defecto de la imagen, utiliza el script `entrypoint.sh` que maneja la inicialización automática y la configuración de credenciales del administrador. Las variables `ODOO_ADMIN_EMAIL` y `ODOO_ADMIN_PASSWORD` se pasan al contenedor para que el script pueda configurar el usuario administrador. El volumen `./addons` mapea tus módulos personalizados dentro del contenedor.

La red `odoo-network` permite que los servicios se comuniquen entre sí usando nombres de servicio como hostnames. Odoo se conecta a PostgreSQL usando `db` como hostname.

### Modo Desarrollo

El parámetro `--dev=xml,reload,qweb` habilita características útiles para desarrollo. Los cambios en archivos XML (vistas) se detectan automáticamente al refrescar el navegador, lo que acelera significativamente el ciclo de desarrollo cuando trabajas en la interfaz de usuario. Los cambios en código Python siguen requiriendo reinicio del servicio con `docker compose restart odoo`.

## Actualizar Versiones

Para actualizar la versión de Odoo o PostgreSQL, simplemente modifica las variables correspondientes en el archivo `.env`:

```env
ODOO_IMAGE=odoo:19
POSTGRES_IMAGE=postgres:18
ODOO_CONTAINER_NAME=odoo-19
POSTGRES_CONTAINER_NAME=postgres-18
```

Luego recrea los contenedores:

```bash
docker compose down
docker compose up -d
```

Ten en cuenta que cambiar la versión de PostgreSQL puede requerir una migración de datos si hay cambios incompatibles entre versiones mayores.

## Troubleshooting

**La inicialización tarda mucho en la primera ejecución**: Es normal que la primera ejecución tarde 60-90 segundos mientras Odoo instala el módulo base y configura las credenciales del administrador. Puedes ver el progreso con `docker compose logs -f odoo`.

**PostgreSQL muestra "unhealthy" después de 30 segundos**: Esto puede ocurrir en la primera ejecución si la inicialización tarda más de lo esperado. Verifica los logs con `docker compose logs db` para ver el progreso. Generalmente se resuelve esperando unos segundos adicionales.

**Puerto 8069 ya en uso**: Otro servicio está usando ese puerto. Cambia `ODOO_PORT` en `.env` a un puerto disponible (por ejemplo 8070) y accede a través del nuevo puerto.

**Módulos no aparecen en Aplicaciones**: Primero activa el modo desarrollador en Odoo (Ajustes > Activar el modo desarrollador), luego ve a Aplicaciones y haz clic en "Actualizar Lista de Aplicaciones".

**Cambios en XML no se reflejan**: Realiza un hard refresh en el navegador con `Ctrl+Shift+R` para evitar la caché. Si persiste, reinicia Odoo con `docker compose restart odoo`.

**Error "not a valid addons directory"**: La carpeta `addons` debe contener al menos un módulo válido de Odoo (una carpeta con `__manifest__.py`). Asegúrate de que el `placeholder_module` existe o que tienes tu propio módulo creado.

**Error "permission denied" en entrypoint.sh**: Asegúrate de dar permisos de ejecución al script con `chmod +x entrypoint.sh` antes de levantar los servicios.

**Las credenciales no funcionan**: Las credenciales de `ODOO_ADMIN_EMAIL` y `ODOO_ADMIN_PASSWORD` solo se aplican durante la primera inicialización. Si ya habías inicializado la base de datos antes de configurar estas variables, necesitas empezar desde cero con `docker compose down -v` y luego `docker compose up -d`.

**Quiero cambiar las credenciales del administrador**: Si la base de datos ya está inicializada, puedes cambiar las credenciales desde la interfaz de Odoo (Mi Perfil > Cambiar contraseña). Si prefieres empezar desde cero con nuevas credenciales, actualiza los valores en `.env`, ejecuta `docker compose down -v` para eliminar los datos existentes, y luego `docker compose up -d` para crear todo nuevamente con las nuevas credenciales.

## Referencias

- Documentación oficial de Odoo: https://www.odoo.com/documentation/18.0/
- Documentación de Docker: https://docs.docker.com/