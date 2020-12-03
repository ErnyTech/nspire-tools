FROM greyltc/archlinux-aur
MAINTAINER Ernesto Castellotti <mail@ernestocastellotti.it>

RUN pacman -Syyu  --noprogressbar --needed --noconfirm && \
    su docker -c 'yay -S --noprogressbar --needed --noconfirm nspire-tools-git' && \
    pacman -D --asdeps --noconfirm $(pacman -Qqe) && \
    pacman -D --asexplicit --noconfirm base nspire-tools-git && \
    pacman -Qtdq | pacman --noconfirm -Rns - && \
    rm -rf /var/cache/pacman/pkg/*
ENTRYPOINT ["/usr/bin/nspire-tools"]
