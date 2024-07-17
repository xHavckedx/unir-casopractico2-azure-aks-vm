#!/bin/sh

# Generar el archivo htpasswd con las credenciales proporcionadas
if [ -n "$USER" ] && [ -n "$PASSWORD" ]; then
    htpasswd -bc /etc/nginx/.htpasswd "$USER" "$PASSWORD"
else
    echo "No se han proporcionado las variables de entorno USER y PASSWORD."
    exit 1
fi

# Reemplazar las credenciales en el archivo HTML
sed -i "s/\$(echo -n \$USER | base64)/$(echo -n $USER | base64)/g" /var/www/html/index.html
sed -i "s/\$(echo -n \$PASSWORD | base64)/$(echo -n $PASSWORD | base64)/g" /var/www/html/index.html

# Iniciar Nginx
nginx -g "daemon off;"

