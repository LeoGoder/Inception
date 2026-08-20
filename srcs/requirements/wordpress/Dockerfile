FROM debian:bookworm
RUN apt-get update -y && apt install php8.2-fpm php8.2-mysql php8.2-curl php8.2-gd php8.2-intl php8.2-mbstring php8.2-soap php8.2-xml php8.2-zip php8.2-redis curl -y
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x entrypoint.sh
RUN sed -i 's/listen = \/run\/php\/php8.2-fpm.sock/listen = 9000/g' /etc/php/8.2/fpm/pool.d/www.conf

CMD ["./entrypoint.sh"]