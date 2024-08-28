#!/bin/bash

BUILD_DIR=$(dirname $0)

PATH=/:$PATH

TARGET_DIR=$1
MONITORIING_VERSION=$2

BASE_URL=https://arm.epk.ericsson.se/artifactory/proj-enm-dev-internal-helm
mkdir -p ${TARGET_DIR}/charts

CHART_VERSION_LIST="eric-enm-monitoring-integration:${MONITORIING_VERSION}"
for CHART_VERSION in ${CHART_VERSION_LIST} ; do
    CHART=$(echo ${CHART_VERSION} | awk -F: '{print $1}')
    VERSION=$(echo ${CHART_VERSION} | awk -F: '{print $2}')

    curl --silent --show-error --output ${TARGET_DIR}/charts/${CHART}.tgz ${BASE_URL}/${CHART}/${CHART}-${VERSION}.tgz
    if [ $? -ne 0 ] ; then
        echo "ERROR: Failed to fetch ${CHART_VERSION}"
        exit 1
    fi

    helm template --output-dir ${TARGET_DIR}/charts ${CHART} ${TARGET_DIR}/charts/${CHART}.tgz
    if [ $? -ne 0 ] ; then
        echo "ERROR: Failed to template ${CHART_VERSION}"
        exit 1
    fi
done

NODE_EXPORTER_IMAGE=$(yq_linux_amd64 '.spec.template.spec.containers[0].image' ${TARGET_DIR}/charts/eric-enm-monitoring-integration/charts/eric-enm-int-node-exporter/charts/eric-pm-node-exporter/templates/daemonset.yaml)

cat > ${TARGET_DIR}/image_versions.txt <<EOF
NODE_EXPORTER_IMAGE=${NODE_EXPORTER_IMAGE}
EOF
