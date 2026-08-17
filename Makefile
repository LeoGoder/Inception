run: up

up:
	cd srcs/ && sudo docker compose up --build -d

down:
	cd srcs/ && sudo docker compose down

show:
	cd srcs/ && sudo docker compose ps

clean:
	sudo docker compose -f srcs/docker-compose.yml down --rmi all

fclean: clean
	sudo docker system prune -a --volumes -f
