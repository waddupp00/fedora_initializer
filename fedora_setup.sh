#!/bin/bash
# SPDX-License-Identifier: WTFPL

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Make the script exit at the first error
set -e
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT

# Install extra repos and codecs, then update
dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y
dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
dnf group update core -y
dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y
dnf install lame\* --exclude=lame-devel -y
dnf group upgrade --with-optional Multimedia -y
dnf update -y

# Same thing but with flatpaks
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org
flatpak update

# Install vscode from Microsoft's repo (I dont remember why I dont use flatpak but there must be a good reason)
rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
dnf check-update
dnf install code -y

# Install GNOME extensions and tweaks
dnf install gnome-extensions-app -y
dnf install gnome-tweaks -y

# Install the GNOME extensions whose uuids are listed in the following array
array=( no-overview@fthx dash-to-panel@jderose9.github.com  appindicatorsupport@rgcjonas.gmail.com arcmenu@arcmenu.com )
do
    VERSION_TAG=$(curl -Lfs "https://extensions.gnome.org/extension-query/?search=${i}" | jq '.extensions[0] | .shell_version_map | map(.pk) | max')
    wget -O ${i}.zip "https://extensions.gnome.org/download-extension/${i}.shell-extension.zip?version_tag=$VERSION_TAG"
    gnome-extensions install --force ${EXTENSION_ID}.zip
    if ! gnome-extensions list | grep --quiet ${i}; then
        busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions InstallRemoteExtension s ${i}
    fi
    gnome-extensions enable ${i}
    rm ${EXTENSION_ID}.zip
done

# Import arc-menu-settings into arc-menu and dash-to-panel-settings into dash-to-panel
dconf load /org/gnome/shell/extensions/arcmenu/ < arc-menu-settings
dconf load /org/gnome/shell/extensions/dash-to-panel/ < dash-to-panel-settings

# Bring back minimize and maximize on window title bars
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

# Disable the GNOME hot corner
gsettings set org.gnome.desktop.interface enable-hot-corners false

# Tell Nauilus to let us type paths in the search bar
gsettings set org.gnome.nautilus.preferences always-use-location-entry true

# Install the posy-black cursor theme and the Papirus icon theme
cp -r posy-black /usr/share/icons/
dnf install papirus-icon-theme -y

# Change the cursor theme to posy-black and the icons theme to Papirus
gsettings set org.gnome.desktop.interface cursor-theme 'posy-black'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus'

# Set GNOME to dark mode, including for GTK3 apps
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface gtk-application-prefer-dark-theme true

# Install Cascadia Fonts using dnf and set Cascadia Mono as the default monospace font with a size of 11
sudo dnf copr enable atim/cascadia-code-fonts -y && sudo dnf install cascadia-code-fonts -y
gsettings set org.gnome.desktop.interface monospace-font-name 'Cascadia Mono 11'

# Install zsh, git, and oh-my-zsh
dnf install zsh git -y
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Change the shell to zsh and set the default shell to zsh
chsh -s /bin/zsh
adduser -D -s /bin/zsh

# Move the oh-my-zsh installation to /usr/share/oh-my-zsh
sudo mv ~/.oh-my-zsh /usr/share/oh-my-zsh

# Move into the dir and copy the zshrc template to zshrc (which will be the default for users)
cd /usr/share/oh-my-zsh/
cp templates/zshrc.zsh-template zshrc

# Nab the patch file from MarcinWieczorek's AUR Package and apply to the zshrc file
wget https://aur.archlinux.org/cgit/aur.git/plain/0001-zshrc.patch\?h\=oh-my-zsh-git -O zshrc.patch && patch -p1 < zshrc.patch

# Cd into previous location
cd -

# Move the risbow theme to the oh-my-zsh themes folder
mv risbow.zsh-theme /usr/share/oh-my-zsh/themes/

# Set theme to risbow and editor to nano
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="risbow"/g' /usr/share/oh-my-zsh/zshrc
sed -i 's/EDITOR="vim"/EDITOR="nano"/g' /usr/share/oh-my-zsh/zshrc

# Create an alias "cls" to "clear" and "zshconfig" to "nano ~/.zshrc"
echo "alias cls='clear'" >> /usr/share/oh-my-zsh/zshrc
echo "alias zshconfig='nano ~/.zshrc'" >> /usr/share/oh-my-zsh/zshrc

# Clone the zsh-syntax-highlighting repo and move it to the oh-my-zsh custom plugins folder in /usr/share
git clone https://github.com/zsh-users/zsh-syntax-highlighting/ ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Enable the plugin using oh-my-zsh's plugin manager
sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting)/g' /usr/share/oh-my-zsh/zshrc

# Create hard link to the zshrc file so it creates an actual independent copy on new users
sudo ln /usr/share/oh-my-zsh/zshrc /etc/skel/.zshrc

# Move the zshrc file to the home directory for each user
for i in $(ls /home); do
    sudo ln /usr/share/oh-my-zsh/zshrc /home/$i/.zshrc
done

# We expect the following grep to fail, so let's unset the auto-exit
set +e

# Ehancing dnf. Making sure we dont spam the config file
grep "defaultyes" /etc/dnf/dnf.conf
if [[ $? -ne 0 ]]; then
    sudo echo -e "fastestmirror=True\nmax_parallel_downloads=10\ndefaultyes=True" >> /etc/dnf/dnf.conf
fi

cat << EOF
Everything has been set up. You should reboot now.
EOF

# So that we don't exit with a pointless error message
trap '' EXIT
