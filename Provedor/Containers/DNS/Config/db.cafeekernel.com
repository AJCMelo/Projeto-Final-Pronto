$TTL    300

@   IN  SOA ns.cafeekernel.com. admin.cafeekernel.com. (
            2025073101  ; Serial
            3600        ; Refresh
            1800        ; Retry
            1209600     ; Expire
            86400 )     ; Negative Cache TTL

@       IN  NS  ns.cafeekernel.com.
@       IN  A   192.168.0.2
ns      IN  A   192.168.0.2

www     IN  A   192.168.0.2
portal  IN  A   192.168.0.2
proxy   IN  CNAME www

; E-mail do provedor
mail    IN  A   192.168.0.2
webmail IN  A   192.168.0.2
@       IN  MX  10 mail.cafeekernel.com.