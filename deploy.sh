# Wayland
wl-paste > deploy.sh

# X11
xclip -selection clipboard -o > deploy.sh

# controleer daarna
head -n 5 deploy.sh
wc -l deploy.sh