#!/usr/bin/env bash

set -ue

rundir=${0%/*}
whom_arg=${1:-}
whom_trim=${whom_arg#*://}
whom=${whom_trim%%/*}
if [ "$whom" != "$whom_arg" ]; then
  echo "Trimmed domain to [$whom]"
fi

# dig a domain, if there's cnames add them too

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
  forward-addr: 8.8.8.8
"
}

print_zone_comment(){
  local domain=$1
  printf "#forward-zone:
#  name: \"$domain\"
#  forward-addr: 8.8.8.8
"
}

reload_unbound(){
  unbound-control reload; unbound-control status
}

# doit

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

