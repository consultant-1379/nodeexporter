#!/bin/bash

BUILD_DIR=$(dirname $0)

PATH=/:$PATH

TARGET_DIR=$1

. ${TARGET_DIR}/image_versions.txt

mkdir -p ${TARGET_DIR}/esm/bin

COPY_LIST="/bin/node_exporter@${TARGET_DIR}/esm/bin@${NODE_EXPORTER_IMAGE}"

# Validate we have the image reference for all the images first
for ONE in ${COPY_LIST} ; do
    IMAGE=$(echo ${ONE} | awk -F@ '{print $3}')
    if [ -z "${IMAGE}" ] ; then
        echo "No Image found for ${ONE}"
        exit 1
    fi
done

for ONE in ${COPY_LIST} ; do
  FILE_LIST=$(echo ${ONE} | awk -F@ '{print $1}' | sed 's/,/ /g')
  TARGET=$(echo ${ONE} | awk -F@ '{print $2}')
  IMAGE=$(echo ${ONE} | awk -F@ '{print $3}')
  echo "${IMAGE}"
  docker create --name cpimage ${IMAGE}
  for FILE in ${FILE_LIST} ; do
   docker cp cpimage:${FILE} ${TARGET}
  done
  docker rm -f cpimage
done


