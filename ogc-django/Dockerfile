FROM python:3.9-alpine

ARG PROJECT_NAME=ogc
ARG WITH_NGINX=1
ENV SUPERUSER admin
ENV SUPERUSER_EMAIL admin@ogc.org
ENV SUPERUSER_PASSWORD ogc
ENV DJANGO_DEBUG False
ENV DJANGO_URIREDIRECT_ALTR_BASETEMPLATE "'vocprez.html'"
ENV DJANGO_ALLOWED_HOSTS "['*',]"
ENV DJANGO_SMUGGLER_FIXTURE_DIR "'/app/initial-data'"
ENV DJANGO_STATIC_ROOT "os.path.join(BASE_DIR, 'static')"

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PIP_ROOT_USER_ACTION ignore
ENV PROJECT_NAME ${PROJECT_NAME}
ENV DJANGO_PATH "/app/django/${PROJECT_NAME}"
ENV WITH_NGINX ${WITH_NGINX}

WORKDIR /app/django
COPY requirements.txt /app/
RUN apk update && \
    ( [ "${WITH_NGINX}" = "1" -o "${WITH_NGINX}" = "true" ] && apk add nginx git || apk add git ) && \
    pip install --upgrade pip && \
    pip install -r /app/requirements.txt && \
    django-admin startproject "${PROJECT_NAME}" . && \
    mkdir -p static /app/resources /etc/nginx/http.d/ && \
    rm -f /etc/nginx/http.d/*.conf

COPY docker-entrypoint.sh settings-append.py django-modules.json install-modules.py /app/
COPY nginx.conf /etc/nginx/http.d/default.conf
RUN cat /app/settings-append.py >> "${PROJECT_NAME}/settings.py" && \
    cp "${PROJECT_NAME}/urls.py" /app/urls-base.py &&\
    cp "${PROJECT_NAME}/settings.py" /app/settings-base.py &&\
    chmod +x /app/docker-entrypoint.sh

VOLUME /app/django

EXPOSE 80

ENTRYPOINT ["/app/docker-entrypoint.sh"]

CMD []