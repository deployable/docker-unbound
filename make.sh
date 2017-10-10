#!/bin/sh

set -ue

IMG_NAMESPACE=deployable
IMG_NAME=unbound
IMG_TAG=$IMG_NAMESPACE/$IMG_NAME
CONTAINER_NAME=unbound-forward

rundir=$(cd -P -- "$(dirname -- "$0")" && printf '%s\n' "$(pwd -P)")
canonical="$rundir/$(basename -- "$0")"

if [ -n "${1:-}" ]; then
  cmd=$1
  shift
else
  cmd=build
fi

cd "$rundir"


run_build(){
  run_build_default
  run_build_apse2 
}

run_build_default(){
  run_template unbound.conf Dockerfile
  docker build -t $IMG_TAG .
}

run_build_apse2(){
  run_template unbound.aws.apse2.conf Dockerfile.apse2
  docker build -t $IMG_TAG-apse2 -f Dockerfile.apse2 .
}

run_run(){
  set +e
  docker rm -f $CONTAINER_NAME
  set -e
  docker run \
    --detach \
    --name $CONTAINER_NAME \
    --publish 53:53/udp \
    --restart always \
    $IMG_TAG

  docker ps
  docker logs --tail 20 $CONTAINER_NAME
}

run_template(){
  template_conffile=$1
  template_dockerfile=$2
  perl -pe 'BEGIN{ $conffile=shift @ARGV; } s/{{unbound_conf}}/$conffile/' $template_conffile Dockerfile.template > "$template_dockerfile"
}

run_help(){
  echo "Commands:"
  awk '/  ".*"/{ print "  "substr($1,2,length($1)-3) }' make.sh
}

set +x

case $cmd in
  "build")     run_build "$@";;
  "template")  run_template "$@";;
  "run")       run_run "$@";;
  '-h'|'--help'|'h'|'help') run_help;;
esac

