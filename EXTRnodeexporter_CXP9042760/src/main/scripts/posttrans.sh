#!/bin/bash

for SERVICE in node-exporter-consul node-exporter  ; do
    if [ -r /usr/lib/systemd/system/${SERVICE}.service ] ; then
        systemctl enable ${SERVICE}
    fi
done

if [ -r /usr/lib/systemd/system/node-exporter.service ] ; then
    systemctl start node-exporter
fi

exit 0
