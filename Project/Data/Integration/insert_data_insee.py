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
fichier_csv = '/scripts/hexa_small.csv'

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