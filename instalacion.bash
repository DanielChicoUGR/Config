#!/bin/bash

# Instala las últimas actualizaciones
sudo nala upgrade --update

# Instala los paquetes necesarios
sudo nala install stacer kitty exa bat python3-pip python3-venv snapd build-essential fzf htop pandoc texlive-latex-recommended zeal libstdc++-12-dev libclang-14-dev clang-14 clang-tidy clang-format fish -y
#sudo apt install software-properties-common apt-transport-https wget -y


sudo nala autoremove -y


#sudo mkdir /usr/share/zsh-sudo
#wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh
#sudo mv sudo.plugin.zsh /usr/share/zsh-sudo/

mkdir $HOME/.repos
mkdir $HOME/.wallpapers

#setup snap
sudo mv /etc/os-release /etc/os-release-backup
sudo ln /etc/pop-os/os-release /etc/os-release


wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -

sudo add-apt-repository ppa:variety/stable
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list

sudo nala install code spotify-client variety --update -y

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh



read -p "Genere Clave de acceso github " texto



#git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.repos/powerlevel10k
git clone --depth=1 git@github.com:DanielChicoUGR/Config.git $HOME/.repos/configuraciones

#ln -s $HOME/.repos/configuraciones/zsh/.zshrc $HOME/.zshrc

#sudo ln -s /home/daniel/.repos/configuraciones/zsh/.zshrc /root/.zshrc
#sudo ln -s /home/daniel/.repos/configuraciones/zsh/.p10k.zsh.root /root/.p10k.zsh



#ln -s $HOME/.repos/configuraciones/zsh/.p10k.zsh $HOME/.p10k.zsh

ln -s $HOME/.repos/configuraciones/kitty $HOME/.config/kitty



mkdir $HOME/.appimage

wget https://github.com/obsidianmd/obsidian-releases/releases/download/v1.6.7/Obsidian-1.6.7.AppImage 

mv Obsidian-1.6.7.AppImage $HOME/.appimage/obsidian.AppImage
chmod a+x $HOME/.appimage/obsidian.AppImage

ln -s $HOME/.repos/configuraciones/desktopEntries/obsidian.desktop $HOME/.local/share/applications/obsidian.desktop

ln -s $HOME/.repos/configuraciones/desktopEntries/spotify-adblock.desktop $HOME/.local/share/applications/spotify-adblock.desktop





#Descarga jetbrains toolbox
wget https://download-cdn.jetbrains.com/toolbox/jetbrains-toolbox-1.28.1.15219.tar.gz
mv jetbrains-toolbox-1.28.1.15219.tar.gz $HOME/Descargas/toolbox.tar.gz
cd $HOME/Descargas


tar xzf toolbox.tar.gz
./jetbrains-toolbox-1.28.1.15219/jetbrains-toolbox &
cd $HOME

# $HOME/Descargas/jetbrains-toolbox-1.28.1.15219/jetbrains-toolbox &




#Descarga e instalación de opera
curl https://download3.operacdn.com/pub/opera/desktop/101.0.4843.33/linux/opera-stable_101.0.4843.33_amd64.deb --output /tmp/opera.deb
sudo apt install /tmp/opera.deb -y
rm $HOME/Descargas/opera.deb


# Configuracion fuente terminal
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Iosevka.zip
sudo unzip Iosevka.zip -d /usr/share/fonts/iosevka/
rm Iosevka.zip

#Descarga del Vault de Obsidian
git clone git@github.com:DanielChicoUGR/docu.git $HOME/Documentos/documentacion

git clone git@github.com:DanielChicoUGR/ideas_projects.git $HOME/Documentos/ideas

#Instalacion y generacion de auto-cpufreq
git clone https://github.com/AdnanHodzic/auto-cpufreq.git $HOME/.repos/auto-cpufreq
chmod a+x $HOME/.repos/auto-cpufreq/auto-cpufreq-installer
sudo /bin/bash $HOME/.repos/auto-cpufreq/auto-cpufreq-installer

#instalacion flutter 
sudo snap install flutter --classic

#modificación terminal por defecto
sudo update-alternatives --config x-terminal-emulator


#Customize nvim
#  git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1

# Configura zsh como tu shell de inicio de sesion
sudo chsh -s /bin/fish
# sudo chsh -s /bin/fish


#Nvim Config
# git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim
# git clone https://github.com/DanielChicoUGR/nvim_astro_files.git ~/.config/nvim/lua/user



#instalar adblock spotify
source $HOME/.cargo/env


git clone https://github.com/abba23/spotify-adblock.git $HOME/.repos/spotify-adblock

make --directory=$HOME/.repos/spotify-adblock/
sudo make install --directory=/home/daniel/.repos/spotify-adblock/ 

#Install cmake tools
/bin/bash -c "$(curl -fsSL https://github.com/Kitware/CMake/releases/download/v3.27.6/cmake-3.27.6-linux-x86_64.sh)"

ln -s $HOME/.local/share/cmake-3.27.6-linux-x86_64/bin/cmake $HOME/.local/bin/cmake

ln -s $HOME/.local/share/cmake-3.27.6-linux-x86_64/bin/ccmake $HOME/.local/bin/ccmake

ln -s $HOME/.local/share/cmake-3.27.6-linux-x86_64/bin/cpack $HOME/.local/bin/cpack

ln -s $HOME/.local/share/cmake-3.27.6-linux-x86_64/bin/ctest $HOME/.local/bin/ctest



# instalacion homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/daniel/.profile

# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

brew install neovim starship


#git clone https://github.com/AstroNvim/AstroNvim $HOME/.config/nvim

#git clone git@github.com:DanielChicoUGR/nvim_astro_files.git $HOME/.config/nvim/lua/user

# instalacion qtile
#pip install qtile xcffib cmake-format

#sudo nala install -y xserver-xorg python3-xcffib libpangocairo-1.0-0 python3-cairocffi python3-cairocffi

#git clone git@github.com:elParaguayo/qtile-extras $HOME/.repos/qtile-extras
#cd $HOME/.repos/qtile-extras
#pip install .

cd $HOME
# sudo wget https://github.com/qtile/qtile/blob/master/resources/qtile.desktop -O

# sudo ln -s $HOME/.repos/configuraciones/desktopEntries/qtile.desktop /usr/share/xsessions/qtile.desktop

#ln -s /home/daniel/.repos/configuraciones/qtile /home/daniel/.config/qtile/
#ln -s /home/daniel/.repos/configuraciones/nitrogen /home/daniel/.config/nitrogen/
#ln -s /home/daniel/.repos/configuraciones/picom /home/daniel/.config/picom/
#ln -s /home/daniel/.repos/configuraciones/rofi /home/daniel/.config/rofi/
#ln -s /home/daniel/.repos/configuraciones/conky /home/daniel/.config/conky/
ln -s /home/daniel/.repos/configuraciones/fish /home/daniel/.config/fish/
ln -s /home/daniel/.repos/configuraciones/starship.toml /home/daniel/.config/starship.toml


# DMScripts

# git clone https://gitlab.com/dwt1/dmscripts.git $HOME/.repos/dmscripts
# sudo make clean build --directory=$HOME/.repos/dmscripts
# sudo make install --directory=$HOME/.repos/dmscripts

# sudo $HOME/.repos/configuraciones/qtile-rofi-keibindings/install.sh


cd $HOME


#sudo nala install -y libgl1-mesa-dev libpulse0 libpulse-dev libxext6 libxext-dev libxrender-dev libxcomposite-dev liblua5.3-dev liblua5.3 lua-lgi lua-filesystem libobs0 libobs-dev meson build-essential gcc 

#git clone https://github.com/jarcode-foss/glava $HOME/.repos/glava
#cd $HOME/.repos/glava
#meson build --prefix /usr
#ninja -C build
#sudo ninja -C build install

cd $HOME
