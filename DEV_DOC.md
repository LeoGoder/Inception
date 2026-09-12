# Inception — Developer Documentation (`DEV_DOC.md`)

This guide is intended for developers, DevOps engineers, and evaluators who need to understand the internal architecture, set up the project from scratch, manage containers and volumes, and debug the **Inception** stack.

## 1. Environment Setup from Scratch

### System Prerequisites
The project must run inside a Linux virtual machine (Debian 12 Bookworm or Ubuntu 22.04+ recommended).

Ensure the following packages are installed:
```bash
sudo apt-get update
sudo apt-get install -y \
    docker.io \
    docker-compose-v2 \
    make \
    curl \
    openssl \
    netcat-openbsd \
    git
```

Enable non-root Docker execution:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

---

### Host DNS Configuration
Add the project domain `lgoderne.42.fr` to `/etc/hosts` pointing to loopback:
```bash
sudo bash -c 'echo "127.0.0.1 lgoderne.42.fr" >> /etc/hosts'
```

Verify DNS resolution:
```bash
ping -c 1 lgoderne.42.fr
```

---

### Host Data Directory Structure
The subject specifies that named volumes must persist in `/home/lgoderne/data` on the host machine.
Although `make` creates these automatically, they can be created manually:

```bash
sudo mkdir -p /home/lgoderne/data/wordpress
sudo mkdir -p /home/lgoderne/data/mariadb
sudo mkdir -p /home/lgoderne/data/portainer
sudo mkdir -p /home/lgoderne/data/database
sudo chmod -R 777 /home/lgoderne/data
```

---

### Configuration Files & Secrets Setup

Two distinct configuration sources are required by the infrastructure:
1. `srcs/.env` (Contains **only** non-confidential deployment configuration: domain name)
2. `srcs/requirements/secrets/*` (Contains **all** confidential credentials and user passwords mounted as Docker secrets)

#### Step 1: Create `srcs/.env`
```bash
cat << 'EOF' > srcs/.env
# Domain configuration (only variable in .env)
DOMAIN_NAME=yourdomain.ft
EOF
```

#### Step 2: Create Secrets in `srcs/requirements/secrets/`
```bash
mkdir -p srcs/requirements/secrets
chmod 700 srcs/requirements/secrets

# 1. MariaDB Database Name & Root Password
cat << 'EOF' > srcs/requirements/secrets/DB.TXT
DBNAME=name
DBMDP=password
EOF

# 2. Database User & WordPress User Credentials
cat << 'EOF' > srcs/requirements/secrets/USER.TXT
# MariaDB Application User
DBUSER=user
UMDP=password

# WordPress Administrator credentials (CANNOT contain 'admin' or 'administrator')
WP_ADMIN=admin
WP_ADMINPWD=password
WP_ADMINMAIL=adminMail

# WordPress Regular Author credentials
WP_USER=user
WP_USERPWD=password
WP_USERMAIL=userMail
EOF

# 3. Portainer Admin Password (minimum 12 characters)
cat << 'EOF' > srcs/requirements/secrets/PORTAINER_PWD.TXT
password
EOF

# 4. FTP User Credentials
cat << 'EOF' > srcs/requirements/secrets/FTP_USER.TXT
FTPUSER=user
FTPPASSWORD=password
EOF

chmod 600 srcs/requirements/secrets/*
```

---

## 2. Building and Launching the Project

### Makefile Architecture & Targets

The build pipeline is automated through the root [Makefile](file:///home/azazel/Documents/42proj/m5/Inception/Makefile):

```makefile
run: up

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
	sudo docker compose -f srcs/docker-compose.yml down --rmi all
	sudo rm -fr /home/lgoderne/data/wordpress
	sudo rm -fr /home/lgoderne/data/mariadb
	sudo rm -fr /home/lgoderne/data/portainer
	sudo rm -fr /home/lgoderne/data/database

fclean: clean
	sudo docker system prune -a --volumes -f
	sudo docker builder prune -a
```

| Target | Description |
| :--- | :--- |
| `make` / `make run` / `make up` | Ensures host storage paths exist, builds all custom container images, and starts the stack detached. |
| `make down` | Gracefully stops all active containers and disconnects the bridge network. Leaves data intact. |
| `make show` | Prints the state, ports, and container names (`docker compose ps`). |
| `make clean` | Stops the stack, deletes all local images (`--rmi all`), and purges the host data directories. |
| `make fclean` | Calls `clean`, then prunes all unused Docker objects, dangling volumes, and builder layer caches. |

---

### Docker Compose Architecture

The `srcs/docker-compose.yml` orchestrates 8 services:

```yaml
services:
  nginx:       # Port 443 only (TLS 1.2/1.3)
  mariadb:     # Database engine, secrets: db, user
  wordpress:   # PHP-FPM 8.2 runtime, secrets: db, user, env: .env
  adminer:     # Web DB manager (bonus)
  static:      # Python 3 showcase app (bonus)
  portainer:   # Docker management GUI (bonus)
  redis:       # Object cache (bonus)
  ftp:         # vsftpd file server, port 21 + passive ports (bonus)
```

- **Network (`inception-net`)**: An isolated user-defined Docker bridge network. No `--link` or `network_mode: host` is used.
- **Secrets Management**: Mounted into `/run/secrets/<secret_name>` in target containers.
- **Volumes**: Defined as named volumes with custom driver options pointing to host directories.

---

## 2. Container, Volume, and Network Management Commands

### Standard Lifecycle Commands

```bash
# Start all containers in detached mode
cd srcs && sudo docker compose up --build -d

# Check running status of containers
cd srcs && sudo docker compose ps

# Stop all containers
cd srcs && sudo docker compose stop

# Restart a specific service
cd srcs && sudo docker compose restart wordpress
cd srcs && sudo docker compose restart nginx
cd srcs && sudo docker compose restart mariadb
```

---

### Live Logging & Debugging

```bash
# Follow logs for the entire stack
cd srcs && sudo docker compose logs -f

# Follow logs for a single service
cd srcs && sudo docker compose logs -f wordpress
cd srcs && sudo docker compose logs -f nginx
cd srcs && sudo docker compose logs -f mariadb
cd srcs && sudo docker compose logs -f redis
cd srcs && sudo docker compose logs -f ftp
```

---

### Service-Specific CLI Operations

#### Redis Caching & Monitoring
To inspect real-time query caching between WordPress and Redis:
```bash
# Monitor all Redis cache commands in real time
sudo docker exec -it redis redis-cli monitor
```
*(As you browse WordPress, you will observe real-time `GET`, `SET`, and `EXPIRE` operations).*

To inspect Redis memory usage and hit/miss statistics:
```bash
sudo docker exec -it redis redis-cli info stats
sudo docker exec -it redis redis-cli info memory
```

#### MariaDB Interactive Shell
Connect directly to the database inside the container:
```bash
# Log in as the WordPress database user
sudo docker exec -it mariadb mariadb -u wp_dbuser -password name

# Log in as root
sudo docker exec -it mariadb mariadb -u root -password

# Quick one-liner SQL query
sudo docker exec -it mariadb mariadb -u root -password -e "SHOW DATABASES; USE inception_db; SHOW TABLES;"
```

#### WordPress WP-CLI Administration
Execute WP-CLI commands inside the WordPress container:
```bash
# List all WordPress users
sudo docker exec -it wordpress wp user list --allow-root

# Inspect Redis Object Cache plugin status
sudo docker exec -it wordpress wp redis status --allow-root

# Flush WordPress object cache
sudo docker exec -it wordpress wp cache flush --allow-root

# List installed plugins
sudo docker exec -it wordpress wp plugin list --allow-root
```

#### NGINX Configuration Testing
```bash
# Test NGINX configuration syntax inside container
sudo docker exec -it nginx nginx -t

# Reload NGINX configuration without downtime
sudo docker exec -it nginx nginx -s reload

# Inspect generated SSL certificate
sudo docker exec -it nginx openssl x509 -in /etc/nginx/ssl/inception.crt -text -noout
```

#### Network Inspection & Troubleshooting
```bash
# Inspect the custom bridge network and assigned IP addresses
sudo docker network inspect srcs_inception-net

# Test DNS resolution from wordpress container to mariadb
sudo docker exec -it wordpress ping -c 2 mariadb

# Test DNS resolution from wordpress container to redis
sudo docker exec -it wordpress ping -c 2 redis
```

---

## 4. Storage, Persistence, and Volume Architecture

### Host Storage Mapping

Data persistence is mapped to the host filesystem as follows:

| Docker Named Volume | Host Path | Container Mount Point | Containers Using Volume |
| :--- | :--- | :--- | :--- |
| `website_files` | `/home/lgoderne/data/wordpress` | `/var/www/html` | `wordpress`, `nginx`, `ftp` |
| `database` | `/home/lgoderne/data/mariadb` | `/var/lib/mysql` | `mariadb` |
| `portainer_data`| `/home/lgoderne/data/portainer` | `/data` | `portainer` |

---

### Named Volumes vs Bind Mounts Under the Hood

The subject explicitly requires:
> *"You must use Docker named volumes for these two persistent storages. Bind mounts are not allowed for these volumes. These named volumes must be configured so that their data ends up in `/home/login/data` on the host machine. They remain Docker named volumes, not bind mounts."*

In `srcs/docker-compose.yml`, this is implemented using Docker's `driver_opts` with the `local` driver:

```yaml
volumes:
  website_files:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/lgoderne/data/wordpress

  database:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/lgoderne/data/mariadb

  portainer_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/lgoderne/data/portainer
```

#### Why this satisfies the requirement:
1. **Registered as Named Volumes**: Docker tracks them as first-class named volumes (`docker volume ls` displays `srcs_website_files`, `srcs_database`, etc.).
2. **Explicit Storage Redirection**: Rather than placing files in Docker's default internal path (`/var/lib/docker/volumes/...`), the volume driver binds the mount target to `/home/lgoderne/data/...`.
3. **Container Decoupling**: Containers reference the logical name `website_files:/var/www/html`, avoiding hardcoded host paths inside service definitions.

---

### Persistence Verification Testing

To prove data persistence during defense or evaluation:

1. **Step 1: Write data**:
   - Access `https://lgoderne.42.fr/wp-login.php` as admin.
   - Publish a new post with the title *"Persistence Test Post"*.
   - Verify post is visible on `https://lgoderne.42.fr/`.

2. **Step 2: Destroy containers**:
   ```bash
   make down
   # Even remove the containers completely:
   cd srcs && sudo docker compose down --volumes=false
   ```

3. **Step 3: Verify host files remain**:
   ```bash
   ls -la /home/lgoderne/data/wordpress
   ls -la /home/lgoderne/data/mariadb
   ```
   *(All WordPress PHP scripts, uploaded media, and MariaDB `.ibd` tablespace files remain intact).*

4. **Step 4: Relaunch stack**:
   ```bash
   make up
   ```
   - Refresh `https://lgoderne.42.fr/`.
   - The *"Persistence Test Post"* will be present, verifying full persistence across container destruction.

5. **Step 5: Testing Clean Wipes**:
   ```bash
   make clean
   ```
   *(Removes images and clears `/home/lgoderne/data/...`, returning the environment to a clean state).*

