# Inception — User & Administrator Documentation (`USER_DOC.md`)

Welcome to the **Inception** infrastructure user guide. This documentation is written for end users and system administrators who want to understand, operate, and interact with the containerized web services.


## 1. Overview of Provided Services

The **Inception** stack deploys a complete, secure, and production-like web hosting infrastructure consisting of 8 distinct containerized services:

```
+-------------------------------------------------------------------------------+
|                             INCEPTION STACK                                   |
|                                                                               |
|  [ NGINX Gateway ] ---> Entrypoint on Port 443 with TLS 1.2 / TLS 1.3         |
|         │                                                                     |
|         ├──> [ WordPress + PHP-FPM ]  - Dynamic CMS & Blogging Platform      |
|         │          ├──> [ MariaDB ]    - Relational Database Backend          |
|         │          └──> [ Redis ]      - High-Performance Object Cache        |
|         │                                                                     |
|         ├──> [ Adminer ]              - Web-based Database Management GUI    |
|         ├──> [ Static Website ]       - Interactive HTML/JS Web Application  |
|         └──> [ Portainer ]            - Container & Docker GUI Dashboard     |
|                                                                               |
|  [ vsftpd FTP Server ] ---> Dedicated File Access on Port 21 & 60000-60100    |
+-------------------------------------------------------------------------------+
```

### Core Mandatory Services:
1. **NGINX**: The sole public web gateway. It terminates SSL/TLS connections using TLSv1.2 or TLSv1.3 and reverse-proxies incoming HTTP requests securely to internal services.
2. **WordPress (with PHP-FPM 8.2)**: A fully functional Content Management System (CMS) hosting articles, media, and comments. It communicates with MariaDB for persistence and Redis for caching.
3. **MariaDB**: The relational SQL database storing all WordPress tables, posts, configuration, and user records.

### Bonus Services:
4. **Redis**: An in-memory key-value cache that stores WordPress database queries in memory to accelerate page loads.
5. **Adminer**: A single-file PHP database management tool providing an easy-to-use web interface to inspect and query the MariaDB database.
6. **Static Website**: A standalone Python 3 HTTP server delivering an animated showcase page (dancing Toothless GIF with dynamic color cycling).
7. **Portainer**: A visual management dashboard for Docker containers, images, volumes, and networks.
8. **FTP Server (vsftpd)**: A secure File Transfer Protocol daemon granting direct read/write access to the WordPress filesystem (`/var/www/html`).

---

## 2. Starting and Stopping the Project

### Initial Host Configuration
Before starting the stack, ensure that your computer maps `lgoderne.42.fr` to your local machine (`127.0.0.1`).

Open `/etc/hosts` on your host machine:
```bash
echo "127.0.0.1 lgoderne.42.fr" | sudo tee -a /etc/hosts
```

Verify that the domain resolves locally:
```bash
ping -c 1 lgoderne.42.fr
```
*(It should respond from `127.0.0.1`).*

---

### Start Commands
All operations are executed via the [Makefile](file:///home/azazel/Documents/42proj/m5/Inception/Makefile) at the root of the repository.

1. **Launch the entire stack**:
   ```bash
   make
   # or
   make up
   ```
   *What this does:*
   - Automatically creates the persistent host directories (`/home/lgoderne/data/wordpress`, `/home/lgoderne/data/mariadb`, `/home/lgoderne/data/portainer`, `/home/lgoderne/data/database`).
   - Builds all 8 Docker images using the Dockerfiles.
   - Starts all containers in the background (`-d`).
   - Creates the isolated `inception-net` network and named volumes.

2. **Check stack status**:
   ```bash
   make show
   ```
   All services should display the status `Up` or `Up (healthy)`.

---

### Stop Commands
- **Stop all services without losing data**:
  ```bash
  make down
  ```
  *Containers are stopped and networks are removed, but your database, posts, and files remain safely preserved on disk.*

- **Restart the stack**:
  ```bash
  make down && make up
  ```

---

### Reset / Wipe Commands
> [!WARNING]
> The following commands will permanently delete your database and uploaded WordPress files!

- **Remove containers, images, and data volumes**:
  ```bash
  make clean
  ```
- **Complete factory reset (removes all containers, images, volumes, networks, and builder caches)**:
  ```bash
  make fclean
  ```

---

## 3. Accessing the Website and Administration Panels

### Quick Access Endpoints

| Service | Public URL / Host | Default Port | Authentication / Credentials |
| :--- | :--- | :--- | :--- |
| **WordPress Site** | `https://lgoderne.42.fr/` | `443` (HTTPS) | Publicly accessible |
| **WordPress Admin** | `https://lgoderne.42.fr/wp-login.php` | `443` (HTTPS) | Defined in `USER.TXT` secret (`WP_ADMIN` / `WP_ADMINPWD`) |
| **Adminer DB Tool** | `https://lgoderne.42.fr/adminer.php` | `443` (HTTPS) | System: `MySQL`, Server: `mariadb`, User/Pass from `USER.TXT` |
| **Static Web App** | `https://lgoderne.42.fr/static/` | `443` (HTTPS) | Publicly accessible |
| **Portainer Dashboard**| `https://lgoderne.42.fr/portainer/` | `443` (HTTPS) | User: `admin`, Password from `PORTAINER_PWD.TXT` |
| **FTP Server** | `ftp://lgoderne.42.fr` | `21` (FTP) | User/Pass from `FTP_USER.TXT` |

---

### Bypassing Self-Signed SSL Certificate Warnings
Because Inception uses a self-signed SSL certificate generated during build time, modern web browsers will display a security warning (e.g., `NET::ERR_CERT_AUTHORITY_INVALID` or `Potential Security Risk Ahead`).

To proceed:
- **In Google Chrome / Chromium**: Click **Advanced** -> Click **Proceed to lgoderne.42.fr (unsafe)**. (Or type `thisisunsafe` directly on the warning screen).
- **In Mozilla Firefox**: Click **Advanced...** -> Click **Accept the Risk and Continue**.

---

### WordPress Website & Admin Panel

1. **Front-End Website**:
   Navigate to `https://lgoderne.42.fr/`. You will see the WordPress homepage titled **"Inception"**.

2. **Admin Dashboard**:
   Navigate to `https://lgoderne.42.fr/wp-login.php` or `https://lgoderne.42.fr/wp-admin/`.
   - **Username / Email**: The value of `WP_ADMIN` from `srcs/requirements/secrets/USER.TXT` (e.g., `master_leo`).
   - **Password**: The value of `WP_ADMINPWD` from `srcs/requirements/secrets/USER.TXT`.
   
   Once logged in, administrators can manage posts, themes, users, and plugins.

3. **Regular User Account**:
   You can also log in as the second user:
   - **Username**: The value of `WP_USER` from `srcs/requirements/secrets/USER.TXT` (e.g., `leo_author`).
   - **Password**: The value of `WP_USERPWD` from `srcs/requirements/secrets/USER.TXT`.
   *(This user has Author privileges and can create/edit articles).*

---

### Adminer Database Management
Adminer provides a complete web management console for your MariaDB database.

1. Navigate to: `https://lgoderne.42.fr/adminer.php`.
2. Fill in the login form with your MariaDB credentials:
   - **System**: Select `MySQL`
   - **Server**: `mariadb`
   - **Username**: The value of `DBUSER` in `srcs/requirements/secrets/USER.TXT`
   - **Password**: The value of `UMDP` in `srcs/requirements/secrets/USER.TXT`
   - **Database**: The value of `DBNAME` in `srcs/requirements/secrets/DB.TXT`
3. Click **Login**.
4. You can now browse tables (such as `wp_posts`, `wp_users`, `wp_options`), execute custom SQL queries, and perform database backups directly from your browser.

---

### Static Showcase Web App
1. Navigate to: `https://lgoderne.42.fr/static/`.
2. You will be greeted by the dancing Toothless animation accompanied by an interactive dynamic background color transition driven by vanilla JavaScript.

---

### Portainer Container Management GUI
Portainer offers a full graphic user interface to monitor and manage your Docker containers, networks, and volumes.

1. Navigate to: `https://lgoderne.42.fr/portainer/`.
2. Log in using:
   - **Username**: `admin`
   - **Password**: The string stored in `srcs/requirements/secrets/PORTAINER_PWD.TXT`.
3. In the dashboard, click on the **local** environment to view:
   - Container statuses and CPU/RAM metrics.
   - Container logs in real time.
   - Volume utilization and inspection.

---

### FTP File Transfer Service
The FTP server allows webmasters to upload or download files directly to the WordPress installation directory (`/var/www/html`).

#### Connecting via Graphical Client (FileZilla):
1. Open **FileZilla**.
2. Go to **File** -> **Site Manager** -> **New Site**.
3. Configure the following:
   - **Protocol**: `FTP - File Transfer Protocol`
   - **Host**: `lgoderne.42.fr` (or `127.0.0.1`)
   - **Port**: `21`
   - **Encryption**: `Use plain FTP`
   - **Logon Type**: `Normal`
   - **User**: The value of `FTPUSER` in `srcs/requirements/secrets/FTP_USER.TXT`
   - **Password**: The value of `FTPPASSWORD` in `srcs/requirements/secrets/FTP_USER.TXT`
   - **Transfer Settings**: Select **Passive** mode.
4. Click **Connect**. You will see the WordPress files (`wp-config.php`, `wp-content/`, etc.).

#### Connecting via Command-Line FTP:
```bash
ftp -p lgoderne.42.fr 21
```
Enter your `$FTPUSER` and `$FTPPASSWORD` when prompted.

---

## 4. Locating and Managing Credentials

### Credential Locations
For security and compliance with 42 evaluation rules, credentials and configurations are strictly segregated:
1. **Public Configuration**: `srcs/.env` — contains **only** non-confidential deployment configuration:
   - `DOMAIN_NAME=lgoderne.42.fr`
2. **Confidential Secrets**: `srcs/requirements/secrets/` — contains **all** sensitive credentials and passwords mounted securely as Docker secrets:
   - `USER.TXT`: MariaDB application user credentials AND WordPress user/administrator accounts.
   - `DB.TXT`: Database name and MariaDB root password.
   - `PORTAINER_PWD.TXT`: Portainer admin dashboard password.
   - `FTP_USER.TXT`: FTP user account credentials for vsftpd.

### Credentials Reference Table

| Configuration Target | File Location | Key / Content | Description |
| :--- | :--- | :--- | :--- |
| **Domain Name** | `srcs/.env` | `DOMAIN_NAME` | Website domain name (`lgoderne.42.fr`) — *only variable in `.env`* |
| **WP Admin User** | `srcs/requirements/secrets/USER.TXT` | `WP_ADMIN` | WordPress administrator username *(cannot contain 'admin')* |
| **WP Admin Password** | `srcs/requirements/secrets/USER.TXT` | `WP_ADMINPWD` | Password for WordPress administrator account |
| **WP Admin Email** | `srcs/requirements/secrets/USER.TXT` | `WP_ADMINMAIL` | Administrator email address |
| **WP Normal User** | `srcs/requirements/secrets/USER.TXT` | `WP_USER` | Regular author account username |
| **WP Normal Password** | `srcs/requirements/secrets/USER.TXT` | `WP_USERPWD` | Password for regular author account |
| **WP Normal Email** | `srcs/requirements/secrets/USER.TXT` | `WP_USERMAIL` | Regular author email address |
| **Database User & Password** | `srcs/requirements/secrets/USER.TXT` | `DBUSER=...`<br>`UMDP=...` | WordPress MariaDB user and user password |
| **Database Name & Root Pwd** | `srcs/requirements/secrets/DB.TXT` | `DBNAME=...`<br>`DBMDP=...` | MariaDB database name & MariaDB root password |
| **Portainer Admin Password** | `srcs/requirements/secrets/PORTAINER_PWD.TXT` | Password string | Initial administrator password for Portainer UI |
| **FTP User & Password** | `srcs/requirements/secrets/FTP_USER.TXT` | `FTPUSER=...`<br>`FTPPASSWORD=...` | FTP username and password for vsftpd |

---

### How to Update Credentials
- **Updating WordPress User Passwords**:
  The easiest way to update passwords without resetting the database is inside the WordPress Admin Dashboard under **Users** -> **Profile** -> **New Password**.
- **Updating Infrastructure Secrets**:
  If you modify credentials in `srcs/requirements/secrets/` or `srcs/.env`:
  1. If you change database passwords (`DBMDP`, `UMDP`) or WordPress account details in `USER.TXT`, the database needs to re-initialize or have privileges updated.
  2. To re-initialize the entire stack with fresh credentials:
     ```bash
     make clean
     make up
     ```

---

## 5. Checking Service Health and Correct Operation

### Container Status Check
Run the following command from the root directory:
```bash
make show
```
Expected output should list all 8 containers with `STATUS: Up`:
- `nginx`
- `wordpress`
- `mariadb`
- `redis`
- `adminer`
- `static`
- `portainer`
- `ftp`

---

### Real-Time Log Inspection
To monitor the activity of any container:
```bash
# View logs of all containers
cd srcs && sudo docker compose logs -f

# View logs of a specific container
cd srcs && sudo docker compose logs -f nginx
cd srcs && sudo docker compose logs -f wordpress
cd srcs && sudo docker compose logs -f mariadb
```

---

### Verifying HTTPS & TLS Protocol
The subject requires that connections use **TLSv1.2 or TLSv1.3 only**.

Verify using `openssl s_client`:
```bash
# Test TLS 1.3 (should succeed)
openssl s_client -connect lgoderne.42.fr:443 -tls1_3 < /dev/null 2>&1 | grep "Protocol"

# Test TLS 1.2 (should succeed)
openssl s_client -connect lgoderne.42.fr:443 -tls1_2 < /dev/null 2>&1 | grep "Protocol"

# Test TLS 1.1 (MUST FAIL)
openssl s_client -connect lgoderne.42.fr:443 -tls1_1 < /dev/null 2>&1 | grep "error"
```

Verify that HTTP on port 80 is closed:
```bash
curl -I http://lgoderne.42.fr
# Output: Failed to connect to lgoderne.42.fr port 80: Connection refused
```

---

### Verifying Redis Object Cache
To check if Redis is actively caching WordPress queries:

1. Open a terminal and run the Redis monitor tool:
   ```bash
   sudo docker exec -it redis redis-cli monitor
   ```
2. In your web browser, refresh `https://lgoderne.42.fr/` or navigate through posts.
3. In your terminal, you will see real-time streaming Redis commands (`GET`, `SET`, `EXISTS`), proving that WordPress is actively utilizing the Redis container as an object cache.

Alternatively, verify cache status from inside the WordPress container:
```bash
sudo docker exec -it wordpress wp redis status --allow-root
```
*(Status should output: `Status: Connected`).*

---

### Verifying FTP File Access
1. Test uploading a file via FTP:
   ```bash
   echo "Inception test file" > test_upload.txt
   curl -T test_upload.txt -u "ftp_leo:FtpSecurePassword42!" ftp://lgoderne.42.fr/ --ftp-pasv
   ```
2. Check that the file appears in the WordPress directory on the host:
   ```bash
   cat /home/lgoderne/data/wordpress/test_upload.txt
   ```
   *(Output should print: `Inception test file`).*

---

### Troubleshooting Common Issues

| Symptom | Cause | Solution |
| :--- | :--- | :--- |
| **`502 Bad Gateway` on NGINX** | WordPress or Adminer PHP-FPM service is still bootstrapping. | Wait 5–10 seconds for the database and WordPress initial setup to complete, then refresh. Check logs with `docker compose logs -f wordpress`. |
| **`Connection refused` on browser** | The stack is down or `/etc/hosts` is missing. | Verify `make show` reports containers `Up`. Verify `/etc/hosts` has `127.0.0.1 lgoderne.42.fr`. |
| **Portainer displays timeout error on first launch** | Portainer has an initial security timeout if no password was supplied within 5 minutes. | Our setup automatically passes `--admin-password-file /run/secrets/portainer_pwd`, preventing this error. If modified, restart Portainer: `sudo docker compose restart portainer`. |
| **Database connection error in WordPress** | MariaDB is not yet ready or credentials mismatch. | Inspect `srcs/requirements/secrets/USER.TXT` and `DB.TXT`. Ensure MariaDB is running with `docker compose logs mariadb`. |
