#!/data/data/com.termux/files/usr/bin/bash

echo ">>> 更新 Termux 软件源并安装基础依赖..."
pkg update -y && pkg install -y git nodejs python curl

SCRIPT_DIR="$HOME/sillytavern-start"
REPO_URL="https://github.com/dujiahuiyi/sillytavern-start.git"

if [ -d "$SCRIPT_DIR/.git" ]; then
    echo ">>> 更新 sillytavern-start 仓库..."
    git -C "$SCRIPT_DIR" pull --rebase --autostash
else
    echo ">>> 克隆 sillytavern-start 仓库..."
    rm -rf "$SCRIPT_DIR"
    git clone "$REPO_URL" "$SCRIPT_DIR" || {
        echo "克隆失败，请检查网络连接！"
        exit 1
    }
fi

chmod +x "$SCRIPT_DIR/menu.sh" "$SCRIPT_DIR/install.sh"

# 添加快捷启动命令 st 并设置打开 Termux 自动进入菜单
touch "$HOME/.bashrc"
if ! grep -q "alias st=" "$HOME/.bashrc"; then
    cat >> "$HOME/.bashrc" << 'EOF'
alias st='bash $HOME/sillytavern-start/menu.sh'
if [ -z "$ST_MENU_LOADED" ] && [ -f "$HOME/sillytavern-start/menu.sh" ]; then
    export ST_MENU_LOADED=1
    bash "$HOME/sillytavern-start/menu.sh"
fi
EOF
fi