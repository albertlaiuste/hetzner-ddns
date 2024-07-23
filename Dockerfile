FROM alpine:latest

# Install dependencies
RUN apk update && \
    apk add --no-cache curl bash jq cronie

# Copy the update script and crontab
COPY entrypoint.sh /entrypoint.sh
COPY update-dns.sh /update-dns.sh
COPY crontab /etc/cron.d/update-dns

# Set correct permissions
RUN chmod 0744 /entrypoint.sh
RUN chmod 0744 /update-dns.sh
RUN chmod 0644 /etc/cron.d/update-dns

RUN crontab /etc/cron.d/update-dns

# Start cron service
ENTRYPOINT ["/entrypoint.sh"]
