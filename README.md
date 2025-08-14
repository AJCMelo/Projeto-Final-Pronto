# Projeto-Final — Provedor + Clientes (C1/C2/C3)

Infraestrutura dockerizada multi-tenant para hospedar WordPress de três clientes sob /cms, com TLS na borda (HAProxy no Provedor), proxies internos por cliente e DNS autoritativo (BIND).

## Domínios e serviços

| Papel     | Domínio público            | Proxy reverso (container)| CMS (container)    | DB (container)     |
| --------- | -------------------------- | ------------------------ | ------------------- | --------------    |
| Provedor  | www.cafeekernel.com        |  proxy (HAProxy)         | — (portal estático) | —                 |
| Cliente 1 | www.bolachaekernel.com     |  c1-proxy (NGINX)        |  c1-wp              |   c1-db           |
| Cliente 2 | www.chaekernel.com         |  c2-proxy (Apache httpd) |  c2-wp              |   c2-db           |
| Cliente 3 | www.bolachacombiscoito.com |  c3-proxy (NGINX)        |  c3-wp              |   c3-db           |

> Todos os CMS são WordPress e atendem em /cms.

## Redes Docker

Externa: kernelenet (bridge, externa) — onde ficam proxy (HAProxy), dns, acme e os proxies internos c1-proxy, c2-proxy, c3-proxy.
Internas: c1_net, c2_net, c3_net (isolam cada stack de cliente).


## Estrutura de pastas

```
Projeto-Final/
├── compose.yaml
├── tmp_net.txt
├── Provedor/
│   └── Containers/
│       ├── DNS/
│       │   ├── Dockerfile
│       │   └── Config/
│       │       ├── db.cafeekernel.com
│       │       ├── db.bolachaekernel.com
│       │       ├── db.chaekernel.com
│       │       ├── db.bolachacombiscoito.com
│       │       └── named.conf.local
│       ├── PROXY/
│       │   ├── Dockerfile
│       │   ├── Config/
│       │   │   └── haproxy.cfg
│       │   ├── acme/
│       │   ├── certs/           (pem + crt-list.txt)
│       │   └── static/
│       │       └── portal.html
│       └── letsencrypt/
│           ├── etc/
│           ├── lib/
│           └── log/
└── Clientes/
    ├── C1/
    │   ├── compose.yaml
    │   └── Containers/
    │       └── PROXY/
    │           ├── Dockerfile
    │           ├── conf/
    │           │   ├── nginx.conf
    │           │   └── site.conf
    │           └── portal/
    ├── C2/
    │   ├── compose.yaml
    │   └── Containers/
    │       └── PROXY/
    │           ├── Dockerfile
    │           ├── conf/
    │           │   ├── httpd.conf
    │           │   └── vhost.conf
    │           └── portal/
    └── C3/
        ├── compose.yaml
        └── Containers/
            └── PROXY/
                ├── Dockerfile
                ├── config/
                │   ├── nginx.conf
                │   └── default.conf
                └── portal/
```


## Dockerfiles 

### PROVEDOR — PROXY (HAProxy)

Dockerfile
FROM haproxy:2.9-alpine

# config e certs serão montados por volume

### PROVEDOR — DNS (BIND)

Dockerfile
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y bind9 dnsutils && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 53/tcp 53/udp

# named.conf (principal) do pacote já inclui named.conf.local
CMD ["/usr/sbin/named", "-g", "-c", "/etc/bind/named.conf", "-u", "bind"]


## Provedor (borda)

* dns (BIND autoritativo) — monta `Provedor/Containers/DNS/Config/*.db` e `named.conf.local`.
* acme (NGINX webroot) — serve `/.well-known/acme-challenge/` de `Provedor/Containers/PROXY/acme`.
* proxy (HAProxy) — termina TLS, rate-limit com exceções (ACME e `/cms/wp-{login,admin}`), ACLs por host e encaminha para `c1-proxy`, `c2-proxy`, `c3-proxy`.
* certbot — emitir/renovar certificados e exportar `.pem` para `Provedor/Containers/PROXY/certs`.

### HAProxy (resumo)

* TLS + alpn h2,http/1.1, ciphers fortes.
* HTTP→HTTPS (exceto ACME).
* ACL por host:

* .bolachaekernel.com → c1-proxy:80
* .chaekernel.com → c2-proxy:80
* .bolachacombiscoito.com → c3-proxy:80
* provedor (cafeekernel.com, www, portal) → portal estático.
* Security headers (HSTS, X-CTO, X-Frame-Options, Referrer-Policy). CSP só no portal do provedor.

## DNS (Zonas)

* db.cafeekernel.com — inclui MX mail.cafeekernel.com e webmail.
* db.bolachaekernel.com
* db.chaekernel.com
* db.bolachacombiscoito.com

> Todas apontam A para 192.168.0.2 (edge HAProxy). Ajuste conforme sua borda.

## Clientes (resumo)

### C1 — www.bolachaekernel.com (NGINX)

* c1-db (MariaDB 11) — c1_wp
* c1-wp (WordPress 6 Apache) — WP_HOME/WP_SITEURL = https://www.bolachaekernel.com/cms
* c1-proxy (NGINX) — /portal/ estático; /cms/* → c1-wp

### C2 — www.chaekernel.com (Apache)

* c2-db — c2_wp
* c2-wp — WP_HOME/WP_SITEURL = https://www.chaekernel.com/cms
* c2-proxy (httpd) — ProxyPassMatch ^/cms/(.*)$ http://c2-wp/$1, correções de Location, ProxyPassReverseCookiePath/Domain

### C3 — www.bolachacombiscoito.com (NGINX)

* c3-db — c3_wp
* c3-wp — WP_HOME/WP_SITEURL = https://www.bolachacombiscoito.com/cms
* c3-proxy (NGINX) — /portal/; /cms/ → c3-wp


## Subida do ambiente

bash
# 1) rede externa
docker network create --driver bridge kernelenet || true

# 2) provedor (na RAIZ do projeto)
docker compose up -d dns acme proxy

# 3) clientes
cd Clientes/C1 && docker compose up -d && cd ../..
cd Clientes/C2 && docker compose up -d && cd ../..
cd Clientes/C3 && docker compose up -d && cd ../..


Testes rápidos:

bash
# backends
docker exec -it c1-proxy sh -lc nginx -t && nginx -s reload && wget -S -O- http://c1-wp/wp-login.php | sed -n "1,20p"
docker exec -it c2-proxy sh -lc httpd -t && wget -S -O- http://c2-wp/wp-login.php | sed -n "1,20p"
docker exec -it c3-proxy sh -lc nginx -t && nginx -s reload && wget -S -O- http://c3-wp/wp-login.php | sed -n "1,20p"

---

## WordPress — instalação

* C1: https://www.bolachaekernel.com/cms/wp-admin/install.php
* C2: https://www.chaekernel.com/cms/wp-admin/install.php
* C3: https://www.bolachacombiscoito.com/cms/wp-admin/install.php

---

## Licença

Uso interno.
