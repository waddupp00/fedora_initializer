# fedora_initializer

**DISCLAIMER : THIS SCRIPT IS PROVIDED AS IS. BARELY ANY TESTING HAS BEEN PERFORMED AND THE SAFEGUARDS ARE MINIMAL. IT MIGHT BE BROKEN, IT MIGHT BREAK YOUR COMPUTER, IT MIGHT BREAK THE SPACE-TIME CONTINUUM. I DECLINE ANY RESPONSIBILITY FOR ANY DAMAGE CAUSED BY THIS SCRIPT. YOU HAVE BEEN WARNED**

A stupid script I use to initialize a fresh Fedora install to my personnal tastes. It requires an internet connection to work.
If you do not understand what this script does, you should not use it.

## Installed stuff
 - zsh
   - oh-my-zsh with hyphen-insensitive completion
   - zsh-syntax-highlighting,
   - my zsh theme ['risbow'](https://github.com/waddupp00/risbow)
   - these aliases : `cls="clear"` and `zshconfig="nano ~/.zshrc"`
 - dash-to-panel with a Win11 style taskbar but the start button kept on the left (see dash-to-panel-settings)
 - the ['Posy']() cursor themes and 'Papirus' icon theme
 - VSCode
 - Cascadia fonts
 - gnome-tweaks and gnome-extensions-app
 
## Performed actions
 - make nano the default editor for all
 - 10 parallel downloads, fastest_mirror and defaultyes for dnf
 - set Papirus and Posy-black as the system-wide default
 - make zsh and co the system-wide default
 - make Cascadia Mono the default monospace font
 - disable gnome's hot corner
 - make the apps' title bar follow a classic Windows layout ('appmenu:minimize,maximize,close')
 - tell nautilus to always allow us to type paths in the path bar (duh)

## Enabled repos
 - the flathub and fedoraproject flatpak repos
 - the rpm fusion free and non-free repos
 - the VSCode rpm repos

