#!/bin/bash
# ==============================================================================
# TDZ NETWORK CONTROL
# V0.0.8 BETA (Some Bug Fixes!)
# x-credit: https://info.tuhinbro.website
# TG: @TuhinBroh
# ==============================================================================

# ===== VERSION =====
VERSION="0.0.8 BETA"

# ===== AUTO DETECT ACTIVE INTERFACE =====
detect_active_interface() {
    local iface=$(ip route show default 2>/dev/null | grep -oP '(?<=dev )\S+')
    if [[ -n "$iface" ]]; then echo "$iface"; return; fi
    iface=$(ip -4 addr show up | grep -oP '^\d+: \K\w+(?=:)' | grep -v lo | head -1)
    if [[ -n "$iface" ]]; then echo "$iface"; return; fi
    echo "eth0"
}

# ===== INTERFACE VALIDATION =====
interface_exists() {
    [[ -d "/sys/class/net/$1" ]]
}

if [[ -z "$INTERFACE" ]]; then INTERFACE=$(detect_active_interface); fi
if ! interface_exists "$INTERFACE"; then INTERFACE=$(detect_active_interface); fi

SCRIPT_PATH="$(realpath "$0")"
CLP_BIN="/usr/local/bin/clp"
INSTALL_FLAG="/tmp/.tdz_clp_installed"
RULES_FILE="/usr/local/bin/.tdz_crontab.sh"
DB_FILE="/usr/local/bin/.clp.db"

# ── Colors ────────────────────────────────────────────────────────────────────
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; B='\033[1;34m'
M='\033[1;35m'; C='\033[1;36m'; W='\033[1;37m'; DG='\033[1;30m'; NC='\033[0m'
O='\033[38;5;208m'

# ── Box Layout Elements (Width 58) ────────────────────────────────────────────
B_TOP="  ${O}┌──────────────────────────────────────────────────────────┐${NC}"
B_BOT="  ${O}└──────────────────────────────────────────────────────────┘${NC}"
B_MID="  ${O}├──────────────────────────────────────────────────────────┤${NC}"
B_MID_T_DN="  ${O}├────────────────────────────┬─────────────────────────────┤${NC}"
B_MID_CRS="  ${O}├────────────────────────────┼─────────────────────────────┤${NC}"
B_BOT_CRS="  ${O}└────────────────────────────┴─────────────────────────────┘${NC}"

# ── Core UI Helpers ───────────────────────────────────────────────────────────
center() {
    local txt="$1"; local w=60
    local clean=$(echo -e "$txt" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    local len=${#clean}; local pad=$(( (w - len) / 2 ))
    [ $pad -lt 0 ] && pad=0
    printf "%${pad}s" ""; echo -e "$txt"
}

hline() {
    local ch="${1:-─}"; local col="${2:-$C}"; local w=60
    echo -ne "${col}"; printf "%0.s${ch}" $(seq 1 "$w"); echo -e "${NC}"
}

row() {
    local text="$1"
    local clean=$(echo -e "$text" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    local pad=$(( 56 - ${#clean} )); [ $pad -lt 0 ] && pad=0
    local p=""; [ $pad -gt 0 ] && printf -v p "%${pad}s" ""
    echo -e "  ${O}│${NC} ${text}${p} ${O}│${NC}"
}

row2() {
    local l="$1"; local r="$2"
    local c_l=$(echo -e "$l" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    local c_r=$(echo -e "$r" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    local p_l=$(( 27 - ${#c_l} )); [ $p_l -lt 0 ] && p_l=0
    local p_r=$(( 27 - ${#c_r} )); [ $p_r -lt 0 ] && p_r=0
    local pl=""; [ $p_l -gt 0 ] && printf -v pl "%${p_l}s" ""
    local pr=""; [ $p_r -gt 0 ] && printf -v pr "%${p_r}s" ""
    echo -e "  ${O}│${NC} ${l}${pl}${O}│${NC} ${r}${pr} ${O}│${NC}"
}

confirm() {
    echo -e "\n  ${Y}⚠  $1 ${DG}[Y/N]${NC} ${C}›${NC} \c"
    read -r ans
    [[ "${ans,,}" == "y" ]] || return 1
    return 0
}

spin() {
    local pid=$1 msg="$2"; local f='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'; local i=0
    local clean_msg=$(echo -e "$msg" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
    local len=${#clean_msg}; local dots_len=$(( 45 - len ))
    [ $dots_len -lt 3 ] && dots_len=3
    local dots=$(printf '%0.s.' $(seq 1 $dots_len))

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r\033[K  ${C}%s${NC}  ${W}%s${NC}${DG}%s${NC} [ ${Y}WAIT${NC} ] " "${f:$i:1}" "$msg" "$dots"
        i=$(( (i+1)%10 )); sleep 0.08
    done
    printf "\r\033[K  ${G}✔${NC}  ${W}%s${NC}${DG}%s${NC} [ ${G}DONE${NC} ] \n" "$msg" "$dots"
}

get_bar() {
    local pct=${1:-0}; local len=10
    local filled=$(( pct / 10 )); local empty=$(( len - filled ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}●"; done
    for ((i=0; i<empty; i++)); do bar="${bar}○"; done
    echo "${G}[${bar}]${NC}"
}

# ── First-Run Installer (unchanged) ───────────────────────────────────────────
run_installer() {
    clear; echo
    echo -e "  ${O}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${O}║${C}            TDZ NETWORK CONTROL - INSTALLER               ${O}║${NC}"
    echo -e "  ${O}║${DG}     DEVELOPED BY: YEASINUL HOQUE TUHIN ● @TUHINBROH      ${O}║${NC}"
    echo -e "  ${O}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    
    (
        local REPO_URL="https://raw.githubusercontent.com/yeasinulhoquetuhin/VPS-SPEED-LIMIT-MANAGER/refs/heads/master/clp.sh"
        curl -s --max-time 5 "$REPO_URL" > /dev/null
        sleep 0.5
    ) & spin $! "FETCHING LATEST VERSION DATA"
    
    (sleep 0.4) & spin $! "VERIFYING SYSTEM COMPATIBILITY"
    
    echo -e "  ${DG}────────────────────────────────────────────────────────────${NC}"
    echo
    if [[ -f "$INSTALL_FLAG" ]]; then
        center "${Y}♻️  REINSTALLING VERSION: ${VERSION}... ${NC}"
    else
        center "${Y}♻️  INSTALLING VERSION: ${VERSION}... ${NC}"
    fi
    echo
    echo -e "  ${DG}────────────────────────────────────────────────────────────${NC}"

    (
        if [[ "$SCRIPT_PATH" != "$CLP_BIN" ]]; then
            printf '#!/bin/bash\nsudo bash "%s" "$@"\n' "$SCRIPT_PATH" | sudo tee "$CLP_BIN" "/usr/local/bin/CLP" "/usr/local/bin/Clp" "/usr/local/bin/cLp" >/dev/null 2>&1
            sudo chmod +x "$CLP_BIN" "/usr/local/bin/CLP" "/usr/local/bin/Clp" "/usr/local/bin/cLp" >/dev/null 2>&1
        fi
    ) & spin $! "CREATING GLOBAL 'CLP' SHORTCUTS"
    
    (if [ -f "$HOME/.bashrc" ]; then sed -i '/alias clp=/d; /alias CLP=/d; /alias Clp=/d; /alias cLp=/d' "$HOME/.bashrc" 2>/dev/null; echo -e "alias clp='sudo bash $SCRIPT_PATH'\nalias CLP='sudo bash $SCRIPT_PATH'\nalias Clp='sudo bash $SCRIPT_PATH'\nalias cLp='sudo bash $SCRIPT_PATH'" >> "$HOME/.bashrc"; fi) & spin $! "CONFIGURING ~/.BASHRC ALIASES"
    
    (touch "$INSTALL_FLAG") & spin $! "PREPARING LOCAL ENVIRONMENT"
    (sudo apt-get update -y >/dev/null 2>&1) & spin $! "UPDATING SYSTEM REPOSITORIES"
    (sudo apt-get install -y ethtool iproute2 sqlite3 psmisc iptables vnstat jq >/dev/null 2>&1) & spin $! "INSTALLING CORE DEPENDENCIES"
    (sudo modprobe ifb numifbs=1 >/dev/null 2>&1) & spin $! "LOADING NETWORK KERNEL MODULES"
    ([ ! -f "$RULES_FILE" ] && echo "#!/bin/bash" > "$RULES_FILE" && chmod +x "$RULES_FILE" >/dev/null 2>&1) & spin $! "INITIALIZING PERSISTENCE DATA"
    ([ ! -f "$DB_FILE" ] && touch "$DB_FILE") & spin $! "CREATING RULES DATABASE"

    echo -e "  ${DG}────────────────────────────────────────────────────────────${NC}"
    echo; center "${G}✔  SYSTEM READY! CLP INSTALLED SUCCESSFULLY.${NC}"; echo
    center "${DG}YOU CAN NOW LAUNCH DASHBOARD ANYTIME WITH:${NC}"; center "${C}RUN: CLP${NC}"
    echo; hline "━" "$M"; echo; printf "  ${DG}PRESS ENTER TO LAUNCH DASHBOARD...${NC}"; read -r
}

if [ ! -x "$CLP_BIN" ]; then run_installer; fi

# ── System Data Fetcher (unchanged) ──────────────────────────────────────────
check_system() {
    if [[ -s "$DB_FILE" ]]; then
        local RULE_COUNT=$(wc -l < "$DB_FILE")
        UP_ST_RAW="ACTIVE RULES"; UP_SP_RAW="${RULE_COUNT} RULES SET"; UP_LAT_RAW="SEE MGR"; UP_C="$Y"
        DL_ST_RAW="ACTIVE RULES"; DL_SP_RAW="${RULE_COUNT} RULES SET"; DL_LAT_RAW="SEE MGR"; DL_C="$Y"
    else
        UP_ST_RAW="DEFAULT"; UP_SP_RAW="MAX SPEED"; UP_LAT_RAW="DEFAULT"; UP_C="$G"
        DL_ST_RAW="DEFAULT"; DL_SP_RAW="MAX SPEED"; DL_LAT_RAW="DEFAULT"; DL_C="$G"
    fi

    ethtool -k "$INTERFACE" 2>/dev/null | grep -q "generic-receive-offload: on" \
        && { GRO_RAW="GRO ON"; GRO_C="$R"; } || { GRO_RAW="OPTIMIZED"; GRO_C="$G"; }
    lsmod | grep -q "ifb" && { IFB_RAW="ACTIVE"; IFB_C="$G"; } || { IFB_RAW="OFFLINE"; IFB_C="$R"; }

    if crontab -l 2>/dev/null | grep -q "\.tdz_crontab\.sh"; then
        REB_RAW="ON"; REB_C="$G"
    else
        REB_RAW="OFF"; REB_C="$Y"
    fi

    INTERFACE_UP=$(echo "$INTERFACE" | tr '[:lower:]' '[:upper:]')
    
    if interface_exists "$INTERFACE"; then
        LOCAL_IP=$(ip -4 addr show "$INTERFACE" 2>/dev/null | grep -oP '(?<=inet )\S+' | head -1)
        [ -z "$LOCAL_IP" ] && LOCAL_IP="N/A"
        if ip link show "$INTERFACE" 2>/dev/null | grep -q -w "UP"; then
            STATE="ACTIVE"
        else
            STATE="DOWN"
        fi
    else
        LOCAL_IP="N/A"
        STATE="MISSING"
    fi
    INTERFACE_DISP="${INTERFACE_UP} (${STATE})"

    PUB_IP=$(curl -4 -s --max-time 3 ifconfig.me 2>/dev/null || echo "N/A")
    CONNS=$(ss -ntu state established 2>/dev/null | awk 'NR>1' | wc -l)
    OS_SYS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d '"' -f 2 | sed 's/ GNU\/Linux//i' | cut -c 1-38 | tr '[:lower:]' '[:upper:]' || echo "LINUX")
    CPU_MOD=$(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null | xargs | cut -c 1-30 | tr '[:lower:]' '[:upper:]')
    [ -z "$CPU_MOD" ] && CPU_MOD="UNKNOWN CPU"
    
    CPU_COR=$(nproc 2>/dev/null || echo "1")
    [ "$CPU_COR" -eq 1 ] && CPU_CORES_TXT="1 CORE" || CPU_CORES_TXT="${CPU_COR} CORES"
    
    RAM_USG=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 " / " $2}' | tr '[:lower:]' '[:upper:]')
    RAM_PCT=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100}')
    DISK_USG=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " / " $2}' | tr '[:lower:]' '[:upper:]')
    DISK_PCT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    CPU_PCT=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1 2>/dev/null)
    [ -z "$CPU_PCT" ] && CPU_PCT=0
}

# ── Dashboard UI (unchanged) ──────────────────────────────────────────────────
draw_dashboard() {
    clear; echo
    echo -e "  ${O}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${O}║${G}      .::::. TDZ NETWORK SPEED LIMIT MANAGER .::::.       ${O}║${NC}"
    echo -e "  ${O}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "$B_TOP"
    row "${G}SERVER & SYSTEM INFO${NC}"
    echo -e "$B_MID"
    row "${W}SYSTEM    : ${C}${OS_SYS}${NC}"
    row "${W}CPU MODEL : ${C}${CPU_MOD}${NC}"
    row "${W}CPU CORES : ${C}${CPU_CORES_TXT}${NC}"
    row "${W}INTERFACE : ${C}${INTERFACE_DISP}${NC}"
    row "${W}LOCAL IP  : ${C}${LOCAL_IP}${NC}"
    row "${W}PUBLIC IP : ${C}${PUB_IP}${NC}"
    echo -e "$B_BOT"

    printf -v CPU_PCT_PADDED "%3s" "$CPU_PCT"
    printf -v RAM_PCT_PADDED "%3s" "$RAM_PCT"
    printf -v DISK_PCT_PADDED "%3s" "$DISK_PCT"

    echo -e "$B_TOP"
    row "${G}PERFORMANCE INFO${NC}"
    echo -e "$B_MID"
    row "${W}CPU       : $(get_bar $CPU_PCT)  ${Y}${CPU_PCT_PADDED}%  ${M}(${CPU_CORES_TXT})${NC}"
    row "${W}RAM       : $(get_bar $RAM_PCT)  ${Y}${RAM_PCT_PADDED}%  ${M}(${RAM_USG})${NC}"
    row "${W}DISK      : $(get_bar $DISK_PCT)  ${Y}${DISK_PCT_PADDED}%  ${M}(${DISK_USG})${NC}"
    echo -e "$B_BOT"

    echo -e "$B_TOP"
    row "${G}BANDWIDTH LIMIT & STATUS${NC}"
    echo -e "$B_MID_T_DN"
    row2 "${C}▼ DOWNLOAD${NC}" "${C}▲ UPLOAD${NC}"
    echo -e "$B_MID_CRS"
    row2 "${W}STATUS : ${DL_C}${DL_ST_RAW}${NC}" "${W}STATUS : ${UP_C}${UP_ST_RAW}${NC}"
    row2 "${W}SPEED  : ${DL_C}${DL_SP_RAW}${NC}" "${W}SPEED  : ${UP_C}${UP_SP_RAW}${NC}"
    row2 "${W}PING   : ${DL_C}${DL_LAT_RAW}${NC}" "${W}PING   : ${UP_C}${UP_LAT_RAW}${NC}"
    echo -e "$B_BOT_CRS"

    echo -e "$B_TOP"
    row "${G}HARDWARE STATUS${NC}"
    echo -e "$B_MID_T_DN"
    row2 "${W}GRO/TSO   : ${GRO_C}${GRO_RAW}${NC}" "${W}IFB CORE : ${IFB_C}${IFB_RAW}${NC}"
    row2 "${W}AUTO START: ${REB_C}${REB_RAW}${NC}" "${W}CONNECTS : ${G}${CONNS} ACTIVE${NC}"
    echo -e "$B_BOT_CRS"

    echo -e "$B_TOP"
    row "${G}CONTROL PANEL${NC}"
    echo -e "$B_MID_T_DN"
    row2 "${G}[1]${NC} SPEED LIMIT MGR"   "${G}[6]${NC} HARDWARE OPTIMIZE"
    row2 "${G}[2]${NC} FIREWALL MANAGER"  "${G}[7]${NC} RESTART ON REBOOT"
    row2 "${G}[3]${NC} CONNECTION MGR"    "${G}[8]${NC} CHANGE INTERFACE"
    row2 "${G}[4]${NC} LIVE BANDWIDTH"    "${G}[9]${NC} BACKUP & EXPORT"
    row2 "${G}[5]${NC} PING & SPEEDTEST"  "${G}[0]${NC} SCRIPT MANAGEMENT"
    echo -e "$B_BOT_CRS"
    
    echo -e "    ${Y}[X] EXIT${NC}"
    echo; echo -e -n "  ${G}▶${NC} ${W}SELECT OPTION${NC} ${DG}[0-9/X]${NC} ${C}›${NC} "
}

# ── Dynamic DB Rules Builder (unchanged) ──────────────────────────────────────
rebuild_tc_rules() {
    cat <<EOF > "$RULES_FILE"
#!/bin/bash
/sbin/modprobe ifb numifbs=1
/sbin/ip link set dev ifb0 up
/sbin/ethtool -K $INTERFACE gro off lro off tso off gso off 2>/dev/null
/sbin/tc qdisc del dev $INTERFACE root 2>/dev/null
/sbin/tc qdisc del dev $INTERFACE ingress 2>/dev/null
/sbin/tc qdisc del dev ifb0 root 2>/dev/null
/sbin/tc qdisc add dev $INTERFACE root handle 1: htb default 9999
/sbin/tc class add dev $INTERFACE parent 1: classid 1:9999 htb rate 10000mbit 2>/dev/null
/sbin/tc qdisc add dev $INTERFACE handle ffff: ingress
/sbin/tc filter add dev $INTERFACE parent ffff: protocol ip u32 match ip src 0.0.0.0/0 action mirred egress redirect dev ifb0
/sbin/tc qdisc add dev ifb0 root handle 1: htb default 9999
/sbin/tc class add dev ifb0 parent 1: classid 1:9999 htb rate 10000mbit 2>/dev/null
EOF

    if [[ -f "$DB_FILE" ]]; then
        local class_id=10
        while IFS='|' read -r type target dl up dl_ping up_ping; do
            [[ -z "$type" ]] && continue
            
            if [[ "$type" == "GLOBAL" ]]; then
                [[ "$up" -gt 0 ]] && { echo "/sbin/tc class change dev $INTERFACE parent 1: classid 1:9999 htb rate ${up}mbit" >> "$RULES_FILE"; echo "/sbin/tc qdisc add dev $INTERFACE parent 1:9999 handle 9999: netem delay ${up_ping}ms 2>/dev/null" >> "$RULES_FILE"; }
                [[ "$dl" -gt 0 ]] && { echo "/sbin/tc class change dev ifb0 parent 1: classid 1:9999 htb rate ${dl}mbit" >> "$RULES_FILE"; echo "/sbin/tc qdisc add dev ifb0 parent 1:9999 handle 9999: netem delay ${dl_ping}ms 2>/dev/null" >> "$RULES_FILE"; }
            elif [[ "$type" == "IP" || "$type" == "PORT" ]]; then
                local f_up="" f_dl=""
                [[ "$type" == "IP" ]] && { f_up="match ip src $target"; f_dl="match ip dst $target"; }
                [[ "$type" == "PORT" ]] && { f_up="match ip sport $target 0xffff"; f_dl="match ip dport $target 0xffff"; }
                if [[ "$up" -gt 0 ]]; then
                    echo "/sbin/tc class add dev $INTERFACE parent 1: classid 1:${class_id} htb rate ${up}mbit" >> "$RULES_FILE"
                    echo "/sbin/tc qdisc add dev $INTERFACE parent 1:${class_id} handle ${class_id}: netem delay ${up_ping}ms" >> "$RULES_FILE"
                    echo "/sbin/tc filter add dev $INTERFACE protocol ip parent 1:0 prio 1 u32 $f_up flowid 1:${class_id}" >> "$RULES_FILE"
                fi
                if [[ "$dl" -gt 0 ]]; then
                    echo "/sbin/tc class add dev ifb0 parent 1: classid 1:${class_id} htb rate ${dl}mbit" >> "$RULES_FILE"
                    echo "/sbin/tc qdisc add dev ifb0 parent 1:${class_id} handle ${class_id}: netem delay ${dl_ping}ms" >> "$RULES_FILE"
                    echo "/sbin/tc filter add dev ifb0 protocol ip parent 1:0 prio 1 u32 $f_dl flowid 1:${class_id}" >> "$RULES_FILE"
                fi
            elif [[ "$type" == "ANTI_SHARE" ]]; then
                echo "/sbin/iptables -D INPUT -p tcp --dport $target -m connlimit --connlimit-above $dl --connlimit-mask 0 -j REJECT 2>/dev/null" >> "$RULES_FILE"
                echo "/sbin/iptables -I INPUT -p tcp --dport $target -m connlimit --connlimit-above $dl --connlimit-mask 0 -j REJECT" >> "$RULES_FILE"
            elif [[ "$type" == "BLOCK_IP" ]]; then
                echo "/sbin/iptables -D INPUT -s $target -j DROP 2>/dev/null" >> "$RULES_FILE"
                echo "/sbin/iptables -I INPUT -s $target -j DROP" >> "$RULES_FILE"
            elif [[ "$type" == "BLOCK_PORT" ]]; then
                echo "/sbin/iptables -D INPUT -p tcp --dport $target -j DROP 2>/dev/null" >> "$RULES_FILE"
                echo "/sbin/iptables -I INPUT -p tcp --dport $target -j DROP" >> "$RULES_FILE"
            fi
            ((class_id++))
        done < "$DB_FILE"
    fi

    chmod +x "$RULES_FILE"
    (sudo bash "$RULES_FILE" >/dev/null 2>&1) & spin $! "APPLYING NEW NETWORK RULES TO KERNEL"
}

# ── 1. Speed Limit Manager (unchanged) ───────────────────────────────────────
speed_limit_manager() {
    while true; do
        clear; hline; center "${C}💠 SPEED LIMIT MANAGER ${NC}"; hline; echo
        echo -e "  ${G}[1]${NC} ADD NEW LIMIT"
        echo -e "  ${G}[2]${NC} TCP LIMIT ON PORT"
        echo -e "  ${G}[3]${NC} UNLIMIT BANDWIDTH"
        echo -e "  ${G}[4]${NC} VIEW ACTIVE LIMITS"
        echo -e "  ${G}[5]${NC} RESET ALL LIMITS"
        echo -e "  ${DG}[0]${NC} BACK TO MAIN MENU"
        echo -e -n "\n  ${G}▶${NC} SELECT OPTION ${DG}[0-5]${NC} ${C}›${NC} "
        read -r sl_choice
        [[ -z "$sl_choice" ]] && continue
        case "$sl_choice" in
            1) add_new_limit ;;
            2) anti_share_manager ;;
            3) remove_specific_limit ;;
            4) view_limits ;;
            5) remove_all ;;
            0) return ;;
            *) sleep 1 ;;
        esac
    done
}

add_new_limit() {
    clear; hline; center "${C}➕ ADD NEW BANDWIDTH LIMIT ${NC}"; hline; echo
    echo -e "  ${Y}SELECT TARGET TYPE:${NC}"
    echo -e "  ${G}[1]${NC} GLOBAL SERVER LIMIT"
    echo -e "  ${G}[2]${NC} SPECIFIC IP LIMIT"
    echo -e "  ${G}[3]${NC} SPECIFIC PORT LIMIT"
    echo -e "  ${DG}[0]${NC} BACK"
    echo -e -n "\n  ${G}▶${NC} SELECT ${DG}[0-3]${NC} ${C}›${NC} "
    read -r limit_type
    [[ -z "$limit_type" ]] && continue

    [[ "$limit_type" == "0" ]] && return
    local CMD_TYPE="GLOBAL"; local TARGET_VAL="ALL"

    if [[ "$limit_type" == "2" ]]; then
        echo -e -n "\n  ${C}ENTER TARGET IP ADDRESS:${NC} "; read -r TARGET_VAL
        [[ -z "$TARGET_VAL" ]] && return; CMD_TYPE="IP"
    elif [[ "$limit_type" == "3" ]]; then
        echo -e -n "\n  ${C}ENTER TARGET PORT (e.g. 443):${NC} "; read -r TARGET_VAL
        [[ -z "$TARGET_VAL" ]] && return; CMD_TYPE="PORT"
    elif [[ "$limit_type" != "1" ]]; then return; fi

    echo -e -n "\n  ${G}📥 TARGET DOWNLOAD (MBPS) [0 TO SKIP]${NC} ${C}›${NC} "; read -r DL_INP
    DL_INP=${DL_INP:-0}; local DL_LAT_INP=0
    if [[ "$DL_INP" =~ ^[0-9]+$ ]] && [[ "$DL_INP" -gt 0 ]]; then
        echo -e -n "     ${B}⏱  DOWNLOAD PING (MS) [DEFAULT 1]${NC}   ${C}›${NC} "; read -r DL_LAT_INP
        DL_LAT_INP=${DL_LAT_INP:-1}
    fi

    echo -e -n "\n  ${M}📤 TARGET UPLOAD   (MBPS) [0 TO SKIP]${NC} ${C}›${NC} "; read -r UP_INP
    UP_INP=${UP_INP:-0}; local UP_LAT_INP=0
    if [[ "$UP_INP" =~ ^[0-9]+$ ]] && [[ "$UP_INP" -gt 0 ]]; then
        echo -e -n "     ${B}⏱  UPLOAD PING (MS)   [DEFAULT 1]${NC}   ${C}›${NC} "; read -r UP_LAT_INP
        UP_LAT_INP=${UP_LAT_INP:-1}
    fi

    [[ "$DL_INP" -eq 0 && "$UP_INP" -eq 0 ]] && { echo -e "\n  ${R}✘ NO LIMITS SPECIFIED.${NC}"; sleep 1; return; }
    confirm "SAVE AND APPLY THESE RULES?" || return; echo

    touch "$DB_FILE" 2>/dev/null
    sed -i "/^${CMD_TYPE}|${TARGET_VAL}|/d" "$DB_FILE" 2>/dev/null
    (echo "${CMD_TYPE}|${TARGET_VAL}|${DL_INP}|${UP_INP}|${DL_LAT_INP}|${UP_LAT_INP}" >> "$DB_FILE") & spin $! "SAVING CONFIGURATION TO DATABASE"
    rebuild_tc_rules
    echo -e "\n  ${G}✔ LIMITS APPLIED SUCCESSFULLY!${NC}"; echo -e -n "\n  ${DG}PRESS ENTER...${NC}"; read -r
}

# ── TCP LIMIT ON PORT (unchanged) ──
anti_share_manager() {
    while true; do
        clear; hline; center "${R}🛑 TCP LIMIT ON PORT ${NC}"; hline; echo
        echo -e "  ${G}[1]${NC} SET MAX CONNECTIONS"
        echo -e "  ${G}[2]${NC} REMOVE TCP CONNECTIONS"
        echo -e "  ${DG}[0]${NC} GO BACK"
        echo -e -n "\n  ${G}▶${NC} SELECT OPTION ${DG}[0-2]${NC} ${C}›${NC} "
        read -r as_choice
        [[ -z "$as_choice" ]] && continue

        case "$as_choice" in
            1)
                echo -e -n "\n  ${C}ENTER TARGET PORT (e.g. 443):${NC} "
                read -r P_TGT; [[ -z "$P_TGT" ]] && continue
                if [[ "$P_TGT" == "22" ]]; then
                    echo -e "\n  ${R}⚠  PORT 22 IS SSH – BLOCKING IT WOULD LOCK YOU OUT!${NC}"
                    echo -e "  ${DG}OPERATION CANCELLED.${NC}"
                    sleep 2
                    continue
                fi

                echo -e -n "  ${G}MAX CONCURRENT CONNECTIONS ALLOWED (e.g. 30):${NC} "
                read -r MAX_CONN
                [[ -z "$MAX_CONN" || ! "$MAX_CONN" =~ ^[0-9]+$ ]] && continue

                confirm "RESTRICT PORT $P_TGT TO MAX $MAX_CONN CONNECTIONS?" || continue; echo
                
                local OLD_LIMIT=$(grep "^ANTI_SHARE|${P_TGT}|" "$DB_FILE" | cut -d'|' -f3 | head -1)
                if [[ -n "$OLD_LIMIT" ]]; then
                    (while sudo iptables -D INPUT -p tcp --dport "$P_TGT" -m connlimit --connlimit-above "$OLD_LIMIT" --connlimit-mask 0 -j REJECT 2>/dev/null; do :; done) & spin $! "CLEARING PREVIOUS TCP LIMITS FOR PORT $P_TGT"
                fi

                touch "$DB_FILE" 2>/dev/null
                sed -i "/^ANTI_SHARE|${P_TGT}|/d" "$DB_FILE" 2>/dev/null
                (echo "ANTI_SHARE|${P_TGT}|${MAX_CONN}|0|0|0" >> "$DB_FILE") & spin $! "SAVING NEW TCP LIMIT TO DATABASE"
                rebuild_tc_rules
                echo -e "\n  ${G}✔ ANTI-SHARE PROTECTION ENABLED!${NC}"; echo -e -n "\n  ${DG}PRESS ENTER...${NC}"; read -r
                ;;
            2)
                echo -e -n "\n  ${C}ENTER TARGET PORT TO UNLIMIT (e.g. 443):${NC} "
                read -r P_TGT; [[ -z "$P_TGT" ]] && continue
                confirm "REMOVE TCP LIMIT FOR PORT $P_TGT?" || continue; echo

                local OLD_LIMIT=$(grep "^ANTI_SHARE|${P_TGT}|" "$DB_FILE" | cut -d'|' -f3 | head -1)
                if [[ -n "$OLD_LIMIT" ]]; then
                    (while sudo iptables -D INPUT -p tcp --dport "$P_TGT" -m connlimit --connlimit-above "$OLD_LIMIT" --connlimit-mask 0 -j REJECT 2>/dev/null; do :; done) & spin $! "REMOVING TCP BLOCK RULES FROM FIREWALL"
                else
                    (sleep 0.5) & spin $! "CHECKING FIREWALL INTEGRITY"
                fi

                (sed -i "/^ANTI_SHARE|${P_TGT}|/d" "$DB_FILE" 2>/dev/null) & spin $! "DELETING ENTRY FROM DATABASE"
                rebuild_tc_rules
                echo -e "\n  ${G}✔ TCP LIMIT FOR PORT $P_TGT REMOVED SUCCESSFULLY!${NC}"; echo -e -n "\n  ${DG}PRESS ENTER...${NC}"; read -r
                ;;
            0)
                return
                ;;
        esac
    done
}

# ── UNLIMIT BANDWIDTH (unchanged) ──
remove_specific_limit() {
    clear; hline; center "${C}🔓 UNLIMIT BANDWIDTH (IP/PORT/GLOBAL) ${NC}"; hline; echo
    echo -e "  ${Y}WHAT DO YOU WANT TO UNLIMIT?${NC}"
    echo -e "  ${G}[1]${NC} GLOBAL SERVER LIMIT"
    echo -e "  ${G}[2]${NC} SPECIFIC IP LIMIT"
    echo -e "  ${G}[3]${NC} SPECIFIC PORT LIMIT"
    echo -e "  ${DG}[0]${NC} BACK"
    echo -e -n "\n  ${G}▶${NC} SELECT OPTION ${DG}[0-3]${NC} ${C}›${NC} "
    read -r unl_choice
    [[ -z "$unl_choice" ]] && continue

    [[ "$unl_choice" == "0" ]] && return
    local CMD_TYPE="GLOBAL"; local TARGET_VAL="ALL"

    if [[ "$unl_choice" == "2" ]]; then
        echo -e -n "\n  ${C}ENTER EXACT IP ADDRESS TO UNLIMIT:${NC} "
        read -r TARGET_VAL; [[ -z "$TARGET_VAL" ]] && return; CMD_TYPE="IP"
    elif [[ "$unl_choice" == "3" ]]; then
        echo -e -n "\n  ${C}ENTER EXACT PORT TO UNLIMIT (e.g. 443):${NC} "
        read -r TARGET_VAL; [[ -z "$TARGET_VAL" ]] && return; CMD_TYPE="PORT"
        if [[ "$TARGET_VAL" == "22" ]]; then
            echo -e "\n  ${R}⚠  PORT 22 IS SSH – LIMIT REMOVAL NOT NEEDED.${NC}"
            sleep 1
            return
        fi
    elif [[ "$unl_choice" != "1" ]]; then return; fi

    confirm "REMOVE BANDWIDTH LIMITS FOR $TARGET_VAL?" || return; echo

    (sleep 0.5) & spin $! "LOCATING TARGET IN SYSTEM"
    (sed -i "/^${CMD_TYPE}|${TARGET_VAL}|/d" "$DB_FILE" 2>/dev/null) & spin $! "DELETING RULES FROM DATABASE"
    (sleep 0.5) & spin $! "RESTORING DEFAULT CONFIGURATION"
    rebuild_tc_rules
    echo -e "\n  ${G}✔ BANDWIDTH LIMIT FOR $TARGET_VAL REMOVED SUCCESSFULLY!${NC}"; echo -e -n "\n  ${DG}PRESS ENTER...${NC}"; read -r
}

view_limits() {
    clear; hline; center "${C}🗄️ ACTIVE LIMITS DATABASE ${NC}"; hline; echo
    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "  ${Y}⚠ NO ACTIVE RULES FOUND IN DATABASE.${NC}"
    else
        echo -e "  ${C}TYPE         TARGET            DL(MB)  UP(MB)  EXTRA${NC}"
        hline "─" "$DG"
        while IFS='|' read -r type target dl up dl_ping up_ping; do
            [[ -z "$type" ]] && continue
            if [[ "$type" == "ANTI_SHARE" ]]; then
                printf "  ${R}%-12s${NC} ${W}PORT %-12s${NC} ${Y}MAX %s CONNS${NC}\n" "$type" "$target" "$dl"
            elif [[ "$type" == "BLOCK_PORT" || "$type" == "BLOCK_IP" ]]; then
                printf "  ${R}%-12s${NC} ${W}%-17s${NC} ${R}BLOCKED / DROPPED${NC}\n" "$type" "$target"
            else
                printf "  ${G}%-12s${NC} ${W}%-17s${NC} ${Y}%-7s${NC} ${M}%-7s${NC} ${DG}PING: %s/%s${NC}\n" "$type" "$target" "$dl" "$up" "$dl_ping" "$up_ping"
            fi
        done < "$DB_FILE"
    fi
    echo -e -n "\n  ${DG}PRESS ENTER TO RETURN...${NC}"; read -r
}

remove_all() {
    confirm "REMOVE ALL LIMITS & FIREWALL RULES?" || return; echo
    (sleep 0.5) & spin $! "INITIATING GLOBAL RESET"
    if [[ -f "$DB_FILE" ]]; then
        while IFS='|' read -r type target dl x y z; do
            [[ "$type" == "ANTI_SHARE" ]] && while sudo iptables -D INPUT -p tcp --dport "$target" -m connlimit --connlimit-above "$dl" --connlimit-mask 0 -j REJECT 2>/dev/null; do :; done
            [[ "$type" == "BLOCK_IP" ]] && while sudo iptables -D INPUT -s "$target" -j DROP 2>/dev/null; do :; done
            [[ "$type" == "BLOCK_PORT" ]] && while sudo iptables -D INPUT -p tcp --dport "$target" -j DROP 2>/dev/null; do :; done
        done < "$DB_FILE"
    fi
    ( rm -f "$DB_FILE" ) & spin $! "WIPING ALL ENTRIES FROM DATABASE"
    (sudo tc qdisc del dev "$INTERFACE" root >/dev/null 2>&1) & spin $! "FLUSHING UPLOAD TRAFFIC RULES"
    (sudo tc qdisc del dev "$INTERFACE" ingress >/dev/null 2>&1) & spin $! "REMOVING INGRESS REDIRECTS"
    (sudo tc qdisc del dev ifb0 root >/dev/null 2>&1) & spin $! "FLUSHING DOWNLOAD TRAFFIC RULES"
    (sudo ethtool -K "$INTERFACE" gro on lro on tso on gso on >/dev/null 2>&1) & spin $! "RESTORING HARDWARE DEFAULTS"
    echo "#!/bin/bash" > "$RULES_FILE"
    echo -e "\n  ${G}✔ DATABASE CLEARED & SERVER RESTORED!${NC}"; echo -e -n "\n  ${DG}PRESS ENTER...${NC}"; read -r
}

# ── 2. Firewall Manager (unchanged) ──────────────────────────────────────────
firewall_manager() {
    while true; do
        clear; hline; center "${C}🛡️ FIREWALL MANAGER ${NC}"; hline; echo
        echo -e "  ${G}[1]${NC} BLOCK AN IP ADDRESS"
        echo -e "  ${G}[2]${NC} BLOCK A PORT"
        echo -e "  ${G}[3]${NC} UNBLOCK IP / PORT"
        echo -e "  ${DG}[0]${NC} BACK TO MAIN MENU"
        echo -e -n "\n  ${G}▶${NC} SELECT OPTION ${DG}[0-3]${NC} ${C}›${NC} "
        read -r fw_choice
        [[ -z "$fw_choice" ]] && continue
        case "$fw_choice" in
            1) block_ip_port "BLOCK_IP" ;;
            2) block_ip_port "BLOCK_PORT" ;;
            3) unblock_rule ;;
            0) return ;;
            *) sleep 1 ;;
        esac
    done
}

block_ip_port() {
    local B_TYPE="$1"
    echo -e -n "\n  ${C}ENTER TARGET TO BLOCK (${B_TYPE}):${NC} "
    read -r B_TGT; [[ -z "$B_TGT" ]] && return
    if [[ "$B_TYPE" == "BLOCK_PORT" && "$B_TGT" == "22" ]]; then
        echo -e "\n  ${R}⚠  PORT 22 IS SSH – BLOCKING IT WOULD LOCK YOU OUT!${NC}"
        echo -e "  ${DG}OPERATION CANCELLED.${NC}"
        sleep 2
        return
    fi
    confirm "ADD FIREWALL RULE TO BLOCK $B_TGT?" || return; echo
    touch "$DB_FILE" 2>/dev/null
    sed -i "/^${B_TYPE}|${B_TGT}|/d" "$DB_FILE" 2>/dev/null
    (echo "${B_TYPE}|${B_TGT}|0|0|0|0" >> "$DB_FILE") & spin $! "SAVING CONFIGURATION TO DATABASE"
    rebuild_tc_rules
    echo -e "\n  ${G}✔ BLOCK APPLIED SUCCESSFULLY!${NC}"; echo -e -n "\n  ${DG}PRESS ENTER...${NC}"; read -r
}

unblock_rule() {
    clear; hline; center "${C}🔓 UNBLOCK IP / PORT ${NC}"; hline; echo
    echo -e "  ${Y}WHAT DO YOU WANT TO UNBLOCK?${NC}"
    echo -e "  ${G}[1]${NC} UNBLOCK IP ADDRESS"
    echo -e "  ${G}[2]${NC} UNBLOCK PORT"
    echo -e "  ${DG}[0]${NC} BACK"
    echo -e -n "\n  ${G}▶${NC} SELECT OPTION ${DG}[0-2]${NC} ${C}›${NC} "
    read -r unb_choice
    [[ -z "$unb_choice" ]] && continue
    
    local U_TGT=""
    if [[ "$unb_choice" == "1" ]]; then
        echo -e -n "\n  ${C}ENTER EXACT IP TO UNBLOCK:${NC} "
        read -r U_TGT; [[ -z "$U_TGT" ]] && return
        confirm "UNBLOCK IP $U_TGT?" || return; echo
        (while sudo iptables -D INPUT -s "$U_TGT" -j DROP 2>/dev/null; do :; done) & spin $! "REMOVING IP BLOCK FROM FIREWALL"
        (sed -i "/^BLOCK_IP|${U_TGT}|/d" "$DB_FILE" 2>/dev/null) & spin $! "REMOVING ENTRY FROM DATABASE"
    elif [[ "$unb_choice" == "2" ]]; then
        echo -e -n "\n  ${C}ENTER EXACT PORT TO UNBLOCK:${NC} "
        read -r U_TGT; [[ -z "$U_TGT" ]] && return
        confirm "UNBLOCK PORT $U_TGT?" || return; echo
        (while sudo iptables -D INPUT -p tcp --dport "$U_TGT" -j DROP 2>/dev/null; do :; done) & spin $! "REMOVING PORT BLOCK FROM FIREWALL"
        (sed -i "/^BLOCK_PORT|${U_TGT}|/d" "$DB_FILE" 2>/dev/null) & spin $! "REMOVING ENTRY FROM DATABASE"
    else
        return
    fi
    
    rebuild_tc_rules
    echo -e "\n  ${G}✔ RULE REMOVED & UNBLOCKED SUCCESSFULLY!${NC}"; echo -e -n "\n  ${DG}PRESS ENTER...${NC}"; read -r
}

# ── 3. Connection Manager (unchanged) ────────────────────────────────────────
connection_manager() {
    while true; do
        clear; hline; center "${C}🔗 CONNECTION MANAGER ${NC}"; hline; echo
        echo -e "  ${G}[1]${NC} VIEW ACTIVE CONNECTIONS"
        echo -e "  ${G}[2]${NC} KILL CONNECTIONS ON PORT"
        echo -e "  ${DG}[0]${NC} BACK TO MAIN MENU"
        echo -e -n "\n  ${G}▶${NC} SELECT OPTION ${DG}[0-2]${NC} ${C}›${NC} "
        read -r cm_choice
        [[ -z "$cm_choice" ]] && continue
        case "$cm_choice" in
            1) view_connections ;;
            2) kill_connections ;;
            0) return ;;
            *) sleep 1 ;;
        esac
    done
}

view_connections() {
    clear; hline; center "${G}🟢 ACTIVE IP & PORT MAPPING${NC}"; hline
    echo -e "  ${C}LOCAL (SERVER) IP:PORT    REMOTE (CLIENT) IP:PORT${NC}"
    hline "─" "$DG"
    ss -ntH state established 2>/dev/null | sed 's/\[::ffff://g; s/\]//g' | awk '{printf "  %-25s %-25s\n", $(NF-1), $NF}' | head -20
    echo -e -n "\n  ${DG}PRESS ENTER TO RETURN...${NC}"; read -r
}

kill_connections() {
    echo -e -n "\n  ${R}⚠ ENTER PORT TO KILL (e.g. 443):${NC} "
    read -r k_port; [[ -z "$k_port" ]] && return
    if [[ "$k_port" == "22" ]]; then
        echo -e "\n  ${R}⚠  PORT 22 IS SSH – KILLING CONNECTIONS MAY LOCK YOU OUT!${NC}"
        confirm "ARE YOU ABSOLUTELY SURE?" || return
    fi
    confirm "KILL ALL USERS CONNECTED TO PORT $k_port?" || return; echo
    if ! command -v fuser &>/dev/null; then
        (sudo apt-get install psmisc -y >/dev/null 2>&1) & spin $! "INSTALLING DEPENDENCIES"
    fi
    (sudo fuser -k "${k_port}/tcp" >/dev/null 2>&1; sudo fuser -k "${k_port}/udp" >/dev/null 2>&1) & spin $! "DROPPING ALL CONNECTIONS ON $k_port"
    echo -e "\n  ${G}✔ DONE! ALL CLIENTS DISCONNECTED.${NC}"; echo -e -n "\n  ${DG}PRESS ENTER...${NC}"; read -r
}

# ── 5. Ping & Speedtest Manager (unchanged) ───────────────────────────────────
ping_speedtest() {
    while true; do
        clear; hline; center "${C}⚡ PING & SPEEDTEST ${NC}"; hline; echo
        echo -e "  ${G}[1]${NC} RUN OOKLA SPEEDTEST"
        echo -e "  ${G}[2]${NC} PING LATENCY TEST"
        echo -e "  ${G}[3]${NC} IP INFORMATION"
        echo -e "  ${DG}[0]${NC} BACK TO MAIN MENU"
        echo -e -n "\n  ${G}▶${NC} SELECT OPTION ${DG}[0-3]${NC} ${C}›${NC} "
        read -r nd_choice
        [[ -z "$nd_choice" ]] && continue
        case "$nd_choice" in
            1) run_speedtest ;;
            2) ping_test ;;
            3) show_ip_info ;;
            0) return ;;
            *) sleep 1 ;;
        esac
    done
}

run_speedtest() {
    confirm "RUN OOKLA SPEEDTEST? (MAY CONSUME BANDWIDTH)" || return
    clear; hline; center "${C}⚡  OOKLA SPEEDTEST ${NC}"; hline; echo
    if ! command -v speedtest &>/dev/null; then
        echo -e "  ${C}SETTING UP OOKLA SPEEDTEST CLI...${NC}\n"
        (curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash >/dev/null 2>&1) & spin $! "CONFIGURING OOKLA REPOSITORY"
        (sudo apt-get install speedtest -y >/dev/null 2>&1) & spin $! "INSTALLING SPEEDTEST PACKAGES"
        echo -e "\n  ${G}✔ SPEEDTEST INSTALLED SUCCESSFULLY!${NC}\n"
    fi
    speedtest; echo -e -n "\n  ${DG}PRESS ENTER...${NC}"; read -r
}

ping_test() {
    clear; hline; center "${M}🔍  LATENCY PING TEST ${NC}"; hline; echo
    for host in "1.1.1.1 (Cloudflare)" "8.8.8.8 (Google DNS)" "google.com (Google Web)" "facebook.com (Facebook)" "speedtest.net (Ookla)" "github.com (GitHub)"; do
        ip=$(echo "$host" | awk '{print $1}')
        res=$(ping -c 3 -W 2 "$ip" 2>/dev/null | tail -1 | awk -F'/' '{printf "%.1f",$5}')
        if [[ -n "$res" ]]; then echo -e "  ${C}PING TO ${W}${host}${NC}  →  ${G}${res} MS${NC}"
        else echo -e "  ${C}PING TO ${W}${host}${NC}  →  ${R}TIMEOUT${NC}"; fi
    done
    echo -e -n "\n  ${DG}PRESS ENTER...${NC}"; read -r
}

show_ip_info() {
    clear; hline; center "${C}🌍 IP INFORMATION${NC}"; hline; echo
    if ! command -v jq &>/dev/null; then
        echo -e "  ${Y}⚠ jq not found. Installing...${NC}"
        sudo apt-get update -y >/dev/null 2>&1
        sudo apt-get install -y jq >/dev/null 2>&1
        echo
    fi
    (curl -s "http://ip-api.com/json") > /tmp/ipinfo.json 2>/dev/null & spin $! "FETCHING IP DATA"
    if [[ -s /tmp/ipinfo.json ]] && grep -q '"status":"success"' /tmp/ipinfo.json; then
        local IP=$(jq -r '.query' /tmp/ipinfo.json 2>/dev/null)
        local CONTINENT=$(jq -r '.continent' /tmp/ipinfo.json 2>/dev/null)
        local COUNTRY=$(jq -r '.country' /tmp/ipinfo.json 2>/dev/null)
        local COUNTRY_CODE=$(jq -r '.countryCode' /tmp/ipinfo.json 2>/dev/null)
        local CITY=$(jq -r '.city' /tmp/ipinfo.json 2>/dev/null)
        local ZIP=$(jq -r '.zip' /tmp/ipinfo.json 2>/dev/null)
        local TIMEZONE=$(jq -r '.timezone' /tmp/ipinfo.json 2>/dev/null)
        local ISP=$(jq -r '.isp' /tmp/ipinfo.json 2>/dev/null)
        local ORG=$(jq -r '.org' /tmp/ipinfo.json 2>/dev/null)
        local AS=$(jq -r '.as' /tmp/ipinfo.json 2>/dev/null)
        local ASNAME=$(jq -r '.asname' /tmp/ipinfo.json 2>/dev/null)
        local CURRENCY=$(jq -r '.currency' /tmp/ipinfo.json 2>/dev/null)
        local LAT=$(jq -r '.lat' /tmp/ipinfo.json 2>/dev/null)
        local LON=$(jq -r '.lon' /tmp/ipinfo.json 2>/dev/null)

        echo
        printf "  ${G}%-16s${NC} : ${W}%s${NC}\n" "Public IP" "$IP"
        [[ -n "$CONTINENT" && "$CONTINENT" != "null" ]] && printf "  ${G}%-16s${NC} : ${W}%s${NC}\n" "Continent" "$CONTINENT"
        printf "  ${G}%-16s${NC} : ${W}%s${NC}\n" "Country" "$COUNTRY ($COUNTRY_CODE)"
        printf "  ${G}%-16s${NC} : ${W}%s${NC}\n" "City" "$CITY"
        [[ -n "$ZIP" && "$ZIP" != "null" ]] && printf "  ${G}%-16s${NC} : ${W}%s${NC}\n" "ZIP" "$ZIP"
        [[ -n "$TIMEZONE" && "$TIMEZONE" != "null" ]] && printf "  ${G}%-16s${NC} : ${W}%s${NC}\n" "Timezone" "$TIMEZONE"
        printf "  ${G}%-16s${NC} : ${W}%s${NC}\n" "ISP" "$ISP"
        [[ -n "$ORG" && "$ORG" != "null" && "$ORG" != "$ISP" ]] && printf "  ${G}%-16s${NC} : ${W}%s${NC}\n" "Organization" "$ORG"
        [[ -n "$AS" && "$AS" != "null" ]] && printf "  ${G}%-16s${NC} : ${W}%s${NC}\n" "AS Number" "$AS"
        [[ -n "$ASNAME" && "$ASNAME" != "null" ]] && printf "  ${G}%-16s${NC} : ${W}%s${NC}\n" "AS Name" "$ASNAME"
        [[ -n "$CURRENCY" && "$CURRENCY" != "null" ]] && printf "  ${G}%-16s${NC} : ${W}%s${NC}\n" "Currency" "$CURRENCY"
        if [[ -n "$LAT" && "$LAT" != "null" && -n "$LON" && "$LON" != "null" ]]; then
            printf "  ${G}%-16s${NC} : ${W}%s, %s${NC}\n" "Coordinates" "$LAT" "$LON"
        fi
    else
        echo -e "\n  ${R}✘ Failed to fetch IP information. Please check your internet connection.${NC}"
    fi
    rm -f /tmp/ipinfo.json
    echo; hline; echo -e "  ${DG}PRESS ENTER TO RETURN...${NC}"; read -r
}

# ── 0. Script Manager (FIXED UPDATE) ──────────────────────────────────────────
script_manager() {
    while true; do
        clear; hline; center "${C}⚙️  SCRIPT MANAGER • VERSION: ${VERSION}${NC}"; hline; echo
        echo -e "  ${G}[1]${NC} UPDATE SCRIPT"
        echo -e "  ${G}[2]${NC} REINSTALL SCRIPT"
        echo -e "  ${G}[3]${NC} UNINSTALL SCRIPT"
        echo -e "  ${DG}[0]${NC} BACK TO MAIN MENU"
        echo -e -n "\n  ${G}▶${NC} SELECT OPTION ${DG}[0-3]${NC} ${C}›${NC} "
        read -r sm_choice
        [[ -z "$sm_choice" ]] && continue
        case "$sm_choice" in
            1) 
                clear
                echo -e "  ${C}┌──────────────────────────────────────────────────────────┐${NC}"
                center "${C}🔄 SCRIPT UPDATER ${NC}"
                echo -e "  ${C}└──────────────────────────────────────────────────────────┘${NC}"
                echo

                (sleep 0.5) & spin $! "CHECKING GITHUB FOR UPDATES"

                local REPO_URL="https://raw.githubusercontent.com/yeasinulhoquetuhin/VPS-SPEED-LIMIT-MANAGER/refs/heads/master/clp.sh"
                local REMOTE_RAW=$(curl -s --max-time 5 "$REPO_URL")
                local REMOTE_VERSION=$(echo "$REMOTE_RAW" | grep -m 1 '^VERSION=' | head -1 | tr -d '\r' | cut -d'"' -f2)

                if [[ -z "$REMOTE_VERSION" ]]; then
                    echo -e "\n  ${DG}------------------------------------------------------------${NC}"
                    echo -e "  ${R}✘ CRITICAL ERROR: COULD NOT DETECT VERSION IN GITHUB SCRIPT.${NC}"
                    echo -e "  ${Y}⚠ REASON: SCRIPT IS MISSING THE 'VERSION=' TAG AT THE TOP.${NC}"
                    echo -e "  ${DG}UPDATE ABORTED TO PREVENT SYSTEM CRASH.${NC}"
                    sleep 4
                    continue
                fi

                echo -e "\n  ${DG}------------------------------------------------------------${NC}"
                echo -e "  ${C}▶ CURRENT VERSION : ${W}${VERSION}${NC}"

                if [[ "$VERSION" == "$REMOTE_VERSION" ]]; then
                    echo -e "  ${C}▶ LATEST VERSION  : ${Y}${REMOTE_VERSION} ${DG}(UP TO DATE)${NC}"
                    echo -e "  ${DG}------------------------------------------------------------${NC}\n"
                    echo -e "  ${G}✔ YOU ALREADY HAVE THE LATEST VERSION!${NC}\n"
                    confirm "UPDATE ANYWAY? (DATA WILL BE SAFE)" || continue
                else
                    echo -e "  ${C}▶ LATEST VERSION  : ${Y}${REMOTE_VERSION} ${M}(UPDATE AVAILABLE)${NC}"
                    echo -e "  ${DG}------------------------------------------------------------${NC}\n"
                    echo -e "  ${G}✨ A NEW VERSION IS AVAILABLE!${NC}\n"
                    confirm "INSTALL LATEST VERSION? (DATA WILL BE SAFE)" || continue
                fi
                echo

                TEMP_SCRIPT="/tmp/tdz_update_$$.sh"
                BACKUP_SCRIPT="/tmp/tdz_backup_$$.sh"

                (echo "$REMOTE_RAW" > "$TEMP_SCRIPT") & spin $! "DOWNLOADING LATEST SCRIPT"
                sleep 0.3

                if [[ -s "$TEMP_SCRIPT" ]]; then
                    # Remove Windows line endings and ensure it's a valid bash script
                    (sed -i 's/\r$//' "$TEMP_SCRIPT" 2>/dev/null) & spin $! "FIXING LINE ENDINGS"
                    sleep 0.3
                    # Quick integrity check: must contain "TDZ NETWORK CONTROL"
                    if ! grep -q "TDZ NETWORK CONTROL" "$TEMP_SCRIPT"; then
                        echo -e "\n  ${R}✘ ERROR: DOWNLOADED SCRIPT IS CORRUPTED OR NOT VALID.${NC}"
                        rm -f "$TEMP_SCRIPT"
                        sleep 3
                        continue
                    fi
                    (sleep 0.3) & spin $! "VERIFYING INTEGRITY"
                else
                    echo -e "\n  ${R}✘ DOWNLOAD FAILED. CHECK CONNECTION.${NC}"
                    sleep 2
                    continue
                fi

                (cp "$SCRIPT_PATH" "$BACKUP_SCRIPT" 2>/dev/null) & spin $! "BACKING UP CURRENT CONFIGURATION"
                sleep 0.3
                (chmod +x "$TEMP_SCRIPT") & spin $! "PREPARING INSTALLATION"
                sleep 0.3
                # Overwrite the current script
                (cat "$TEMP_SCRIPT" > "$SCRIPT_PATH") & spin $! "INSTALLING UPDATE"
                sleep 0.3
                (rm -f "$TEMP_SCRIPT" "$BACKUP_SCRIPT" 2>/dev/null) & spin $! "CLEANING UP TEMPORARY FILES"

                echo -e "\n  ${G}✔ SCRIPT UPDATED SUCCESSFULLY!${NC}\n"
                echo -e "  ${DG}PLEASE RESTART THE DASHBOARD BY TYPING:${NC} ${C}clp${NC}\n"
                echo -e -n "  ${DG}PRESS ENTER TO EXIT...${NC}"
                read -r
                exit 0
                ;;
            2)
                echo
                echo -e "  ${Y}⚠  REINSTALL SCRIPT?${NC}"
                echo -e "  ${G}[1]${NC} KEEP EXISTING DATABASE"
                echo -e "  ${G}[2]${NC} CLEAR EXISTING DATABASE"
                echo -e "  ${DG}[0]${NC} CANCEL"
                echo
                echo -e -n "  ${C}SELECT OPTION:${NC} "
                read -r ri_choice

                local keep_data="y"
                if [[ "$ri_choice" == "1" ]]; then
                    echo; confirm "KEEP EXISTING DATA AND REINSTALL?" || continue; echo
                    keep_data="y"
                elif [[ "$ri_choice" == "2" ]]; then
                    echo; confirm "CLEAR ALL DATA AND REINSTALL?" || continue; echo
                    keep_data="n"
                elif [[ "$ri_choice" == "0" ]]; then
                    continue
                else
                    echo -e "\n  ${R}✘ INVALID SELECTION.${NC}"; sleep 1; continue
                fi

                (sudo tc qdisc del dev "$INTERFACE" root 2>/dev/null; sudo tc qdisc del dev "$INTERFACE" ingress 2>/dev/null; sudo tc qdisc del dev ifb0 root 2>/dev/null) & spin $! "CLEARING NETWORK RULES"
                
                rm -f "$INSTALL_FLAG"
                echo "#!/bin/bash" > "$RULES_FILE"
                
                if [[ "$keep_data" == "n" ]]; then
                    > "$DB_FILE"
                    echo -e "\n  ${G}✔ ALL DATA CLEARED. READY FOR REINSTALL.${NC}"
                else
                    echo -e "\n  ${G}✔ DATA KEPT SAFE. READY FOR REINSTALL.${NC}"
                fi
                
                echo -e -n "\n  ${DG}PRESS ENTER TO CONTINUE...${NC}"; read -r
                run_installer
                ;;
            3) uninstall_clp ;;
            0) return ;;
            *) sleep 1 ;;
        esac
    done
}

uninstall_clp() {
    clear; hline; center "${R}⚠  COMPLETE UNINSTALLATION ${NC}"; hline; echo
    confirm "THIS WILL REMOVE ALL LIMITS & DATA. CONTINUE?" || return; echo

    if [[ -f "$DB_FILE" ]]; then
        while IFS='|' read -r type target dl x y z; do
            [[ "$type" == "ANTI_SHARE" ]] && while sudo iptables -D INPUT -p tcp --dport "$target" -m connlimit --connlimit-above "$dl" --connlimit-mask 0 -j REJECT 2>/dev/null; do :; done
            [[ "$type" == "BLOCK_IP" ]] && while sudo iptables -D INPUT -s "$target" -j DROP 2>/dev/null; do :; done
            [[ "$type" == "BLOCK_PORT" ]] && while sudo iptables -D INPUT -p tcp --dport "$target" -j DROP 2>/dev/null; do :; done
        done < "$DB_FILE"
    fi

    (sudo tc qdisc del dev "$INTERFACE" root >/dev/null 2>&1) & spin $! "CLEANING UPLOAD RULES"
    (sudo tc qdisc del dev "$INTERFACE" ingress >/dev/null 2>&1) & spin $! "CLEANING DOWNLOAD RULES"
    (sudo tc qdisc del dev ifb0 root >/dev/null 2>&1) & spin $! "CLEANING IFB CORE"
    (sudo ip link set dev ifb0 down >/dev/null 2>&1) & spin $! "DISABLING IFB INTERFACE"
    (sudo ethtool -K "$INTERFACE" gro on lro on tso on gso on >/dev/null 2>&1) & spin $! "RESTORING HARDWARE CONFIG"
    ((crontab -l 2>/dev/null | grep -v "\.tdz_crontab\.sh") | crontab -) & spin $! "CLEANING CRONTAB STARTUP"
    (sudo rm -f "$CLP_BIN" "$CLP_BIN_UPPER" "/usr/local/bin/Clp" "/usr/local/bin/cLp" "$RULES_FILE" "$DB_FILE" >/dev/null 2>&1) & spin $! "REMOVING SYSTEM FILES"

    for RC in ~/.bashrc ~/.zshrc; do
        [ -f "$RC" ] && sed -i '/alias clp=/d; /alias CLP=/d; /alias Clp=/d; /alias cLp=/d' "$RC" >/dev/null 2>&1
    done
    rm -f "$INSTALL_FLAG" 2>/dev/null

    echo -e -n "\n  ${Y}⚠  REMOVE THE SCRIPT FILE ITSELF? ${DG}[Y/N]${NC} ${C}›${NC} "
    read -r rm_self
    if [[ "${rm_self,,}" == "y" ]]; then
        (rm -f "$SCRIPT_PATH" >/dev/null 2>&1) & spin $! "DELETING SCRIPT FILE"
    else
        echo -e "  ${DG}⊘  SCRIPT FILE KEPT INTACT.${NC}"
    fi

    echo -e "\n  ${G}✔ UNINSTALLATION COMPLETE. SERVER IS CLEAN!${NC}"; exit 0
}

# ── Misc Tools ────────────────────────────────────────────────────────────────
backup_export() {
    clear; hline; center "${C}💾 BACKUP & EXPORT RULES ${NC}"; hline; echo
    local EXPORT_FILE="/root/TDZ_LIMITS_BACKUP.txt"
    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "  ${Y}⚠ NO ACTIVE LIMITS IN DATABASE TO BACKUP.${NC}"
        echo -e "\n  ${DG}PRESS ENTER TO RETURN...${NC}"
        read -r
        return
    fi
    confirm "GENERATE BACKUP OF CURRENT DATABASE RULES?" || return; echo
    (sleep 1) & spin $! "ANALYZING DATABASE RECORDS"
    (
        echo "=========================================" > "$EXPORT_FILE"
        echo "      TDZ NETWORK SPEED LIMITS BACKUP    " >> "$EXPORT_FILE"
        echo "      DATE: $(date)                      " >> "$EXPORT_FILE"
        echo "=========================================" >> "$EXPORT_FILE"
        echo "TYPE      TARGET            DL      UP   " >> "$EXPORT_FILE"
        echo "-----------------------------------------" >> "$EXPORT_FILE"
        while IFS='|' read -r type target dl up dl_ping up_ping; do
            [[ -z "$type" ]] && continue
            printf "%-9s %-17s %-7s %-7s\n" "$type" "$target" "${dl}M" "${up}M" >> "$EXPORT_FILE"
        done < "$DB_FILE"
    ) & spin $! "CREATING BACKUP FILE"
    (sleep 0.5) & spin $! "EXPORTING TO $EXPORT_FILE"
    echo -e "\n  ${G}✔ EXPORTED! FILE SAVED AT : ${C}$EXPORT_FILE${NC}"
    echo -e "\n  ${DG}PRESS ENTER TO RETURN HOME...${NC}"
    read -r
}

# ===== TRAFFIC MONITOR (unchanged) =====
live_monitor() {
    while true; do
        clear; hline; center "${M}📊  TRAFFIC USAGE REPORT${NC}"; hline; echo
        echo -e "  ${G}[1]${NC} LIVE BANDWIDTH USAGE"
        echo -e "  ${G}[2]${NC} DAILY TRAFFIC USAGE"
        echo -e "  ${G}[3]${NC} MONTHLY TRAFFIC USAGE"
        echo -e "  ${DG}[0]${NC} BACK TO MAIN MENU"
        echo -e -n "\n  ${G}▶${NC} SELECT OPTION ${DG}[0-3]${NC} ${C}›${NC} "
        read -r tm_choice
        [[ -z "$tm_choice" ]] && continue
        
        case "$tm_choice" in
            1)
                clear; trap 'break' INT
                while true; do
                    R1=$(cat /sys/class/net/"$INTERFACE"/statistics/rx_bytes 2>/dev/null || echo 0)
                    T1=$(cat /sys/class/net/"$INTERFACE"/statistics/tx_bytes 2>/dev/null || echo 0)
                    sleep 1
                    R2=$(cat /sys/class/net/"$INTERFACE"/statistics/rx_bytes 2>/dev/null || echo 0)
                    T2=$(cat /sys/class/net/"$INTERFACE"/statistics/tx_bytes 2>/dev/null || echo 0)
                    RX=$(awk "BEGIN{printf \"%.2f\",($R2-$R1)/131072}")
                    TX=$(awk "BEGIN{printf \"%.2f\",($T2-$T1)/131072}")

                    printf "\033[H"
                    echo
                    hline "━" "$M"; center "${C}📊  LIVE BANDWIDTH MONITOR ${NC}"
                    center "${DG}INTERFACE: ${W}${INTERFACE_UP}${NC}  ●  ${Y}PRESS CTRL+C TO EXIT${NC}"; hline "━" "$M"
                    echo
                    echo -e "  ${G}📥 DOWNLOAD (IN) :${NC} ${W}${RX} MBPS       \033[K"
                    echo -e "  ${C}📤 UPLOAD (OUT)  :${NC} ${W}${TX} MBPS       \033[K"
                    echo
                    hline "─" "$DG"
                done
                trap - INT
                ;;
            2)
                clear; hline; center "${C}📅  DAILY TRAFFIC SUMMARY  📅${NC}"; hline; echo
                local output=$(vnstat -d -i "$INTERFACE" 2>/dev/null)
                if [[ -n "$output" ]]; then
                    echo "$output" | while IFS= read -r line; do
                        echo -e "  ${W}${line}${NC}"
                    done
                else
                    echo -e "  ${Y}⚠ NO DATA AVAILABLE YET.${NC}"
                fi
                echo -e "\n  ${DG}PRESS ENTER TO RETURN...${NC}"; read -r
                ;;
            3)
                clear; hline; center "${C}📅  MONTHLY TRAFFIC SUMMARY  📅${NC}"; hline; echo
                local output=$(vnstat -m -i "$INTERFACE" 2>/dev/null)
                if [[ -n "$output" ]]; then
                    echo "$output" | while IFS= read -r line; do
                        echo -e "  ${W}${line}${NC}"
                    done
                else
                    echo -e "  ${Y}⚠ NO DATA AVAILABLE YET.${NC}"
                fi
                echo -e "\n  ${DG}PRESS ENTER TO RETURN...${NC}"; read -r
                ;;
            0)
                return
                ;;
            *)
                echo -e "\n  ${DG}INVALID SELECTION.${NC}"
                sleep 1
                ;;
        esac
    done
}

# ===== ENHANCED: Multi-Interface Selection (unchanged) =====
change_interface() {
    while true; do
        clear; hline; center "${R}⚠  CHANGE NETWORK INTERFACE${NC}"; hline; echo
        
        local ifaces=()
        while read -r line; do
            iface=$(echo "$line" | awk -F': ' '{print $2}')
            [[ "$iface" == "lo" ]] && continue
            [[ -n "$iface" ]] && ifaces+=("$iface")
        done < <(ip link show | grep -E '^[0-9]+: ')
        
        echo -e "  ${C}AVAILABLE NETWORK INTERFACES:${NC}"
        for i in "${!ifaces[@]}"; do
            local idx=$((i+1))
            local status=$(ip link show "${ifaces[i]}" 2>/dev/null | grep -q "UP" && echo "UP" || echo "DOWN")
            local ip_addr=$(ip -4 addr show "${ifaces[i]}" 2>/dev/null | grep -oP '(?<=inet )\S+' | head -1)
            [[ -z "$ip_addr" ]] && ip_addr="NO IP"
            if [[ "${ifaces[i]}" == "$INTERFACE" ]]; then
                echo -e "  ${G}[$idx]${NC} ${W}${ifaces[i]}${NC} (${Y}CURRENT${NC}) - ${status} - $ip_addr"
            else
                echo -e "  ${G}[$idx]${NC} ${W}${ifaces[i]}${NC} - ${status} - $ip_addr"
            fi
        done
        
        local num_interfaces=${#ifaces[@]}
        local custom_num=$((num_interfaces + 1))
        
        echo -e "  ${G}[$custom_num]${NC} ${W}ENTER CUSTOM INTERFACE NAME${NC}"
        echo -e "  ${DG}[0]${NC} ${W}BACK${NC}"
        echo
        echo -e -n "  ${M}SELECT OPTION:${NC} "
        read -r if_choice
        
        if [[ -z "$if_choice" ]]; then
            continue
        fi
        
        if [[ "$if_choice" == "0" ]]; then
            return
        elif [[ "$if_choice" == "$custom_num" ]]; then
            echo -e -n "\n  ${C}ENTER INTERFACE NAME:${NC} "
            read -r new_if
            if [[ -z "$new_if" ]]; then
                echo -e "\n  ${DG}NO INPUT. OPERATION CANCELLED.${NC}"
                sleep 1
                continue
            fi
            if interface_exists "$new_if"; then
                INTERFACE="$new_if"
                echo -e "\n  ${G}INTERFACE CHANGED TO: ${C}$INTERFACE${NC}"
                confirm "APPLY RULES WITH NEW INTERFACE?" && rebuild_tc_rules
                echo -e -n "\n  ${DG}PRESS ENTER TO CONTINUE...${NC}"; read -r
                return
            else
                echo -e "\n  ${R}INTERFACE '$new_if' DOES NOT EXIST.${NC}"
                sleep 2
                continue
            fi
        elif [[ "$if_choice" =~ ^[0-9]+$ ]] && [ "$if_choice" -ge 1 ] && [ "$if_choice" -le "$num_interfaces" ]; then
            INTERFACE="${ifaces[$((if_choice-1))]}"
            echo -e "\n  ${G}INTERFACE CHANGED TO: ${C}$INTERFACE${NC}"
            confirm "APPLY RULES WITH NEW INTERFACE?" && rebuild_tc_rules
            echo -e -n "\n  ${DG}PRESS ENTER TO CONTINUE...${NC}"; read -r
            return
        else
            echo -e "\n  ${DG}INVALID SELECTION.${NC}"
            sleep 1
        fi
    done
}

toggle_reboot() {
    clear; hline; center "${C}🔁 REBOOT PERSISTENCE SETTINGS ${NC}"; hline; echo
    if crontab -l 2>/dev/null | grep -q "\.tdz_crontab\.sh"; then
        echo -e "  ${G}CURRENT STATUS : ON (AUTO-APPLY ENABLED)${NC}\n"
        confirm "DISABLE AUTO-APPLY ON REBOOT?" || return; echo
        ((crontab -l 2>/dev/null | grep -v "\.tdz_crontab\.sh") | crontab -) & spin $! "DISABLING REBOOT APPLY"
        echo -e "\n  ${Y}✔ REBOOT APPLY IS NOW OFF!${NC}"; echo -e -n "\n  ${DG}PRESS ENTER...${NC}"; read -r
    else
        echo -e "  ${Y}CURRENT STATUS : OFF (AUTO-APPLY DISABLED)${NC}\n"
        confirm "ENABLE AUTO-APPLY ON REBOOT?" || return; echo
        [ ! -f "$RULES_FILE" ] && echo "#!/bin/bash" > "$RULES_FILE" && chmod +x "$RULES_FILE"
        ((crontab -l 2>/dev/null | grep -v "\.tdz_crontab\.sh"; echo "@reboot sleep 15 && bash $RULES_FILE") | crontab -) & spin $! "ENABLING REBOOT APPLY"
        echo -e "\n  ${G}✔ REBOOT APPLY IS NOW ON!${NC}"; echo -e -n "\n  ${DG}PRESS ENTER...${NC}"; read -r
    fi
}

# ── Main Loop ─────────────────────────────────────────────────────────────────
while true; do
    check_system
    draw_dashboard
    read -r choice
    case "${choice,,}" in
        "" | " ") continue ;;
        1) speed_limit_manager ;;
        2) firewall_manager ;;
        3) connection_manager ;;
        4) live_monitor ;;
        5) ping_speedtest ;;
        6) confirm "FORCE HARDWARE OPTIMIZATION?" && { echo; (sudo ethtool -K "$INTERFACE" gro off lro off tso off gso off >/dev/null 2>&1) & spin $! "OPTIMIZING HARDWARE"; sleep 1; } ;;
        7) toggle_reboot ;;
        8) change_interface ;;
        9) backup_export ;;
        0) script_manager ;;
        x) clear; echo -e "\n  ${C}📴 SYSTEM EXIT. HAVE A GREAT DAY @TUHINBROH!  ${NC}\n"; exit 0 ;;
        *) echo -e "\n  ${R}✘ INVALID CHOICE!${NC}"; sleep 1 ;;
    esac
done
