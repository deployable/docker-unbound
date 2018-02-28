#!/usr/bin/env bash

set -ue

rundir=${0%/*}
whom_arg=${1:-}
whom_trim=${whom_arg#*://}
whom=${whom_trim%%/*}
tag=${2:-}

# dig a domain, if there's cnames add them too

error_die(){
  echo "Error: $@"
  exit 1
}

get_cnames(){
  local domain=$1
  dig @8.8.8.8 $domain | awk '/CNAME/ { print $NF }'
#  dig @172.30.1.102 $domain | awk '/CNAME/ { print $NF }'
}

check_forward_zone_exists(){
  local domain=$1
  grep -A2 "^forward-zone:" unbound.conf | grep "  name: \"$domain\"" >/dev/null
}

print_zone_header(){
  local domain=$1
  local tag=$2
  local file=$3
  local date_now=$(date)
  echo >> $file
  echo "# ## $domain - $tag - $date_now" >> $file
  echo "# domain: $domain" >> $file
  echo "# tag: $tag" >> $file
  echo "# date: $date_now" >> $file
}

print_zone_or_comment(){
  local domain=$1
  local file=$2
  if check_forward_zone_exists "$domain"; then
    print_zone_comment "$domain" >> $file
  else
    print_zone "$domain" >> $file
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
if [ -z "$tag" ]; then
  echo "No tag, using 'default'"
  tag=default
fi

domain=$whom
echo "Looking up \"$domain\""
cnames=$(get_cnames "$domain")
echo "adding $domain with $tag"

file_config=unbound.conf
file_tag_config=configs/unbound.$tag.config

print_zone_header "$domain" "$tag" "$file_config"
print_zone_header "$domain" "$tag" "$file_tag_config"
print_zone_or_comment "$domain" "$file_config"
print_zone "$domain" >> "$file_tag_config"

for host in $cnames; do 
  echo "adding $host"
  print_zone_or_comment "$host" "$file_config"
  print_zone_or_comment "$host" "$file_tag_config"
done 

reload_unbound
sudo /Users/matt/bin/restartdns

echo "unbound restarted with new $whom config added to forward-zone"

