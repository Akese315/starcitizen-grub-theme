#!/usr/bin/env bash
# =====================================================================
# install.sh - installe le theme GRUB "Holo Select" quel que soit
# l'endroit ou le depot a ete clone.
#
# Utilisation :
#   sudo ./install.sh [nom_du_theme]
#
# Arborescence attendue a cote de ce script (celle du depot GRUB-THEME) :
#   theme.txt
#   background/  (background.jpg, ...)
#   buttons/     (item_*.png, select_*.png)
#
# Le script :
#   1. Se repere par rapport a son propre chemin (pas un chemin en dur)
#   2. Trouve theme.txt + les dossiers background/ et buttons/ a cote de lui
#   3. Detecte /boot/grub ou /boot/grub2
#   4. Copie tout dans <grub>/themes/<nom_du_theme>/ en gardant la structure
#   5. Met a jour GRUB_THEME dans /etc/default/grub
#   6. Regenere grub.cfg
# =====================================================================
set -euo pipefail

THEME_NAME="${1:-scifi}"

# --- 1. Chemin reel du script, peu importe d'ou on l'appelle ---
# theme.txt, background/ et buttons/ sont censes etre juste a cote de ce
# script, dans le meme dossier que le git clone.
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
SRC_DIR="$SCRIPT_DIR"

if [ ! -f "$SRC_DIR/theme.txt" ]; then
    echo "Erreur : theme.txt introuvable dans $SRC_DIR" >&2
    echo "Verifie que le depot a bien ete clone completement." >&2
    exit 1
fi

echo "Fichiers source trouves dans : $SRC_DIR"

# --- 3. Verifier qu'on est root (ecriture dans /boot) ---
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit etre lance avec sudo (ecriture dans /boot)." >&2
    echo "Exemple : sudo $0 $THEME_NAME" >&2
    exit 1
fi

# --- 4. Detecter le dossier grub (BIOS/legacy vs grub2) ---
if [ -d /boot/grub2 ]; then
    GRUB_DIR=/boot/grub2
elif [ -d /boot/grub ]; then
    GRUB_DIR=/boot/grub
else
    echo "Erreur : ni /boot/grub ni /boot/grub2 n'existe sur ce systeme." >&2
    exit 1
fi

DEST_DIR="$GRUB_DIR/themes/$THEME_NAME"
echo "Installation vers : $DEST_DIR"

mkdir -p "$DEST_DIR"

# --- 5. Copier theme.txt + les sous-dossiers background/ et buttons/ ---
# On preserve la structure en sous-dossiers, car theme.txt reference les
# images via des chemins du type "background/background.jpg" et
# "buttons/item_*.png" (relatifs au dossier du theme installe).
cp -v "$SRC_DIR/theme.txt" "$DEST_DIR/"

copied=1
for sub in background buttons; do
    if [ -d "$SRC_DIR/$sub" ]; then
        mkdir -p "$DEST_DIR/$sub"
        shopt -s nullglob
        for f in "$SRC_DIR/$sub"/*; do
            cp -v "$f" "$DEST_DIR/$sub/"
            copied=$((copied + 1))
        done
        shopt -u nullglob
    else
        echo "Attention : dossier $SRC_DIR/$sub introuvable, ignore." >&2
    fi
done

if [ ! -e "$DEST_DIR/background/background.png" ]; then
    if [ -e "$DEST_DIR/background/background.jpg" ] || [ -e "$DEST_DIR/background/background.jpeg" ]; then
        echo "Attention : theme.txt attend background/background.png, mais seul un" >&2
        echo ".jpg/.jpeg a ete trouve. GRUB refuse souvent les JPEG au boot" >&2
        echo "(module absent ou JPEG progressif). Convertis-le :" >&2
        echo "  convert $SRC_DIR/background/background.jpg $SRC_DIR/background/background.png" >&2
        echo "puis relance ce script." >&2
    else
        echo "Attention : $DEST_DIR/background/background.png introuvable." >&2
    fi
fi

# --- 6. Mettre a jour /etc/default/grub ---
DEFAULT_GRUB=/etc/default/grub
BACKUP="$DEFAULT_GRUB.bak.$(date +%Y%m%d%H%M%S)"
cp "$DEFAULT_GRUB" "$BACKUP"
echo "Sauvegarde de $DEFAULT_GRUB -> $BACKUP"

THEME_LINE="GRUB_THEME=\"$DEST_DIR/theme.txt\""
if grep -q '^GRUB_THEME=' "$DEFAULT_GRUB"; then
    sed -i "s|^GRUB_THEME=.*|$THEME_LINE|" "$DEFAULT_GRUB"
else
    echo "$THEME_LINE" >> "$DEFAULT_GRUB"
fi
echo "GRUB_THEME configure : $DEST_DIR/theme.txt"

# --- 7. Regenerer grub.cfg (nom de commande variable selon la distro) ---
if command -v update-grub >/dev/null 2>&1; then
    update-grub
elif command -v grub2-mkconfig >/dev/null 2>&1; then
    grub2-mkconfig -o "$GRUB_DIR/grub.cfg"
elif command -v grub-mkconfig >/dev/null 2>&1; then
    grub-mkconfig -o "$GRUB_DIR/grub.cfg"
else
    echo "Attention : aucune commande grub-mkconfig/update-grub trouvee." >&2
    echo "Regenere grub.cfg manuellement." >&2
    exit 0
fi

echo ""
echo "Theme installe. Redemarre pour verifier le resultat."