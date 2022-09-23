#!/bin/bash
# Cloudflare DDNS Bash

# Configuration
# =============
# Cloudflare API Auth Token
declare APITOKEN=""
# Cloudflare Zone ID
declare ZONEID=""
# Domain: "example.com" || "www.example.com"
declare -l DOMAIN=""
# IPv4 A Record: "true" || "false"
declare -l A_RECORD="true"
# IPv6 AAAA Record: "true" || "false"
declare -l AAAA_RECORD="false"
# Utilities
declare CURL="$(which curl)"
declare GREP="$(which grep)"

# Cloudflare API
# Input $1 [string]: "GET" || "PATCH" - API method
# Input $2 [string]: "api/request" - API request
# Input $3 [string]: "\"api\":\"data"\" - API data (optional)
# Output [string]: "API response"
cloudflare_api() {
  declare APIURI="https://api.cloudflare.com/client/v4"
  declare -u APIMETHOD="$1"
  declare APIREQ="$2"
  declare APIDATA="$3"

  echo "$(
    $CURL -f -q -s -X $APIMETHOD "$APIURI/$APIREQ" \
    -H "Authorization: Bearer $APITOKEN" \
    -H "Content-Type: application/json" \
    --data "{$APIDATA}"
  )"
  return 0
}

# System IP Address
# Input $1 [string]: "A" || "AAAA" - IP version to use
# Output [string]: "1.1.1.1" - IP from ipify.org
ip_system() {
  declare -u IPV="$1"
  declare -l API

  case "$IPV" in
    A) API="https://api.ipify.org";;
    AAAA | *) API="https://api64.ipify.org";;
  esac

  echo "$($CURL -f -q -s -X GET $API)"
  return 0
}

# IP Version
# Input $1 [string]: "1.1.1.1" - IP to check
# Output [string]: "A" - IPv4 || "AAAA" - IPv6
ip_version() {
  declare CHECKIP="$1"
  declare -u IPVERSION
  # Regex statements: https://stackoverflow.com/a/17871737/5291015
  declare IPV4REGEX="((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])"
  declare IPV6REGEX="(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4})"

  if [[ ${CHECKIP} =~ ${IPV4REGEX} ]]; then
    IPVERSION="A"
  elif [[ ${CHECKIP} =~ ${IPV6REGEX} ]]; then
    IPVERSION="AAAA"
  else
    echo "Error: Invalid IP version requested."
    return 1
  fi

  echo "$IPVERSION"
  return 0
}

# Cloudflare DDNS
cloudflare_ddns() {
  declare -u RECORDTYPE="$1"
  # Record state
  declare -u RECORDSTATE="${RECORDTYPE}_RECORD"
  if [ "${!RECORDSTATE}" != "true" ]; then
    # Record type disabled, skipping
    return 0
  fi

  # System IP address
  declare SYSTEMIP="$(ip_system $RECORDTYPE)"
  if [ "$(ip_version $SYSTEMIP)" != "$RECORDTYPE" ]; then
    echo "Error: System IP $SYSTEMIP is not valid $RECORDTYPE record."
    return 1
  fi

  # Cloudflare record
  declare CFRECORD="$(
    cloudflare_api "GET" "zones/$ZONEID/dns_records?type=$RECORDTYPE&name=$DOMAIN&match=all&order=type"
  )"
  if [ "$(echo $CFRECORD | $GREP -o -P '(?<="result":")[^"]+')" = "" ]; then
    echo "Error: Cloudflare DNS $RECORDTYPE record does not exist for $DOMAIN."
    return 1
  elif [ "$(echo $CFRECORD | $GREP -o -P '(?<="content":")[^"]+')" = "$SYSTEMIP" ]; then
    # Record already updated
    return 0
  fi

  declare CFRECORDID="$(echo $CFRECORD | $GREP -o -P '(?<="id":")[^"]+')"
  declare CFRECORDPATCH="$(
    cloudflare_api "PATCH" "zones/$ZONEID/dns_records/$CFRECORDID" "\"type\":\"$RECORDTYPE\",\"content\":\"$SYSTEMIP\""
  )"
  return 0
}

for RECORDTYPE in "A" "AAAA"; do
  cloudflare_ddns "$RECORDTYPE"
done

unset APITOKEN ZONEID DOMAIN A_RECORD AAAA_RECORD CURL GREP RECORDTYPE
