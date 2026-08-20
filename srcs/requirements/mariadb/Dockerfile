FROM debian:bookworm
RUN apt-get update -y && apt-get install -y mariadb-server
RUN mkdir -p /var/run/mysqld /var/log/mysql && \
    chown -R mysql:mysql /var/run/mysqld /var/log/mysql
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY entrypoint.sh /entrypoint.sh
CMD ["./entrypoint.sh"]
