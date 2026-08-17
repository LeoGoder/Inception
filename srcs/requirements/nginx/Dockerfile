FROM debian:bookworm
RUN apt-get update -y && apt-get install -y nginx openssl \
    && mkdir -p /etc/nginx/ssl/ \
    && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=FR/ST=ARA/L=Lyon/O=42/OU=42/CN=lgoderne.42.fr"

COPY conf/nginx.conf /etc/nginx/nginx.conf
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
