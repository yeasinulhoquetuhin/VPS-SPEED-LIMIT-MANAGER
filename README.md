<h1 align="center">⚡ ᴠᴩɴ ɴᴇᴛᴡᴏʀᴋ ʟɪᴍɪᴛ ᴍᴀɴᴀɢᴇᴍᴇɴᴛ ꜱᴄʀɪᴩᴛ</h1>
<h4 align="center">The Ultimate Network Control & Bandwidth Optimizer for Linux Servers</h4>

<p align="center">
  Easily manage, monitor, and limit your Linux server's network speed with a powerful and visually stunning CLI dashboard.
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/yeasinulhoquetuhin/VPS-SPEED-LIMIT-MANAGER/refs/heads/master/Screenshot_20260326-194229_com.termux.png" alt="Dashboard Preview" width="85%">
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

---

## ✨ Advanced Features Breakdown

Here is a detailed look at what you can do with this dashboard:

* 🎛️ **Custom Speed Throttling (Inbound & Outbound):**
  Set precise limits for your **Upload** and **Download** speeds independently. Want to restrict downloads to 10 Mbps but keep uploads at 50 Mbps? You can do it instantly from the menu.
* 📊 **Live Bandwidth Monitor:**
  Watch your server's real-time network usage. The tool calculates exact RX (Receive/Download) and TX (Transmit/Upload) data passing through your active interface in real-time.
* ⚙️ **Hardware Optimization (GRO/TSO Management):**
  Automatically configures Generic Receive Offload (GRO) and TCP Segmentation Offload (TSO) when applying limits. This ensures your traffic shaping works flawlessly without hardware bottlenecks.
* ⚡ **Integrated Speedtest & Ping Diagnostics:**
  No need to install separate heavy tools. Run Ookla Speedtest and check connection latency (Ping) to major global servers (Cloudflare, Google, GitHub) directly from the dashboard.
* 🛡️ **Persistent Rules (Auto-Crontab):**
  Your speed limits are safe! The script automatically saves your rules to the server's startup routine. Even if your VPS restarts or reboots, the limits will be re-applied automatically.
* ♻️ **One-Click Reset & Uninstall:**
  Instantly flush all network rules, delete crontab entries, and restore the server to its default maximum speed with a single click.

---

## 🛠️ Complete Installation Guide

We have combined all the necessary commands into a single block for your convenience. Just copy the entire block below and paste it into your server's terminal. 

**What these commands will do:**
1. Update your server's package list (Highly recommended for fresh servers).
2. Download the core installer script from this repository.
3. Grant execution permissions to the downloaded file.
4. Run the installer to set up the environment and network dependencies (`tc`, `ethtool`).
5. Reload your terminal profile so you can start using the tool immediately.

```bash
sudo apt update && sudo apt upgrade -y
wget -O /root/clp.sh [https://raw.githubusercontent.com/yeasinulhoquetuhin/VPS-SPEED-LIMIT-MANAGER/refs/heads/master/install.sh](https://raw.githubusercontent.com/yeasinulhoquetuhin/VPS-SPEED-LIMIT-MANAGER/refs/heads/master/install.sh)
chmod +x /root/clp.sh
sudo bash /root/clp.sh
source ~/.bashrc
```

---

## 💠 ʜᴏᴡ ᴛᴏ ᴏᴩᴇʀᴀᴛᴇ ᴛʜᴇ ᴅᴀꜱʜʙᴏᴀʀᴅ?

Once the installation is complete, you no longer need to type long commands or locate script files. The installer creates a permanent shortcut on your server.

Simply type the following command anywhere in your terminal and hit **Enter**:

```bash
clp
```

**Navigating the Menu:**
When the dashboard opens, you will see a beautifully designed menu with numbers `[0-9]`. Just type the number of the action you want to perform (e.g., type `1` to set custom limits, type `3` to open the live monitor) and press Enter. Enjoy full control over your network!
