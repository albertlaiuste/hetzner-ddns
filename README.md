# Dynamic DNS with Docker and Hetzner DNS

This project sets up a dynamic DNS service using the Hetzner Cloud DNS API (`api.hetzner.cloud/v1`). The service periodically checks for any changes to your current IP address and if it detects one then it updates your DNS record with your current IP address using the Hetzner REST API.

> **Note:** Hetzner is shutting down the legacy DNS Console API (`dns.hetzner.com/api/v1`) on **2026-05-20**. Zones must be migrated to the Hetzner Console and used with a project-scoped Bearer token. This project targets the new API.

## Prerequisites
* You own a domain you can point the nameservers to.
* You have some sort of device (like Raspberry Pi or any random computer) in your desired network that can run this.

## Step 1 - Installing Docker
I'm using Raspberry Pi with Ubuntu server 24.04 so my examples here are according to that. You should use your distributions documentation.
```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo groupadd docker
sudo usermod -aG docker $USER
```
## Step 2 - Adding Hetzner DNS Zone

Log into [Hetzner Console](https://console.hetzner.com/), open a project (or create one), and add a new DNS zone for your domain. If you previously had the zone in the legacy DNS Console, migrate it from there — migration is one-way and zone IDs are preserved.

## Step 3 - Update your domain registrar nameservers
Go to your domain registrar and change the nameservers to the ones that Hetzner shows.
This is different for everyone as everyone has their own registrar but it should look something like this:
![image](https://github.com/user-attachments/assets/7d52e455-987e-4431-b90a-72f6127755f4)

## Step 4 - Create Dummy DDNS record
Back in the Hetzner Console DNS view, create a new A record. Use the relative name (e.g. `ddns`) and set type to A. The value is not important at the moment as we are rewriting it automatically later on. Make sure the TTL is at least 60 seconds (Hetzner now requires this).

## Step 5 - Create API Access Key
In the [Hetzner Console](https://console.hetzner.com/), open the project that contains your DNS zone, then go to `Security -> API tokens -> Generate API token`. Tokens are project-scoped, so the token will work for any zone in that project. Store the value (`hcloud_…`) for later — it's shown only once.

## Step 6 - Running the container
In your home server, do
```bash
git clone https://github.com/albertlaiuste/hetzner-ddns.git /opt/ddns
cd /opt/ddns
```
Fill in the values for .env.
```bash
mv .env.example .env
nano .env # Ctrl+O to save, Ctrl+X to exit. Or use other editors, like vim.
```
You need three things in `.env`: the API token, the zone (name or ID), and the relative record name. To list the rrsets in a zone and confirm the record name/type:
```bash
curl -s "https://api.hetzner.cloud/v1/zones/YOUR_DOMAIN/rrsets" \
  -H "Authorization: Bearer YOUR_HETZNER_CONSOLE_TOKEN" | jq
```
Additionally check the API documentation [here](https://docs.hetzner.cloud/reference/cloud#dns).

To run the container
```bash
docker compose up -d
```

You can observe the service using
```
docker logs hetzner-ddns -f
```
It runs after every 5 minutes.





