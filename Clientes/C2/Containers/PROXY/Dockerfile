FROM httpd:2.4-alpine

# Habilita módulos necessários (proxy, headers, rewrite, etc.) e garante o MPM
RUN sed -i 's/^#\s*LoadModule proxy_module/LoadModule proxy_module/' /usr/local/apache2/conf/httpd.conf && \
    sed -i 's/^#\s*LoadModule proxy_http_module/LoadModule proxy_http_module/' /usr/local/apache2/conf/httpd.conf && \
    sed -i 's/^#\s*LoadModule headers_module/LoadModule headers_module/' /usr/local/apache2/conf/httpd.conf && \
    sed -i 's/^#\s*LoadModule rewrite_module/LoadModule rewrite_module/' /usr/local/apache2/conf/httpd.conf && \
    # Garante que algum MPM esteja carregado (event é o padrão no Alpine)
    grep -q "LoadModule mpm_event_module" /usr/local/apache2/conf/httpd.conf || \
    echo "LoadModule mpm_event_module modules/mod_mpm_event.so" >> /usr/local/apache2/conf/httpd.conf

# Sobrescreve conf principal e vhosts
# (garantindo que seu httpd.conf customizado não apague o MPM — inclua a linha nele também)
COPY conf/httpd.conf /usr/local/apache2/conf/httpd.conf
COPY conf/vhost.conf /usr/local/apache2/conf/extra/httpd-vhosts.conf

# Portal estático
COPY portal/ /usr/local/apache2/htdocs/
