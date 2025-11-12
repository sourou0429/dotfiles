#!/bin/bash

# CPU使用率を取得
get_cpu_usage() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        cpu=$(ps -A -o %cpu | awk '{s+=$1} END {print s}')
        printf "%.1f%%" "$cpu"
    else
        # Linux
        cpu=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        printf "%.1f%%" "$cpu"
    fi
}

# RAM使用率を取得
get_ram_usage() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        ram=$(vm_stat | awk '/Pages active/ {active=$3} /Pages wired/ {wired=$4} /Pages occupied/ {occupied=$5} /Pages free/ {free=$3} END {
            gsub(/\.$/, "", active); gsub(/\.$/, "", wired); gsub(/\.$/, "", occupied); gsub(/\.$/, "", free);
            total=active+wired+occupied+free;
            used=active+wired+occupied;
            printf "%.1f%%", (used/total)*100
        }')
        echo "$ram"
    else
        # Linux
        ram=$(free | grep Mem | awk '{printf "%.1f%%", ($3/$2) * 100.0}')
        echo "$ram"
    fi
}

# ディスク使用率を取得
get_disk_usage() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        disk=$(df -h / | awk 'NR==2 {print $5}')
    else
        # Linux
        disk=$(df -h / | awk 'NR==2 {print $5}')
    fi
    echo "$disk"
}

# メイン処理
main() {
    cpu=$(get_cpu_usage)
    ram=$(get_ram_usage)
    disk=$(get_disk_usage)
    
    echo "CPU:$cpu RAM:$ram ROM:$disk"
}

main
