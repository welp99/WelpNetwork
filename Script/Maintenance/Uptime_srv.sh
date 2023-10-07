#!/bin/bash

# Liste des serveurs à interroger
servers=("serveur1" "serveur2" "serveur3")

# Nom du fichier CSV
csv_filename="uptime.csv"

# Vérifier si le fichier CSV existe
if [ ! -e "$csv_filename" ]; then
    touch "$csv_filename"
    echo "Serveur,Uptime" >> "$csv_filename"
fi

# Fonction pour obtenir l'uptime d'un serveur
get_uptime() {
    server_address="$1"
    uptime_result=$(ssh user@$server_address "uptime -p")
    echo "$server_address,$uptime_result"
}

# Boucle sur la liste des serveurs
for server in "${servers[@]}"; do
    # Obtenir l'uptime du serveur actuel
    uptime_data=$(get_uptime "$server")

    # Remplacer l'uptime précédent du même serveur dans le fichier CSV
    grep -v "$server" "$csv_filename" > "$csv_filename.tmp"
    echo "$uptime_data" >> "$csv_filename.tmp"
    mv "$csv_filename.tmp" "$csv_filename"

    echo "Uptime du serveur $server enregistré dans $csv_filename"
done
