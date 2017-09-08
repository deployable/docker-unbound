#!/bin/sh

set -ue

IMG_NAMESPACE=deployable
IMG_NAME=unbound
IMG_TAG=$IMG_NAMESPACE/$IMG_NAME
CONTAINER_NAME=unbound-forward

sudo docker build -t $IMG_TAG .
set +e
sudo docker rm -f $CONTAINER_NAME
set -e
sudo docker run \
  --detach \
  --name $CONTAINER_NAME \
  --publish 172.30.1.102:53:53/udp \
  --restart always \
  $IMG_TAG

sudo docker ps 

