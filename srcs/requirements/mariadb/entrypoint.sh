#!/bin/bash

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

mysqld_safe &
sleep 5

source /run/secrets/db
source /run/secrets/user

mariadb -e "
CREATE DATABASE IF NOT EXISTS ${DBNAME};
CREATE USER IF NOT EXISTS '${DBUSER}'@'%' IDENTIFIED BY '${UMDP}';
GRANT ALL PRIVILEGES ON ${DBNAME}.* TO '${DBUSER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DBMDP}';
FLUSH PRIVILEGES;
USE ${DBNAME};
CREATE TABLE IF NOT EXISTS users (id INT, nom varchar(50));
SHOW TABLES;
"

wait
