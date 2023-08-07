#!/bin/bash

#ejecutar dentro del repositorio para su instalacion automatica


make

sudo make install

mkdir -p ~/.spotify-adblock && cp target/release/libspotifyadblock.so ~/.spotify-adblock/spotify-adblock.so

mkdir -p ~/.config/spotify-adblock && cp config.toml ~/.config/spotify-adblock

flatpak override --user --filesystem="~/.spotify-adblock/spotify-adblock.so" --filesystem="~/.config/spotify-adblock/config.toml" com.spotify.Client


