#!/usr/bin/env bash
# setup.sh - Installation portable XFCE + apps + dotfiles + st + thème Nordic + Rofi + Nerd Fonts
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
    sudo apt install -y steam lsd wget curl apt-transport-https gnupg build-essential git make gcc xfce4 xfce4-goodies snapd rofi fontconfig unzip
elif [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
    sudo pacman -S --noconfirm steam lsd wget curl base-devel git xfce4 xfce4-goodies snapd rofi ttf-dejavu fontconfig unzip
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

echo "=== Installation du thème Nordic pour XFCE ==="
THEME_DIR="$HOME/.themes"
mkdir -p "$THEME_DIR"
TMP_NORDIC=$(mktemp -d)

echo "📥 Téléchargement du thème Nordic depuis GitHub..."
git clone --depth=1 https://github.com/EliverLara/Nordic.git "$TMP_NORDIC"

echo "📂 Copie dans $THEME_DIR..."
cp -r "$TMP_NORDIC/Nordic" "$THEME_DIR/"

rm -rf "$TMP_NORDIC"

echo "✅ Thème Nordic installé ! Pour l'appliquer :"
echo "   Paramètres XFCE → Apparence → Style → 'Nordic'"
echo "   Paramètres XFCE → Gestionnaire de fenêtres → Style → 'Nordic'"

echo "=== Installation des Nerd Fonts (y compris Iosevka Nerd Font) ==="
FONTS_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"
TMP_FONTS=$(mktemp -d)

# Liste des Nerd Fonts à installer
NERD_FONTS=(
    "Iosevka"
    "FiraCode"
    "Hack"
    "RobotoMono"
    "DejaVuSansMono"
    "SourceCodePro"
    "Meslo"
    "JetBrainsMono"
    "UbuntuMono"
)

for font in "${NERD_FONTS[@]}"; do
    echo "📥 Téléchargement de $font Nerd Font..."
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font// /}-Complete.zip"
    wget -q -O "$TMP_FONTS/$font.zip" "$FONT_URL"
    unzip -qq "$TMP_FONTS/$font.zip" -d "$TMP_FONTS/$font"
    cp -r "$TMP_FONTS/$font/"* "$FONTS_DIR/"
done

# Rafraîchir le cache des polices
fc-cache -fv
rm -rf "$TMP_FONTS"

echo "✅ Nerd Fonts installées !"

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
echo "✅ Rofi et Nerd Fonts sont installés. Vous pouvez maintenant appliquer le thème Nordic et configurer Rofi."
