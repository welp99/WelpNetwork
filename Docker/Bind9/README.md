<aside>
💡 DNS (Domain Name System) is a crucial component of the internet infrastructure, and BIND9 is one of the most widely used DNS server software. This tutorial will guide you through the basics of setting up and configuring BIND9 for your DNS needs.

</aside>

# Installing BIND9 with Docker Compose

To install BIND9 using Docker Compose, follow these steps:

- Create a new directory for your BIND9 configuration files.
- Create a new file named `docker-compose.yml` in the directory.
- Open the `docker-compose.yml` file and add the following content:

```yaml
version: '3'
services:
  bind9:
    image: ubuntu/bind:latest
    restart: always
		environment: 
      - BIND9_USER=root
      - TZ=Europe/Paris
    volumes:
      - ./config:/etc/bind
      - ./cache:/var/cache/bind
      - ./records:/var/lib/bind
    ports:
      - 53:53/udp
      - 53:53/tcp

```

- Save the `docker-compose.yml` file.
- Create multiple directory named config, cache and records
- Create a new file named `named.conf` in the directory config and configure your BIND9 settings.
- Create a new file named `exempleDomain.zone` in the same directory and place your zone files inside it.
- In ubuntu the local DNS is active. You will need to unable it.

```bash
vi /etc/systemd/resolved.conf
```

- Uncomment this line
- #DNSStubListener=yes
- Change “yes” to “no” then restart the service

```bash
systemctl restart systemd-resolved
```

- Open a terminal, navigate to the directory where your `docker-compose.yml` file is located, and run the following command:

```bash
docker-compose up -d

```

- Docker Compose will pull the BIND9 image, create a container, and start BIND9 with the specified configuration.

Now you have BIND9 installed and running using Docker Compose. You can proceed with configuring your DNS records and other settings as needed.

# Configuration Files and Zones

- Create a file named named.conf in the directory config and check the following exemple

```
    <ipAddress>/<netMask>;   # Define the first IP address internal ACL
    <ipAddress>/<netMask>;   
    <ipAddress>/<netMask>;   
};

options {
    forwarders {
        8.8.8.8;   # Use Google's DNS server as a forwarder
        1.1.1.1;   # Use Cloudflare's DNS server as a forwarder
    };
    allow-query { internal; };  # Allow queries only from the 'internal' ACL
};

zone "exampleDomain" IN {
    type master;   # Configure the zone as a master zone
    file "/etc/bind/exampleDomain.zone";   # Specify the zone file location
};```
```

This configuration sets up an ACL (Access Control List) named "internal" that includes three IP addresses and netmask definitions. 

It also configures the forwarders to use Google's DNS server and Cloudflare's DNS server. Queries are allowed only from the "internal" ACL.

The zone "exampleDomain" is configured as a master zone, and the zone file is located at "/etc/bind/exampleDomain.zone".

Please note that this is just an example configuration. You need to replace `<ipAddress>` and `<netMask>` with actual IP addresses and netmask values, and replace "exampleDomain" with your own domain name.

# Creating DNS Records

- Create a file named `exempleDomain.zone` in the directory config and check the following exemple

```jsx
$TTL 2d  ; Cache Time To Live (2 days)
$ORIGIN exempleDomain.  ; Setting the domain's origin

@               IN              SOA         ns.exempleDomain.    info.exempleDomain.   (
20231016    ;   serial
12h         ;   refresh
15m         ;   retry
3w          ;   expire
2h          ;   minimum ttl
)

IN              NS          ns.exempleDomain.  ; Name Server Record

ns              IN              A           <ipAddress_dnsServer>  ; A Record for the DNS server

; -- add dns records below

<nameServer>         IN              A           <ipAddress>  ; A Record for a server named <nameServer>
<nameServer>         IN              A           <ipAddress>
<nameServer>           IN              A           <ipAddress>
*.<nameServer>         IN              A           <ipAddress>  ; Generic A Record for all subdomains of <nameServer>
;
```

The provided DNS record file named `exempleDomain.zone` contains the following records:

- `$TTL 2d`: This sets the cache Time To Live (TTL) to 2 days.
- `$ORIGIN exempleDomain.`: This sets the origin of the domain to `exempleDomain.`.
- `@ IN SOA ns.exempleDomain. info.exempleDomain. (`:
    - `@` refers to the domain itself.
    - `IN SOA` specifies the Start of Authority record.
    - `ns.exempleDomain.` is the primary name server for the domain.
    - `info.exempleDomain.` is the email address of the responsible party for the domain.
    - `(20231016 12h 15m 3w 2h)`: These values represent the serial number, refresh time, retry time, expiration time, and minimum TTL for the domain.
- `@ IN NS ns.exempleDomain.`: This specifies the Name Server (NS) record for the domain.
- `ns IN A <ipAddress_dnsServer>`: This defines an A record for the DNS server with the specified IP address.
- `<nameServer> IN A <ipAddress>`: These are A records for servers named `<nameServer>`, each with its corresponding IP address.
- `.<nameServer> IN A <ipAddress>`: This is a generic A record that matches all subdomains of `<nameServer>` and maps them to the specified IP address.

Please note that you need to replace `<ipAddress_dnsServer>`, `<ipAddress>`, `<nameServer>`, and `<exempleDomain>` with the actual values for your DNS setup.

- Now restart the docker

```
docker-compose up -d
```

1. Forwarding and Caching
2. DNS Security
3. Troubleshooting and Debugging
4. Best Practices

By the end of this tutorial, you will have a solid understanding of how to configure and manage DNS using BIND9.

Let's get started!

Dump dns cache on mac

```bash
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
```