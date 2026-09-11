#!/bin/bash

source /run/secrets/ftp

if ! id -u "$FTPUSER" > /dev/null 2>&1; then
    echo $FTPUSER
    useradd -d /var/www/html $FTPUSER
    echo "$FTPUSER:$FTPPASSWORD" | chpasswd
    chown -R $FTPUSER:$FTPUSER /var/www/html
fi
mkdir -p /var/run/vsftpd/empty
exec /usr/sbin/vsftpd /etc/vsftpd.conf
