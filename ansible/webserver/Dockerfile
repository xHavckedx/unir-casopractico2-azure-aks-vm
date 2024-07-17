# Usar la imagen base de nginx
FROM nginx:alpine

# Instalar openssl para generar el certificado autofirmado
RUN apk add --no-cache openssl

# Crear directorios necesarios
RUN mkdir -p /etc/nginx/certs /etc/nginx/conf.d /var/www/html

# Generar el certificado x.509 autofirmado
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/certs/selfsigned.key \
    -out /etc/nginx/certs/selfsigned.crt \
    -subj "/CN=localhost"

# Copiar la configuración de Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Copiar el archivo HTML
COPY index.html /var/www/html/index.html

# Añadir un script para crear las credenciales de autenticación básica
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Exponer el puerto 443
EXPOSE 443

# Establecer el punto de entrada
ENTRYPOINT ["/entrypoint.sh"]

