FROM telegraf:1.29

COPY ./mibs/aruba ./mibs/standard /usr/share/snmp/mibs/

COPY \
    ./telegraf.conf \
    ./transform.star \
    /etc/telegraf/

ENV \
    SNMP_HOST=127.0.0.1 \
    SNMP_PORT=161 \
    SNMP_COMMUNITY=public \
    MIBS=ALL

CMD ["/usr/bin/telegraf", "--config", "/etc/telegraf/telegraf.conf"]
