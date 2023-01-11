#!/usr/bin/env bash

NVIDEA="FALSE"
NONFREE="FALSE"
MAX_PARALLEL_DOWNLOADS=5
MODE="dark"

#argument parser
usage() {
	echo "Installation of software and DE tweaks for Fedora"
	echo "Usage: $0 [-n or --nvidea] [-r or --non-free] [-p <INT> or --max-par-down <INT>] [-m dark,light or --mode dark,light]"
	echo "-n or --nvidea: Install Nvidea drivers (non-free)"
	echo "-r or --non-free: Enable non-free RPM fusion repository"
	echo "-p <INT> or --max-par-down <INT>: Set maximum parallel downloads for dnf (default is 5)"
	echo "-m dark,light or --mode dark,light: Enable dark or light mode (default is dark)"
	exit 1
}

while getopts "rnp:m:?h" c
do
  case $c in
    -n|--nvidea) 
        NVIDEA="TRUE" 
        ;;
	-r|--non-free) 
	    NONFREE="TRUE" 
	    ;;
	-p|--max-par-down) 
		MAX_PARALLEL_DOWNLOADS=$OPTARG
		;;
	-m|--mode) 
		MAX_PARALLEL_DOWNLOADS=$OPTARG
		;;
    h|?) usage 
        ;;
  esac
done


REBOOT=".reboot" #hidden file to mark if system has been rebooted

if [[ ! -f "$REBOOT" ]]; 
then
	echo "Reconfiguring dnf to make it faster"
	sudo echo fastestmirror=True >> /etc/dnf/dnf.conf
	sudo echo max_parallel_downloads="${MAX_PARALLEL_DOWNLOADS}" >> /etc/dnf/dnf.conf
	sudo echo defaultyes=True >> /etc/dnf/dnf.conf
	
	echo "Updating system"
	sudo dnf update -y
	touch .reboot
	echo "Rebooting system in 5 seconds (CTRL + C to abort)"
	sleep 5
	sudo reboot
else
	echo "Enabling ${MODE} mode"
	gsettings set org.genome.desktop.interface color-scheme 'prefer-${MODE}'
	
	echo "Reconfiguring dnf"
	sudo echo fastestmirror=True >> /etc/dnf/dnf.conf
	sudo echo max_parallel_downloads=${MAX_PARALLEL_DOWNLOADS} >> /etc/dnf/dnf.conf
	sudo echo defaultyes=True >> /etc/dnf/dnf.conf
	
	echo "Enabling RPM free fusion repository"
	sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y
	if [[ NONFREE == "TRUE" ]];
	then
		echo "Enabling RPM non-free fusion repository"
		sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
	fi
	
	echo "Enabling Flathub"
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	
	echo "Installing gnome-tweak-tools"
	sudo dnf install gnome-tweak-tool -y
	
	echo "Installing gedit flatpak"
	flatpak install flathub org.gnome.gedit
	
	#echo "Configuring gedit"
	
	echo "Installing Timeshift"
	sudo dnf install timeshift -y
	
	echo "Installing R"
	sudo dnf install R -y
	
	echo "Installing pip"
	sudo dnf python3-pip -y
	
	echo "Installing Spyder IDE"
	pip install spyder
	
	echo "Installing wallpaper packs"
	sudo dnf install f34-backgrounds-gnome f33-backgrounds-gnome f33-backgrounds-gnome verne-backgrounds-gnome -y
	
	echo "Changing login screen background"
	IMAGE="~/Pictures/haven1-i_see_stars-01.png"
	wget https://fedoramagazine.org/wp-content/uploads/2019/02/haven1-i_see_stars-01.png -o $IMAGE
	sudo dnf copr enable zirix/gdm-wallpaper
	sudo dnf install gdm-wallpaper -y
	sudo set-gdm-wallpaper $IMAGE
	
	echo "Installing Vivaldi browser"
	sudo dnf config-manager --add-repo https://repo.vivaldi.com/archive/vivaldi-fedora.repo
	sudo dnf install vivaldi-stable -y
	
	echo "Installing gnome-extensions-app"
	dnf install chrome-gnome-shell gnome-extensions-app -y
	
	echo "Installing Gnome extensions"
	git clone https://github.com/brunelli/gnome-shell-extension-installer.git
	INSTALLER="gnome-shell-extension-installer/gnome-shell-extension-installer"
	chmod +x $INSTALLER
	
	$INSTALLER --yes 307 #dash-to-dock
	$INSTALLER --yes 19 #User-Themes
	$INSTALLER --yes 517 #Caffeine
	$INSTALLER --yes 779 #clipboard-indicator
	$INSTALLER --yes 4099 #no-overview
	$INSTALLER --yes 1465 #desktop-icons
	$INSTALLER --yes 277 #impatience
	$INSTALLER --yes 3193 #blur-my-shell
	
	if [[ NVIDEA == "TRUE" ]];
	then
		echo "Installing Nvidea drivers"
		sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora36/x86_64/cuda-fedora36.repo
		sudo dnf install kernel-headers kernel-devel tar bzip2 make automake gcc gcc-c++ pciutils elfutils-libelf-devel libglvnd-opengl libglvnd-glx libglvnd-devel acpid pkgconfig dkms -y
	fi
	
fi






