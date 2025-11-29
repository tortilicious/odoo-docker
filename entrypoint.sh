#!/bin/bash
set -e

# Esperar a que PostgreSQL esté listo
until pg_isready -h db -U ${POSTGRES_USER} -d ${POSTGRES_DB}; do
  echo "Esperando a PostgreSQL..."
  sleep 2
done

# Verificar si la base de datos ya tiene tablas de Odoo
TABLE_COUNT=$(PGPASSWORD=${POSTGRES_PASSWORD} psql -h db -U ${POSTGRES_USER} -d ${POSTGRES_DB} -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")

if [ "$TABLE_COUNT" -eq "0" ]; then
  echo "Base de datos vacía. Inicializando Odoo con módulo base..."
  odoo --db_host=db \
       --db_user=${POSTGRES_USER} \
       --db_password=${POSTGRES_PASSWORD} \
       --database=${POSTGRES_DB} \
       --addons-path=/usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons \
       -i base \
       --stop-after-init \
       --without-demo=all

  echo "Configurando credenciales del administrador..."

  # Actualizar email y contraseña del usuario admin usando SQL
  # Odoo almacena las contraseñas hasheadas, así que usamos la función de Odoo para esto
  PGPASSWORD=${POSTGRES_PASSWORD} psql -h db -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c \
    "UPDATE res_users SET login='${ODOO_ADMIN_EMAIL}' WHERE id=2;"

  # Para la contraseña, necesitamos ejecutar un comando de Odoo porque usa hashing
  odoo shell --db_host=db \
             --db_user=${POSTGRES_USER} \
             --db_password=${POSTGRES_PASSWORD} \
             --database=${POSTGRES_DB} \
             --addons-path=/usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons \
             --no-http \
             -c /dev/null <<EOF
env['res.users'].browse(2).write({'password': '${ODOO_ADMIN_PASSWORD}'})
env.cr.commit()
EOF

  echo "Inicialización completada. Usuario: ${ODOO_ADMIN_EMAIL}"
fi

# Arrancar Odoo normalmente
exec odoo --db_host=db \
          --db_user=${POSTGRES_USER} \
          --db_password=${POSTGRES_PASSWORD} \
          --database=${POSTGRES_DB} \
          --addons-path=/usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons \
          --dev=xml,reload,qweb