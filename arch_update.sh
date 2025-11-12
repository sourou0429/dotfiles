#!/bin/bash

# Arch Linux pacman/yay パッケージアップデートチェッカー
# pacman (-Syu) とyay (AUR) のアップデートを確認・実行

set -e  # エラー時にスクリプトを終了

# 色付きの出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ログ出力関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_note() {
    echo -e "${CYAN}[NOTE]${NC} $1"
}

log_aur() {
    echo -e "${MAGENTA}[AUR]${NC} $1"
}

# root権限チェック（pacmanの場合）
check_root_permission() {
    if [ "$EUID" -ne 0 ] && [ "$USE_SUDO" = true ]; then
        if ! command -v sudo &> /dev/null; then
            log_error "sudoコマンドが見つかりません。rootで実行するかsudoをインストールしてください。"
            exit 1
        fi
        PACMAN_CMD="sudo pacman"
    elif [ "$EUID" -eq 0 ]; then
        PACMAN_CMD="pacman"
    else
        log_error "pacmanの実行にはroot権限またはsudoが必要です。"
        exit 1
    fi
}

# pacmanとyayの存在確認
check_package_managers() {
    if ! command -v pacman &> /dev/null; then
        log_error "pacmanコマンドが見つかりません。Arch Linuxで実行してください。"
        exit 1
    fi

    YAY_AVAILABLE=false
    if command -v yay &> /dev/null; then
        YAY_AVAILABLE=true
        log_info "yay (AUR helper) が利用可能です。"
    else
        log_warning "yay (AUR helper) が見つかりません。AURパッケージのアップデートはスキップされます。"
    fi
}

# 現在のシステム状態を表示
show_current_status() {
    log_info "現在のArch Linux システム状態を確認中..."
    echo ""
    
    # カーネルバージョン
    log_note "カーネルバージョン: $(uname -r)"
    
    # pacmanパッケージ数
    PACMAN_COUNT=$(pacman -Q 2>/dev/null | wc -l || echo "0")
    log_info "インストール済み公式パッケージ数: $PACMAN_COUNT"
    
    # AURパッケージ数（yayが利用可能な場合）
    if [ "$YAY_AVAILABLE" = true ]; then
        AUR_COUNT=$(pacman -Qm 2>/dev/null | wc -l || echo "0")
        log_aur "インストール済みAURパッケージ数: $AUR_COUNT"
    fi
    
    # 孤児パッケージ数
    ORPHAN_COUNT=$(pacman -Qtd 2>/dev/null | wc -l || echo "0")
    if [ "$ORPHAN_COUNT" -gt 0 ]; then
        log_warning "孤児パッケージ数: $ORPHAN_COUNT"
    fi
    
    # キャッシュサイズ
    if [ -d "/var/cache/pacman/pkg" ]; then
        CACHE_SIZE=$(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1 || echo "不明")
        log_info "パッケージキャッシュサイズ: $CACHE_SIZE"
    fi
    
    echo ""
}

# pacmanのアップデート可能パッケージをチェック
check_pacman_updates() {
    log_info "公式リポジトリのアップデートを確認中..."
    
    # パッケージデータベースを同期
    if ! $PACMAN_CMD -Sy &> /dev/null; then
        log_error "パッケージデータベースの同期に失敗しました。"
        return 1
    fi
    
    # アップデート可能なパッケージを確認
    PACMAN_UPDATES=$(pacman -Qu 2>/dev/null | grep -v "\[ignored\]" || echo "")
    
    if [ -z "$PACMAN_UPDATES" ]; then
        log_success "公式パッケージはすべて最新です！"
        return 1
    else
        PACMAN_UPDATE_COUNT=$(echo "$PACMAN_UPDATES" | wc -l)
        log_warning "アップデート可能な公式パッケージ: $PACMAN_UPDATE_COUNT 個"
        echo ""
        log_info "アップデート可能なパッケージ一覧:"
        echo "$PACMAN_UPDATES" | head -20 | while read -r line; do
            echo "  • $line"
        done
        
        if [ "$PACMAN_UPDATE_COUNT" -gt 20 ]; then
            echo "  ... および他 $((PACMAN_UPDATE_COUNT - 20)) 個"
        fi
        
        echo ""
        return 0
    fi
}

# yay (AUR) のアップデート可能パッケージをチェック
check_aur_updates() {
    if [ "$YAY_AVAILABLE" = false ]; then
        return 1
    fi
    
    log_aur "AURパッケージのアップデートを確認中..."
    
    # yayでアップデート可能なAURパッケージを確認
    AUR_UPDATES=$(yay -Qua 2>/dev/null || echo "")
    
    if [ -z "$AUR_UPDATES" ]; then
        log_success "AURパッケージはすべて最新です！"
        return 1
    else
        AUR_UPDATE_COUNT=$(echo "$AUR_UPDATES" | wc -l)
        log_warning "アップデート可能なAURパッケージ: $AUR_UPDATE_COUNT 個"
        echo ""
        log_aur "アップデート可能なAURパッケージ一覧:"
        echo "$AUR_UPDATES" | head -20 | while read -r line; do
            echo "  • $line"
        done
        
        if [ "$AUR_UPDATE_COUNT" -gt 20 ]; then
            echo "  ... および他 $((AUR_UPDATE_COUNT - 20)) 個"
        fi
        
        echo ""
        return 0
    fi
}

# pacmanアップデートを実行
perform_pacman_update() {
    log_info "公式パッケージのアップデートを開始します..."
    echo ""
    
    START_TIME=$(date)
    log_info "pacman -Syu を実行中..."
    
    if $PACMAN_CMD -Syu; then
        echo ""
        log_success "公式パッケージのアップデートが完了しました！"
        END_TIME=$(date)
        log_info "開始時刻: $START_TIME"
        log_info "完了時刻: $END_TIME"
        return 0
    else
        log_error "pacmanアップデート中にエラーが発生しました。"
        return 1
    fi
}

# yayアップデートを実行
perform_aur_update() {
    if [ "$YAY_AVAILABLE" = false ]; then
        return 1
    fi
    
    log_aur "AURパッケージのアップデートを開始します..."
    echo ""
    
    START_TIME=$(date)
    log_aur "yay -Sua を実行中..."
    
    if yay -Sua; then
        echo ""
        log_success "AURパッケージのアップデートが完了しました！"
        END_TIME=$(date)
        log_info "開始時刻: $START_TIME"
        log_info "完了時刻: $END_TIME"
        return 0
    else
        log_error "yayアップデート中にエラーが発生しました。"
        return 1
    fi
}

# クリーンアップの提案
suggest_cleanup() {
    echo ""
    log_note "システムクリーンアップのオプション:"
    echo "パッケージキャッシュをクリア: $PACMAN_CMD -Sc"
    echo "孤児パッケージを削除: $PACMAN_CMD -Rns \$(pacman -Qtdq)"
    echo "yayキャッシュをクリア: yay -Sc"
    
    if [ "$ORPHAN_COUNT" -gt 0 ]; then
        echo ""
        read -p "孤児パッケージを削除しますか？ (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            $PACMAN_CMD -Rns $(pacman -Qtdq) 2>/dev/null && log_success "孤児パッケージを削除しました。"
        fi
    fi
}

# ヘルプメッセージ
show_help() {
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "オプション:"
    echo "  -h, --help         このヘルプメッセージを表示"
    echo "  -f, --force        確認なしでアップデートを実行"
    echo "  -c, --check        チェックのみ実行（アップデートしない）"
    echo "  -p, --pacman-only  pacmanのみ（AURをスキップ）"
    echo "  -a, --aur-only     AUR（yay）のみ"
    echo "  -n, --no-sudo      sudoを使用しない（root実行を想定）"
    echo "  -q, --quiet        詳細出力を抑制"
    echo ""
}

# コマンドライン引数の処理
FORCE_UPDATE=false
CHECK_ONLY=false
PACMAN_ONLY=false
AUR_ONLY=false
USE_SUDO=true
QUIET_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            FORCE_UPDATE=true
            shift
            ;;
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -p|--pacman-only)
            PACMAN_ONLY=true
            shift
            ;;
        -a|--aur-only)
            AUR_ONLY=true
            shift
            ;;
        -n|--no-sudo)
            USE_SUDO=false
            shift
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        *)
            log_error "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
done

# メイン処理
main() {
    if [ "$QUIET_MODE" = false ]; then
        echo "========================================"
        echo "   Arch Linux pacman/yay Updater"
        echo "========================================"
        echo ""
    fi
    
    # 権限とパッケージマネージャーの確認
    check_root_permission
    check_package_managers
    
    # 現在の状態表示（Quietモードでない場合）
    if [ "$QUIET_MODE" = false ]; then
        show_current_status
    fi
    
    HAS_UPDATES=false
    HAS_PACMAN_UPDATES=false
    HAS_AUR_UPDATES=false
    
    # pacmanアップデートチェック
    if [ "$AUR_ONLY" = false ]; then
        if check_pacman_updates; then
            HAS_UPDATES=true
            HAS_PACMAN_UPDATES=true
        fi
    fi
    
    # AURアップデートチェック
    if [ "$PACMAN_ONLY" = false ]; then
        if check_aur_updates; then
            HAS_UPDATES=true
            HAS_AUR_UPDATES=true
        fi
    fi
    
    # アップデートの実行
    if [ "$HAS_UPDATES" = true ]; then
        if [ "$CHECK_ONLY" = true ]; then
            log_info "チェックのみモードです。アップデートは実行しません。"
            exit 0
        fi
        
        if [ "$FORCE_UPDATE" = true ]; then
            log_info "強制アップデートモードでアップデートを実行します..."
        else
            echo ""
            read -p "アップデートを実行しますか？ (y/N): " -n 1 -r
            echo ""
            
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "アップデートをキャンセルしました。"
                exit 0
            fi
        fi
        
        # pacmanアップデート実行
        if [ "$HAS_PACMAN_UPDATES" = true ]; then
            perform_pacman_update
        fi
        
        # AURアップデート実行
        if [ "$HAS_AUR_UPDATES" = true ]; then
            echo ""
            perform_aur_update
        fi
        
        # クリーンアップの提案
        if [ "$QUIET_MODE" = false ] && [ "$FORCE_UPDATE" = false ]; then
            suggest_cleanup
        fi
        
    else
        log_success "すべてのパッケージが最新です！"
    fi
    
    if [ "$QUIET_MODE" = false ]; then
        echo ""
        log_info "スクリプト完了。"
    fi
}

# 割り込み処理
trap 'log_error "スクリプトが中断されました。"; exit 130' INT

# スクリプト実行
main "$@"#!/bin/bash

# Arch Linux pacman/yay パッケージアップデートチェッカー
# pacman (-Syu) とyay (AUR) のアップデートを確認・実行

set -e  # エラー時にスクリプトを終了

# 色付きの出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ログ出力関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_note() {
    echo -e "${CYAN}[NOTE]${NC} $1"
}

log_aur() {
    echo -e "${MAGENTA}[AUR]${NC} $1"
}

# root権限チェック（pacmanの場合）
check_root_permission() {
    if [ "$EUID" -ne 0 ] && [ "$USE_SUDO" = true ]; then
        if ! command -v sudo &> /dev/null; then
            log_error "sudoコマンドが見つかりません。rootで実行するかsudoをインストールしてください。"
            exit 1
        fi
        PACMAN_CMD="sudo pacman"
    elif [ "$EUID" -eq 0 ]; then
        PACMAN_CMD="pacman"
    else
        log_error "pacmanの実行にはroot権限またはsudoが必要です。"
        exit 1
    fi
}

# pacmanとyayの存在確認
check_package_managers() {
    if ! command -v pacman &> /dev/null; then
        log_error "pacmanコマンドが見つかりません。Arch Linuxで実行してください。"
        exit 1
    fi

    YAY_AVAILABLE=false
    if command -v yay &> /dev/null; then
        YAY_AVAILABLE=true
        log_info "yay (AUR helper) が利用可能です。"
    else
        log_warning "yay (AUR helper) が見つかりません。AURパッケージのアップデートはスキップされます。"
    fi
}

# 現在のシステム状態を表示
show_current_status() {
    log_info "現在のArch Linux システム状態を確認中..."
    echo ""
    
    # カーネルバージョン
    log_note "カーネルバージョン: $(uname -r)"
    
    # pacmanパッケージ数
    PACMAN_COUNT=$(pacman -Q 2>/dev/null | wc -l || echo "0")
    log_info "インストール済み公式パッケージ数: $PACMAN_COUNT"
    
    # AURパッケージ数（yayが利用可能な場合）
    if [ "$YAY_AVAILABLE" = true ]; then
        AUR_COUNT=$(pacman -Qm 2>/dev/null | wc -l || echo "0")
        log_aur "インストール済みAURパッケージ数: $AUR_COUNT"
    fi
    
    # 孤児パッケージ数
    ORPHAN_COUNT=$(pacman -Qtd 2>/dev/null | wc -l || echo "0")
    if [ "$ORPHAN_COUNT" -gt 0 ]; then
        log_warning "孤児パッケージ数: $ORPHAN_COUNT"
    fi
    
    # キャッシュサイズ
    if [ -d "/var/cache/pacman/pkg" ]; then
        CACHE_SIZE=$(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1 || echo "不明")
        log_info "パッケージキャッシュサイズ: $CACHE_SIZE"
    fi
    
    echo ""
}

# pacmanのアップデート可能パッケージをチェック
check_pacman_updates() {
    log_info "公式リポジトリのアップデートを確認中..."
    
    # パッケージデータベースを同期
    if ! $PACMAN_CMD -Sy &> /dev/null; then
        log_error "パッケージデータベースの同期に失敗しました。"
        return 1
    fi
    
    # アップデート可能なパッケージを確認
    PACMAN_UPDATES=$(pacman -Qu 2>/dev/null | grep -v "\[ignored\]" || echo "")
    
    if [ -z "$PACMAN_UPDATES" ]; then
        log_success "公式パッケージはすべて最新です！"
        return 1
    else
        PACMAN_UPDATE_COUNT=$(echo "$PACMAN_UPDATES" | wc -l)
        log_warning "アップデート可能な公式パッケージ: $PACMAN_UPDATE_COUNT 個"
        echo ""
        log_info "アップデート可能なパッケージ一覧:"
        echo "$PACMAN_UPDATES" | head -20 | while read -r line; do
            echo "  • $line"
        done
        
        if [ "$PACMAN_UPDATE_COUNT" -gt 20 ]; then
            echo "  ... および他 $((PACMAN_UPDATE_COUNT - 20)) 個"
        fi
        
        echo ""
        return 0
    fi
}

# yay (AUR) のアップデート可能パッケージをチェック
check_aur_updates() {
    if [ "$YAY_AVAILABLE" = false ]; then
        return 1
    fi
    
    log_aur "AURパッケージのアップデートを確認中..."
    
    # yayでアップデート可能なAURパッケージを確認
    AUR_UPDATES=$(yay -Qua 2>/dev/null || echo "")
    
    if [ -z "$AUR_UPDATES" ]; then
        log_success "AURパッケージはすべて最新です！"
        return 1
    else
        AUR_UPDATE_COUNT=$(echo "$AUR_UPDATES" | wc -l)
        log_warning "アップデート可能なAURパッケージ: $AUR_UPDATE_COUNT 個"
        echo ""
        log_aur "アップデート可能なAURパッケージ一覧:"
        echo "$AUR_UPDATES" | head -20 | while read -r line; do
            echo "  • $line"
        done
        
        if [ "$AUR_UPDATE_COUNT" -gt 20 ]; then
            echo "  ... および他 $((AUR_UPDATE_COUNT - 20)) 個"
        fi
        
        echo ""
        return 0
    fi
}

# pacmanアップデートを実行
perform_pacman_update() {
    log_info "公式パッケージのアップデートを開始します..."
    echo ""
    
    START_TIME=$(date)
    log_info "pacman -Syu を実行中..."
    
    if $PACMAN_CMD -Syu; then
        echo ""
        log_success "公式パッケージのアップデートが完了しました！"
        END_TIME=$(date)
        log_info "開始時刻: $START_TIME"
        log_info "完了時刻: $END_TIME"
        return 0
    else
        log_error "pacmanアップデート中にエラーが発生しました。"
        return 1
    fi
}

# yayアップデートを実行
perform_aur_update() {
    if [ "$YAY_AVAILABLE" = false ]; then
        return 1
    fi
    
    log_aur "AURパッケージのアップデートを開始します..."
    echo ""
    
    START_TIME=$(date)
    log_aur "yay -Sua を実行中..."
    
    if yay -Sua; then
        echo ""
        log_success "AURパッケージのアップデートが完了しました！"
        END_TIME=$(date)
        log_info "開始時刻: $START_TIME"
        log_info "完了時刻: $END_TIME"
        return 0
    else
        log_error "yayアップデート中にエラーが発生しました。"
        return 1
    fi
}

# クリーンアップの提案
suggest_cleanup() {
    echo ""
    log_note "システムクリーンアップのオプション:"
    echo "パッケージキャッシュをクリア: $PACMAN_CMD -Sc"
    echo "孤児パッケージを削除: $PACMAN_CMD -Rns \$(pacman -Qtdq)"
    echo "yayキャッシュをクリア: yay -Sc"
    
    if [ "$ORPHAN_COUNT" -gt 0 ]; then
        echo ""
        read -p "孤児パッケージを削除しますか？ (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            $PACMAN_CMD -Rns $(pacman -Qtdq) 2>/dev/null && log_success "孤児パッケージを削除しました。"
        fi
    fi
}

# ヘルプメッセージ
show_help() {
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "オプション:"
    echo "  -h, --help         このヘルプメッセージを表示"
    echo "  -f, --force        確認なしでアップデートを実行"
    echo "  -c, --check        チェックのみ実行（アップデートしない）"
    echo "  -p, --pacman-only  pacmanのみ（AURをスキップ）"
    echo "  -a, --aur-only     AUR（yay）のみ"
    echo "  -n, --no-sudo      sudoを使用しない（root実行を想定）"
    echo "  -q, --quiet        詳細出力を抑制"
    echo ""
}

# コマンドライン引数の処理
FORCE_UPDATE=false
CHECK_ONLY=false
PACMAN_ONLY=false
AUR_ONLY=false
USE_SUDO=true
QUIET_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            FORCE_UPDATE=true
            shift
            ;;
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -p|--pacman-only)
            PACMAN_ONLY=true
            shift
            ;;
        -a|--aur-only)
            AUR_ONLY=true
            shift
            ;;
        -n|--no-sudo)
            USE_SUDO=false
            shift
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        *)
            log_error "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
done

# メイン処理
main() {
    if [ "$QUIET_MODE" = false ]; then
        echo "========================================"
        echo "   Arch Linux pacman/yay Updater"
        echo "========================================"
        echo ""
    fi
    
    # 権限とパッケージマネージャーの確認
    check_root_permission
    check_package_managers
    
    # 現在の状態表示（Quietモードでない場合）
    if [ "$QUIET_MODE" = false ]; then
        show_current_status
    fi
    
    HAS_UPDATES=false
    HAS_PACMAN_UPDATES=false
    HAS_AUR_UPDATES=false
    
    # pacmanアップデートチェック
    if [ "$AUR_ONLY" = false ]; then
        if check_pacman_updates; then
            HAS_UPDATES=true
            HAS_PACMAN_UPDATES=true
        fi
    fi
    
    # AURアップデートチェック
    if [ "$PACMAN_ONLY" = false ]; then
        if check_aur_updates; then
            HAS_UPDATES=true
            HAS_AUR_UPDATES=true
        fi
    fi
    
    # アップデートの実行
    if [ "$HAS_UPDATES" = true ]; then
        if [ "$CHECK_ONLY" = true ]; then
            log_info "チェックのみモードです。アップデートは実行しません。"
            exit 0
        fi
        
        if [ "$FORCE_UPDATE" = true ]; then
            log_info "強制アップデートモードでアップデートを実行します..."
        else
            echo ""
            read -p "アップデートを実行しますか？ (y/N): " -n 1 -r
            echo ""
            
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "アップデートをキャンセルしました。"
                exit 0
            fi
        fi
        
        # pacmanアップデート実行
        if [ "$HAS_PACMAN_UPDATES" = true ]; then
            perform_pacman_update
        fi
        
        # AURアップデート実行
        if [ "$HAS_AUR_UPDATES" = true ]; then
            echo ""
            perform_aur_update
        fi
        
        # クリーンアップの提案
        if [ "$QUIET_MODE" = false ] && [ "$FORCE_UPDATE" = false ]; then
            suggest_cleanup
        fi
        
    else
        log_success "すべてのパッケージが最新です！"
    fi
    
    if [ "$QUIET_MODE" = false ]; then
        echo ""
        log_info "スクリプト完了。"
    fi
}

# 割り込み処理
trap 'log_error "スクリプトが中断されました。"; exit 130' INT

# スクリプト実行
main "$@"
