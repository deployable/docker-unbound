#!/bin/sh

set -uex

rundir=${0%/*}
cd "$rundir"

find_arg=${1:-}
replace_arg=${2:-}


exit_log(){
  echo "Error: $1"
  exit 1
}


#8.8.8.8}   # goog

if [ -z "$find_arg" ]; then
  find_arg=$(cat .forward-addr)
  if [ "$find_arg" = "8.8.8.8" ]; then
    replace_arg="172.30.1.102"
  elif [ "$find_arg" = "172.30.1.102" ]; then
    replace_arg="8.8.8.8"
  else 
    exit_log "Can't lookup replacement/new server"
  fi
fi
if [ -z "$replace_arg" ]; then
  exit_log "No replacement server argument (2)"
fi

echo "Finding forwarders \"$find_arg\""
echo "Replacing with \"$replace_arg\""

sed_replace="s/forward-addr: $find_arg/forward-addr: $replace_arg/g"

#sed -i "" "$sed_replace" unbound.conf
perl -spi -e 'BEGIN { $find_arg = quotemeta($find_arg); } s/$find_arg/$replace_arg/g' -- -find_arg="$find_arg" -replace_arg="$replace_arg" "$rundir"/unbound.conf 
echo "$replace_arg" > .forward-addr

reload_unbound(){
  unbound-control reload; unbound-control status
}

reload_unbound
sudo /Users/matt/bin/restartdns


