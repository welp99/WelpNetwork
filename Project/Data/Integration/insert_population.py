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