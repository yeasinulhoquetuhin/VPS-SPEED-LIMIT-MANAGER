<h1 align="center">⚡ ᴠᴩꜱ ꜱᴩᴇᴇᴅ ʟɪᴍɪᴛ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ ꜱᴄʀɪᴩᴛ</h1>
<h4 align="center">The Ultimate Network Control & Bandwidth Optimizer for Linux Servers</h4>

<p align="center">
  <img src="https://img.shields.io/badge/Version-0.0.8%20BETA-blue?style=for-the-badge&logo=appveyor" alt="Version">
  <img src="https://img.shields.io/badge/OS-Ubuntu%20%7C%20Debian-orange?style=for-the-badge&logo=linux" alt="OS">
  <img src="https://img.shields.io/badge/Bash-Script-green?style=for-the-badge&logo=gnu-bash" alt="Bash">
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License">
</p>

<p align="center">
  Easily manage, monitor, and limit your Linux server's network speed with a powerful and visually stunning CLI dashboard.
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/yeasinulhoquetuhin/VPS-SPEED-LIMIT-MANAGER/refs/heads/master/Screenshot_20260328-230425_com.termux.png" alt="Dashboard Preview" width="85%">
</p>

---

> [!IMPORTANT]
> **Crucial Concept to Understand Before Using:**
> This tool is specifically designed to **limit and manage** your server's bandwidth to save costs and prevent network abuse.
> * ❌ **It CANNOT increase your overall speed:** If your ISP or Hosting Provider gives you a maximum server speed of 200 Mbps, this tool **cannot** magically boost it to 400 Mbps.
> * ✅ **It CAN throttle/limit your speed:** You can easily restrict your 200 Mbps connection down to 100 Mbps, 50 Mbps, or any exact rate you prefer.

---

## 🌟 What is this tool?
VPS Speed Limit Manager is a powerful, lightweight, and interactive Command Line Interface (CLI) dashboard. It allows server administrators to seamlessly control network interfaces, throttle traffic, and monitor real-time data consumption without needing complex networking knowledge.

## ✨ Key Features

### ♻️ Core Functionality
- **Global Server Speed Limit** – Set upload/download limits for the entire server.
- **Per‑IP/Port Speed Limits** – Apply custom bandwidth restrictions to specific IP addresses or ports.
- **TCP/UDP Anti‑Share** – Limit the number of concurrent connections on any port (perfect for VPN/proxy sharing).
- **Port Lock to Single IP** – Whitelist only one IP to connect to a specific port (e.g., your private VPN port).
- **Hardware Optimization** – Disable GRO/TSO for better throughput and lower latency.

### 🔒 Firewall & Security
- **Block IP Addresses** – Permanently block unwanted IPs (supports both IPv4 and IPv6).
- **Block Ports** – Prevent access to specific ports.
- **Unblock Anything** – Easily remove any blocking rule.

### 📊 Real‑Time Monitoring
- **Live Bandwidth Monitor** – See current download/upload speeds in MBps.
- **Daily Traffic Summary** – View total data used per day.
- **Monthly Traffic Summary** – Check monthly usage stats.
- **Connection Manager** – List all active TCP connections and kill connections on any port.
- **IP Information** – Fetch your server's public IP, country, ISP, ASN, and more (via ip‑api.com).

### 🔧 Advanced Management
- **Multi‑Interface Support** – Automatically detect all available network interfaces, list them with status and IP, and switch between them.
- **Custom Interface Name** – Enter any interface manually (e.g., `wg0`, `tun0`).
- **Persistent Rules** – All limits survive reboots (optional cron job).
- **Backup & Export** – Save your current rule set to a file.
- **Self‑Updater** – Update the script to the latest version with one click.
- **Complete Uninstall** – Remove all rules and clean up the system.

---

## 🛠️ Complete Installation Guide

Follow these steps one by one to install the manager on your server. Copy each command box separately and run it in your terminal.

### Step 1: Update Server Packages
Highly recommended if you are using a fresh server. This updates your server's package list and upgrades existing packages.
```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2: Download the Installer
This command will securely download the core installer script from this repository to your server.
```bash
wget -O /root/clp.sh https://raw.githubusercontent.com/yeasinulhoquetuhin/VPS-SPEED-LIMIT-MANAGER/refs/heads/master/install.sh
```

### Step 3: Grant Execution Permissions
You need to give the downloaded file permission to run as a program.
```bash
chmod +x /root/clp.sh
```

### Step 4: Run the Setup
This executes the script to set up the environment, install network dependencies (`tc`, `ethtool`), and create the core files.
```bash
sudo bash /root/clp.sh
```

### Step 5: Reload Terminal Profile
This applies the newly created dashboard shortcut to your current terminal session immediately.
```bash
source ~/.bashrc
```

---

## 💠 ʜᴏᴡ ᴛᴏ ᴏᴩᴇʀᴀᴛᴇ ᴛʜᴇ ᴅᴀꜱʜʙᴏᴀʀᴅ?

Once the installation is complete, you no longer need to type long commands or locate script files. The installer creates a permanent shortcut on your server.

Simply type the following command anywhere in your terminal and hit **Enter**:

```bash
clp
```

---

## 🖥️ Dashboard Navigation

The main menu offers these options:

| Option | Description |
|--------|-------------|
| `[1]` | **Speed Limit Manager** – Add, remove, view, or reset limits (global, IP, port, anti‑share). |
| `[2]` | **Firewall Manager** – Block/unblock IPs and ports. |
| `[3]` | **Connection Manager** – View active connections and kill by port. |
| `[4]` | **Live Bandwidth** – Real‑time speeds + daily/monthly traffic stats. |
| `[5]` | **Ping & Speedtest** – Run OOKLA speedtest, ping latency test, IP information. |
| `[6]` | **Hardware Optimize** – Disable GRO/TSO for better network performance. |
| `[7]` | **Restart on Reboot** – Enable/disable automatic rule reload after reboot. |
| `[8]` | **Change Interface** – Switch to another network interface (list auto‑detected). |
| `[9]` | **Backup & Export** – Save current rules to a text file. |
| `[0]` | **Script Management** – Update, reinstall, or uninstall the script. |
| `[X]` | **Exit** – Leave the dashboard. |

---

## 🔧 Usage Examples

### Limit a specific port (e.g., 443) to max 10 connections (anti‑share)
1. `[1]` → Speed Limit Manager  
2. `[2]` → TCP Limit on Port  
3. `[1]` → Set Max Connections  
4. Enter port `443`, max connections `10`, protocol `tcp` (or `both`).

### Lock a port to a single IP (whitelist)
1. `[1]` → Speed Limit Manager  
2. `[2]` → TCP Limit on Port  
3. `[3]` → Lock Port to Single IP  
4. Enter port (e.g., `15553`) and the allowed IP (e.g., `1.2.3.4`).  
   > Only that IP can connect; all others are blocked.

### Block an IP address permanently
1. `[2]` → Firewall Manager  
2. `[1]` → Block an IP Address  
3. Enter the IP (e.g., `203.0.113.5`).  
   > The rule works for both IPv4 and IPv6 (automatically handles `::ffff:` prefixes).

### View total traffic since installation
1. `[4]` → Live Bandwidth  
2. `[4]` → Total Traffic (All Time)  

### Change network interface
1. `[8]` → Change Interface  
2. Select from the list (e.g., `[1]` for eth0) or choose custom.  
   > The new interface is immediately used for all future rules.

---

## 🛡️ Port 22 Protection
The script includes safeguards to **never allow blocking or limiting SSH port 22**. Attempts to block it will show a warning and cancel the operation.

---

## 💾 Data Storage
All rules are stored in:
- `/usr/local/bin/.clp.db` – the database (limits, firewall blocks, locks).
- `/usr/local/bin/.tdz_crontab.sh` – the persistent rule script.
- `/usr/local/bin/clp` – global shortcut (symlink).

Rules survive reboots if you enable “Restart on Reboot”.

---

## ⚙️ Requirements
- **Debian/Ubuntu** (other distributions may work but are not tested)
- **Bash 4+**
- Root access (sudo)

---

## 📝 Changelog (v0.0.8 BETA)
- **New:** TCP/UDP anti‑share with protocol selection.
- **New:** Port lock to single IP (whitelist).
- **New:** Multi‑interface detection and selection.
- **New:** Traffic monitor with daily/monthly totals.
- **New:** IP information (country, ISP, ASN, coordinates).
- **New:** IPv6 support for firewall blocks (automatically converts mapped addresses).
- **Improved:** Empty input handling – pressing Enter reloads the current screen.
- **Improved:** Interface change menu shows all active interfaces with status and IP.
- **Fixed:** View connections now strips `::ffff:` prefixes and aligns columns.
- **Fixed:** Uninstall cleans both IPv4 and IPv6 rules.
- **Fixed:** Backup/export shows correct message when no limits exist.

---

## 🧑‍💻 Credits & Support
- Developed by **[Yeasinul Hoque Tuhin](https://info.tuhinbro.website)**  
- Telegram: [@TuhinBroh](https://t.me/TuhinBroh)  
- Project Page: [GitHub Repository](https://github.com/yeasinulhoquetuhin/VPS-SPEED-LIMIT-MANAGER)

---

<p align="center">
  <i>Made with ❤️ for the Linux community</i><br>
  <i>If you find this tool useful, please ⭐ the repo and share with friends!</i>
</p>
