sudo pacman -S mesa lib32-mesa mesa-utils lib32-mesa-utils vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader linux-firmware intel-media-driver libva libva-utils intel-compute-runtime level-zero-loader vulkan-tools gamemode lib32-gamemode ffmpeg gst-libav clinfo intel-oneapi-toolkit sof-firmware pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber intel-ucode bluez bluez-utils brightnessctl

#sudo pacman -S tlp
#sudo cp ~/Hyprland-Dracula-Mint-Dotfiles/Dotfiles/tlp.conf /etc/tlp.conf
#sudo systemctl enable tlp.service

sudo pacman -S power-profiles-daemon
sudo systemctl enable power-profiles-daemon

sudo systemctl enable bluetooth.service
