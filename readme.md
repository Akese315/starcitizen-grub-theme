## GRUB

### Installation

Installer GRUB et les outils nécessaires :

```bash
sudo pacman -S grub efibootmgr os-prober
# Vérifier que le système est bien démarré en UEFI :
ls /sys/firmware/efi
# Installer GRUB en UEFI avec l'ESP montée sur /boot :
sudo grub-install \
    --target=x86_64-efi \
    --efi-directory=/boot \
    --bootloader-id=Archel
```

## Configuration

Dans /etc/default/grub :

```
GRUB_PRELOAD_MODULES="part_gpt png"
GRUB_THEME="/boot/grub/themes/starcitizen/theme.txt"
```

png doit être préchargé pour permettre à GRUB de charger les images PNG utilisées par le thème.
(1960x1080)

# Générer la configuration :

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg

#Vérifier que le module PNG est bien présent :

grep "insmod png" /boot/grub/grub.cfg
```

# Thème GRUB

Structure :
/boot/grub/themes/starcitizen/
├── theme.txt
├── background/
│   └── background.png
└── buttons/
    ├── item_*.png
    └── select_*.png

Dans ```theme.txt```
```
desktop-image: "background/background.png"
```

Pour espacer les entrées du menu :

```
+ boot_menu {
    item_height = 44
    item_spacing = 30
    item_padding = 14
}
```

## PNG

GRUB peut refuser certains PNG malgré une résolution et une profondeur correctes.

Pour générer un PNG RGB 24 bits compatible :

```magick input.png -alpha off -strip -depth 8 PNG24:background.png```

Puis vérifier :

```file background.png```

Format attendu :

```PNG image data, 1920 x 1080, 8-bit/color RGB, non-interlaced```
Régénération après modification

## Après toute modification de /etc/default/grub ou du thème :

sudo grub-mkconfig -o /boot/grub/grub.cfg

GRUB doit ensuite charger :

UEFI
 ↓
GRUB
 ↓
theme.txt
 ↓
Arch Linux

Pour ton futur **dual-boot Windows**, il faudra simplement adapter `grub-install` à l'emplacement de l'ESP (`/boot