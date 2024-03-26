## **Intro**

Passbolt is a free, open-source, self-hosted password manager designed for teamwork. It allows teams to securely store and share passwords and other sensitive information.

### **Prerequisites:**

- Docker Engine installed on your system.
- docker-compose installed on your system.
- A domain and a DNS configured for your Passbolt server.

### **`docker-compose.yml`**

```
---
volumes:
  passbolt-db:
  passbolt-data-gpg:
  passbolt-data-jwt:
services:
  passbolt-db:
    container_name: passbolt-db
    image: mariadb:10.3
    environment:
      - MYSQL_RANDOM_ROOT_PASSWORD=true
      - MYSQL_DATABASE=$PASSBOLT_DB_NAME
      - MYSQL_USER=$PASSBOLT_DB_USER
      - MYSQL_PASSWORD=$PASSBOLT_DB_PASS
    volumes:
      - passbolt-db:/var/lib/mysql
    restart: unless-stopped
    networks:
      - backend
  passbolt:
    container_name: passbolt-app
    image: passbolt/passbolt:latest-ce
    depends_on:
      - passbolt-db
    environment:
      - APP_FULL_BASE_URL=https://passbolt.your-domain.com
      - DATASOURCES_DEFAULT_HOST=passbolt-db
      - DATASOURCES_DEFAULT_USERNAME=$PASSBOLT_DB_USER
      - DATASOURCES_DEFAULT_PASSWORD=$PASSBOLT_DB_PASS
      - DATASOURCES_DEFAULT_DATABASE=$PASSBOLT_DB_NAME
      - EMAIL_TRANSPORT_DEFAULT_HOST=smtp.gmail.com
      - EMAIL_TRANSPORT_DEFAULT_PORT=587
      - EMAIL_TRANSPORT_DEFAULT_USERNAME=$EMAIL_TRANSPORT_DEFAULT_USERNAME
      - EMAIL_TRANSPORT_DEFAULT_PASSWORD=$EMAIL_TRANSPORT_DEFAULT_PASSWORD
      - EMAIL_TRANSPORT_DEFAULT_TLS=true
      - EMAIL_DEFAULT_FROM=no-reply@domain.tld
    volumes:
      - passbolt-data-gpg:/etc/passbolt/gpg
      - passbolt-data-jwt:/etc/passbolt/jwt
    command: ["/usr/bin/wait-for.sh", "-t", "0", "passbolt-db:3306", "--", "/docker-entrypoint.sh"]
    restart: unless-stopped
    networks:
      - frontend
      - backend
    labels:
      - traefik.enable=true
      - traefik.http.routers.passbolt.rule=Host(`passbolt.your-domain.com`)
      - traefik.http.routers.passbolt.entrypoints=web
      - traefik.http.routers.passbolt-secure.entrypoints=websecure
      - traefik.http.routers.passbolt-secure.rule=Host(`passbolt.your-domain.com`)
      - traefik.http.routers.passbolt-secure.tls=true
      - traefik.http.routers.passbolt-secure.tls.certresolver=cloudflare

networks:
  frontend:
    external: true
  backend:
    external: true
```

### **`.env`**

```bash
PASSBOLT_DB_USER=
PASSBOLT_DB_PASS=
PASSBOLT_DB_NAME=

EMAIL_TRANSPORT_DEFAULT_USERNAME=
EMAIL_TRANSPORT_DEFAULT_PASSWORD=
```

### **Steps:**

1. **Create a docker-compose.yml file**: Copy the content of your docker-compose into a file named **`docker-compose.yml`**.
2. **Configure environment variables**:
    - Replace the environment variables **`$PASSBOLT_DB_NAME`**, **`$PASSBOLT_DB_USER`**, **`$PASSBOLT_DB_PASS`**, **`$EMAIL_TRANSPORT_DEFAULT_USERNAME`**, and **`$EMAIL_TRANSPORT_DEFAULT_PASSWORD`** with the corresponding values in the **`.env`** file.
    - Ensure that the volumes **`passbolt-db`**, **`passbolt-data-gpg`**, and **`passbolt-data-jwt`** are correctly configured to store the database data and Passbolt data.
3. **Define your Passbolt application settings**:
    - Configure settings such as the base URL (**`APP_FULL_BASE_URL`**), database information (**`DATASOURCES_DEFAULT_HOST`**, **`DATASOURCES_DEFAULT_USERNAME`**, **`DATASOURCES_DEFAULT_PASSWORD`**, **`DATASOURCES_DEFAULT_DATABASE`**), and email settings (**`EMAIL_TRANSPORT_DEFAULT_HOST`**, **`EMAIL_TRANSPORT_DEFAULT_PORT`**, **`EMAIL_TRANSPORT_DEFAULT_TLS`**, **`EMAIL_DEFAULT_FROM`**) according to your setup.
4. **Configure Traefik (optional)**:
    - If you're using Traefik as a reverse proxy, ensure that the labels in the Passbolt service are correctly configured to work with Traefik. These labels define the rules for accessing Passbolt through Traefik.
5. **Launch Passbolt**:
    - Open a terminal, navigate to the directory containing your **`docker-compose.yml`** file, and run the following command:
        
        ```
        docker-compose up -d
        ```
        
    
    This will launch Passbolt in the background.
    
6. **Check container status**:
    - Verify that the containers are running using the following command:
        
        ```
        docker-compose ps
        ```
        
    
    Ensure that the **`passbolt-db`** and **`passbolt-app`** containers are in the "Up" state.
    
7. **Access Passbolt**:
    - Open a web browser and access the URL you defined for your Passbolt application (e.g., **`https://passbolt.your-domain.com`**). You should see the Passbolt interface.
8. **Configure Passbolt**:
    - Follow the on-screen instructions to complete the initial configuration of Passbolt, including creating the first admin user.
9. **Create the first user**:
    - Run the following command to create the first user (replace the email, first name, and last name with your desired values):
        
        ```bash
        docker exec <passbolt_container_id> su -m -c "bin/cake passbolt register_user -u example@email.com -f <name> -l <lastname> -r admin" -s /bin/sh www-data
        ```
        
    
    This command registers a new user with the email **`example@email.com`**, first name **`<name>`**, last name **`<lastname>`**, and assigns them the admin role.
    
10. **Configure email (optional)**:
    - If you've configured email sending for notifications, ensure that the email settings are correct and that emails are sent successfully.
11. **Configure Traefik (optional)**:
    - Ensure that Traefik is correctly configured to route traffic to Passbolt using the labels defined in the **`docker-compose.yml`** file.

Congratulations, you have now set up Passbolt with Docker and created the first user! You can start using Passbolt to securely manage your passwords.