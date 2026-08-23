FROM debian:bookworm
RUN apt-get update -y && apt install wget redis-server -y
COPY conf/redis.conf /etc/redis/redis.conf
CMD [ "redis-server" , "/etc/redis/redis.conf", "--daemonize" , "no", "--protected-mode" , "no" ]
