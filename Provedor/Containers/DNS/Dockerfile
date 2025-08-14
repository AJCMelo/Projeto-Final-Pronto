FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y bind9 dnsutils && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 53/tcp 53/udp

# named.conf (principal) do pacote já inclui named.conf.local
CMD ["/usr/sbin/named", "-g", "-c", "/etc/bind/named.conf", "-u", "bind"]
