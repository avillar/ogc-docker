user nginx;
worker_processes  auto;

error_log  /dev/stderr notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /dev/stdout  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    server {
        listen 80;
        server_name localhost;

        location ~ ^/(static|media)/ {
            root /var/django;
        }

        location =/robots.txt {
            root /var/django/static/;
        }

        location =/favicon.ico {
            root /var/django/static/;
        }

        ##LOCATIONS_MARKER##

        location / {
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_pass http://django:80;
            add_header Access-Control-Max-Age '1000';
            add_header Access-Control-Allow-Headers 'x-requested-with, Content-Type, origin, authorization, accept, client-security-token';
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }
}