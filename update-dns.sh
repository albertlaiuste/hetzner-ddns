#!/bin/bash

source /etc/environment

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Fetch current IP address
IP=$(curl -s http://checkip.amazonaws.com/)

# Validate IP address
if [[ ! $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  log "Invalid IP address: $IP"
  exit 1
fi

# Get current Hetzner record value
RECORD=$(curl -s "https://dns.hetzner.com/api/v1/records/$HETZNER_RECORD_ID" -H "Auth-API-Token: $HETZNER_ACCESS_KEY")
CURRENT_IP=$(echo "$RECORD" | jq -r .record.value)

log "Current IP from Hetzner: $CURRENT_IP"

# Check if IP is different from Hetzner
if [ "$IP" == "$CURRENT_IP" ]; then
  log "IP has not changed, exiting."
  exit 0
fi

log "IP has changed, updating records."

ZONE_ID=$(echo "$RECORD" | jq -r .record.zone_id)
TYPE=$(echo "$RECORD" | jq -r .record.type)
NAME=$(echo "$RECORD" | jq -r .record.name)
TTL=$(echo "$RECORD" | jq -r .record.ttl)
UPDATE_RECORD_PAYLOAD=$(cat << EOF
{
  "zone_id": "$ZONE_ID",
  "type": "$TYPE",
  "name": "$NAME",
  "value": "$IP",
  "ttl": $TTL
}
EOF
)

# Update record
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X "PUT" "https://dns.hetzner.com/api/v1/records/$HETZNER_RECORD_ID" \
     -H "Content-Type: application/json" \
     -H "Auth-API-Token: $HETZNER_ACCESS_KEY" \
     -d "$UPDATE_RECORD_PAYLOAD")

if [ "$HTTP_RESPONSE" -eq 200 ]; then
  echo "DNS record updated successfully."
else
  echo "Failed to update DNS record. HTTP Status: $HTTP_RESPONSE"
  exit 1
fi
