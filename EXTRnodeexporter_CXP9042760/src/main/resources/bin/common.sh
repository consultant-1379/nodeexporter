#!/bin/bash

getInternalIP() {
    INTERNAL_IP=$(cat /etc/hosts  | awk -v hostname=$(hostname) '{if (($2 == hostname) && ($0 ~ /Created by LITP/)) {print $1}}')

    if [ -z "${INTERNAL_IP}" ] ; then
        echo "WARN: Coud not get internal IP address, defaulting to 127.0.0.1"
        INTERNAL_IP="127.0.0.1"
    fi
}
