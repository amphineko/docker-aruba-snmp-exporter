FROM telegraf:1.29

COPY ./mibs/aruba ./mibs/standard /usr/share/snmp/mibs/

CMD ["/usr/bin/telegraf", "--config", "/etc/telegraf/telegraf.conf"]
