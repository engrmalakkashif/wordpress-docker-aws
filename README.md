# 🚀 WordPress on AWS with Docker Compose & Nginx

A production-style WordPress deployment using **Docker Compose, Nginx reverse proxy, MySQL, persistent volumes, and AWS EC2**.

This project demonstrates how to containerize WordPress and its database while keeping application traffic behind an Nginx reverse proxy.

The current implementation runs on a **single AWS EC2 instance** and is designed so that it can later be extended into a highly available architecture.

---

## 📌 Project Overview

### Technologies

* AWS EC2
* Docker
* Docker Compose
* WordPress
* MySQL 8
* Nginx
* Linux
* Bash
* Docker Volumes
* Docker Networks

---

## 🏗️ Architecture

```text
                         Internet
                            │
                            │ HTTP :80
                            ▼
                  ┌────────────────────┐
                  │      AWS EC2       │
                  │                    │
                  │   ┌────────────┐   │
                  │   │   Nginx    │   │
                  │   │   Reverse  │   │
                  │   │    Proxy   │   │
                  │   └─────┬──────┘   │
                  │         │           │
                  │         ▼           │
                  │   ┌────────────┐   │
                  │   │ WordPress  │   │
                  │   │ Container  │   │
                  │   └─────┬──────┘   │
                  │         │           │
                  │         ▼           │
                  │   ┌────────────┐   │
                  │   │   MySQL    │   │
                  │   │ Container  │   │
                  │   └────────────┘   │
                  │                    │
                  └────────────────────┘
                           │
                    Persistent Storage
                    ┌──────┴───────┐
                    ▼              ▼
              wordpress_data   mysql_data
```

---

# 🎯 Project Goals

The main goals of this project are:

1. Deploy WordPress using Docker.
2. Run MySQL in a separate container.
3. Place Nginx in front of WordPress as a reverse proxy.
4. Use Docker volumes for persistent application and database data.
5. Use Docker networks for container communication.
6. Deploy the environment on AWS EC2.
7. Implement database backup and restore scripts.
8. Keep the architecture ready for future HA expansion.

---

# 📂 Project Structure

```text
wordpress-docker-aws/
│
├── README.md
├── docker-compose.yml
├── .env.example
├── .gitignore
│
├── nginx/
│   └── nginx.conf
│
└── scripts/
    ├── backup.sh
    └── restore.sh
```

---

# 🐳 Docker Services

## 1. Nginx

Nginx acts as the reverse proxy.

Responsibilities:

* Accept HTTP traffic.
* Forward requests to WordPress.
* Hide the WordPress container from direct public access.
* Handle client request headers.
* Control maximum upload size.

```text
Client
   │
   ▼
Nginx :80
   │
   ▼
WordPress :80
```

---

## 2. WordPress

The WordPress application runs inside the official WordPress Docker image.

```yaml
image: wordpress:php8.2-apache
```

WordPress connects to MySQL through the Docker network:

```text
wordpress → mysql:3306
```

WordPress data is stored using a persistent Docker volume:

```text
wordpress_data
```

This means removing/recreating the WordPress container does not automatically remove the WordPress data.

---

## 3. MySQL

MySQL provides the WordPress database.

```yaml
image: mysql:8.0
```

Database data is stored in:

```text
mysql_data
```

This protects database data from being lost when the MySQL container is recreated.

---

# 💾 Persistent Volumes

Two Docker volumes are used:

```text
wordpress_data
mysql_data
```

Check them:

```bash
docker volume ls
```

Inspect a volume:

```bash
docker volume inspect wordpress_data
```

List running containers:

```bash
docker ps
```

---

# 🔐 Environment Variables

Database credentials are stored in `.env`.

Example:

```env
MYSQL_ROOT_PASSWORD=change_this_root_password
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
MYSQL_PASSWORD=change_this_database_password
```

The `.env` file is intentionally excluded from Git using `.gitignore`.

Only `.env.example` should be committed.

---

# 🚀 Local Deployment

## Step 1 — Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/wordpress-docker-aws.git

cd wordpress-docker-aws
```

---

## Step 2 — Create Environment File

```bash
cp .env.example .env
```

Edit the credentials:

```bash
nano .env
```

---

## Step 3 — Start Containers

```bash
docker compose up -d
```

Check the containers:

```bash
docker compose ps
```

Expected services:

```text
wordpress-nginx
wordpress-app
wordpress-mysql
```

---

## Step 4 — Check Logs

Nginx:

```bash
docker compose logs nginx
```

WordPress:

```bash
docker compose logs wordpress
```

MySQL:

```bash
docker compose logs mysql
```

Follow logs:

```bash
docker compose logs -f
```

---

## Step 5 — Access WordPress

Open:

```text
http://SERVER-IP
```

WordPress installation should appear.

---

# ☁️ AWS EC2 Deployment

Create an Ubuntu EC2 instance.

Recommended security group rules:

| Protocol | Port | Source    |
| -------- | ---: | --------- |
| SSH      |   22 | Your IP   |
| HTTP     |   80 | 0.0.0.0/0 |
| HTTPS    |  443 | 0.0.0.0/0 |

Do not expose MySQL port `3306` publicly.

---

## Connect to EC2

```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

Update packages:

```bash
sudo apt update
sudo apt upgrade -y
```

Install Docker:

```bash
sudo apt install docker.io docker-compose-plugin -y
```

Enable Docker:

```bash
sudo systemctl enable --now docker
```

Verify:

```bash
docker --version
docker compose version
```

---

## Deploy Application

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/wordpress-docker-aws.git

cd wordpress-docker-aws
```

Create environment file:

```bash
cp .env.example .env
```

Edit credentials:

```bash
nano .env
```

Start the application:

```bash
docker compose up -d
```

Check:

```bash
docker compose ps
```

Access:

```text
http://YOUR_EC2_PUBLIC_IP
```

---

# 🔄 Container Restart Policy

The services use:

```yaml
restart: unless-stopped
```

This allows Docker to automatically restart containers after failures or an EC2 reboot.

For example:

```text
EC2 reboot
     │
     ▼
Docker starts
     │
     ▼
Containers restart
     │
     ├── Nginx
     ├── WordPress
     └── MySQL
```

---

# ❤️ Health Checks

MySQL includes a health check:

```bash
mysqladmin ping
```

WordPress checks:

```text
/wp-login.php
```

Docker Compose uses these health checks to control service startup dependencies.

---

# 🗄️ Database Backup

The project includes a backup script.

Make it executable:

```bash
chmod +x scripts/backup.sh
```

Run:

```bash
./scripts/backup.sh
```

Example output:

```text
Creating MySQL backup...
Database backup created:
./backup/wordpress-db-2026-09-16_22-30-00.sql
```

---

# ♻️ Database Restore

Restore a database backup:

```bash
./scripts/restore.sh backup/wordpress-db-2026-09-16_22-30-00.sql
```

This provides a basic recovery mechanism for the MySQL database.

---

# 🔍 Useful Docker Commands

Check containers:

```bash
docker ps
```

Check all containers:

```bash
docker ps -a
```

Check images:

```bash
docker images
```

Check volumes:

```bash
docker volume ls
```

Check networks:

```bash
docker network ls
```

Restart services:

```bash
docker compose restart
```

Stop services:

```bash
docker compose down
```

Start services:

```bash
docker compose up -d
```

Follow logs:

```bash
docker compose logs -f
```

---

# 🧹 Removing Containers

```bash
docker compose down
```

This removes the containers and network but keeps the named volumes.

To remove volumes as well:

```bash
docker compose down -v
```

⚠️ **Warning:** Removing volumes can permanently delete WordPress and MySQL data.

---

# 🔐 Security Considerations

For a real production deployment, consider:

* HTTPS with TLS certificates.
* AWS Application Load Balancer.
* AWS security groups with least-privilege rules.
* AWS Secrets Manager or Parameter Store.
* Automated backups.
* S3 backup storage.
* Database encryption.
* EBS encryption.
* OS patching.
* Container image updates.
* Monitoring and alerting.
* WAF protection.
* Restricting SSH access.
* Disabling unnecessary public ports.

---

# 📈 Extending This Project to High Availability

The current project uses a **single EC2 instance**, so it is not fully highly available.

However, you can extend the architecture.

A future HA architecture could look like:

```text
                         Internet
                            │
                            ▼
                    ┌───────────────┐
                    │ AWS Route 53  │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │ Application   │
                    │ Load Balancer │
                    └───────┬───────┘
                            │
                 ┌──────────┴──────────┐
                 ▼                     ▼
          ┌─────────────┐       ┌─────────────┐
          │   EC2 #1    │       │   EC2 #2    │
          │  WordPress  │       │  WordPress  │
          │   + Nginx   │       │   + Nginx   │
          └──────┬──────┘       └──────┬──────┘
                 │                     │
                 └──────────┬──────────┘
                            ▼
                    ┌───────────────┐
                    │   Amazon RDS  │
                    │     MySQL     │
                    │ Multi-AZ      │
                    └───────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │      S3       │
                    │ Media/Backup  │
                    └───────────────┘
```

### Possible improvements

The single-instance deployment can be extended with:

```text
Single EC2
    │
    ├── Auto Scaling Group
    │
    ├── Application Load Balancer
    │
    ├── Multiple WordPress instances
    │
    ├── Amazon RDS MySQL Multi-AZ
    │
    ├── S3 for media/static assets
    │
    ├── EFS for shared WordPress files
    │
    ├── Route 53
    │
    ├── CloudWatch
    │
    └── AWS WAF
```

This would remove the EC2 instance as a single point of failure and provide a more production-oriented architecture.

---

# 📊 Current vs Future Architecture

| Component     | Version 1       | HA Extension           |
| ------------- | --------------- | ---------------------- |
| Compute       | Single EC2      | Auto Scaling Group     |
| WordPress     | Docker          | Multiple instances     |
| Reverse Proxy | Nginx           | Nginx + ALB            |
| Database      | MySQL container | Amazon RDS MySQL       |
| Database HA   | Single MySQL    | RDS Multi-AZ           |
| Storage       | Docker volumes  | EFS/S3                 |
| DNS           | EC2 IP          | Route 53               |
| Monitoring    | Docker logs     | CloudWatch             |
| Security      | Security Groups | SG + WAF               |
| Backup        | Bash/MySQL dump | S3 + automated backups |

---

# 🎓 What This Project Demonstrates

This project demonstrates practical knowledge of:

* Linux administration
* Docker
* Docker Compose
* Container networking
* Nginx reverse proxy
* WordPress deployment
* MySQL
* Persistent storage
* Health checks
* Container restart policies
* AWS EC2
* Security Groups
* Bash scripting
* Database backup and restore
* Production architecture planning
* High-availability design concepts

---

# 🚀 Future Improvements

Possible next versions:

### Version 2

* HTTPS with Let's Encrypt
* Domain name
* Automated database backups
* S3 backup storage

### Version 3

* Terraform infrastructure
* AWS ALB
* Auto Scaling Group
* RDS MySQL

### Version 4

* EFS shared WordPress storage
* CloudWatch monitoring
* CI/CD with GitHub Actions or Jenkins
* Blue/green deployment

### Version 5

* Full production-oriented HA architecture
* WAF
* Route 53
* Secrets Manager
* Automated disaster recovery

---

# 👨‍💻 Author

**Kashif Khan**

DevOps Engineer

GitHub: `https://github.com/engrmalakkashif/`

---

## ⭐ If you found this project useful

Star the repository ⭐ and feel free to fork it for your own learning.
