#!/bin/bash

ROOT_DIR=$(dirname $0)
TS=$(date +%Y%m%d%H%M%S)

curl --location --output ${ROOT_DIR}/yq_linux_amd64 https://github.com/mikefarah/yq/releases/download/v4.25.2/yq_linux_amd64
chmod 755 ${ROOT_DIR}/yq_linux_amd64

docker build --tag armdocker.rnd.ericsson.se/proj_oss_releases/nodeexporter/containertest:${TS} ${ROOT_DIR}

