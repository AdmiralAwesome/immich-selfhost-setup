#!/bin/bash
set -e

echo "=== Updating system and installing dependencies ==="
apt update && apt install -y cifs-utils docker.io docker-compose-plugin

echo "=== Creating mount point ==="
mkdir -p /mnt/immich

echo "=== Creating CIFS credentials file ==="
cat > /root/.smbcred << 'EOF'
username=immich
password=Immich123x!
EOF
chmod 600 /root/.smbcred

echo "=== Mounting CIFS share ==="
mount -t cifs //10.1.0.111/immich /mnt/immich -o credentials=/root/.smbcred,uid=0,gid=0,rw,vers=3.0,nounix,nobrl,dir_mode=0777,file_mode=0777

echo "=== Verifying mount ==="
ls /mnt/immich && echo "Mount OK"

echo "=== Making mount permanent ==="
echo "//10.1.0.111/immich  /mnt/immich  cifs  credentials=/root/.smbcred,uid=0,gid=0,rw,vers=3.0,nounix,nobrl,dir_mode=0777,file_mode=0777  0  0" >> /etc/fstab

echo "=== Creating Immich directories ==="
mkdir -p /mnt/immich/{upload,encoded-video,library,profile,thumb}
touch /mnt/immich/{upload,encoded-video,library,profile,thumb}/.immich
chown -R 1000:1000 /mnt/immich
chmod -R 777 /mnt/immich

echo "=== Preparing Immich stack ==="
mkdir -p /opt/stacks/immich
cd /opt/stacks/immich

cat > docker-compose.yml << 'EOF'
name: immich

services:
  immich-server:
    container_name: immich_server
    image: ghcr.io/immich-app/immich-server:release
    volumes:
      - ${UPLOAD_LOCATION}:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    env_file:
      - .env
    ports:
      - '2283:2283'
    depends_on:
      - redis
      - database
    restart: always

  immich-machine-learning:
    container_name: immich_machine_learning
    image: ghcr.io/immich-app/immich-machine-learning:release
    volumes:
      - model-cache:/cache
    env_file:
      - .env
    restart: always

  redis:
    container_name: immich_redis
    image: valkey/valkey:8-bookworm
    restart: always

  database:
    container_name: immich_postgres
    image: ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_DB: ${DB_DATABASE_NAME}
    volumes:
      - ${DB_DATA_LOCATION}:/var/lib/postgresql/data
    env_file:
      - .env
    restart: always

volumes:
  model-cache:
EOF

mkdir -p /opt/immich/postgres
cat > .env << 'EOF'
UPLOAD_LOCATION=/mnt/immich
DB_DATA_LOCATION=/opt/immich/postgres
DB_PASSWORD=postgres
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
EOF

echo "=== Starting Immich ==="
docker compose pull
docker compose up -d

echo "Waiting 15 seconds for startup..."
sleep 15
docker ps
docker logs immich_server --tail 10
echo "OPEN: http://$(hostname -I | awk '{print $1}'):2283"
