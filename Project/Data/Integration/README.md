# TP INSEE

<aside>
💡 In the context of this exercise, I created a MySQL database in a Docker environment, designed a table suitable for data from an INSEE CSV file, configured a user dedicated to the table, and developed a Python script to efficiently import this data from the CSV file. This practical work aims to demonstrate our skills in data management and integration, while highlighting the solutions used and their aspects in terms of security and data integrity.

</aside>


# Configuration de l'Environnement

## Docker MySQL :

I used a MySQL docker for my database. Its simple and quick to install. 

## VSCode :

I chose VSCode as my IDE for its versatility and compatibility with database extensions. I installed the MySQL database management extension directly from VSCode.

## Création de l'Utilisateur et de la table :

In MySQL, I created a specific user named "insee_app." Afterward, I created the "communes" table and added appropriate privileges to access the table, which I would use to store the INSEE data.

## Ansible :

J’utilise ansible pour lancer le script sur le serveur d’application. Les identifiants de connexion a la base de donnée sont transmis au script avec ansible. 

docker compose 

```
version: '3'
services:
  mysql:
    image: mysql:latest
    container_name: welpdb
    environment:
      MYSQL_ROOT_PASSWORD: <root_password>
      MYSQL_DATABASE: <db_name>
      MYSQL_USER: <user_name>
      MYSQL_PASSWORD: <password>
    ports:
      - "3306:3306"
    volumes:
      - /mnt/storage/mysql_data_welpdb:/var/lib/mysql
```

```sql
CREATE TABLE communes2 (
    Code_commune_INSEE INT(10) NOT NULL,
    Nom_de_la_commune VARCHAR(255) NOT NULL,
    Code_postal INT(10) NOT NULL,
    PRIMARY KEY (Code_commune_INSEE)
);
```

Creation User 

```
CREATE USER 'insee_app'@'192.168.1.34' IDENTIFIED BY 'insee';
```

User Acces 

```
GRANT USAGE,SELECT,INSERT,DELETE,UPDATE ON communes TO 'insee_app'@'192.168.1.34';
```

Requierment 

```
mysql-connector-python==8.0.23

sudo apt install mysql-client-core-8.0
```

Playbook Ansible 

```
#tp_insee/main.yml
---
- name: Exécuter un script sur un serveur distant
  hosts: all
  become: yes

  tasks:
    - name: Exécuter le script Python avec les variables
      command: python3 /scripts/insert_data_insee.py --host '{{ mysql_host }}' --user '{{ mysql_user }}' --port '{{ mysql_port|int }}' --password '{{ mysql_password }}' --database '{{ mysql_database }}'
```

Inventaire Ansible 

```
node1.welpnetwork.com mysql_host=192.168.1.34 mysql_user=insee_app mysql_port=3333 mysql_password=insee mysql_database=welpdb
```

Schéma de fichier ansible 

```
tp_insee/
├── roles/
		├── id_welpdb/
│   └── main.yml
└── main.yml
```

```python
#!/usr/bin/env python3
import sys
import csv
import mysql.connector

host = sys.argv[sys.argv.index("--host") + 1]
user = sys.argv[sys.argv.index("--user") + 1]
port = int(sys.argv[sys.argv.index("--port") + 1])
password = sys.argv[sys.argv.index("--password") + 1]
database = sys.argv[sys.argv.index("--database") + 1]

# Connexion à la BDD
conn = mysql.connector.connect(
    host=host,
    user=user,
    port=port,
    password=password,
    database=database
)
cursor = conn.cursor()

# Chemin vers le fichier CSV
fichier_csv = 'Hexa Small.csv'

# Lecture du fichier CSV et insertion des données dans la table 'communes'
with open(fichier_csv, 'r', newline='', encoding='iso-8859-1') as csvfile:
    csv_reader = csv.reader(csvfile, delimiter=';')  # Spécifie le délimiteur
    next(csv_reader)  # Ignore la première ligne si elle contient les en-têtes

    # Assurez-vous que l'ordre des colonnes dans le fichier CSV correspond à la structure de la table
    for row in csv_reader:    
        code_commune_INSEE = row[0]
        nom_de_la_commune = row[1]
        code_postal = row[2]

        # Insérer les données dans la table 'communes' et mettre à jour en cas de doublon
        cursor.execute('''
            INSERT INTO communes2 (Code_commune_INSEE, Nom_de_la_commune, Code_postal)
            VALUES (%s, %s, %s)
            ON DUPLICATE KEY UPDATE
            Nom_de_la_commune = VALUES(Nom_de_la_commune),
            Code_postal = VALUES(Code_postal)
        ''', (code_commune_INSEE, nom_de_la_commune, code_postal))

conn.commit()
conn.close()
```

## Result

![Untitled](https://prod-files-secure.s3.us-west-2.amazonaws.com/bda25b28-90cb-4bb1-b230-9312482e55f1/907ea09e-e769-4aa8-bc70-47296c66f9b3/Untitled.png)

Trigger NOK

```
CREATE PROCEDURE LogConnexion(IN utilisateur_name VARCHAR(255))
BEGIN
    INSERT INTO ConnexionLog (utilisateur) VALUES (utilisateur_name);
END;
```

```
CREATE TABLE IF NOT EXISTS ConnexionLog (
    id INT AUTO_INCREMENT PRIMARY KEY,
    utilisateur VARCHAR(255),
    date_connexion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

View 

```
CREATE VIEW view_communes_du_nord
AS
SELECT * FROM communes2
WHERE LEFT(code_postal, 2) IN ('59', '62');
```

add colonne population 

```
ALTER TABLE communes2
ADD COLUMN Population INT(255);
```

add population to table  with API

```
cat insert_population.py
#!/usr/bin/env python3

import requests
import mysql.connector
import sys

host = sys.argv[sys.argv.index("--host") + 1]
user = sys.argv[sys.argv.index("--user") + 1]
port = int(sys.argv[sys.argv.index("--port") + 1])
password = sys.argv[sys.argv.index("--password") + 1]
database = sys.argv[sys.argv.index("--database") + 1]

# Connexion à la BDD
conn = mysql.connector.connect(
    host=host,
    user=user,
    port=port,
    password=password,
    database=database
)
cursor = conn.cursor()

# URL de l'API
api_url = "https://geo.api.gouv.fr/communes/{}"

# Récupération des 10 premières communes de la base de données
cursor.execute("SELECT Code_commune_INSEE FROM communes2 LIMIT 100")
communes = cursor.fetchall()

# Boucle sur les 10 premières communes
for commune in communes:
    code_commune_insee = commune[0]

    # Appel à l'API pour obtenir les données de la commune
    response = requests.get(api_url.format(code_commune_insee))

    # Traitement de la réponse JSON
    if response.status_code == 200:
        commune_data = response.json()

        # Récupération de la population depuis les données de la commune
        population = commune_data.get("population", None)

        # Vérification de la présence de la population
        if population is not None:
            # Mise à jour de la base de données
            update_query = "UPDATE communes2 SET Population = %s WHERE Code_commune_INSEE = %s"
            cursor.execute(update_query, (population, code_commune_insee))
            conn.commit()

# Fermeture de la connexion
cursor.close()
conn.close()
```
# TP INSEE 2

<aside>
💡 In this exercise, we have established an automated process to enrich our INSEE  database with population information. To achieve this, we utilized Ansible to execute a Python script on a remote server, which leveraged the government API to retrieve population data for each INSEE code. Here is an overview of the key steps in our approach:

</aside>

[Operational procedure](https://www.notion.so/Operational-procedure-c67e7f4250e64c618f01a0787dba176b?pvs=21)

# Technology used

## Docker Ansible

https://hub.docker.com/r/semaphoreui/semaphore

Ansible Semaphore is a modern UI for Ansible. It lets you easily run Ansible playbooks, get notifications about fails, control access to deployment system.

## Docker MySQL

I used a MySQL docker for my database. Its simple and quick to install. 

You need to install mysql connecteur on the distant server. 

```python
sudo apt install python3-mysql.connector
```

## Docker Vault

Vault, developed by HashiCorp, is a secret management tool that allows storing, managing, and controlling access to tokens, passwords, certificates, API keys, and other secrets.

```python
version: '3'

services:
  vault: 
    image: hashicorp/vault
    container_name: vault
    ports: 
      - "8200:8200"
    volumes:
      - ./vault:/vault/file
      - ./config:/vault/config
    restart: always
```

## GitHub

https://github.com/welp99/TP_master

I used GitHub to host my Ansible playbooks and enable a Docker container to execute these playbooks by fetching them from my GitHub repository

## VIEW

We began by creating an SQL view named "view_communes_du_nord" by filtering data from the "communes2" table to display only the communes with postal codes starting with '59' or '62,' representing the Nord Pas de Calais region.

```
CREATE VIEW view_communes_du_nord
AS
SELECT * FROM communes2
WHERE LENGTH(code_postal) = 5 AND LEFT(code_postal, 2) IN ('59', '62');
```

## ADD COLUMN POPULATION

Next, we extended the structure of the "communes2" table by adding a new column named "Population," with an INTEGER data type. This column would be used to store the population data we would retrieve.

```
ALTER TABLE communes2
ADD COLUMN Population INT(255);
```

## ADD POPULATION WITH API

We developed a Python script, "insert_population.py," which was executed on a remote server using Ansible. This script iterated through the first 100 INSEE codes in the "communes2" table, made API calls with each code, and fetched population information for each commune.

```
import requests
import mysql.connector
import sys

host = sys.argv[sys.argv.index("--host") + 1]
user = sys.argv[sys.argv.index("--user") + 1]
port = int(sys.argv[sys.argv.index("--port") + 1])
password = sys.argv[sys.argv.index("--password") + 1]
database = sys.argv[sys.argv.index("--database") + 1]

# Connexion à la BDD
conn = mysql.connector.connect(
    host=host,
    user=user,
    port=port,
    password=password,
    database=database
)
cursor = conn.cursor()

# URL de l'API 
api_url = "https://geo.api.gouv.fr/communes/{}"

# Récupération des données de la base de données
cursor.execute("SELECT Code_commune_INSEE FROM communes2 LIMIT 100")
communes = cursor.fetchall()

# Boucle sur les communes
for commune in communes:
    code_commune_insee = commune[0]

    # Appel à l'API pour obtenir les données de population
    params = {
        "code_commune_insee": code_commune_insee
    }
    response = requests.get(api_url.format(code_commune_insee))

    # Traitement de la réponse JSON
    if response.status_code == 200:
        population_data = response.json()
        population = population_data.get("population", None)

        # Mise à jour de la base de données
        if population is not None:
            update_query = "UPDATE communes2 SET Population = %s WHERE Code_commune_INSEE = %s"
            cursor.execute(update_query, (population, code_commune_insee))
            conn.commit()

# Fermeture de la connexion
cursor.close()
conn.close()
```

## Ansible vault

- Create a vault file

```python
ansible-vault create vault.yml
```

- Put a password
- list variable you need to crypt

```python
ANSIBLE_TOKEN: hvs.yyKFrGYsiknu9Qs7XiJTPI2u
```

without the password the file look like this 

```yaml
$ANSIBLE_VAULT;1.1;AES256
63336439666535393162393064613833343266366439646430326361653038353464623466653236
3735363733326161643637393839623332613864343164350a336234613536646262376561386533
38313039303866396336633866616430316236316239633161313663636538326264386361613361
3638313635336436370a333463373036326236313531613832353762656137626134383334633434
37613465666663616439343836623532643835393231346261386232363830373137346563363030
3466353664373034333838333264633265333239313663623331
```

## Vault Secret

```
{
  "mysql_database": "welpdb",
  "mysql_host": "192.168.1.27",
  "mysql_password": "insee",
  "mysql_port": "3333",
  "mysql_user": "insee_app"
}
```

## Ansible playbook

The "insert_population.yml" Ansible playbook is a YAML file that defines a set of tasks and instructions for Ansible to execute on the target server(s) specified in the inventory. In this playbook, we have the following tasks.

```yaml
---
- name: Exécuter un script sur un serveur distant
  hosts: node2
  become: yes
	vars_files:
    - "./vault.yml"

  tasks:
    - name: Copier le script
      copy:
        src: ./insert_population.py  
        dest: /scripts/insert_population.py  
      become: yes

    - name: Return secrets
      set_fact:
        vault_secrets: "{{ lookup('community.general.hashi_vault', 'secret=secret/data/database token={{ANSIBLE_TOKEN}} url=http://192.168.1.23:8200')}}"

    - name: Exécuter le script Python avec les variables de Vault
      command: >
        python3 /scripts/insert_population.py
        --host "{{ vault_secrets.data.mysql_host | default(vault_secrets.mysql_host) }}"
        --user "{{ vault_secrets.data.mysql_user | default(vault_secrets.mysql_user) }}"
        --port "{{ vault_secrets.data.mysql_port | default(vault_secrets.mysql_port) }}"
        --password "{{ vault_secrets.data.mysql_password | default(vault_secrets.mysql_password) }}"
        --database "{{ vault_secrets.data.mysql_database | default(vault_secrets.mysql_database) }}"
   
    - name: Supprimer le script
      file: 
        path: /scripts/insert_population.py
        state: absent
      become: yes
```