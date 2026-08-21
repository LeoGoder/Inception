FROM debian:bookworm
RUN apt-get update -y && apt install php8.2-fpm php8.2-mysql php8.2-curl php8.2-gd php8.2-intl php8.2-mbstring php8.2-soap php8.2-xml php8.2-zip php8.2-redis curl -y
RUN mkdir -p /var/www/html && mkdir -p /run/php
RUN curl -L -o /var/www/html/adminer.php https://github.com/vrana/adminer/releases/download/v6.0.1/adminer-6.0.1.php
RUN sed -i 's/listen = \/run\/php\/php8.2-fpm.sock/listen = 9000/g' /etc/php/8.2/fpm/pool.d/www.conf
CMD ["/usr/sbin/php-fpm8.2", "-F"]
