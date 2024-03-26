## Intro

This tutorial aims to guide you through the process of setting up a robust log management solution using Elastic Stack. Elastic Stack, comprising Elastic Search, Kibana, and other components, offers powerful tools for searching, analyzing, and visualizing log data in real-time. 

## Pre-requis

- Elastic : server Ubuntu 22.04 > RAM : 4G // CPU : 2 // Disk : 32Go
- Fleet Server : server Ubuntu 22.04 > RAM : 2G // CPU : 1 // Disk : 16Go

## Elasticsearch

### **Installation of Elasticsearch**

```bash
sudo apt install curl
```

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
```

```bash
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
```

```bash
sudo apt update
sudo apt install elasticsearch
```

```bash
The generated password for the elastic built-in superuser is : wugLGil0YL01fuDEixQF

If this node should join an existing cluster, you can reconfigure this with
'/usr/share/elasticsearch/bin/elasticsearch-reconfigure-node --enrollment-token <token-here>'
after creating an enrollment token on your existing cluster.

You can complete the following actions at any time:

Reset the password of the elastic built-in superuser with
'/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic'.

Generate an enrollment token for Kibana instances with
 '/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana'.

Generate an enrollment token for Elasticsearch nodes with
'/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node'.
```

```bash
sudo nano /etc/elasticsearch/elasticsearch.yml
```


```bash
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
```

Test Elasticsearch

```bash
curl -X GET -k https://elastic:wugLGil0YL01fuDEixQF@localhost:9200
```

```bash
curl -X GET -k https://elastic:<elasticpasswd>@localhost:9200
```

You should have a return like this

```bash
{
  "name" : "Elastic-MSPR",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "SWXS_Do6RSG4HJLaaglxFQ",
  "version" : {
    "number" : "8.12.2",
    "build_flavor" : "default",
    "build_type" : "deb",
    "build_hash" : "48a287ab9497e852de30327444b0809e55d46466",
    "build_date" : "2024-02-19T10:04:32.774273190Z",
    "build_snapshot" : false,
    "lucene_version" : "9.9.2",
    "minimum_wire_compatibility_version" : "7.17.0",
    "minimum_index_compatibility_version" : "7.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

## Kibana

### Installation of Kibana

```bash
sudo apt update
sudo apt install kibana
```

### Create an enrollement token

```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
```

```bash
eyJ2ZXIiOiI4LjEyLjIiLCJhZHIiOlsiMTAuMTAuMjIuMTA6OTIwMCJdLCJmZ3IiOiI2MjkwM2NlNWVjZjY5ZGY1YzQ4MTNkYzgxOWM5YjIyM2Q1YzUyOTM2ZGQ0YjA5YjU4YTdmMDRjNjY0NzI0MGFhIiwia2V5IjoicmxOcVc0NEJmMDdvY2dnNlE2aU46Y21SVk9rNXdTS2FSLVJ0WllzaDhQdyJ9
```

### Add token to kibana

```bash
sudo /usr/share/kibana/bin/kibana-setup
```

Paste the enrollement token 

![kibana-token](../SIEM/src/kibana-token.png)

### Start Kibana

```bash
sudo systemctl enable kibana
sudo systemctl start kibana
```

## Check if kibana is up

```bash
ss -lntp
```

![check-kibana](../SIEM/src/check-kibana.png)

## Nginx

### Installation of nginx

```bash
sudo apt update
sudo apt install nginx
```

### Create a proxy pass

```bash
sudo nano /etc/nginx/sites-enabled/default
```

![proxypass-1](../SIEM/src/proxypass-1.png)

![proxypass-2](../SIEM/src/proxypass-2.png)

```bash
sudo systemctl enable nginx
sudo systemctl start nginx 
```

### SSL certificate creation (optional)

Install certbot 

```bash
sudo snap install --classic certbot
```

```bash
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

```bash
sudo snap set certbot trust-plugin-with-root=ok
```

```bash
sudo snap install certbot-dns-<PLUGIN>
```

Create a .ini file

- `cloudflare.ini`
    
    ```bash
    # Cloudflare API token
    dns_cloudflare_api_token = <VOTRE_TOKEN_API_CLOUDFLARE>
    ```
    

```bash
certbot certonly --dns-cloudflare --dns-cloudflare-credentials /chemin/vers/votre/fichier/credentials.ini -d votre_domaine.com
```
    
## Fleet Server

### Log in to kibana

```bash
http:<IP_Adress>
```

Or

```bash
https://<IP_Adress>
```

### Add fleet server

To ensure connection with this fleet server and elastic search we will copy into fleet server the elastic certificate 

- On elastic server

```bash
sudo -s
```

```bash
cd /etc/elasticsearch/certs
```

```bash
python3 -m http.server
```

- On Fleet Server

```bash
sudo mkdir -p /usr/local/etc/ssl/certs/elastic/
```

```bash
sudo curl 10.10.22.10:8000/http_ca.crt -o /usr/local/etc/ssl/certs/elastic/http_ca.crt
```

![transfert-cert](../SIEM/src/transfert-cert.png)

- Go to kibana
- Clic on Add Integration

![add-integration](../SIEM/src/add-integration.png)

- Search for “Fleet server”

![fleet-server](../SIEM/src/fleet-server.png)

- Add fleet server

![add-fleetserver](../SIEM/src/add-fleetserver.png)

![fleet-server-integration](../SIEM/src/fleet-server-integration.png)

- Leave as default & click on “Save and continue”
- Click on “Add Elastic Agent to yours hosts”

![create-agent](../SIEM/src/create-agent.png)

- Add Fleet Server

We will used a different server, only the fleet server will be connected to elastic 

- Enroll in fleet
- Select the agent policy created earlier
- We will used Quick Start as deployment mode
- Add your fleet server host
- Add name and URL for you fleet server

![add-fleet-host](../SIEM/src/add-fleet-host.png)

- Generate a service token

![generate-serviceToken](../SIEM/src/genererate-serviceToken.png)

```bash
AAEAAWVsYXN0aWMvZmxlZXQtc2VydmVyL3Rva2VuLTE3MTA5MzU1NzMxOTA6RlBiLXc4UTVRRUtjUjlnZnd0VGZXQQ
```

```bash
curl -L -O https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-8.12.2-linux-x86_64.tar.gz
tar xzvf elastic-agent-8.12.2-linux-x86_64.tar.gz
cd elastic-agent-8.12.2-linux-x86_64
sudo ./elastic-agent install \
  --fleet-server-es=https://10.10.22.10:9200 \
  --fleet-server-service-token=AAEAAWVsYXN0aWMvZmxlZXQtc2VydmVyL3Rva2VuLTE3MTA5MzU1NzMxOTA6RlBiLXc4UTVRRUtjUjlnZnd0VGZXQQ \
  --fleet-server-policy=1ef305f7-02d4-4201-b44c-7026ceda3943 \
  --fleet-server-es-ca-trusted-fingerprint=62903ce5ecf69df5c4813dc819c9b223d5c52936dd4b09b58a7f04c6647240aa \
  --fleet-server-port=8220 \
  --insecure
```

![fleet-setting](../SIEM/src/fleet-setting.png)

- go to “Fleet Settings”

You should have your fleet server with the right URL display here

![fleet-url](../SIEM/src/fleet-url.png)

### Creation of encrypted-key for Kibana

```bash
cd /usr/share/kibana/bin/
sudo ./kibana-encryption-keys generate -q
```

```bash
xpack.encryptedSavedObjects.encryptionKey: b67434c7cc01b08dedfd046ea08e618b
xpack.reporting.encryptionKey: e286998b837edff9d4b51def73cf11a2
xpack.security.encryptionKey: 10ca0eadbb70b4c31a615da045740043
```

Paste output at the bottom of your `kibana.yml`

```bash
sudo nano /etc/kibana/kibana.yml
```

```bash
sudo systemctl restart kibana
```
