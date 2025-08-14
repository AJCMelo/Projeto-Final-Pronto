$TTL   300

@   IN  SOA ns.bolachaekernel.com. admin.bolachaekernel.com. (
            2025073101
            3600
            1800
            1209600
            86400 )

@       IN  NS  ns.bolachaekernel.com.
@       IN  A   192.168.0.2
ns      IN  A   192.168.0.2

www     IN  A   192.168.0.2
portal  IN  A   192.168.0.2
hotsite IN  A   192.168.0.2
sign    IN  A   192.168.0.2
proxy   IN  CNAME www
; (opcional) wildcard para laboratório:
;*      IN  A   192.168.0.2