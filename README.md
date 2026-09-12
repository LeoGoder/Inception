*This project has been created as part of the 42 curriculum by lgoderne.*

# Inception

A multi-container system administration infrastructure virtualized with **Docker** and **Docker Compose**, running inside a dedicated Linux Virtual Machine.

---

## Description

### Project Overview
The goal of the **Inception** project is to broaden system administration and DevOps knowledge through container virtualization. The objective is to design, configure, and deploy a secure, modular, and containerized LEMP-like infrastructure from scratch.

In accordance with the 42 project constraints:
- Every image is built from scratch using custom **Dockerfiles** based on `debian:bookworm`. Ready-made images from Docker Hub or using the `latest` tag are strictly prohibited.
- Each service runs in its own dedicated container.
- **NGINX** is the single secure entrypoint for all web traffic over port `443`, strictly using **TLSv1.2** or **TLSv1.3**.
- A custom Docker user-defined bridge network (`inception-net`) interconnects all containers without using legacy links or host networking.
- Data persistence is handled via **Docker named volumes** whose storage resides in `/home/lgoderne/data` on the host machine.
- Container stability is ensured with restart policies (`restart: always`) and proper PID 1 process management without hacky loops (e.g., `tail -f`, `sleep infinity`, `while true`).

---

### Architecture & Infrastructure

```
                                      Internet / Host Machine
                                                 │
                                                 │  HTTPS (443)
                                                 ▼
               ┌──────────────────────────────────────────────────────────────────┐
               │                         NGINX Container                          │
               │                   (TLSv1.2 / TLSv1.3 SSL Only)                   │
               └───────────┬─────────────────────┬────────────────────┬───────────┘
                           │                     │                    │
              FastCGI:9000 │        Reverse Proxy│:3000  Reverse Proxy│:9000
                           ▼                     ▼                    ▼
     ┌────────────────────────────┐  ┌───────────────────┐  ┌───────────────────┐
     │    WordPress + PHP-FPM     │  │  Static Web App   │  │     Portainer     │
     │        Container           │  │ (Python 3 Server) │  │  (Docker Manager) │
     └──────┬──────────────┬──────┘  └───────────────────┘  └─────────┬─────────┘
            │              │                                          │
   MySQL:3306              │ Redis:6379                               │ /var/run/
            ▼              ▼                                          │ docker.sock
     ┌─────────────┐ ┌─────────────┐                                  │
     │   MariaDB   │ │ Redis Cache │                                  │
     │  Container  │ │  Container  │                                  │
     └──────┬──────┘ └─────────────┘                                  │
            │                                                         │
   FastCGI:9000 (from NGINX /adminer.php)                             │
            │                                                         │
            ▼                                                         ▼
     ┌─────────────┐                                        ┌───────────────────┐
     │   Adminer   │                                        │  portainer_data   │
     │  Container  │                                        │  (Named Volume)   │
     └─────────────┘                                        └───────────────────┘
            ▲
            │ FTP (Port 21, Passive 60000-60100)
     ┌─────────────┐
     │ vsftpd FTP  │
     │  Container  │
     └──────┬──────┘
            │
            │ Mounted to /var/www/html
            ▼
 ┌───────────────────────────────────────┐          ┌───────────────────────────┐
 │             website_files             │          │         database          │
 │            (Named Volume)             │          │      (Named Volume)       │
 │   (/home/lgoderne/data/wordpress)     │          │ (/home/lgoderne/data/mariadb) │
 └───────────────────────────────────────┘          └───────────────────────────┘
```

---

### Services Summary

| Service | Container Name | Base Image | Ports | Volume Mount | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **NGINX** | `nginx` | `debian:bookworm` | `443:443` | `website_files:/var/www/html` | Secure TLSv1.2/1.3 reverse proxy & web gateway |
| **WordPress** | `wordpress` | `debian:bookworm` | Internal (`9000`) | `website_files:/var/www/html` | CMS dynamic runtime powered by PHP-FPM 8.2 |
| **MariaDB** | `mariadb` | `debian:bookworm` | Internal (`3306`) | `database:/var/lib/mysql` | Relational database server storing WP data |
| **Redis** *(Bonus)* | `redis` | `debian:bookworm` | Internal (`6379`) | None | In-memory key-value cache with LRU eviction |
| **Adminer** *(Bonus)* | `adminer` | `debian:bookworm` | Internal (`9000`) | None | Lightweight web GUI for MariaDB database management |
| **Static Site** *(Bonus)* | `static` | `debian:bookworm` | Internal (`3000`) | None | Non-PHP showcase page served via Python 3 |
| **Portainer** *(Bonus)* | `portainer` | `debian:bookworm` | Internal (`9000`) | `portainer_data:/data`, `docker.sock` | Web-based container and infrastructure manager |
| **FTP** *(Bonus)* | `ftp` | `debian:bookworm` | `21:21`, `60000-60100` | `website_files:/var/www/html` | Secure vsftpd access to WordPress files |

---

### Main Design Choices
1. **Single Public HTTP Entrypoint**: In strict adherence to subject security rules, NGINX is the sole container exposing web ports (`443:443`). All internal web services (`wordpress`, `adminer`, `static`, `portainer`) are isolated inside `inception-net` and reached through NGINX via FastCGI or reverse proxy directives.
2. **Foreground Process Management (PID 1)**: Daemons run in the foreground without resorting to hacky infinite loops (`tail -f`, `sleep infinity`).
   - NGINX: `nginx -g 'daemon off;'`
   - WordPress & Adminer: `/usr/sbin/php-fpm8.2 -F`
   - MariaDB: `mysqld_safe` in background during initial bootstrap, followed by `wait`
   - Static: `python3 -m http.server 3000`
   - Redis: `redis-server --daemonize no --protected-mode no`
   - FTP: `/usr/sbin/vsftpd /etc/vsftpd.conf`
3. **Secret Segregation**: Passwords and sensitive credentials are isolated into Docker secrets located in `srcs/requirements/secrets/` and mounted as read-only memory files under `/run/secrets/` in target containers.

---

### Key Technical Comparisons

#### Virtual Machines vs Docker

| Metric / Dimension | Virtual Machine (VM) | Docker (Container) |
| :--- | :--- | :--- |
| **Architecture** | Runs a complete Guest OS on top of a Hypervisor (Type 1 or Type 2) with virtualized hardware. | Shares the Host OS Linux kernel using kernel features (**namespaces** and **cgroups**). |
| **Boot Time** | Minutes (boots a complete operating system and hardware abstraction). | Sub-seconds / seconds (launches isolated user-space processes directly). |
| **Resource Overhead** | Heavy memory and CPU consumption due to duplicate OS kernels and virtual devices. | Extremely lightweight; only consumes resources required by the application process itself. |
| **Disk Footprint** | Gigabytes per VM (includes full OS image, swap, system binaries). | Megabytes per image (layered filesystem sharing base layers across images). |
| **Isolation Level** | Strong hardware-level isolation enforced by the hypervisor and CPU virtualization extensions (VT-x/AMD-V). | Process-level isolation enforced by Linux namespaces (`pid`, `net`, `mnt`, `ipc`, `uts`, `user`) and cgroups. |
| **Portability** | Heavy VM disk formats (`.vmdk`, `.qcow2`, `.ova`), dependent on hypervisor compatibility. | Highly portable Docker images adhering to Open Container Initiative (OCI) standards. |

#### Secrets vs Environment Variables

| Dimension | Environment Variables (`.env` / `environment`) | Docker Secrets (`secrets:`) |
| :--- | :--- | :--- |
| **Storage Mechanism** | Injected into the process environment table in plaintext memory. | Mounted as an in-memory `tmpfs` file inside the container (default: `/run/secrets/<secret_name>`). |
| **Inspection Exposure** | Exposed in plaintext via `docker inspect <container>`, `docker compose config`, and `/proc/<PID>/environ`. | **Never** shown in `docker inspect` output; file content stays shielded from container metadata inspection. |
| **Process Inheritance** | Inherited by every child process spawned by the main process, increasing exposure to sub-shells and logs. | Only processes with explicit filesystem read permissions on `/run/secrets/` can access the value. |
| **Version Control Risk** | Often mistakenly committed to Git if `.env` is not strictly ignored. | Backed by separate files; easily gitignored and rotated independently of deployment configurations. |
| **Best-Practice Usage** | Non-sensitive configurations (domain names, URLs, port numbers, debug flags). | Sensitive data (database passwords, API keys, SSL private keys, administrator credentials). |

#### Docker Network vs Host Network

| Feature | Docker Network (User-Defined Bridge) | Host Network (`network_mode: host`) |
| :--- | :--- | :--- |
| **Network Namespace** | Container gets its own isolated network stack, virtual interface (`eth0`), and dedicated IP address. | Disables network isolation; container shares the host machine's network stack and IP address directly. |
| **Port Management** | Ports must be explicitly mapped (`ports: "443:443"`); unmapped ports remain inaccessible to outside networks. | Container services bind directly to host ports; port conflicts occur if a host process uses the same port. |
| **DNS Service Discovery** | Embedded Docker DNS resolver automatically resolves container names (e.g., `mariadb`, `redis`) to their internal IPs. | No container name resolution; communication must rely on `localhost` or host IPs. |
| **Security Boundary** | High: traffic between containers stays inside the private bridge network, invisible to host interfaces. | Low: opens internal container ports directly to the local network; explicitly forbidden by 42 Inception subject. |

#### Docker Volumes vs Bind Mounts

| Aspect | Docker Named Volumes | Host Bind Mounts |
| :--- | :--- | :--- |
| **Management** | Fully managed by the Docker engine (`docker volume ls`, `docker volume inspect`, `docker volume rm`). | Directly tied to an arbitrary absolute directory on the host filesystem (`/path/on/host:/path/in/container`). |
| **Portability & Abstraction**| Decoupled from host OS filesystem hierarchy; can use different storage drivers (NFS, cloud block storage, local). | Tightly coupled to the exact host directory structure, permissions, and filesystem layout. |
| **Initial Population** | If a named volume is empty, Docker automatically copies pre-existing directory contents from the image into the volume. | Overwrites/hides the container directory contents with whatever exists on the host directory. |
| **Subject Implementation** | Configured with `driver_opts` (`type: none`, `o: bind`, `device: /home/lgoderne/data/...`), blending Docker volume tracking with 42 host path requirements. | Raw bind mounts (`- /host/dir:/container/dir`) are explicitly prohibited for mandatory persistent data volumes. |

---

## Instructions

### Prerequisites
Before running the infrastructure, ensure the host machine has the following tools installed:
- **Operating System**: Linux (Debian 12 or Ubuntu 22.04+ recommended)
- **Docker Engine**: version 24.0+
- **Docker Compose Plugin**: version 2.20+
- **Make**: GNU Make utility
- **OpenSSL**: for SSL testing and inspection
- **cURL**: for HTTP/HTTPS verification

```bash
sudo apt-get update && sudo apt-get install -y docker.io docker-compose-v2 make curl openssl
```

Ensure your current user belongs to the `docker` group:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

---

### Domain Name Configuration
The subject mandates that the domain name must point to your local IP address:
```
lgoderne.42.fr -> 127.0.0.1
```

Add this mapping to your host `/etc/hosts` file:
```bash
echo "127.0.0.1 lgoderne.42.fr" | sudo tee -a /etc/hosts
```

---

### Compilation & Execution

The project is driven through the root Makefile:

| Command | Action |
| :--- | :--- |
| `make` / `make up` | Creates host storage directories (`/home/lgoderne/data/...`), builds all Docker images, and starts containers in detached mode. |
| `make down` | Stops and removes all running containers and networks without deleting persistent data. |
| `make show` | Displays status of all containers in the stack (`docker compose ps`). |
| `make clean` | Stops the stack, removes all custom images, and removes host data directories. |
| `make fclean` | Executes `make clean`, runs `docker system prune -a --volumes -f`, and purges Docker builder cache. |

#### Launch the Stack
```bash
make
```

#### Check Stack Status
```bash
make show
```

#### View Live Logs
```bash
cd srcs && sudo docker compose logs -f
```

---

### SSH & Remote Access
When working inside a dedicated Virtual Machine, connect via SSH from your local workstation:

**Standard SSH connection:**
```bash
ssh lgoderne@127.0.0.1 -p 2222
# or
ssh lgoderne@localhost -p 2222
```

**SSH with X11 Graphical Export:**
```bash
ssh -X lgoderne@127.0.0.1 -p 2222
# or
ssh -X lgoderne@localhost -p 2222
```

---

## Resources

### References & Documentation
- [Docker Engine Official Documentation](https://docs.docker.com/engine/)
- [Docker Compose Specification](https://docs.docker.com/compose/)
- [NGINX Reverse Proxy & SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [WordPress Developer Handbook & WP-CLI Reference](https://developer.wordpress.org/cli/commands/)
- [MariaDB Knowledge Base: Server Configuration](https://mariadb.com/kb/en/configuring-mariadb-with-option-files/)
- [Redis Official Documentation & Configuration Options](https://redis.io/docs/management/config/)
- [vsftpd (Very Secure FTP Daemon) Manual](https://security.appspot.com/vsftpd/vsftpd_conf.html)
- [Portainer CE Documentation](https://docs.portainer.io/)
- [Adminer Official Site](https://www.adminer.org/)

### Use of Artificial Intelligence
In accordance with 42 curriculum guidelines regarding AI transparency:
- **Scope of AI Assistance**:
  - **Conceptual Analysis & Comparison**: AI was consulted to structure rigorous, technical comparisons between virtualization paradigms (VMs vs. Containers, Volumes vs. Bind Mounts, Docker Networks vs. Host Networks, and Secrets vs. Environment Variables).
  - **Documentation Drafting**: Assisted in drafting and structuring comprehensive Markdown documentation (README.md, USER_DOC.md, DEV_DOC.md) meeting all mandatory checklist requirements of the 42 Inception subject.
  - **Command & Script Verification**: Assisted in auditing shell scripts and entrypoints for best practices (checking PID 1 foreground execution, signal termination handling, and absence of prohibited hacky loops such as `tail -f`).

