run: up

up:
	mkdir -p /home/lgoderne/data/wordpress
	mkdir -p /home/lgoderne/data/mariadb
	cd srcs/ && sudo docker compose up --build -d

down:
	cd srcs/ && sudo docker compose down

show:
	cd srcs/ && sudo docker compose ps

clean:
	sudo docker compose -f srcs/docker-compose.yml down --rmi all
	sudo rm -fr /home/lgoderne/data/wordpress
	sudo rm -fr /home/lgoderne/data/mariadb

fclean: clean
	sudo docker system prune -a --volumes -f
