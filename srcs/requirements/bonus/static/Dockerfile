FROM debian:bookworm
RUN apt-get update -y && apt install python3 -y
RUN mkdir -p /var/www/static
COPY index.html /var/www/static/index.html
COPY css.css /var/www/static/css.css
COPY main.js /var/www/static/main.js
COPY test.jpg /var/www/static/test.jpg
COPY toothless.gif /var/www/static/toothless.gif
WORKDIR /var/www/static/
CMD [ "python3", "-m", "http.server", "3000" ]
