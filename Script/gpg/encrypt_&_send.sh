#!/bin/bash

# Dossier contenant les fichiers à chiffrer
directory="/path/to/files"

# Dossier temporaire pour les fichiers chiffrés
encrypted_directory="/tmp/encrypted_files"

# Créer le dossier temporaire s'il n'existe pas
mkdir -p "$encrypted_directory"

# Adresse du serveur de destination
server_address="user@IP_server"

# Dossier de destination sur le serveur
remote_directory="/path/to/files_encrypted"

# Clé publique pour le chiffrement
recipient_email="example@mail.com"

# Boucle sur chaque fichier dans le dossier (sans chiffrer les fichiers déjà chiffrés)
for file in "$directory"/*; do
    if [[ $file != *.gpg ]]; then
        # Chiffrer le fichier
        gpg --yes --encrypt --recipient "$recipient_email" --output "$encrypted_directory/$(basename "$file").gpg" "$file"

        # Vérifier si le chiffrement a réussi
        if [ $? -eq 0 ]; then
            echo "Chiffrement réussi: $file"

            # Envoyer le fichier chiffré
            scp "$encrypted_directory/$(basename "$file").gpg" "$server_address:$remote_directory"

            # Vérifier si l'envoi a réussi
            if [ $? -eq 0 ]; then
                echo "Envoi réussi: $(basename "$file").gpg"
            else
                echo "Échec de l'envoi: $(basename "$file").gpg"
            fi
        else
            echo "Échec du chiffrement: $file"
        fi
    fi
done

echo "Traitement terminé."