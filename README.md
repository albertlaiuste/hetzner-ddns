# Dynamic DNS with Docker and Hetzner DNS

This project sets up a dynamic DNS service using Hetzner DNS Public API. The service periodically checks for any changes to your current IP address and if it detects one then it updates your DNS record with your current IP address using the Hetzner REST API. 

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

Log into [Hetzner](https://accounts.hetzner.com/login) and from top-right dropdown menu click DNS.
Click `Add new zone` big yellow button, set the name to your domain and click `Continue`.

## Step 3 - Update your domain registrar nameservers
Go to your domain registrar and change the nameservers to the ones that Hetzner shows.
This is different for everyone as everyone has their own registrar but it should look something like this:
![image](https://github.com/user-attachments/assets/7d52e455-987e-4431-b90a-72f6127755f4)

## Step 4 - Create Dummy DDNS record
Back in Hetzner DNS Console create new A record:
Name it `ddns.yourdomain.com` and set type to A. The value is not important at the moment as we are rewriting it automatically later on.
![image](https://github.com/user-attachments/assets/21fc1bec-7002-465b-9fc6-adf442cdac82)

## Step 5 - Create API Access Key
From top-right click on `Account Icon->API Tokens->Set token name->Create access token` and store it for later.

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
Optional: to find record id you can directly query their API and find it listed, like:
```bash
curl -s "https://dns.hetzner.com/api/v1/records?zone_id=YOUR_DOMAIN_NAME" \
  -H 'Auth-API-Token: YOUR_ACCESS_KEY'
```
Additionally check their documentation [here](https://dns.hetzner.com/api-docs).

To run the container
```bash
docker compose up -d
```

You can observe the service using
```
docker logs hetzner-ddns -f
```
It runs after every 5 minutes.





