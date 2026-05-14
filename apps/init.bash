#!/bin/bash

# Función para listar los entornos virtuales en el directorio actual
list_venvs() {
    echo "Entornos virtuales disponibles:"
    for file in _backup_*.tar.gz; do
        if [ -f "$file" ]; then
            echo "  - ${file#_backup_}" | sed 's/.tar.gz$//'
        fi
    done
}

# Función para encriptar la contraseña
encrypt_password() {
    echo -n "$1" | xxd -p
}

# Verificar si se pasaron argumentos al script
if [ "$#" -ge 4 ]; then
    OPTION=$1
    VENV_NAME=$2
    USERNAME=$3
    PASSWORD=$4
else
    # Si no se pasaron argumentos, solicitar entrada del usuario
    echo "Selecciona una opción:"
    echo "1. Activar o crear un entorno virtual"
    echo "2. Listar entornos virtuales"
    echo "3. Desactivar y eliminar un entorno virtual"
    echo "4. Iniciar sesión en un entorno virtual"
    read -p "Opción: " OPTION

    if [ "$OPTION" -eq 1 ] || [ "$OPTION" -eq 4 ]; then
        read -p "Introduce el nombre del entorno virtual: " VENV_NAME
        read -p "Introduce el nombre de usuario: " USERNAME
        read -sp "Introduce la contraseña: " PASSWORD
        echo
    elif [ "$OPTION" -eq 3 ]; then
        read -p "Introduce el nombre del entorno virtual a eliminar: " VENV_NAME
    fi
fi

# Ejecutar la opción seleccionada
case $OPTION in
    1)
        VENV_NAME="${VENV_NAME%/}"
        TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")
        ARCHIVE_NAME="_backup_${VENV_NAME}_${TIMESTAMP}.tar.gz"

        if ls _backup_${VENV_NAME}_*.tar.gz 1> /dev/null 2>&1; then
            echo "El entorno virtual ya existe. Por favor, selecciona otra opción."
            exit 1
        else
            echo "El entorno virtual no existe. Creándolo..."
            python3 -m venv "$VENV_NAME"
            if [ $? -eq 0 ]; then
                echo "Entorno virtual creado exitosamente."
                ENCRYPTED_PASSWORD=$(encrypt_password "$PASSWORD")
                echo "$USERNAME:$ENCRYPTED_PASSWORD" > "$VENV_NAME/.credentials"
                echo "Usuario y contraseña guardados en el entorno virtual."
                echo "Comprimiendo el entorno virtual..."
                tar -czf - "$VENV_NAME" | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -pass pass:"$PASSWORD" -out "$ARCHIVE_NAME"
                if [ $? -eq 0 ]; then
                    echo "Entorno virtual comprimido exitosamente en '$ARCHIVE_NAME'."
                    rm -rf "$VENV_NAME"
                    echo "Carpeta del entorno virtual eliminada."
                else
                    echo "Error: No se pudo comprimir el entorno virtual."
                    exit 1
                fi
            else
                echo "Error: No se pudo crear el entorno virtual."
                exit 1
            fi
        fi
        ;;
    2)
        list_venvs
        ;;
    3)
        ARCHIVE_NAME=$(ls _backup_${VENV_NAME}_*.tar.gz 2>/dev/null)
        if [ -f "$ARCHIVE_NAME" ]; then
            echo "Eliminando el archivo comprimido '$ARCHIVE_NAME'..."
            rm -f "$ARCHIVE_NAME"
            echo "Archivo comprimido eliminado exitosamente."
        else
            echo "Error: El archivo comprimido para '$VENV_NAME' no existe."
        fi
        ;;
    4)
        ARCHIVE_NAME=$(ls _backup_${VENV_NAME}_*.tar.gz 2>/dev/null)
        if [ -f "$ARCHIVE_NAME" ]; then
            if openssl enc -d -aes-256-cbc -salt -pbkdf2 -iter 100000 -in "$ARCHIVE_NAME" -pass pass:"$PASSWORD" -out decrypted.tar.gz; then
                tar -xzf decrypted.tar.gz && rm -f decrypted.tar.gz
            else
                echo "Error: No se pudo descomprimir el archivo. Contraseña incorrecta o archivo corrupto."
                exit 1
            fi
            if [ $? -eq 0 ]; then
                echo "Archivo descomprimido exitosamente."
                if [ -f "$VENV_NAME/.credentials" ]; then
                    STORED_CREDENTIALS=$(cat "$VENV_NAME/.credentials")
                    STORED_USERNAME=$(echo "$STORED_CREDENTIALS" | cut -d':' -f1)
                    STORED_PASSWORD=$(echo "$STORED_CREDENTIALS" | cut -d':' -f2)
                    ENCRYPTED_PASSWORD=$(encrypt_password "$PASSWORD")
                    if [ "$STORED_USERNAME" == "$USERNAME" ] && [ "$ENCRYPTED_PASSWORD" == "$STORED_PASSWORD" ]; then
                        echo "Inicio de sesión exitoso. Activando el entorno virtual..."
                        bash --rcfile <(echo "source $VENV_NAME/bin/activate")
                    else
                        echo "Error: Credenciales incorrectas."
                    fi
                else
                    echo "Error: No se encontraron credenciales en el entorno virtual."
                fi
            else
                echo "Error: No se pudo descomprimir el archivo. Contraseña incorrecta."
            fi
        else
            echo "Error: El archivo comprimido para '$VENV_NAME' no existe."
        fi
        ;;
    *)
        echo "Opción no válida."
        exit 1
        ;;
esac
