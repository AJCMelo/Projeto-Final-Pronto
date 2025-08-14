FROM nginx:alpine
# Conf principal e vhost
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/default.conf /etc/nginx/conf.d/default.conf
# Portal estático
COPY portal/ /usr/share/nginx/html/
