#!/bin/bash

# Проверка, установлен ли whiptail
if ! command -v whiptail &> /dev/null; then

    echo "Installing libnewt..."
    echo " "

    sudo pacman -Sy --noconfirm libnewt
    
    if [ $? -eq 0 ]; then
        echo " "
        echo "libnewt was installed successfully"
        echo " "
    else
        echo " "
        echo "Error installing libnewt"
        exit 1
    fi
else
    echo "libnewt is installed"
    echo " "
fi

sleep 1

CHOICE=$(whiptail --title "Install" --menu " " 15 80 2 \
"Full" "     Install the full software package." \
"Minimal" "     Install the minimal software package." 3>&1 1>&2 2>&3)

if [ $? -eq 0 ]; then

    echo "Installation of the base software packages."
    echo " "

    #Installation of the AUR helper
    git clone https://aur.archlinux.org/yay.git ~/yay
    cd ~/yay
    makepkg -si

    # Instalation of the base software packages
    sudo pacman -Sy --noconfirm wayland xorg xorg-server xorg-xwayland hyprland xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk kitty alacritty neovim firefox pavucontrol pamixer nemo grim slurp swappy rofi rofi-calc rofi-emoji waybar mako ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-firacode-nerd noto-fonts-emoji otf-font-awesome file-roller hyprpicker hypridle hyprlock btop wlsunset geoclue2 python3 swayimg swaybg nodejs npm eza fish fuse2 wl-clipboard mc udiskie vlc mpv unzip flatpak fastfetch zenity gsimplecal flameshot mission-center yad qt5ct qt5 qt5-graphicaleffects qt5-quickcontrols2 qt5-svg qt6ct sddm playerctl xed stow hyprpolkitagent gzip unrar bzip2 xz 7zip ffmpeg dav1d foot

    yay -S --noconfirm swayosd bibata-cursor-theme-bin pwvucontrol vscodium-bin

    case $CHOICE in
        Full)
            echo " "
            echo "Installation of the additional packages."
            echo " "

            # Instalation of the additional software packages

            sudo pacman -Sy --noconfirm syncthing feishin telegram-desktop discord chromium wine winetricks kolourpaint vivaldi krita torbrowser-launcher audacity kdiskmark gamescope mangohud qemu-full obsidian helvum libreoffice-still kdenlive steam qbittorrent

            yay -S --noconfirm elyprismlauncher-bin viber adwsteamgtk betterdiscordctl zoom onlyoffice-bin portproton

            flatpak install flathub com.obsproject.Studio com.github.wwmm.easyeffects -y

            echo " "
            ;;
        Minimal)
            echo " "
            ;;
    esac

    echo "Software installation is complete"
    echo "Creating some directories"
    echo " "

    # Creating some directories
    mkdir -p ~/.config
    mkdir -p ~/.config/VSCodium/User
    mkdir -p ~/.config/fish
    mkdir -p ~/.config/BetterDiscord
    mkdir -p ~/.config/micro
    mkdir -p ~/.config/nvim

    mkdir -p ~/.themes

    mkdir -p ~/.vscode-oss/extensions

    mkdir -p ~/.mozilla/firefox/n0eij4j3.default-release
    mkdir -p ~/.config/vivaldi

    mkdir -p ~/.local/share/ElyPrismLauncher/themes

    
    sleep 1
    echo "Some directories was created"
    echo " "

    # SDDM

    echo "Configuring SDDM"
    echo " "

    sudo cp -rf ~/Hyprland-Dracula-Mint-Dotfiles/Dotfiles/SDDM/sugar-dark /usr/share/sddm/themes/
    sudo cp ~/Hyprland-Dracula-Mint-Dotfiles/Dotfiles/SDDM/sddm.conf /etc/

    sleep 1
    echo "SDDM was configured"
    echo " "

    # Firefox polices

    echo "Configuring firefox polices"
    echo " "

    sudo cp -rf ~/Hyprland-Dracula-Mint-Dotfiles/Dotfiles/firefox /etc/firefox

    sleep 1
    echo "Firefox polices was configured"
    echo " "

    # Dotfiles

    echo "Set up dotfiles"
    echo " "

    cp -rf ~/Hyprland-Dracula-Mint-Dotfiles/Dotfiles/.dotfiles ~/
    chmod +x ~/.dotfiles/.config/rofi/network-manager.sh
    chmod +x ~/.dotfiles/.config/rofi/rofi-power-menu.sh
    chmod +x ~/.dotfiles/.config/hypr/rofi-power-menu-alt-f4.sh
    chmod +x ~/.dotfiles/.config/hypr/show_layout_popup.sh

    stow -d ~/.dotfiles/ .

    sleep 1
    echo "Dotfiles was set up"
    echo " "

    # Other Settings

    echo "Configuring system"
    echo " "

    gsettings set org.gnome.desktop.interface gtk-theme Nordic-darker-standard-buttons
    gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 12'
    gsettings set org.gnome.desktop.wm.preferences button-layout :
    gsettings set org.cinnamon.desktop.default-applications.terminal exec "foot"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

    flatpak override --user --filesystem=~/.themes
    flatpak override --user --filesystem=~/.icons
    flatpak override --user --filesystem=xdg-config/gtk-3.0:ro
    flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
    
    xdg-settings set default-web-browser firefox.desktop
    xdg-mime default firefox.desktop x-scheme-handler/http
    xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
    xdg-mime default firefox.desktop x-scheme-handler/https
    xdg-mime default firefox.desktop text/html
    
    systemctl --user enable hyprpolkitagent.service
    
    case $CHOICE in
        Full)
            systemctl --user enable syncthing.service
            ;;
        Minimal)
            echo ""
            ;;
    esac

    sleep 1
    echo "System was configured"
    echo " "

    echo "Hyprland was successfully installed"

else
    echo "Installation cancelled"
fi
