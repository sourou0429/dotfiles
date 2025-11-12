#!/bin/bash

# tmux WiFi表示プラグイン (Arch Linux用)
# SSIDとシグナル強度を表示

get_wifi_info() {
    # nmcliを使用してWiFi情報を取得
    if ! command -v nmcli &> /dev/null; then
        echo "WiFi: N/A"
        return
    fi

    # アクティブなWiFi接続を取得
    local wifi_info=$(nmcli -t -f active,ssid,signal dev wifi | grep '^yes')
    
    if [ -z "$wifi_info" ]; then
        echo "WiFi: 未接続"
        return
    fi

    # SSIDとシグナル強度を抽出
    local ssid=$(echo "$wifi_info" | cut -d: -f2)
    local signal=$(echo "$wifi_info" | cut -d: -f3)

    # シグナル強度に応じてバーを表示
    local bars=""
    if [ "$signal" -ge 80 ]; then
        bars="█"
    elif [ "$signal" -ge 60 ]; then
        bars="▆"
    elif [ "$signal" -ge 40 ]; then
        bars="▄"
    elif [ "$signal" -ge 20 ]; then
        bars="▂"
    else
        bars="▁"
    fi

    echo "${ssid} ${bars}"
}

get_wifi_info
