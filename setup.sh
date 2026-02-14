#!/usr/bin/env bash
# setup.sh - Installation portable XFCE + apps + dotfiles + st
# Compatible Debian/Ubuntu et Arch/Manjaro

set -e

echo "=== Détection de la distribution ==="
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "⚠️ Impossible de détecter la distribution"
    exit 1
fi

echo "Distribution détectée : $DISTRO"

echo "=== Mise à jour des paquets ==="
if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
    sudo apt update && sudo apt upgrade -y
elif [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
    sudo pacman -Syu --noconfirm
else
    echo "⚠️ Distribution non prise en charge par ce script"
    exit 1
fi

echo "=== Installation des paquets essentiels ==="
if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
    sudo apt install -y steam lsd wget curl apt-transport-https gnupg build-essential git make gcc xfce4 xfce4-goodies snapd
elif [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
    sudo pacman -S --noconfirm steam lsd wget curl base-devel git xfce4 xfce4-goodies snapd
fi

# Activer snap si nécessaire
if ! systemctl is-active --quiet snapd; then
    sudo systemctl enable --now snapd
fi

echo "=== Installation de Cider ==="
if ! command -v cider &> /dev/null; then
    sudo snap install cider
fi

echo "=== Installation de Zen Browser depuis GitHub ==="
if ! command -v zen &> /dev/null; then
    ZEN_URL="https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.xz"
    ZEN_DEST="/opt/zen"
    ZEN_BIN="/usr/local/bin/zen"
    TMP_DIR="/tmp/zen-install"

    echo "📥 Téléchargement de Zen..."
    mkdir -p "$TMP_DIR"
    wget -q -O "$TMP_DIR/zen.tar.xz" "$ZEN_URL"

    echo "📦 Extraction dans $ZEN_DEST..."
    sudo mkdir -p "$ZEN_DEST"
    sudo tar -xJf "$TMP_DIR/zen.tar.xz" -C "$ZEN_DEST" --strip-components=1

    echo "🔗 Création du lanceur global..."
    echo -e "#!/usr/bin/env bash\nexec $ZEN_DEST/zen \"\$@\"" | sudo tee "$ZEN_BIN" > /dev/null
    sudo chmod +x "$ZEN_BIN"

    echo "🛠️ Création du fichier .desktop..."
    sudo tee /usr/share/applications/zen-browser.desktop > /dev/null << EOF
[Desktop Entry]
Name=Zen Browser
Comment=Navigateur Zen
Exec=$ZEN_BIN %U
Icon=$ZEN_DEST/resources/app/icon.png
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF

    echo "🧹 Nettoyage..."
    rm -rf "$TMP_DIR"

    echo "✅ Zen Browser installé ! Lancer avec : zen"
else
    echo "Zen Browser déjà installé."
fi

echo "=== Copie du dossier config ==="
DOTFILES="$HOME/dotfiles-xfce/config"
if [ -d "$DOTFILES" ]; then
    mkdir -p ~/.config
    cp -r "$DOTFILES/"* ~/.config/
    echo "✅ Configs copiées dans ~/.config"
else
    echo "⚠️ Dossier $DOTFILES introuvable. Ignoré."
fi

echo "=== Copie du dossier icons ==="
DOTFILES="$HOME/dotfiles-xfce/.icon"
if [ -d "$DOTFILES" ]; then
    mkdir -p ~/.icons
    cp -r "$DOTFILES/"* ~/.icons/
    echo "✅ Configs copiées dans ~/.icons"
else
    echo "⚠️ Dossier $DOTFILES introuvable. Ignoré."
fi

echo "=== Copie du dossier themes ==="
DOTFILES="$HOME/dotfiles-xfce/themes"
if [ -d "$DOTFILES" ]; then
    mkdir -p ~/.themes
    cp -r "$DOTFILES/"* ~/.themes/
    echo "✅ Configs copiées dans ~/.themes"
else
    echo "⚠️ Dossier $DOTFILES introuvable. Ignoré."
fi

echo "=== Compilation de st ==="
ST_DIR="$HOME/.config/st"
if [ -d "$ST_DIR" ]; then
    echo "Compilation de st depuis $ST_DIR"
    cd "$ST_DIR"
    make clean || true
    sudo make install
else
    echo "⚠️ Répertoire $ST_DIR introuvable. Ignoré."
fi


echo "=== Redémarrage des panels XFCE ==="
xfce4-panel --restart
xfwm4 --replace &

echo "✅ Setup complet terminé !"
