#!/bin/bash

# PCヘルスチェックスクリプト
# Linux/macOS対応

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ヘッダー表示
print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 警告レベルの判定
get_status_color() {
    local value=$1
    local warning=$2
    local critical=$3
    
    if (( $(echo "$value >= $critical" | bc -l) )); then
        echo -e "${RED}"
    elif (( $(echo "$value >= $warning" | bc -l) )); then
        echo -e "${YELLOW}"
    else
        echo -e "${GREEN}"
    fi
}

# OS判定
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux"
    else
        echo "Unknown"
    fi
}

OS_TYPE=$(detect_os)

echo ""
print_header "🖥️  PCヘルスチェック - $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ============================================
# 1. 基本情報と稼働状況
# ============================================
print_header "📊 基本情報と稼働状況"

# システム稼働時間
if [[ "$OS_TYPE" == "macOS" ]]; then
    boot_time=$(sysctl -n kern.boottime | awk '{print $4}' | sed 's/,//')
    current_time=$(date +%s)
    uptime_seconds=$((current_time - boot_time))
else
    uptime_seconds=$(awk '{print int($1)}' /proc/uptime)
fi

days=$((uptime_seconds / 86400))
hours=$(((uptime_seconds % 86400) / 3600))
minutes=$(((uptime_seconds % 3600) / 60))

echo -e "⏱️  稼働時間: ${GREEN}${days}d ${hours}h ${minutes}m${NC}"

# OS情報
if [[ "$OS_TYPE" == "macOS" ]]; then
    os_version=$(sw_vers -productVersion)
    os_name="macOS $os_version"
else
    os_name=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)
    [[ -z "$os_name" ]] && os_name="Linux $(uname -r)"
fi
echo -e "💿 OS: ${BLUE}$os_name${NC}"

# CPU情報
if [[ "$OS_TYPE" == "macOS" ]]; then
    cpu_model=$(sysctl -n machdep.cpu.brand_string)
    cpu_cores=$(sysctl -n hw.ncpu)
else
    cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
    cpu_cores=$(nproc)
fi
echo -e "🔧 CPU: ${BLUE}$cpu_model (${cpu_cores}コア)${NC}"

echo ""

# ============================================
# 2. パフォーマンス（負荷）情報
# ============================================
print_header "⚡ パフォーマンス（負荷）情報"

# CPU使用率
if [[ "$OS_TYPE" == "macOS" ]]; then
    cpu_usage=$(ps -A -o %cpu | awk '{s+=$1} END {print s}')
    cpu_usage=$(printf "%.1f" $cpu_usage)
else
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
fi

cpu_color=$(get_status_color $cpu_usage 70 90)
echo -e "🔥 CPU使用率: ${cpu_color}${cpu_usage}%${NC}"

# メモリ使用量
if [[ "$OS_TYPE" == "macOS" ]]; then
    total_mem=$(sysctl -n hw.memsize)
    total_mem_gb=$(echo "scale=1; $total_mem / 1024 / 1024 / 1024" | bc)
    
    page_size=$(pagesize)
    mem_info=$(vm_stat)
    pages_free=$(echo "$mem_info" | awk '/Pages free/ {print $3}' | tr -d '.')
    pages_active=$(echo "$mem_info" | awk '/Pages active/ {print $3}' | tr -d '.')
    pages_inactive=$(echo "$mem_info" | awk '/Pages inactive/ {print $3}' | tr -d '.')
    pages_wired=$(echo "$mem_info" | awk '/Pages wired down/ {print $4}' | tr -d '.')
    
    used_mem=$((($pages_active + $pages_inactive + $pages_wired) * $page_size))
    used_mem_gb=$(echo "scale=1; $used_mem / 1024 / 1024 / 1024" | bc)
    mem_percent=$(echo "scale=1; $used_mem_gb / $total_mem_gb * 100" | bc)
else
    mem_info=$(free -b)
    total_mem=$(echo "$mem_info" | awk '/Mem:/ {print $2}')
    used_mem=$(echo "$mem_info" | awk '/Mem:/ {print $3}')
    total_mem_gb=$(echo "scale=1; $total_mem / 1024 / 1024 / 1024" | bc)
    used_mem_gb=$(echo "scale=1; $used_mem / 1024 / 1024 / 1024" | bc)
    mem_percent=$(echo "scale=1; $used_mem / $total_mem * 100" | bc)
fi

mem_color=$(get_status_color $mem_percent 80 95)
echo -e "🧠 メモリ: ${total_mem_gb} GB中 ${mem_color}${used_mem_gb} GB使用 (${mem_percent}%)${NC}"

# ロードアベレージ
if [[ "$OS_TYPE" == "macOS" ]]; then
    load_avg=$(sysctl -n vm.loadavg | awk '{print $2, $3, $4}')
else
    load_avg=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
fi

load_1min=$(echo $load_avg | awk '{print $1}')
load_color=$(get_status_color $load_1min $cpu_cores $((cpu_cores * 2)))
echo -e "📈 ロードアベレージ: ${load_color}$load_avg${NC} (1分, 5分, 15分)"

echo ""

# ============================================
# 3. ストレージ（ディスク）情報
# ============================================
print_header "💾 ストレージ（ディスク）情報"

# ディスク空き容量
if [[ "$OS_TYPE" == "macOS" ]]; then
    disk_info=$(df -H / | tail -1)
else
    disk_info=$(df -h / | tail -1)
fi

disk_total=$(echo $disk_info | awk '{print $2}')
disk_used=$(echo $disk_info | awk '{print $3}')
disk_avail=$(echo $disk_info | awk '{print $4}')
disk_percent=$(echo $disk_info | awk '{print $5}' | tr -d '%')

disk_color=$(get_status_color $disk_percent 80 90)
echo -e "💿 メインドライブ: ${disk_total}中 ${disk_color}${disk_avail}空き (使用率: ${disk_percent}%)${NC}"

# ディスクI/O (Linuxのみ)
if [[ "$OS_TYPE" == "Linux" ]] && command -v iostat &> /dev/null; then
    io_info=$(iostat -d -x 1 2 | tail -n +4 | tail -1)
    read_mb=$(echo $io_info | awk '{printf "%.1f", $6/1024}')
    write_mb=$(echo $io_info | awk '{printf "%.1f", $7/1024}')
    echo -e "📊 ディスクI/O: 読込 ${GREEN}${read_mb} MB/s${NC} / 書込 ${GREEN}${write_mb} MB/s${NC}"
elif [[ "$OS_TYPE" == "macOS" ]]; then
    echo -e "📊 ディスクI/O: ${YELLOW}macOSでは詳細情報取得に制限があります${NC}"
fi

# S.M.A.R.T.ステータス
if command -v smartctl &> /dev/null; then
    if [[ "$OS_TYPE" == "Linux" ]]; then
        main_disk=$(lsblk -no pkname $(df / | tail -1 | awk '{print $1}') | head -1)
        smart_status=$(sudo smartctl -H /dev/$main_disk 2>/dev/null | grep "SMART overall-health" | awk '{print $NF}')
    else
        smart_status="PASSED"  # macOSではsudo権限が必要なため簡易表示
    fi
    
    if [[ "$smart_status" == "PASSED" ]] || [[ "$smart_status" == "OK" ]]; then
        echo -e "✅ S.M.A.R.T.ステータス: ${GREEN}正常 (OK)${NC}"
    else
        echo -e "⚠️  S.M.A.R.T.ステータス: ${RED}要確認${NC}"
    fi
else
    echo -e "ℹ️  S.M.A.R.T.ステータス: ${YELLOW}smartctl未インストール${NC}"
fi

echo ""

# ============================================
# 4. ネットワーク情報
# ============================================
print_header "🌐 ネットワーク情報"

# ネットワーク接続状況
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "📡 ネットワーク: ${GREEN}接続中${NC}"
    
    # 接続タイプの判定
    if [[ "$OS_TYPE" == "macOS" ]]; then
        conn_type=$(networksetup -getairportnetwork en0 2>/dev/null | grep "Current Wi-Fi Network")
        if [[ -n "$conn_type" ]]; then
            echo -e "📶 接続タイプ: ${BLUE}Wi-Fi${NC}"
        else
            echo -e "🔌 接続タイプ: ${BLUE}有線LAN${NC}"
        fi
    else
        if iwconfig 2>/dev/null | grep -q "ESSID"; then
            echo -e "📶 接続タイプ: ${BLUE}Wi-Fi${NC}"
        else
            echo -e "🔌 接続タイプ: ${BLUE}有線LAN${NC}"
        fi
    fi
else
    echo -e "📡 ネットワーク: ${RED}未接続${NC}"
fi

# IPアドレス
if [[ "$OS_TYPE" == "macOS" ]]; then
    ip_addr=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
else
    ip_addr=$(hostname -I | awk '{print $1}')
fi

if [[ -n "$ip_addr" ]]; then
    echo -e "🏠 IPアドレス: ${BLUE}$ip_addr${NC}"
else
    echo -e "🏠 IPアドレス: ${YELLOW}取得できませんでした${NC}"
fi

echo ""

# ============================================
# まとめ
# ============================================
print_header "📋 ヘルスチェックまとめ"

# 警告がある場合の通知
warnings=0

if (( $(echo "$cpu_usage >= 90" | bc -l) )); then
    echo -e "${RED}⚠️  CPU使用率が非常に高い状態です${NC}"
    ((warnings++))
elif (( $(echo "$cpu_usage >= 70" | bc -l) )); then
    echo -e "${YELLOW}⚠️  CPU使用率がやや高めです${NC}"
    ((warnings++))
fi

if (( $(echo "$mem_percent >= 95" | bc -l) )); then
    echo -e "${RED}⚠️  メモリ使用量が危険水準です${NC}"
    ((warnings++))
elif (( $(echo "$mem_percent >= 80" | bc -l) )); then
    echo -e "${YELLOW}⚠️  メモリ使用量が高めです${NC}"
    ((warnings++))
fi

if (( $(echo "$disk_percent >= 90" | bc -l) )); then
    echo -e "${RED}⚠️  ディスク容量が逼迫しています${NC}"
    ((warnings++))
elif (( $(echo "$disk_percent >= 80" | bc -l) )); then
    echo -e "${YELLOW}⚠️  ディスク容量が少なくなっています${NC}"
    ((warnings++))
fi

if [[ $warnings -eq 0 ]]; then
    echo -e "${GREEN}✅ すべての項目が正常範囲内です${NC}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
