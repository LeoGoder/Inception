#!/bin/bash

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

mysqld_safe &
sleep 5


mariadb -e"
CREATE DATABASE IF NOT EXISTS data;
CREATE USER IF NOT EXISTS '${USER}'@'%' IDENTIFIED BY '${UMDP}';
GRANT ALL PRIVILEGES ON data.* TO '${USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DBMDP}';
FLUSH PRIVILEGES;
USE data;
CREATE TABLE IF NOT EXISTS users (id INT, nom varchar(50));
SHOW TABLES;
"

wait
