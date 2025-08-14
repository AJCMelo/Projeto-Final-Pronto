$TTL    300

@   IN  SOA ns.bolachacombiscoito.com. admin.bolachacombiscoito.com. (
            2025073101
            3600
            1800
            1209600
            86400 )

@       IN  NS  ns.bolachacombiscoito.com.
@       IN  A   192.168.0.2
ns      IN  A   192.168.0.2

www     IN  A   192.168.0.2
portal  IN  A   192.168.0.2
cms     IN  A   192.168.0.2
proxy   IN  CNAME www
;*      IN  A   192.168.0.2