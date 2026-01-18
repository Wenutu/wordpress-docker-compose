# Docker Compose WordPress Stack

[English](README.md) | [中文](README_CN.md)

A high-performance, scalable, and secure WordPress deployment solution using Docker Compose.

## 🌟 Features / Design Characteristics

### 1. High-Performance Architecture (LNMP)
- **Nginx & PHP-FPM Decoupling**: Uses Nginx as a dedicated reverse proxy and static file server, separating it from the PHP-FPM processing container.
- **Aggressive Caching**: Nginx is configured with long expiration times (`expires 365d`) for static assets (images, CSS, JS) to minimize server load.

### 2. Tuned for Production
- **OPcache Enabled**: PHP OPcache is configured with `validate_timestamps=0`, keeping compiled scripts in memory and eliminating filesystem checks for significantly faster execution.
- **Optimized Database**: MariaDB includes specific tuning for InnoDB buffer pool (`512M`) and connection connection limits to handle higher concurrency.

### 3. Automatic Object Caching (Redis)
- **Zero-Config Redis**: The stack includes a Redis container for WordPress Object Cache.
- **Auto-Initialization**: A dedicated `wpcli` container monitors the installation. Once WordPress is installed, it automatically installs the Redis plugin, activates it, and enables the object cache without manual intervention.

### 4. Data Persistence & Security
- **Volume Managed**: All critical data (Database, WordPress files, Redis data, Logs) is persisted in a structured `data/` directory.
- **Network Isolation**: Backend services (Database, Redis) communicate on an internal docker network.

## 📋 Requirements

- Docker Engine
- Docker Compose

## 🚀 Configuration & Usage

### 1. Environment Setup
Clone the project and navigate to the directory. Create your environment configuration file:

```bash
cp .env.example .env
```

Edit the `.env` file to set your secure passwords:
- `DB_ROOT_PASSWORD`: Root password for MariaDB.
- `DB_PASSWORD`: Password for the WordPress database user.
- `DB_USER`: (Optional) Change default username if desired.
- `DATA_PATH`: Location to store data (Default: `./data`).

### 2. Start Services
Launch the stack in detached mode:

```bash
docker-compose up -d
```

### 3. Install WordPress
- Open your browser and visit `http://localhost:8080` (or your server's IP).
- Complete the standard WordPress 5-minute installation.

**Note:** After you complete the installation, the background `wpcli` service will detect it and automatically enable Redis Object Caching (this may take 10-20 seconds).

### 4. (Optional) External Reverse Proxy
If you use an external Nginx server (e.g., on the host machine) to proxy traffic (port 80/443) to this stack, configure it to forward requests to port `8080`.

Example Nginx Configuration for Host:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🚚 Migration Guide

### 📤 Backup (Export)

To migrate out or backup your site, you need to save both the **Database** and the **Files**.

#### 1. Database Backup
Use the included script for an automated, secure backup:

```bash
bash scripts/migration.sh
```
This will create a timestamped SQL dump in `data/backup/`.

Alternatively, run the manual command:

```bash
# Export database to a SQL file
docker-compose exec db mariadb-dump -u wordpress -p"YOUR_PASSWORD" wordpress > backup.sql
```

#### 2. File Backup
Compress the `data/wp-app` directory (contains `wp-content`, uploads, themes, plugins):

```bash
tar -czvf wp-files.tar.gz ./data/wp-app
```

### 📥 Restore (Import)

To deploy to a new server:

1. **Prepare Environment**:
   - Copy `docker-compose.yaml` and `.env` to the new server.
   - Run `docker-compose up -d` to initialize empty containers.

2. **Restore Files**:
   Extract your file backup into the data volume path:
   ```bash
   tar -xzvf wp-files.tar.gz -C ./
   # Ensure permissions are correct (www-data user usually id 82 in Alpine or 33 in Debian)
   docker-compose exec wp chown -R www-data:www-data /var/www/html
   ```

3. **Restore Database**:
   Import your SQL dump:
   ```bash
   cat backup.sql | docker-compose exec -T db mariadb -u wordpress -p"YOUR_PASSWORD" wordpress
   ```
4. **Restart Services**:
   ```bash
   docker-compose restart
   ```


## 🛠 Utility Scripts

- **`scripts/migration.sh`**: Creates a database backup.
- **`scripts/wpcli_init.sh`**: Internal script used by the `wpcli` container to initialize Redis.
