#!/bin/sh

mkdir -p $(echo ${DJANGO_SMUGGLER_FIXTURE_DIR} | sed -r "s@^'|'\$@@g")

# Migrations
python manage.py makemigrations --noinput
python manage.py migrate --noinput

# Create superuser
cat <<EOF | python manage.py shell >/dev/null 2>&1 && echo "Superuser ${SUPERUSER} created" || echo "User ${SUPERUSER} already exists, not creating"
from django.contrib.auth import get_user_model
User = get_user_model()
User.objects.create_superuser('${SUPERUSER}', '${SUPERUSER_EMAIL}', '${SUPERUSER_PASSWORD}')
EOF

# Update settings
export SETTINGS_FILE="/app/settings-base.py"
for CONFVAR in DEBUG URIREDIRECT_ALTR_BASETEMPLATE SMUGGLER_FIXTURE_DIR STATIC_ROOT ALLOWED_HOSTS ; do
  VARNAME="DJANGO_${CONFVAR}"
  eval CONFVALUE="\$${VARNAME}"
  if [ -n "${CONFVALUE}" ]; then
    echo "Setting configuration ${CONFVAR} = ${CONFVALUE}"
    grep -q ^${CONFVAR} "${SETTINGS_FILE}" \
      && sed -r "s/^${CONFVAR}\s+=.*/${CONFVAR} = ${CONFVALUE}/" -i "${SETTINGS_FILE}" \
      || echo "${CONFVAR} = ${CONFVALUE}" >> "${SETTINGS_FILE}"
  fi
done

python /app/install-modules.py

if [ -f "/app/installed-modules" ]; then
  python manage.py makemigrations --noinput
  python manage.py migrate --noinput
  rm /app/installed-modules
fi

yes yes | python manage.py collectstatic

if [ "${WITH_NGINX}" = "1" -o "${WITH_NGINX}" = "true" ]; then
  gunicorn --bind unix:/run/gunicorn.sock --access-logfile - "${PROJECT_NAME}.wsgi:application" --daemon
  CMD="nginx -g 'daemon off;'"
else
  CMD="gunicorn --bind 0.0.0.0:80 --access-logfile - ${PROJECT_NAME}.wsgi:application"
fi

if [ $# -gt 0 ]; then
  exec "$@"
else
  exec $CMD
fi