#!/bin/bash

# Dossier contenant les fichiers .gpg
directory="/path/to/files_encrypted"

# Dossier de sortie pour les fichiers déchiffrés
output_directory="/path/to/files_decrypted"

# Créer le dossier de sortie s'il n'existe pas
mkdir -p "$output_directory"

# Boucle sur chaque fichier .gpg dans le dossier
for file in "$directory"/*.gpg; do
    # Extraire le nom de base sans l'extension .gpg
    base_name=$(basename "$file" .gpg)

    # Déchiffrer le fichier
    gpg --yes --decrypt --output "$output_directory/$base_name" "$file"

    # Vérifier si le déchiffrement a réussi
    if [ $? -eq 0 ]; then
        echo "Déchiffrement réussi: $file"
    else
        echo "Échec du déchiffrement: $file"
    fi
done

echo "Traitement terminé."