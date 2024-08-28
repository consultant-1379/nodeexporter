#!/bin/bash

BIN_DIR=$(dirname $0)
. ${BIN_DIR}/common.sh

getNodeType() {
    NODE_TYPE="other"
    if [ -x /usr/bin/litp ] ; then
        NODE_TYPE="lms"
    elif [ -r /etc/VRTSvcs/conf/config/main.cf ] ; then
        NODE_TYPE=$(egrep '^cluster ' /etc/VRTSvcs/conf/config/main.cf | awk '{print $2}' | awk -F_ '{print $1}')
    fi
}

doAction() {
    # On LMS, internal network on br3

    getInternalIP

    local PAYLOAD=/tmp/payload.json.$$
    local HOSTNAME=$(hostname)
    local AGENT_PATH=/etc/consul.d/agent/config.json

    getNodeType

    # Check if we've a local consul agent
    if [ -e ${AGENT_PATH} ] ; then
       # Local mode, register via the agent
       local MODE=LOCAL
    else
       local MODE=REMOTE
    fi

    if [ "${MODE}" = "LOCAL" ] ; then
        cat > ${PAYLOAD} <<EOF
{
    "Name": "node-exporter",
    "Port": 16163,
    "Tags": [ "nodetype=${NODE_TYPE}" ]
}
EOF
        local URL_BASE=http://${INTERNAL_IP}:8500/v1/agent/service
    else
        cat > ${PAYLOAD} <<EOF
{
    "Node": "${HOSTNAME}",
    "Address": "${INTERNAL_IP}",
    "Service": {
        "ID": "node-exporter-${HOSTNAME}",
        "Service": "node-exporter",
        "Port": 16163,
        "Tags": [ "nodetype=${NODE_TYPE}" ]
    }
}
EOF
        local URL_BASE=http://kvstore:8500/v1/catalog
    fi

    if [ "${ACTION}" = "start" ] ; then
        curl --silent --show-error --request PUT --data @${PAYLOAD} ${URL_BASE}/register
    elif [ "${ACTION}" = "stop" ] ; then
        if [ "${MODE}" = "LOCAL" ] ; then
            curl --silent --show-error --request PUT ${URL_BASE}/deregister/node-exporter
        else
            curl --silent --show-error --request PUT --data @${PAYLOAD} ${URL_BASE}/deregister
        fi
    fi
    RESULT=$?

    /bin/rm ${PAYLOAD}
}

ACTION=$1

if [ "${ACTION}" = "start" ] ; then
    RESULT=1
    # Allow the sleep interval to be configured when we're testing
    if [ -z "${SLEEP_INTERVAL}" ] ; then
        SLEEP_INTERVAL=30
    fi
    while [ ${RESULT} -ne 0 ] ; do
        doAction
        if [ ${RESULT} -ne 0 ] ; then
            echo "WARN: Failed to register"
            sleep ${SLEEP_INTERVAL}
        else
            echo "INFO: Successfully registered with consul"
        fi
    done
elif [ "${ACTION}" = "stop" ] ; then
    doAction
else
    echo "Usage: $0 <start/stop>"
fi

exit 0
