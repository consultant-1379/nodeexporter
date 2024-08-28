#!/bin/bash

ROOT_DIR=$(dirname $0)
ROOT_DIR=$(cd ${ROOT_DIR}/../../.. ; pwd)

startdocker() {
    local IMAGE=$1

    docker run --rm \
        --volume ${ROOT_DIR}:${ROOT_DIR} \
        ${IMAGE} \
        bash ${ROOT_DIR}/EXTRnodeexporter_CXP9042760/src/test/containertest.sh -a starttest

}

starttest() {
    RPM=$(find ${ROOT_DIR}/EXTRnodeexporter_CXP9042760/target/rpm/EXTRnodeexporter_CXP9042760 -name 'EXTRnodeexporter_CXP9042760-*.rpm')
    rpm --install --nodeps ${RPM}

    cat > /sbin/ip <<'EOF'
#!/bin/bash

if [ "$1" = "-f" ] ; then
 echo "1: br1 inet 127.0.0.1/24"
fi
EOF

    cat > /sbin/hostname <<'EOF'
#!/bin/bash
echo "containertest"
EOF

    chmod 755 /sbin/ip /sbin/hostname

    # SystemD isn't running in the container so we need to run the scripts "manually"
    /opt/ericsson/esm/bin/node_exporter.sh &
    sleep 10
    pgrep -f 'node_exporter --web.listen-address='
    if [ $? -ne 0 ] ; then
        echo "ERROR: Could not find node_exporter process"
        ps -ef
        exit 1
    fi

    # Force consul_reg.sh to use LOCAL mode
    mkdir -p /etc/consul.d/agent
    echo "{}" > /etc/consul.d/agent/config.json
    echo "INFO: Running consul_reg.sh start"
    # Want to check more often during the test
    export SLEEP_INTERVAL=1
    /opt/ericsson/esm/bin/consul_reg.sh start &
    # Consul stub not running so we should find consul_reg.sh start running
    sleep 10
    pgrep -f 'consul_reg.sh start'
    if [ $? -ne 0 ] ; then
        echo "ERROR: Could not find consul_reg.sh start process"
        ps -ef
        exit 1
    fi

    # create "stub" consul
    echo "INFO: starting consul stub"
    python3 ${ROOT_DIR}/EXTRnodeexporter_CXP9042760/src/test/server.py 8500 &

    sleep 10

    # Consul stub running so we consul_reg.sh _start should have completed
    pgrep -f 'consul_reg.sh start'
    if [ $? -eq 0 ] ; then
        echo "ERROR:consul_reg.sh _start process still running"
        cat /var/log/consul_reg.log
        ps -ef
        exit 1
    fi

    echo "INFO: Running consul_reg.sh stop"
    /opt/ericsson/esm/bin/consul_reg.sh stop

    echo "INFO: Stopping consul stub"
    pkill -f '${ROOT_DIR}/EXTRnodeexporter_CXP9042760/src/test/server.py'

    grep --silent "PUT /v1/agent/service/register" /tmp/httpd.log
    if [ $? -ne 0 ] ; then
        echo "ERROR: Failed to find register request"
        cat /tmp/httpd.log
        cat /var/log/consul_reg.log
        sleep 3600
        exit 1
    fi

    grep --silent "PUT /v1/agent/service/deregister" /tmp/httpd.log
    if [ $? -ne 0 ] ; then
        echo "ERROR: Failed to find deregister request"
        cat /tmp/httpd.log
        exit 1
    fi

    echo "INFO: Verify metrics endpoint available"
    curl --silent --show-error http://127.0.0.1:16163/metrics --out /tmp/metrics.txt
    if [ $? -ne 0 ] ; then
        echo "ERROR: Failed to get metrics from node_exporter"
        exit 1
    fi
    if [ ! -s /tmp/metrics.txt ] ; then
        echo "ERROR: metrics file not empty"
        exit 1
    fi

    echo "INFO: All tests pass"
    exit 0
}

while getopts  "a:i:" flag ; do
    case "$flag" in
        a) ACTION="$OPTARG";;
        i) IMAGE="$OPTARG";;
    esac
done

if [ "${ACTION}" = "startdocker" ] ; then
    startdocker ${IMAGE}
else
    starttest
fi

