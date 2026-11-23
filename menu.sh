#!/data/data/com.termux/files/usr/bin/bash

# ================= 路径与仓库配置 =================
ST_DIR="$HOME/SillyTavern"
AISTUDIO_DIR="$HOME/aistudio-api"
BRIDGE_DIR="$HOME/uncut-bridge"
SCRIPT_DIR="$HOME/sillytavern-start"

ST_REPO="https://github.com/SillyTavern/SillyTavern.git"
AISTUDIO_REPO="https://github.com/dujiahuiyi/aistudio-api.git"
BRIDGE_REPO="https://github.com/dujiahuiyi/uncut-bridge.git"
SELF_REPO="https://github.com/dujiahuiyi/sillytavern-start.git"

# ================= 颜色定义 =================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ================= 工具函数 =================
pause() {
    echo ""
    read -rp "按回车键返回菜单..."
}

check_pkg() {
    local pkg_name="$1"
    local cmd_name="${2:-$1}"
    if ! command -v "$cmd_name" >/dev/null 2>&1; then
        echo -e "${YELLOW}检测到未安装 $pkg_name，正在安装...${NC}"
        pkg install -y "$pkg_name"
    fi
}

get_st_status() {
    if [ -d "$ST_DIR" ] && [ -f "$ST_DIR/package.json" ]; then
        local ver
        ver=$(grep -m1 '"version"' "$ST_DIR/package.json" | cut -d'"' -f4)
        echo -e "${GREEN}${ver:-已安装}${NC}"
    else
        echo -e "${RED}未安装${NC}"
    fi
}

get_git_status() {
    local dir="$1"
    if [ -d "$dir/.git" ]; then
        local hash date_str
        hash=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
        date_str=$(git -C "$dir" log -1 --format=%cd --date=short 2>/dev/null)
        echo -e "${GREEN}已安装 (${hash} / ${date_str})${NC}"
    elif [ -d "$dir" ]; then
        echo -e "${YELLOW}已存在(非Git目录)${NC}"
    else
        echo -e "${RED}未安装${NC}"
    fi
}

# ================= SillyTavern =================
install_update_st() {
    check_pkg git
    check_pkg nodejs node

    if [ -d "$ST_DIR/.git" ]; then
        echo -e "${CYAN}>>> 正在更新 SillyTavern...${NC}"
        cd "$ST_DIR" || return
        git pull --rebase --autostash
    else
        echo -e "${CYAN}>>> 正在安装 SillyTavern (release 分支)...${NC}"
        git clone "$ST_REPO" -b release "$ST_DIR" || {
            echo -e "${RED}克隆失败，请检查网络连接！${NC}"
            pause
            return
        }
        cd "$ST_DIR" || return
    fi

    echo -e "${CYAN}>>> 正在安装/更新 npm 依赖...${NC}"
    npm install --no-audit --no-fund --loglevel=error --omit=dev
    echo -e "${GREEN}SillyTavern 安装/更新完成！${NC}"
    pause
}

start_st() {
    if [ ! -d "$ST_DIR" ]; then
        echo -e "${RED}SillyTavern 未安装，请先执行安装！${NC}"
        pause
        return
    fi
    check_pkg nodejs node
    echo -e "${GREEN}>>> 正在启动 SillyTavern (按 Ctrl+C 停止)...${NC}"
    cd "$ST_DIR" && bash start.sh
    pause
}

# ================= aistudio-api =================
install_update_aistudio() {
    check_pkg git
    check_pkg python

    if [ -d "$AISTUDIO_DIR/.git" ]; then
        echo -e "${CYAN}>>> 正在更新 aistudio-api...${NC}"
        cd "$AISTUDIO_DIR" || return
        git pull --rebase --autostash
    else
        echo -e "${CYAN}>>> 正在克隆 aistudio-api...${NC}"
        git clone "$AISTUDIO_REPO" "$AISTUDIO_DIR" || {
            echo -e "${RED}克隆失败，请检查网络连接！${NC}"
            pause
            return
        }
    fi
    echo -e "${GREEN}aistudio-api 安装/更新完成！${NC}"
    pause
}

start_aistudio() {
    if [ ! -d "$AISTUDIO_DIR" ]; then
        echo -e "${RED}aistudio-api 未安装，请先执行安装！${NC}"
        pause
        return
    fi
    echo -e "${GREEN}>>> 正在启动 aistudio-api (按 Ctrl+C 停止)...${NC}"
    cd "$AISTUDIO_DIR" && bash start.sh
    pause
}

# ================= uncut-bridge =================
install_update_bridge() {
    check_pkg git

    if [ -d "$BRIDGE_DIR/.git" ]; then
        echo -e "${CYAN}>>> 正在更新 uncut-bridge...${NC}"
        cd "$BRIDGE_DIR" || return
        git pull --rebase --autostash
    else
        echo -e "${CYAN}>>> 正在克隆 uncut-bridge...${NC}"
        git clone "$BRIDGE_REPO" "$BRIDGE_DIR" || {
            echo -e "${RED}克隆失败，请检查网络连接！${NC}"
            pause
            return
        }
    fi
    echo -e "${GREEN}uncut-bridge 安装/更新完成！${NC}"
    pause
}

start_bridge() {
    if [ ! -d "$BRIDGE_DIR" ]; then
        echo -e "${RED}uncut-bridge 未安装，请先执行安装！${NC}"
        pause
        return
    fi
    if [ ! -x "$AISTUDIO_DIR/.venv/bin/python" ]; then
        echo -e "${RED}未找到 Python 虚拟环境: $AISTUDIO_DIR/.venv/bin/python${NC}"
        echo -e "${YELLOW}请先安装并启动一次 aistudio-api 以创建 .venv 环境。${NC}"
        pause
        return
    fi
    echo -e "${GREEN}>>> 正在启动 uncut-bridge (按 Ctrl+C 停止)...${NC}"
    cd "$BRIDGE_DIR" && "$AISTUDIO_DIR/.venv/bin/python" oai-bridge.py
    pause
}

# ================= 脚本自更新 =================
update_self() {
    if [ -d "$SCRIPT_DIR/.git" ]; then
        echo -e "${CYAN}>>> 正在更新启动脚本...${NC}"
        git -C "$SCRIPT_DIR" pull --rebase --autostash && {
            echo -e "${GREEN}更新完成，正在重启脚本...${NC}"
            sleep 1
            exec bash "$SCRIPT_DIR/menu.sh"
        }
    else
        echo -e "${YELLOW}未检测到脚本 Git 仓库 ($SCRIPT_DIR)，正在重新拉取...${NC}"
        rm -rf "$SCRIPT_DIR"
        git clone "$SELF_REPO" "$SCRIPT_DIR" && {
            chmod +x "$SCRIPT_DIR"/*.sh
            exec bash "$SCRIPT_DIR/menu.sh"
        }
    fi
    pause
}

# ================= 主菜单 =================
while true; do
    clear
    echo -e "${CYAN}=========================================${NC}"
    echo -e "           ${YELLOW}SillyTavern 启动台${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "SillyTavern  : $(get_st_status)"
    echo -e "aistudio-api : $(get_git_status "$AISTUDIO_DIR")"
    echo -e "uncut-bridge : $(get_git_status "$BRIDGE_DIR")"
    echo -e "${CYAN}-----------------------------------------${NC}"
    echo -e "${YELLOW}[SillyTavern 管理]${NC}"
    echo -e "  ${GREEN}1)${NC} 安装/更新 SillyTavern"
    echo -e "  ${GREEN}2)${NC} 启动 SillyTavern"
    echo ""
    echo -e "${YELLOW}[aistudio-api 管理]${NC}"
    echo -e "  ${GREEN}3)${NC} 安装/更新 aistudio-api"
    echo -e "  ${GREEN}4)${NC} 启动 aistudio-api"
    echo ""
    echo -e "${YELLOW}[uncut-bridge 管理]${NC}"
    echo -e "  ${GREEN}5)${NC} 安装/更新 uncut-bridge"
    echo -e "  ${GREEN}6)${NC} 启动 uncut-bridge"
    echo ""
    echo -e "${YELLOW}[脚本管理]${NC}"
    echo -e "  ${GREEN}7)${NC} 更新本脚本"
    echo ""
    echo -e "  ${RED}0)${NC} 退出"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "提示: 需同时运行多个服务时，左滑屏幕新建 Termux 会话即可"
    read -rp "请选择 [0-7]: " choice

    case "$choice" in
        1) install_update_st ;;
        2) start_st ;;
        3) install_update_aistudio ;;
        4) start_aistudio ;;
        5) install_update_bridge ;;
        6) start_bridge ;;
        7) update_self ;;
        0) echo "已退出。"; exit 0 ;;
        *) echo -e "${RED}无效选项，请重新输入！${NC}"; sleep 1 ;;
    esac
done
