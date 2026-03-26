#!/bin/bash
# ==============================================================================
#  TDZ NETWORK CONTROL
# V 0.0.1 BETA (Flawless Pro Max)
#  x-credit: https://info.tuhinbro.website
# TG: @TuhinBroh
# ==============================================================================

INTERFACE="eth0"
SCRIPT_PATH="$(realpath "$0")"
CLP_BIN="/usr/local/bin/clp"
INSTALL_FLAG="/tmp/.tdz_clp_installed"

# ── Colors ────────────────────────────────────────────────────────────────────
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'
M='\033[1;35m'; C='\033[1;36m'; W='\033[1;37m'; DG='\033[1;30m'; NC='\033[0m'

# ── UI Helpers ────────────────────────────────────────────────────────────────
TW() { tput cols 2>/dev/null || echo 60; }

center() {
    local txt="$1"; local w=$(TW)
    local clean=$(echo -e "$txt" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    local len=${#clean}
    local pad=$(( (w - len) / 2 ))
    [ $pad -lt 0 ] && pad=0
    printf "%${pad}s" ""
    echo -e "$txt"
}

hline() {
    local ch="${1:-─}"; local col="${2:-$C}"; local w=$(TW)
    echo -ne "${col}"
    printf "%0.s${ch}" $(seq 1 "$w")
    echo -e "${NC}"
}

confirm() {
    echo -e "\n  ${Y}⚠  $1 ${DG}[y/N]${NC} ${C}›${NC} \c"
    read -r ans
    [[ "${ans,,}" == "y" ]] || return 1
    return 0
}

spin() {
    local pid=$1 msg="$2"; local f='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'; local i=0
    while kill -0 "$pid" 2>/dev/null; do
        echo -ne "\r  ${C}${f:$i:1}${NC}  $msg "; i=$(( (i+1)%10 )); sleep 0.08
    done
    echo -e "\r  ${G}✔${NC}  $msg  ${G}DONE${NC}"
}

# ── Install Step Printer ──────────────────────────────────────────────────────
# Usage: install_step "Label" command_result(0=ok, 1=fail)
install_step() {
    local label="$1"
    local status="$2"   # 0 = ok, anything else = fail
    local w=$(TW)
    local dots_len=$(( w - ${#label} - 18 ))
    [ $dots_len -lt 3 ] && dots_len=3
    local dots=$(printf '%0.s.' $(seq 1 $dots_len))
    if [ "$status" -eq 0 ]; then
        printf "  ${W}%s${NC}${DG}%s${NC}  [  ${G}✔  DONE  ${NC}]\n" "$label" "$dots"
    else
        printf "  ${W}%s${NC}${DG}%s${NC}  [  ${R}✘  FAIL  ${NC}]\n" "$label" "$dots"
    fi
}

# ── First-Run Installer ───────────────────────────────────────────────────────
run_installer() {
    clear; echo
    hline "━" "$M"
    center "${C}♻️ TDZ NETWORK CONTROL - INSTALLER ${NC}"
    center "${DG}Developed By: Yeasinul Hoque Tuhin ● @TuhinBroh${NC}"
    hline "━" "$M"
    echo
    center "${Y}⚡  First-run setup detected. Installing... ${NC}"
    echo
    hline "─" "$DG"
    echo

    local all_ok=0

    # Step 1: Create /usr/local/bin/clp
    printf '#!/bin/bash\nsudo bash %s "$@"\n' "$SCRIPT_PATH" \
        | sudo tee "$CLP_BIN" >/dev/null 2>&1
    sudo chmod +x "$CLP_BIN" >/dev/null 2>&1
    if [ -x "$CLP_BIN" ]; then
        install_step "Creating global 'clp' command" 0
    else
        install_step "Creating global 'clp' command" 1
        all_ok=1
    fi
    sleep 0.2

    # Step 2: Add alias to ~/.bashrc
    if [ -f "$HOME/.bashrc" ]; then
        sed -i '/alias clp=/d' "$HOME/.bashrc" 2>/dev/null
        echo "alias clp='sudo bash $SCRIPT_PATH'" >> "$HOME/.bashrc"
        grep -q "alias clp=" "$HOME/.bashrc" && install_step "Adding alias to ~/.bashrc" 0 || install_step "Adding alias to ~/.bashrc" 1
    else
        touch "$HOME/.bashrc"
        echo "alias clp='sudo bash $SCRIPT_PATH'" >> "$HOME/.bashrc"
        install_step "Creating ~/.bashrc with alias" 0
    fi
    sleep 0.2

    # Step 3: Add alias to ~/.zshrc (if exists)
    if [ -f "$HOME/.zshrc" ]; then
        sed -i '/alias clp=/d' "$HOME/.zshrc" 2>/dev/null
        echo "alias clp='sudo bash $SCRIPT_PATH'" >> "$HOME/.zshrc"
        install_step "Adding alias to ~/.zshrc" 0
    else
        install_step "Skipping ~/.zshrc (not found)" 0
    fi
    sleep 0.2

    # Step 4: Source bashrc (apply immediately in current shell)
    # shellcheck disable=SC1090
    source "$HOME/.bashrc" >/dev/null 2>&1
    install_step "Applying aliases to current session" 0
    sleep 0.2

    # Step 5: Mark as installed
    touch "$INSTALL_FLAG"
    install_step "Saving installation state" 0
    sleep 0.2

    # Step 6: Check required tools (ethtool, iproute2)
    if command -v tc &>/dev/null && command -v ethtool &>/dev/null; then
        install_step "Required tools (tc, ethtool)" 0
    else
        echo -ne "\r  ${C}⠋${NC}  Installing required tools (tc, ethtool) "
        (sudo apt-get update -y >/dev/null 2>&1 && sudo apt-get install -y ethtool iproute2 >/dev/null 2>&1) &
        spin $! "Installing required tools (tc, ethtool)"
        command -v tc &>/dev/null && install_step "Verifying tool installation" 0 || install_step "Verifying tool installation" 1
    fi
    sleep 0.2

    # Step 7: Load IFB module
    sudo modprobe ifb numifbs=1 >/dev/null 2>&1
    lsmod | grep -q "ifb" && install_step "Loading IFB kernel module" 0 || install_step "Loading IFB kernel module" 1
    sleep 0.2

    echo
    hline "─" "$DG"

    if [ "$all_ok" -eq 0 ]; then
        echo
        center "${G}✔  Installation Completed Successfully!  ✔${NC}"
        echo
        center "${DG}You can now launch dashboard anytime with:${NC}"
        center "${C}run: clp${NC}"
    else
        echo
        center "${R}⚠  Installation completed with some warnings.${NC}"
        center "${Y}Try running with: sudo bash $SCRIPT_PATH${NC}"
    fi

    echo
    hline "━" "$M"
    echo
    printf "  ${DG}Press ENTER to launch dashboard...${NC}"; read -r
}

# ── Auto clp check ────────────────────────────────────────────────────────────
# Run installer ONLY if clp binary doesn't exist yet
if [ ! -x "$CLP_BIN" ]; then
    run_installer
fi

# ── System Data Fetcher ───────────────────────────────────────────────────────
check_system() {
    if tc qdisc show dev "$INTERFACE" 2>/dev/null | grep -q "tbf"; then
        UP_VAL=$(tc qdisc show dev "$INTERFACE" | grep -oP 'rate \K[^ ]+' | head -1)
        UP_LAT=$(tc qdisc show dev "$INTERFACE" | grep -oP '(lat|latency) \K[^ ]+' | head -1)
        UP_ST="${Y}THROTTLED${NC}"; UP_SP="${Y}${UP_VAL}${NC}"; UP_LAT_D="${Y}${UP_LAT:-N/A}${NC}"
    else
        UP_ST="${G}DEFAULT${NC}"; UP_SP="${G}Max Speed${NC}"; UP_LAT_D="${G}DEFAULT${NC}"
    fi

    if tc qdisc show dev ifb0 2>/dev/null | grep -q "tbf"; then
        DL_VAL=$(tc qdisc show dev ifb0 | grep -oP 'rate \K[^ ]+' | head -1)
        DL_LAT=$(tc qdisc show dev ifb0 | grep -oP '(lat|latency) \K[^ ]+' | head -1)
        DL_ST="${Y}THROTTLED${NC}"; DL_SP="${Y}${DL_VAL}${NC}"; DL_LAT_D="${Y}${DL_LAT:-N/A}${NC}"
    else
        DL_ST="${G}DEFAULT${NC}"; DL_SP="${G}Max Speed${NC}"; DL_LAT_D="${G}DEFAULT${NC}"
    fi

    ethtool -k "$INTERFACE" 2>/dev/null | grep -q "generic-receive-offload: on" \
        && GRO_ST="${R}GRO ON (Warning)${NC}" || GRO_ST="${G}OPTIMIZED${NC}"
    lsmod | grep -q "ifb" && IFB_ST="${G}ACTIVE${NC}" || IFB_ST="${R}OFFLINE${NC}"

    LOCAL_IP=$(ip -4 addr show "$INTERFACE" 2>/dev/null | grep -oP '(?<=inet )\S+' | head -1 || echo "N/A")
    PUB_IP=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo "N/A")
    CONNS=$(ss -tn 2>/dev/null | grep -c ESTAB || echo "0")

    OS_SYS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d '"' -f 2 | cut -c 1-35 || echo "Linux")
    CPU_MOD=$(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null | xargs | cut -c 1-30)
    [ -z "$CPU_MOD" ] && CPU_MOD="Unknown CPU"
    CPU_COR=$(nproc 2>/dev/null || echo "1")
    RAM_USG=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 " / " $2}')
    DISK_USG=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " ("$5")"}')
    UPTIME_S=$(uptime -p 2>/dev/null | sed 's/up //' || echo "N/A")
}

# ── Dashboard UI ──────────────────────────────────────────────────────────────
draw_dashboard() {
    clear; echo
    hline "━" "$M"
    center "${C} PUBLIC NETWORK SPEED LIMIT MONITOR - BY: TUHIN DROID ZONE ${NC}"
    center "${DG}Developed By: Yeasinul Hoque Tuhin ● info.tuhinbro.website${NC}"
    hline "━" "$M"; echo

    echo -e "  ${W}[ 🖥️  SERVER SPECIFICATIONS ]${NC}"
    hline "─" "$DG"
    echo -e "  ${C}OS System :${NC} ${W}${OS_SYS}${NC}"
    echo -e "  ${C}CPU Model :${NC} ${W}${CPU_MOD}${NC}"
    echo -e "  ${C}CPU Cores :${NC} ${W}${CPU_COR} Cores${NC}"
    echo -e "  ${C}RAM Usage :${NC} ${W}${RAM_USG}${NC}"
    echo -e "  ${C}Disk Used :${NC} ${W}${DISK_USG}${NC}"
    echo -e "  ${C}Uptime    :${NC} ${W}${UPTIME_S}${NC}\n"

    echo -e "  ${W}[ 🌐 NETWORK INFORMATION ]${NC}"
    hline "─" "$DG"
    echo -e "  ${C}Interface :${NC} ${W}${INTERFACE}${NC}"
    echo -e "  ${C}Local IP  :${NC} ${W}${LOCAL_IP}${NC}"
    echo -e "  ${C}Public IP :${NC} ${W}${PUB_IP}${NC}"
    echo -e "  ${C}Connects  :${NC} ${W}${CONNS} ESTABLISHED${NC}\n"

    echo -e "  ${W}[ ⛈️  BANDWIDTH LIMITS ]${NC}"
    hline "─" "$DG"
    echo -e "  ${G}📥 DOWNLOAD${NC}"
    echo -e "     Status : ${DL_ST}"
    echo -e "     Speed  : ${DL_SP}"
    echo -e "     Ping   : ${DL_LAT_D}\n"
    echo -e "  ${R}📤 UPLOAD${NC}"
    echo -e "     Status : ${UP_ST}"
    echo -e "     Speed  : ${UP_SP}"
    echo -e "     Ping   : ${UP_LAT_D}\n"

    echo -e "  ${W}[ ⚙️  HARDWARE STATUS ]${NC}"
    hline "─" "$DG"
    echo -e "  ${C}GRO/TSO   :${NC} ${GRO_ST}"
    echo -e "  ${C}IFB Core  :${NC} ${IFB_ST}\n"

    echo -e "  ${W}[ 🕹️  CONTROL PANEL ]${NC}"
    hline "━" "$DG"
    echo -e "  ${Y}[1]${NC} 💠 SET CUSTOM SPEED LIMITS"
    echo -e "  ${Y}[2]${NC} ♻️  RESET TO DEFAULT"
    echo -e "  ${Y}[3]${NC} 📊 LIVE BANDWIDTH MONITOR"
    echo -e "  ${Y}[4]${NC} ⚡ RUN OOKLA SPEEDTEST"
    echo -e "  ${Y}[5]${NC} ⚙️  FORCE HARDWARE OPTIMIZE"
    echo -e "  ${Y}[6]${NC} 🔍 PING LATENCY TEST"
    echo -e "  ${Y}[7]${NC} 🟢 ACTIVE CONNECTIONS"
    echo -e "  ${Y}[8]${NC} 🔄 CHANGE INTERFACE"
    echo -e "  ${R}[9]${NC} ❌ UNINSTALL COMMAND CENTER"
    echo -e "  ${DG}[0]${NC} 🚪 EXIT"
    hline "━" "$DG"
    echo -e -n "  ${G}▶${NC} ${W}SELECT OPTION${NC} ${DG}[0-9]${NC} ${C}›${NC} "
}

# ── Limits Setup ──────────────────────────────────────────────────────────────
setup_limits() {
    clear; hline; center "${C}💠 SET CUSTOM BANDWIDTH LIMITS ${NC}"; hline; echo

    echo -e -n "  ${G}📥 Target Download (Mbps) [0 to skip]${NC} ${C}›${NC} "; read -r DL_INP
    if [[ "$DL_INP" =~ ^[0-9]+$ ]] && [[ "$DL_INP" -gt 0 ]]; then
        echo -e -n "     ${M}⏱  Download Ping (ms) [Default 1]${NC}   ${C}›${NC} "; read -r DL_LAT_INP
        DL_LAT_INP=${DL_LAT_INP:-1}
    fi

    echo -e -n "\n  ${R}📤 Target Upload   (Mbps) [0 to skip]${NC} ${C}›${NC} "; read -r UP_INP
    if [[ "$UP_INP" =~ ^[0-9]+$ ]] && [[ "$UP_INP" -gt 0 ]]; then
        echo -e -n "     ${M}⏱  Upload Ping (ms)   [Default 1]${NC}   ${C}›${NC} "; read -r UP_LAT_INP
        UP_LAT_INP=${UP_LAT_INP:-1}
    fi

    confirm "Apply these rules to the server?" || return
    echo

    (sudo apt install ethtool iproute2 -y >/dev/null 2>&1) & spin $! "Checking dependencies"
    (sudo modprobe ifb numifbs=1 >/dev/null 2>&1
     sudo ip link set dev ifb0 up >/dev/null 2>&1
     sudo ethtool -K "$INTERFACE" gro off lro off tso off gso off >/dev/null 2>&1
     sudo tc qdisc del dev "$INTERFACE" root 2>/dev/null
     sudo tc qdisc del dev "$INTERFACE" ingress 2>/dev/null
     sudo tc qdisc del dev ifb0 root 2>/dev/null) & spin $! "Flushing old rules"

    CRON_CMD="@reboot modprobe ifb numifbs=1 && ip link set dev ifb0 up && ethtool -K $INTERFACE gro off lro off tso off gso off"

    if [[ "$UP_INP" =~ ^[0-9]+$ ]] && [[ "$UP_INP" -gt 0 ]]; then
        (sudo tc qdisc add dev "$INTERFACE" root tbf rate "${UP_INP}mbit" burst 128kbit latency "${UP_LAT_INP}ms" >/dev/null 2>&1) & spin $! "Applying Upload Limit → ${UP_INP} Mbps (${UP_LAT_INP}ms)"
        CRON_CMD="$CRON_CMD && tc qdisc add dev $INTERFACE root tbf rate ${UP_INP}mbit burst 128kbit latency ${UP_LAT_INP}ms"
    fi

    if [[ "$DL_INP" =~ ^[0-9]+$ ]] && [[ "$DL_INP" -gt 0 ]]; then
        (sudo tc qdisc add dev "$INTERFACE" handle ffff: ingress >/dev/null 2>&1
         sudo tc filter add dev "$INTERFACE" parent ffff: protocol ip u32 match ip src 0.0.0.0/0 action mirred egress redirect dev ifb0 >/dev/null 2>&1
         sudo tc qdisc add dev ifb0 root tbf rate "${DL_INP}mbit" burst 128kbit latency "${DL_LAT_INP}ms" >/dev/null 2>&1) & spin $! "Applying Download Limit → ${DL_INP} Mbps (${DL_LAT_INP}ms)"
        CRON_CMD="$CRON_CMD && tc qdisc add dev $INTERFACE handle ffff: ingress && tc filter add dev $INTERFACE parent ffff: protocol ip u32 match ip src 0.0.0.0/0 action mirred egress redirect dev ifb0 && tc qdisc add dev ifb0 root tbf rate ${DL_INP}mbit burst 128kbit latency ${DL_LAT_INP}ms"
    fi

    ((crontab -l 2>/dev/null | grep -v "tc qdisc" | grep -v "ethtool -K"; echo "$CRON_CMD") | crontab -) & spin $! "Saving to startup rules"

    echo -e "\n  ${G}✔ Limits Applied Successfully!${NC}"; echo -e -n "  ${DG}Press ENTER...${NC}"; read -r
}

# ── Remove All ────────────────────────────────────────────────────────────────
remove_all() {
    confirm "Are you sure you want to completely remove all limits?" || return
    echo
    (sudo tc qdisc del dev "$INTERFACE" root >/dev/null 2>&1) &        spin $! "Removing upload rules"
    (sudo tc qdisc del dev "$INTERFACE" ingress >/dev/null 2>&1) &     spin $! "Removing ingress redirect"
    (sudo tc qdisc del dev ifb0 root >/dev/null 2>&1) &                spin $! "Removing download rules"
    (sudo ethtool -K "$INTERFACE" gro on lro on tso on gso on >/dev/null 2>&1) & spin $! "Restoring hardware optimizations"
    ((crontab -l 2>/dev/null | grep -v "tc qdisc" | grep -v "ethtool -K") | crontab -) & spin $! "Cleaning startup scripts"

    echo -e "\n  ${G}✔ Server restored to default max speed!${NC}"; echo -e -n "  ${DG}Press ENTER...${NC}"; read -r
}

# ── Uninstall ─────────────────────────────────────────────────────────────────
uninstall_clp() {
    clear; hline; center "${R}⚠  COMPLETE UNINSTALLATION ${NC}"; hline; echo
    confirm "This will remove all limits, crontab entries, and aliases. Continue?" || return
    echo

    (sudo tc qdisc del dev "$INTERFACE" root >/dev/null 2>&1) & spin $! "Cleaning Upload rules"
    (sudo tc qdisc del dev "$INTERFACE" ingress >/dev/null 2>&1) & spin $! "Cleaning Download rules"
    (sudo tc qdisc del dev ifb0 root >/dev/null 2>&1) & spin $! "Cleaning IFB core"
    (sudo ip link set dev ifb0 down >/dev/null 2>&1) & spin $! "Disabling IFB interface"
    (sudo ethtool -K "$INTERFACE" gro on lro on tso on gso on >/dev/null 2>&1) & spin $! "Restoring hardware config"
    ((crontab -l 2>/dev/null | grep -v "tc qdisc" | grep -v "ethtool -K") | crontab -) & spin $! "Cleaning crontab startup"
    (sudo rm -f "$CLP_BIN" >/dev/null 2>&1) & spin $! "Removing global 'clp' command"

    for RC in ~/.bashrc ~/.zshrc; do
        [ -f "$RC" ] && sed -i '/alias clp=/d' "$RC" >/dev/null 2>&1
    done
    install_step "Removing shell aliases" 0

    rm -f "$INSTALL_FLAG" 2>/dev/null
    install_step "Clearing install state" 0

    echo -e -n "\n  ${Y}⚠  Remove the script file itself? ${DG}[y/N]${NC} ${C}›${NC} "
    read -r rm_self
    if [[ "${rm_self,,}" == "y" ]]; then
        (rm -f "$SCRIPT_PATH" >/dev/null 2>&1) & spin $! "Deleting script file"
    else
        echo -e "  ${DG}⊘  Script file kept intact.${NC}"
    fi

    echo -e "\n  ${G}✔ Uninstallation complete. Server is clean!${NC}"; exit 0
}

# ── Live Monitor ──────────────────────────────────────────────────────────────
live_monitor() {
    trap 'break' INT
    while true; do
        R1=$(cat /sys/class/net/"$INTERFACE"/statistics/rx_bytes 2>/dev/null || echo 0)
        T1=$(cat /sys/class/net/"$INTERFACE"/statistics/tx_bytes 2>/dev/null || echo 0)
        sleep 1
        R2=$(cat /sys/class/net/"$INTERFACE"/statistics/rx_bytes 2>/dev/null || echo 0)
        T2=$(cat /sys/class/net/"$INTERFACE"/statistics/tx_bytes 2>/dev/null || echo 0)

        RX=$(awk "BEGIN{printf \"%.2f\",($R2-$R1)/131072}")
        TX=$(awk "BEGIN{printf \"%.2f\",($T2-$T1)/131072}")

        printf "\033[H\033[J"
        echo
        hline "━" "$M"; center "${C}📊  LIVE BANDWIDTH MONITOR ${NC}"
        center "${DG}Interface: ${W}$INTERFACE${NC}  ●  ${Y}Press CTRL+C to Exit${NC}"; hline "━" "$M"
        echo
        echo -e "  ${G}📥 DOWNLOAD (IN) :${NC} ${W}${RX} Mbps${NC}"
        echo -e "  ${R}📤 UPLOAD (OUT)  :${NC} ${W}${TX} Mbps${NC}"
        echo
        hline "─" "$DG"
    done
    trap - INT
}

# ── Speedtest & Ping ──────────────────────────────────────────────────────────
run_speedtest() {
    confirm "Run Ookla Speedtest? (May consume bandwidth)" || return
    clear; hline; center "${C}⚡  OOKLA SPEEDTEST ${NC}"; hline; echo
    if ! command -v speedtest &>/dev/null; then
        echo -e "  ${C}Installing Ookla CLI...${NC}"
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash >/dev/null 2>&1
        sudo apt install speedtest -y >/dev/null 2>&1
    fi
    speedtest; echo -e -n "\n  ${DG}Press ENTER...${NC}"; read -r
}

ping_test() {
    clear; hline; center "${M}🔍  LATENCY PING TEST ${NC}"; hline; echo
    for host in "1.1.1.1 (Cloudflare)" "8.8.8.8 (Google DNS)" "google.com (Google Web)" "facebook.com (Facebook)" "speedtest.net (Ookla)" "github.com (GitHub)"; do
        ip=$(echo "$host" | awk '{print $1}')
        res=$(ping -c 3 -W 2 "$ip" 2>/dev/null | tail -1 | awk -F'/' '{printf "%.1f",$5}')
        if [[ -n "$res" ]]; then
            echo -e "  ${C}Ping to ${W}${host}${NC}  →  ${G}${res} ms${NC}"
        else
            echo -e "  ${C}Ping to ${W}${host}${NC}  →  ${R}TIMEOUT${NC}"
        fi
    done
    echo -e -n "\n  ${DG}Press ENTER...${NC}"; read -r
}

# ── Main Loop ─────────────────────────────────────────────────────────────────
while true; do
    check_system
    draw_dashboard
    read -r choice
    case "$choice" in
        1) setup_limits ;;
        2) remove_all ;;
        3) live_monitor ;;
        4) run_speedtest ;;
        5) confirm "Force Hardware Optimization?" && {
               echo
               (sudo ethtool -K "$INTERFACE" gro off lro off tso off gso off >/dev/null 2>&1) & spin $! "Optimizing Hardware"
               sleep 1
           } ;;
        6) ping_test ;;
        7)
            clear; hline; center "${G}🟢 ACTIVE CONNECTIONS${NC}"; hline
            echo -e "  ${C}STATE      LOCAL IP:PORT          REMOTE IP:PORT${NC}"
            hline "─" "$DG"
            ss -tn 2>/dev/null | awk 'NR>1 {
                state=substr($1,1,10)
                loc=substr($4,1,21)
                rem=substr($5,1,21)
                printf "  %-10s %-22s %-22s\n", state, loc, rem
            }' | head -15
            echo -e -n "\n  ${DG}Press ENTER...${NC}"; read -r
            ;;
        8) echo -e -n "\n  ${Y}Enter new interface name (Current: $INTERFACE):${NC} "; read -r new_if; [[ -n "$new_if" ]] && INTERFACE="$new_if" ;;
        9) uninstall_clp ;;
        0) clear; echo -e "\n  ${C}⚡  System Exit. Have a great day @TuhinBroh!  ${NC}\n"; exit 0 ;;
        *) echo -e "\n  ${R}✘ Invalid Choice!${NC}"; sleep 1 ;;
    esac
done
