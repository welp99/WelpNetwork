<aside>
💡 To secure access to applications using Traefik as a proxy/reverse proxy and Authentik as an Identity Provider, it's crucial to understand the role of each component and how they interact. Here's a detailed documentation based on the provided configuration files and specified requirements.

</aside>

## **Traefik Configuration**

Traefik acts as a dynamic reverse proxy, routing client requests to the appropriate backend services. It's configured to use Let's Encrypt for SSL certificates via Cloudflare, enabling secure HTTPS traffic.

### **Step 1: Docker-compose Configuration for Traefik**

### **`docker-compose.yml`**

```bash
---
networks:
  frontend:
    external: true
  backend:
    external: true
services:
  traefik_NESS:
    container_name: traefik_NESS
    image: traefik:2.10.5
    ports:
      - 80:80
      - 443:443
    #  - 8080:8080
    volumes:
      - ./config:/etc/traefik
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./config/conf/:/etc/traefik/conf/:ro
      - ./config/certs/:/etc/traefik/certs/
      - ./config/config.yml:/config.yml:ro
    environment:
      - CLOUDFLARE_EMAIL=${CLOUDFLARE_EMAIL}
      - CLOUDFLARE_API_KEY=${CLOUDFLARE_API_KEY}
    networks:
      - frontend
      - backend
    restart: unless-stopped
    labels:
        - "traefik.enable=true"
        - "traefik.http.routers.traefik.entrypoints=web"
        - "traefik.http.routers.traefik.rule=Host(`traefik-dashboard.yourdomain.com`)"
        - "traefik.http.middlewares.traefik-auth.basicauth.users=${TRAEFIK_PASSWORD}"
        - "traefik.http.middlewares.traefik-https-redirect.redirectscheme.scheme=https"
        - "traefik.http.middlewares.sslheader.headers.customrequestheaders.X-Forwarded-Proto=websecure"
        - "traefik.http.routers.traefik.middlewares=traefik-https-redirect"
        - "traefik.http.routers.traefik-secure.entrypoints=websecure"
        - "traefik.http.routers.traefik-secure.rule=Host(`traefik-dashboard.youdomain.com`)"
        - "traefik.http.routers.traefik-secure.middlewares=traefik-auth"
        - "traefik.http.routers.traefik-secure.tls=true"
        - "traefik.http.routers.traefik-secure.tls.certresolver=cloudflare"
        - "traefik.http.routers.traefik-secure.tls.domains[1].main=yourdomain" #if you use the .home.welpnetwork.com entry you have to change the [0] into [1]
        - "traefik.http.routers.traefik-secure.tls.domains[1].sans=*.yourdomain" # same here, change 0 to 1
        - "traefik.http.routers.traefik-secure.service=api@internal"
```

- **Docker Networks**: Use external networks **`frontend`** and **`backend`** to allow Traefik to communicate with services.
- **Ports**: Expose ports 80 (HTTP) and 443 (HTTPS) for web traffic.
- **Volumes**: Mount the necessary configurations and SSL certificates.
- **Environment**: Set variables for Cloudflare (email and API key).
- **Labels**: Configure routing rules, including HTTPS redirects and authentication.

### **Step 2: Configuration of traefik.yml**

### **`traefik.yml`**

```bash
global:
  checkNewVersion: false
  sendAnonymousUsage: false

# -- (Optional) Change Log Level and Format here...
#     - loglevels [DEBUG, INFO, WARNING, ERROR, CRITICAL]
#     - format [common, json, logfmt]
log:
  level: ERROR
#  format: common
#  filePath: /var/log/traefik/traefik.log

# -- (Optional) Enable Accesslog and change Format here...
#     - format [common, json, logfmt]
# accesslog:
#   format: common
#   filePath: /var/log/traefik/access.log

# -- (Optional) Enable API and Dashboard here, don't do in production
api:
   dashboard: true
   debug: true

# -- Change EntryPoints here...
entryPoints:
  web:
    address: :80
    http:
      redirections:
        entrypoint:
          to: websecure
          scheme: https
  #   -- (Optional) Redirect all HTTP to HTTPS
  websecure:
    address: :443
    
  # -- (Optional) Add custom Entrypoint
  #traefik:
  #  address: :8080

# -- Configure your CertificateResolver here...
certificatesResolvers:
  cloudflare:
    acme:
      email: example@email.com
      storage: /etc/traefik/certs/acme.json
      caServer: 'https://acme-v02.api.letsencrypt.org/directory'
      keyType: EC256
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"

# -- (Optional) Disable TLS Cert verification check
serversTransport:
   insecureSkipVerify: true

# -- (Optional) Overwrite Default Certificates
tls:
  stores:
    default:
      defaultCertificate:
        certFile: /etc/traefik/certs/cert.pem
        keyFile: /etc/traefik/certs/cert-key.pem
# -- (Optional) Disable TLS version 1.0 and 1.1
#   options:
#     default:
#       minVersion: VersionTLS12

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    # -- (Optional) Enable this, if you want to expose all containers automatically
    exposedByDefault: false
  file:
    directory: /etc/traefik
    #watch: true
```

- **API and Dashboard**: Enable them for easier debugging and monitoring.
- **EntryPoints**: Define **`web`** for HTTP traffic and **`websecure`** for HTTPS.
- **CertificatesResolvers**: Use Cloudflare for SSL certificate acquisition.
- **Providers**: Configure Traefik to use Docker and files for service discovery.

## **Authentik Configuration**

Authentik will provide authentication and authorization for applications.

### **Step 1: Docker-compose Configuration for Authentik**

### **`docker-compose.yml`**

```bash
---
version: "3.4"

services:
  postgresql:
    image: docker.io/library/postgres:12-alpine
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}"]
      start_period: 20s
      interval: 30s
      retries: 5
      timeout: 5s
    volumes:
      - database:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: ${PG_PASS:?database password required}
      POSTGRES_USER: ${PG_USER:-authentik}
      POSTGRES_DB: ${PG_DB:-authentik}
    env_file:
      - .env
    networks:
      - frontend
  redis:
    image: docker.io/library/redis:alpine
    command: --save 60 1 --loglevel warning
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "redis-cli ping | grep PONG"]
      start_period: 20s
      interval: 30s
      retries: 5
      timeout: 3s
    volumes:
      - redis:/data
    networks:
      - frontend
  server:
    image: ${AUTHENTIK_IMAGE:-ghcr.io/goauthentik/server}:${AUTHENTIK_TAG:-2024.2.0}
    container_name: authentik_server
    restart: unless-stopped
    command: server
    environment:
      AUTHENTIK_REDIS__HOST: redis
      AUTHENTIK_POSTGRESQL__HOST: postgresql
      AUTHENTIK_POSTGRESQL__USER: ${PG_USER:-authentik}
      AUTHENTIK_POSTGRESQL__NAME: ${PG_DB:-authentik}
      AUTHENTIK_POSTGRESQL__PASSWORD: ${PG_PASS}
    volumes:
      - ./media:/media
      - ./custom-templates:/templates
    env_file:
      - .env
    networks:
      - frontend
    depends_on:
      - postgresql
      - redis
    labels:
      - traefik.enable=true
      - traefik.http.routers.authentik.rule=Host(`authentik.lab.welpnetwork.com`)
      - traefik.http.middlewares.authentik-https-redirect.redirectscheme.scheme=https
      - traefik.http.routers.authentik.middlewares=authentik-https-redirect
      - traefik.http.routers.authentik.entrypoints=web
      - traefik.http.routers.authentik-secure.entrypoints=websecure
      - traefik.http.routers.authentik-secure.rule=Host(`authentik.lab.welpnetwork.com`)
      - traefik.http.routers.authentik-secure.tls=true
      - traefik.http.routers.authentik-secure.service=authentik
      - traefik.http.services.authentik.loadbalancer.server.port=9000
      - traefik.http.routers.authentik-secure.tls.certresolver=cloudflare
      - traefik.docker.network=frontend
  worker:
    image: ${AUTHENTIK_IMAGE:-ghcr.io/goauthentik/server}:${AUTHENTIK_TAG:-2024.2.0}
    restart: unless-stopped
    command: worker
    environment:
      AUTHENTIK_REDIS__HOST: redis
      AUTHENTIK_POSTGRESQL__HOST: postgresql
      AUTHENTIK_POSTGRESQL__USER: ${PG_USER:-authentik}
      AUTHENTIK_POSTGRESQL__NAME: ${PG_DB:-authentik}
      AUTHENTIK_POSTGRESQL__PASSWORD: ${PG_PASS}
    # `user: root` and the docker socket volume are optional.
    # See more for the docker socket integration here:
    # https://goauthentik.io/docs/outposts/integrations/docker
    # Removing `user: root` also prevents the worker from fixing the permissions
    # on the mounted folders, so when removing this make sure the folders have the correct UID/GID
    # (1000:1000 by default)
    user: root
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./media:/media
      - ./certs:/certs
      - ./custom-templates:/templates
    env_file:
      - .env
    depends_on:
      - postgresql
      - redis
    networks:
      - frontend

volumes:
  database:
    driver: local
  redis:
    driver: local

networks:
  authentik:
  frontend:
    external: true
```

### **`.env`**

```bash
PG_PASS=password
AUTHENTIK_SECRET_KEY=password
# SMTP Host Emails are sent to
AUTHENTIK_EMAIL__HOST=localhost
AUTHENTIK_EMAIL__PORT=25
# Optionally authenticate (don't add quotation marks to your password)
AUTHENTIK_EMAIL__USERNAME=example@email.com
AUTHENTIK_EMAIL__PASSWORD=password
# Use StartTLS
AUTHENTIK_EMAIL__USE_TLS=false
# Use SSL
AUTHENTIK_EMAIL__USE_SSL=false
AUTHENTIK_EMAIL__TIMEOUT=10
# Email address authentik will send from, should have a correct @domain
AUTHENTIK_EMAIL__FROM=authentik@localhost
```

- **Services**: PostgreSQL for the database, Redis for caching, Authentik server, and a worker for background tasks.
- **Volumes**: Store persistent data for PostgreSQL and Redis.
- **Networks**: Use the **`frontend`** network to allow communication with Traefik.

### **Step 2: Authentication Configuration**

### **`config.yml`**

(This file go in /config/ in your traefik folder)

```bash
http:
  middlewares: 
    middlewares-authentik:
          forwardAuth:
            address: "http://authentik_server:9000/outpost.goauthentik.io/auth/traefik"
            trustForwardHeader: true
            authResponseHeaders:
              - X-authentik-username
              - X-authentik-groups
              - X-authentik-email
              - X-authentik-name
              - X-authentik-uid
              - X-authentik-jwt
              - X-authentik-meta-jwks
              - X-authentik-meta-outpost
              - X-authentik-meta-provider
              - X-authentik-meta-app
              - X-authentik-meta-version
```

Configure Authentik to act as an authentication system for applications behind Traefik using the **`forwardAuth`** middleware. This allows redirecting authentication requests to Authentik.

## **Securing an Application with Traefik and Authentik**

To have an application (e.g., Kuma) managed by Traefik, receive an SSL certificate from Cloudflare, and have access secured via Authentik, follow these steps:

1. **Traefik Labels for the Application**:
    - Use labels in the Docker-compose configuration of the application to define routing rules, HTTPS usage, and integration with Authentik for authentication.
2. **Example of Labels**:
    
    ```yaml
    yamlCopy code
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.domain.com`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls.certresolver=cloudflare"
      - "traefik.http.routers.myapp.middlewares=middlewares-authentik@file"
      - "traefik.http.services.myapp.loadbalancer.server.port=80"
    ```
    
    Replace **`myapp.domain.com`** with your application's domain name and **`80`** with the port your application listens on.
    

## **Conclusion**

Following this documentation, you will have configured Traefik to manage traffic and SSL certificates, as well as Authentik to secure access to your applications. Ensure to replace the placeholders (**`${...}`**) with your actual values and adapt the configurations to your specific environment.