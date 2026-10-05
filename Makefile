all: up

up:
	mkdir -p /home/lgoderne/data/wordpress
	mkdir -p /home/lgoderne/data/mariadb
	mkdir -p /home/lgoderne/data/portainer
	mkdir -p /home/lgoderne/data/database
	cd srcs/ && sudo docker compose up --build -d

down:
	cd srcs/ && sudo docker compose down

show:
	cd srcs/ && sudo docker compose ps

clean:
	cd srcs/ && sudo docker compose -f docker-compose.yml down --rmi all
	sudo docker volume rm database portainer_data website_files
	sudo rm -fr /home/lgoderne/data/wordpress
	sudo rm -fr /home/lgoderne/data/mariadb
	sudo rm -fr /home/lgoderne/data/portainer
	sudo rm -fr /home/lgoderne/data/database

fclean: clean
	sudo docker system prune -a --volumes -f
	sudo docker builder prune -a

re: fclean up
