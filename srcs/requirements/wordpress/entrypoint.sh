#!/bin/bash

while ! nc -z mariadb 3306; do
    sleep 1
done
source /run/secrets/db
source /run/secrets/user
cd /var/www/html
if [ ! -f "wp-login.php" ]; then
    wp core download --allow-root
    wp config create --dbname=$DBNAME --dbuser=$DBUSER --dbpass=$UMDP --dbhost=mariadb --allow-root
    wp core install --url=$DOMAIN_NAME --title="Inception" --admin_user=$WP_ADMIN --admin_password=$WP_ADMINPWD --admin_email=$WP_ADMINMAIL --allow-root
    wp user create $WP_USER $WP_USERMAIL --role=author --user_pass=$WP_USERPWD --allow-root
    wp config set WP_REDIS_HOST 'redis' --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --allow-root
    wp config set WP_CACHE true --raw --allow-root
    wp plugin install redis-cache --activate --allow-root
    wp redis enable --allow-root
fi
exec /usr/sbin/php-fpm8.2 -F
