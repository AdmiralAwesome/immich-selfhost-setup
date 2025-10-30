# 🚀 Immich Docker Setup Script

Easily deploy [Immich](https://github.com/immich-app/immich) — a high-performance self-hosted photo and video backup solution — with a single command.  
This script automatically mounts a CIFS/SMB network share and sets up Immich using Docker Compose on Ubuntu/Debian.

---

## 🧱 Before You Start (Proxmox Users)

If you’re running this inside **Proxmox**, make sure you **create a virtual machine (VM)** — **not an LXC container!**  
Immich requires full Docker support, which works properly only on a VM.

### ✅ Steps:

1. Go to the **Proxmox Web UI**  
2. Use this community script to create a Docker-ready VM:  
   👉 [Proxmox Docker VM Script](https://community-scripts.github.io/ProxmoxVE/scripts?id=docker-vm&category=Containers%20%26%20Docker)
3. Once the VM is created and you log in via SSH or the Proxmox console, **immediately change your password**:
   ```bash
   passwd
   ```
4. After changing the password, follow the installation instructions below.

---

## 🧰 Requirements

- 🖥️ Ubuntu or Debian-based **virtual machine**
- 🐳 Docker & Docker Compose (installed automatically)
- 💾 Accessible CIFS/SMB network share (for example, from a NAS)
- 🔑 Root privileges

---

## ⚙️ Installation

Run the following command on your VM:

```bash
curl -sSL https://raw.githubusercontent.com/<YOUR_GITHUB_USERNAME>/immich-docker-setup/main/setup.sh | bash
```

> ⚠️ **Important:** Before running, review or edit the `setup.sh` file to update:
> - CIFS share path (`//10.1.0.111/immich`)
> - SMB username/password (stored in `/root/.smbcred`)
> - Optional port or folder paths

---

## 📂 What This Script Does

1. Installs required dependencies (`cifs-utils`, `docker`, `docker-compose-plugin`)
2. Mounts your CIFS/SMB share at `/mnt/immich`
3. Creates persistent Immich data directories
4. Generates a working Docker Compose stack with:
   - `immich-server`
   - `immich-machine-learning`
   - `redis`
   - `postgres` (with vector extension)
5. Pulls all required images and starts the containers
6. Displays the access URL for your instance

---

## 🧠 Default Configuration

| Component | Path | Notes |
|------------|------|-------|
| **Immich Uploads** | `/mnt/immich` | CIFS-mounted network storage |
| **Postgres Data** | `/opt/immich/postgres` | Local persistent volume |
| **Port** | `2283` | Access Immich UI via `http://<host-ip>:2283` |

---

## 📁 Folder Structure

After installation, you’ll have:

```
/mnt/immich/
├── upload/
├── encoded-video/
├── library/
├── profile/
└── thumb/
```

Each directory includes a `.immich` marker file and is fully writable by Immich containers.

---

## 🔄 Managing Immich

Navigate to your stack directory:
```bash
cd /opt/stacks/immich
```

Common commands:
```bash
docker compose ps           # List containers
docker compose logs -f      # Follow logs
docker compose restart      # Restart Immich
docker compose down         # Stop Immich
```

---

## 🧾 Environment Variables

Defined in `.env`:
```
UPLOAD_LOCATION=/mnt/immich
DB_DATA_LOCATION=/opt/immich/postgres
DB_PASSWORD=postgres
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
```

You can edit these if you wish to change database credentials or paths.

---

## 🧱 Example Output

When setup completes, you should see:
```
✅ Immich is up!
🌍 Open: http://192.168.1.50:2283
```

Then open your browser and log into the Immich web interface.

---

## 🧼 Uninstallation

To completely remove Immich:
```bash
cd /opt/stacks/immich
docker compose down -v
umount /mnt/immich
rm -rf /opt/stacks/immich /opt/immich /mnt/immich
```

---

## 🩺 Troubleshooting

Here are some common issues and fixes:

### ❌ Mount Failed
If `/mnt/immich` doesn’t mount:
```bash
dmesg | tail
```
Check for SMB version or credentials issues.  
Try specifying an older SMB version:
```bash
mount -t cifs //10.1.0.111/immich /mnt/immich -o credentials=/root/.smbcred,vers=2.1
```

### ❌ “Permission Denied” on CIFS Share
Ensure the NAS share allows the `immich` user full access.  
You can also relax permissions temporarily:
```bash
chmod -R 777 /mnt/immich
```

### ❌ Docker Containers Not Starting
Check the logs:
```bash
docker compose logs immich_server
```
If Postgres fails, it may be due to incorrect data folder permissions:
```bash
chown -R 999:999 /opt/immich/postgres
```

### ❌ Cannot Access Web Interface
Ensure the port `2283` is open in your Proxmox or VM firewall:
```bash
ufw allow 2283/tcp
```

---

## 🧑‍💻 Author

**Admiral Awesome**  
Created for easy and repeatable Immich deployments.  
Feel free to fork, star ⭐, or contribute!

---

## 🪪 License

MIT License © Admiral Awesome

---

## 🏷️ Tags
`immich` • `docker` • `selfhosted` • `photos` • `setup-script` • `automation` • `proxmox`
