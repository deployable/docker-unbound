#!/usr/bin/env bash

set -ue

rundir=${0%/*}
whom_arg=${1:-}
whom_trim=${whom_arg#*://}
whom=${whom_trim%%/*}

# dig a domain, if there's cnames add them too

error_die(){
  echo "Error: $@"
  exit 1
}

get_cnames(){
  local domain=$1
  dig @8.8.8.8 $domain | awk '/CNAME/ { print $NF }'
}

check_forward_zone_exists(){
  local domain=$1
  grep -A2 "^forward-zone:" unbound.conf | grep "  name: \"$domain\"" >/dev/null
}

print_zone_or_comment(){
  local domain=$1
  if check_forward_zone_exists "$domain"; then
    print_zone_comment "$domain" >> unbound.conf
  else
    print_zone "$domain" >> unbound.conf
  fi
}

print_zone(){
  local domain=$1
  printf "forward-zone:
  name: \"$domain\"
  forward-addr: $forwarder
"
}

print_zone_comment(){
  local domain=$1
  printf "#forward-zone:
#  name: \"$domain\"
#  forward-addr: $forwarder
"
}

reload_unbound(){
  unbound-control reload; unbound-control status
}

# doit

if [ "$whom" != "$whom_arg" ]; then
  echo "Trimmed domain to [$whom]"
fi
if [ -z "$whom" ]; then
  error_die "Needs a domain/url as first argument"
fi
if [ -f .forward-addr ]; then 
  forwarder=$(cat .forward-addr)
  if [ -z "$forwarder" ]; then
    error_die "no forwarder in .forward-addr"
  fi
else 
  forwarder="8.8.8.8"
fi

domain=$whom
echo "Looking up \"$domain\""
cnames=$(get_cnames "$domain")
echo "adding $domain"

echo >> unbound.conf
echo "# ## $domain - $(date)" >> unbound.conf

print_zone_or_comment "$domain"

for host in $cnames; do 
  echo "adding $host"
  print_zone_or_comment "$host"
done 

reload_unbound
sudo /Users/matt/bin/restartdns

echo "unbound restarted with new $whom config added to forward-zone"

