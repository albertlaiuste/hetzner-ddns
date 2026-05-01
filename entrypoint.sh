#!/bin/bash

printenv | grep -E '^HETZNER_(API_TOKEN|ZONE|RECORD_NAME|RECORD_TYPE|TTL)=' >> /etc/environment

# Start cron service
crond -f

