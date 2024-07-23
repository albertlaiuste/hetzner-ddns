#!/bin/bash

printenv | grep -E 'HETZNER_ACCESS_KEY|HETZNER_RECORD_ID' >> /etc/environment

# Start cron service
crond -f

