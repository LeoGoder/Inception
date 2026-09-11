FROM debian:bookworm
RUN apt-get update -y && apt-get install wget tar vsftpd -y
COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x entrypoint.sh
CMD ["./entrypoint.sh"]
