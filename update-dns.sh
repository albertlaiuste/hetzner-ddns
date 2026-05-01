#!/bin/bash

source /etc/environment

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

IP=$(curl -s http://checkip.amazonaws.com/)

if [[ ! $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  log "Invalid IP address: $IP"
  exit 1
fi

TYPE="${HETZNER_RECORD_TYPE:-A}"
TTL="${HETZNER_TTL:-300}"
RRSET_URL="https://api.hetzner.cloud/v1/zones/${HETZNER_ZONE}/rrsets/${HETZNER_RECORD_NAME}/${TYPE}"
AUTH_HEADER="Authorization: Bearer ${HETZNER_API_TOKEN}"

RRSET=$(curl -fsS "$RRSET_URL" -H "$AUTH_HEADER")
if [ -z "$RRSET" ]; then
  log "Failed to fetch RRset from $RRSET_URL"
  exit 1
fi

CURRENT_IP=$(echo "$RRSET" | jq -r '.rrset.records[0].value')
log "Current IP from Hetzner: $CURRENT_IP"

if [ "$IP" == "$CURRENT_IP" ]; then
  log "IP has not changed, exiting."
  exit 0
fi

log "IP has changed, updating record."

PAYLOAD=$(jq -nc \
  --arg ip "$IP" \
  --argjson ttl "$TTL" \
  '{ttl: $ttl, records: [{value: $ip}]}')

HTTP_RESPONSE=$(curl -s -o /tmp/hetzner-resp -w "%{http_code}" -X PUT "$RRSET_URL" \
     -H "Content-Type: application/json" \
     -H "$AUTH_HEADER" \
     -d "$PAYLOAD")

if [ "$HTTP_RESPONSE" -eq 200 ]; then
  log "DNS record updated successfully to $IP."
else
  log "Failed to update DNS record. HTTP Status: $HTTP_RESPONSE. Response: $(cat /tmp/hetzner-resp)"
  exit 1
fi
