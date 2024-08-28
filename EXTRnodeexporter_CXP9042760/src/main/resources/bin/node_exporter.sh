#!/bin/bash

BIN_DIR=$(dirname $0)
. ${BIN_DIR}/common.sh

getInternalIP

exec ${BIN_DIR}/node_exporter  \
 --web.listen-address="${INTERNAL_IP}:16163" \
 --no-collector.xfs \
 --no-collector.time \
 --no-collector.timex \
 --no-collector.nfs \
 --collector.netdev.device-blacklist="^vnet|^lo" \
 --collector.filesystem.ignored-fs-types="^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs|nfs)$" \
 --collector.diskstats.device-exclude="^(ram|loop|fd|(h|s|v|xv)d[a-z]|nvme\\d+n\\d+p)\\d+$|^dm-\d+" \
 --collector.buddyinfo

