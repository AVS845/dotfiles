#!/bin/bash
# ~/.config/hypr/launcher.sh

choice=$(echo "a  firefox
s  thunar
d  discord
f  spotify
g  gimp" | wofi --show dmenu --prompt "Launcher")

key=$(echo $choice | awk '{print $1}')

case $key in
a) firefox ;;
s) thunar ;;
d) discord ;;
f) spotify ;;
g) gimp ;;
esac
