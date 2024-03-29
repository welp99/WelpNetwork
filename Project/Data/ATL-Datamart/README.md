ATL-Datamart
==============================

Projet pour le cours d'atelier Datamart (TRDE704) pour les I1 de l'EPSI

Project Organization
------------

    ├── LICENSE
    ├── Makefile           <- Makefile with commands like `make data` or `make train`
    ├── README.md          <- The top-level README for developers using this project.
    ├── data
    │   ├── external       <- Data from third party sources.
    │   ├── interim        <- Intermediate data that has been transformed.
    │   ├── processed      <- The final, canonical data sets for modeling.
    │   └── raw            <- The original, immutable data dump.
    │
    ├── docs               <- A default Sphinx project; see sphinx-doc.org for details
    │
    ├── models             <- Trained and serialized models, model predictions, or model summaries
    │
    ├── notebooks          <- Jupyter notebooks. Naming convention is a number (for ordering),
    │                         the creator's initials, and a short `-` delimited description, e.g.
    │                         `1.0-jqp-initial-data-exploration`.
    │
    ├── references         <- Data dictionaries, manuals, and all other explanatory materials.
    │
    ├── reports            <- Generated analysis as HTML, PDF, LaTeX, etc.
    │   └── figures        <- Generated graphics and figures to be used in reporting
    │
    ├── requirements.txt   <- The requirements file for reproducing the analysis environment, e.g.
    │                         generated with `pip freeze > requirements.txt`
    │
    ├── setup.py           <- makes project pip installable (pip install -e .) so src can be imported
    ├── src                <- Source code for use in this project.
    │   ├── __init__.py    <- Makes src a Python module
    │   │
    │   ├── data           <- Scripts to download or generate data
    │   │   └── make_dataset.py
    │   │
    │   ├── features       <- Scripts to turn raw data into features for modeling
    │   │   └── build_features.py
    │   │
    │   ├── models         <- Scripts to train models and then use trained models to make
    │   │   │                 predictions
    │   │   ├── predict_model.py
    │   │   └── train_model.py
    │   │
    │   └── visualization  <- Scripts to create exploratory and results oriented visualizations
    │       └── visualize.py
    │
    └── tox.ini            <- tox file with settings for running tox; see tox.readthedocs.io


--------

<p><small>Project based on the <a target="_blank" href="https://drivendata.github.io/cookiecutter-data-science/">cookiecutter data science project template</a>. #cookiecutterdatascience</small></p>

--------

<aside>
💡 Au cours de cette série de TP, j’ai vu différents aspects de la gestion, de la transformation et de la visualisation des données. Chaque TP a abordé une étape clé dans le travail des données, en commençant par la récupération des données brutes, leur transformation et chargement, jusqu'à l'analyse et la visualisation pour en tirer des insights significatifs.

</aside>

<aside>
💡 Need to used python 3.11

</aside>

## **Créer un environnement virtuel**

python3.11 -m venv atlenv

source atlenv/bin/activate

pip3.11 install -r requierments.txt

pyton3 <app.py>

## **TP 1 : Récupération des Données**

Dans le premier TP, je me suis concentrés sur la récupération des données. En utilisant le script **`grab_parquet.py`**, j’ai téléchargé des fichiers Parquet contenant des données de trajets de taxi à New York. L'objectif était de récupérer des données brutes, c’est la première étape de notre pipeline de données.

**`grab_parquet.py`**

```python
from minio import Minio
from minio.error import S3Error
import urllib.request
import pandas as pd
import sys
import requests
from bs4 import BeautifulSoup
import re
import os

page_url = "https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page"
base_url = "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_{}.parquet"
client = Minio(
        "localhost:9400",
        access_key="minio",
        secret_key="minio123",
        secure=False
    )
directory_path: str = "../../data/raw/"
bucket_name: str = "datalake"
def main():
    grab_data(page_url, base_url, 23, 24, 1, 8, directory_path)
    create_minio_bucket(bucket_name, client)
    upload_file_to_minio(directory_path, bucket_name, client)
    

def grab_data(page_url, base_url, start_year, end_year, start_month, end_month, destination_folder):
    """Grab the data from New York Yellow Taxi

    This method download x files of the New York Yellow Taxi. 
    
    Files need to be saved into "../../data/raw" folder
    This methods takes no arguments and returns nothing.
    """
    # Send an HTTP request to retrieve the content of the page
    response = requests.get(page_url)
    if response.status_code != 200:
        print(f"Failed to retrieve the web page. Status code: {response.status_code}")
        return

    soup = BeautifulSoup(response.text, 'html.parser')

    # Generate list of dates for the specified range
    dates = ["20{:02d}-{:02d}".format(year, month) for year in range(start_year, end_year + 1) 
             for month in range(start_month, end_month + 1)]
    links = [base_url.format(date) for date in dates]

    # Ensure the destination folder exists
    os.makedirs(destination_folder, exist_ok=True)

    for link in links:
        # Generate the filename using the date in the URL
        filename = link.split("/")[-1]

        # Full path for the destination file
        file_path = os.path.join(destination_folder, filename)

        # Test if the link is accessible
        link_response = requests.head(link)
        if link_response.status_code != 200:
            print(f"Download failed for: {filename}. Link not accessible.")
            continue

        # The link is accessible, download the file
        file_response = requests.get(link)
        try:
            with open(file_path, 'wb') as file:
                file.write(file_response.content)
            print(f"Successful download: {filename}")
        except IOError as e:
            print(f"Error writing to file: {filename}. Error: {e}")

    print("All files have been downloaded.")

def create_minio_bucket(bucket_name, minio_client):
    """
    Create a new bucket in MinIO.

    :param bucket_name: The name of the bucket to create.
    :param minio_client: An instance of Minio client.
    """
    try:
        found = minio_client.bucket_exists(bucket_name)
        if not found:
            minio_client.make_bucket(bucket_name)
            print(f"Bucket '{bucket_name}' created successfully.")
        else:
            print(f"Bucket '{bucket_name}' already exists.")
    except S3Error as err:
        print(f"Error occurred: {err}")

def upload_file_to_minio(directory_path, bucket_name, minio_client):
    # Upload each file in the directory
        for filename in os.listdir(directory_path):
            file_path = os.path.join(directory_path, filename)

            if os.path.isfile(file_path):
                file_size = os.path.getsize(file_path)
                with open(file_path, 'rb') as file_data:
                    minio_client.put_object(bucket_name, filename, file_data, length=file_size)

                print(f"File '{filename}' uploaded to bucket '{bucket_name}'.")

if __name__ == '__main__':
    sys.exit(main())
```

## Créer la BDD

```
CREATE DATABASE "nyc_warehouse”
CREATE DATABASE "nyc_datamart" 
```

## **TP 2 : Transformation et Chargement**

Le TP 2 a impliqué l'adaptation du script **`dump_to_sql.py`** pour qu'il puisse traiter les fichiers Parquet stockés dans Minio. Cette étape transforme les données de leur format brut à un format structuré dans une base de données, facilitant ainsi les requêtes et l'analyse ultérieures.

**`dump_to_sql.py`**

```python
import gc
import os
import sys

import pandas as pd
from sqlalchemy import create_engine

from minio import Minio
from io import BytesIO

def get_minio_client():
    return Minio(
        "localhost:9400",
        access_key="minio",
        secret_key="minio123",
        secure=False
    )

def download_files_from_minio(bucket_name, minio_client):
    objects = minio_client.list_objects(bucket_name)
    for obj in objects:
        if obj.object_name.endswith('.parquet'):
            data = minio_client.get_object(bucket_name, obj.object_name)
            yield obj.object_name, BytesIO(data.read())

def write_data_postgres(dataframe: pd.DataFrame) -> bool:
    """
    Dumps a Dataframe to the DBMS engine

    Parameters:
        - dataframe (pd.Dataframe) : The dataframe to dump into the DBMS engine

    Returns:
        - bool : True if the connection to the DBMS and the dump to the DBMS is successful, False if either
        execution is failed
    """
    db_config = {
        "dbms_engine": "postgresql",
        "dbms_username": "postgres",
        "dbms_password": "admin",
        "dbms_ip": "localhost",
        "dbms_port": "15432",
        "dbms_database": "nyc_warehouse",
        "dbms_table": "nyc_raw"
    }

    db_config["database_url"] = (
        f"{db_config['dbms_engine']}://{db_config['dbms_username']}:{db_config['dbms_password']}@"
        f"{db_config['dbms_ip']}:{db_config['dbms_port']}/{db_config['dbms_database']}"
    )
    try:
        engine = create_engine(db_config["database_url"])
        with engine.connect():
            success: bool = True
            print("Connection successful! Processing parquet file")
            dataframe.to_sql(db_config["dbms_table"], engine, index=False, if_exists='append')

    except Exception as e:
        success: bool = False
        print(f"Error connection to the database: {e}")
        return success

    return success

def clean_column_name(dataframe: pd.DataFrame) -> pd.DataFrame:
    """
    Take a Dataframe and rewrite it columns into a lowercase format.
    Parameters:
        - dataframe (pd.DataFrame) : The dataframe columns to change

    Returns:
        - pd.Dataframe : The changed Dataframe into lowercase format
    """
    dataframe.columns = map(str.lower, dataframe.columns)
    return dataframe

def main() -> None:
    bucket_name = "datalake"  
    minio_client = get_minio_client()

    for file_name, file_data in download_files_from_minio(bucket_name, minio_client):
        parquet_df = pd.read_parquet(file_data, engine='pyarrow')
        clean_column_name(parquet_df)
        if not write_data_postgres(parquet_df):
            del parquet_df
            gc.collect()
            return

        del parquet_df
        gc.collect()

if __name__ == '__main__':
    sys.exit(main())
```

## **TP 3 : Modélisation des Données en Modèle Flocon**

Dans le TP 3, nous avons utilisé des requêtes SQL pour modéliser les données dans un schéma en flocon, une approche de modélisation dimensionnelle qui facilite les analyses complexes. Les scripts **`creation.sql`** et **`insertion.sql`** ont été utilisés pour créer les tables nécessaires dans notre Data Mart et y insérer des données depuis notre Data Warehouse. 

**`creation.sql`**

```sql
-- Active: 1680532809848@@192.168.1.23@15432
-- Création des tables de dimensions
CREATE TABLE date_dim (
    date_id SERIAL PRIMARY KEY,
    date DATE,
    day_of_week INT,
    month INT,
    year INT
);

CREATE TABLE time_dim (
    time_id SERIAL PRIMARY KEY,
    hour INT,
    minute INT,
    second INT
);

-- Création de la table de faits
CREATE TABLE taxi_trips (
    trip_id SERIAL PRIMARY KEY,
    pickup_date_id INT,
    pickup_time_id INT,
    dropoff_date_id INT,
    dropoff_time_id INT,
    passenger_count INT,
    trip_distance FLOAT,
    fare_amount FLOAT,
    total_amount FLOAT,
    FOREIGN KEY (pickup_date_id) REFERENCES date_dim(date_id),
    FOREIGN KEY (pickup_time_id) REFERENCES time_dim(time_id),
    FOREIGN KEY (dropoff_date_id) REFERENCES date_dim(date_id),
    FOREIGN KEY (dropoff_time_id) REFERENCES time_dim(time_id)
);
```

**`insertion.sql`**

```sql
-- Active: 1680532809848@@192.168.1.23@15432
-- Insertion dans la table de dimensions 'date_dim'
INSERT INTO date_dim (date, day_of_week, month, year)
SELECT DISTINCT
    DATE(tpep_pickup_datetime) AS date,
    EXTRACT(DOW FROM tpep_pickup_datetime) AS day_of_week,
    EXTRACT(MONTH FROM tpep_pickup_datetime) AS month,
    EXTRACT(YEAR FROM tpep_pickup_datetime) AS year
FROM nyc_raw;

-- Insertion dans la table de dimensions 'time_dim'
INSERT INTO time_dim (hour, minute)
SELECT DISTINCT
    EXTRACT(HOUR FROM tpep_pickup_datetime) AS hour,
    EXTRACT(MINUTE FROM tpep_pickup_datetime) AS minute
FROM nyc_raw;

-- Insertion dans la table de faits 'taxi_trips'
INSERT INTO taxi_trips (
    pickup_date_id, pickup_time_id, dropoff_date_id, dropoff_time_id, passenger_count, trip_distance, fare_amount, total_amount
)
SELECT
    (SELECT date_id FROM date_dim WHERE date = DATE(tpep_pickup_datetime)),
    (SELECT time_id FROM time_dim WHERE hour = EXTRACT(HOUR FROM tpep_pickup_datetime) AND minute = EXTRACT(MINUTE FROM tpep_pickup_datetime)),
    (SELECT date_id FROM date_dim WHERE date = DATE(tpep_dropoff_datetime)),
    (SELECT time_id FROM time_dim WHERE hour = EXTRACT(HOUR FROM tpep_dropoff_datetime) AND minute = EXTRACT(MINUTE FROM tpep_dropoff_datetime)),
    passenger_count,
    trip_distance,
    fare_amount,
    total_amount
FROM nyc_raw;
```

## **TP 4 : Exploration Data Analysis et Visualisation**

Enfin, le TP 4 j’ai exploré les données à l'aide d'un Notebook Jupyter, en effectuant une analyse des données (EDA) et en produisant des visualisations pour comprendre mieux les tendances et les modèles dans les données. 

**`eda.py`**

```python
import pandas as pd
import sqlalchemy
import matplotlib.pyplot as plt
import seaborn as sns

# Connexion à la base de données

engine = sqlalchemy.create_engine('postgresql://postgre:admin@192.168.1.23:15432/nyc_warehouse')
conn = engine.connect()

# Exécution d'une requête et chargement des données dans un DataFrame

query = "SELECT * FROM taxi_trips"  # Modifiez ceci selon vos besoins
df = pd.read_sql(query, conn)
conn.close()

EDA de base

print(df.describe())
print([df.info](http://df.info/)())

# Visualisation de base

plt.figure(figsize=(10, 6))
sns.countplot(data=df, x='passenger_count')
plt.title('Distribution du Nombre de Passagers')
plt.show()
```
