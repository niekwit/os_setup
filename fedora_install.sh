#!/usr/bin/env bash

##############################
#run as:                     #
#sudo bash fedora_install.sh #
##############################

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

#defaults values
NVIDIA="FALSE"
NONFREE="FALSE"
MAX_PARALLEL_DOWNLOADS=5
MODE="dark"

#argument parser
usage() {
	echo "Installation of software and DE tweaks for Fedora"
	echo "Usage: $0 [-n or --nvidia] [-r or --non-free] [-p <INT> or --max-par-down <INT>] [-m dark,light or --mode dark,light]"
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
        NVIDIA="TRUE" 
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
	echo "Updating system"
	dnf update -y
	touch $REBOOT
	echo "Rebooting system in 5 seconds (CTRL + C to abort)"
	sleep 5
	reboot
else
	echo "Enabling ${MODE} mode"
	sudo -u $USER gsettings set org.genome.desktop.interface color-scheme 'prefer-${MODE}'
	
	echo "Reconfiguring dnf"
	cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.copy #create backup copy of original file
	echo "#added by ${USER}:" >> /etc/dnf/dnf.conf
	echo fastestmirror=True >> /etc/dnf/dnf.conf
	echo max_parallel_downloads=${MAX_PARALLEL_DOWNLOADS} >> /etc/dnf/dnf.conf
	echo defaultyes=True >> /etc/dnf/dnf.conf
	
	echo "Enabling free RPM fusion repository"
	dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y
	if [[ NONFREE == "TRUE" ]];
	then
		echo "Enabling non-free RPM fusion repository"
		sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
	fi
	
	echo "Enabling Flathub"
	sudo -u $USER flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	
	echo "Installing gnome-tweak-tools"
	dnf install gnome-tweak-tool -y
	
	echo "Enabling windows minimise/maximise"
	sudo -u $USER gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
	
	echo "Installing gedit flatpak"
	sudo -u $USER flatpak install flathub org.gnome.gedit
	
	#echo "Configuring gedit"
	
	echo "Installing VirtualBox"
	dnf install @development-tools -y
	dnf install kernel-devel kernel-headers dkms qt5-qtx11extras elfutils-libelf-devel zlib-devel  -y
	wget -q https://www.virtualbox.org/download/oracle_vbox.asc
	rpm --import oracle_vbox.asc
	cp "{$SCRIPT_DIR}/virtualbox.repo" /etc/yum.repos.d/
	dnf install VirtualBox-7.0
	
	echo "Installing Timeshift"
	dnf install timeshift -y
	
	echo "Installing R"
	dnf install R -y
	
	echo "Installing R packages"
	sudo -u $USER Rscript -e "install.packages(c("tidyverse","reshape2","caret","BiocManager"))"
	
	echo "Installing RStudio"
	URL="https://download1.rstudio.org/electron/rhel8/x86_64/rstudio-2022.12.0-353-x86_64.rpm"
	sudo -u $USER wget $URL
	FILE=$(echo $URL | awk -F "/" '{print $NF}')
	rpm -i $FILE
	rm $FILE
	
	echo "Installing pip"
	sudo dnf install python3-pip -y
	
	echo "Installing Spyder IDE"
	sudo -u $USER pip install spyder
	
	echo "Installing more Python packages"
	sudo -u $USER pip install numpy pandas matplotlib seaborn pysam yaml pybedtools clint gseapy tqdm
	
	echo "Installing wallpaper packs"
	dnf install f34-backgrounds-gnome f33-backgrounds-gnome f26-backgrounds-gnome verne-backgrounds-gnome -y
	
	echo "Changing login screen background"
	IMAGE="haven1-i_see_stars-01.png"
	wget https://fedoramagazine.org/wp-content/uploads/2019/02/haven1-i_see_stars-01.png
	dnf copr enable zirix/gdm-wallpaper
	dnf install gdm-wallpaper -y
	set-gdm-wallpaper $IMAGE
	
	echo "Installing Vivaldi browser"
	dnf config-manager --add-repo https://repo.vivaldi.com/archive/vivaldi-fedora.repo
	dnf install vivaldi-stable -y
	
	echo "Installing gnome-extensions-app"
	dnf install chrome-gnome-shell gnome-extensions-app -y
	
	echo "Installing Gnome extensions"
	sudo -u $USER git clone https://github.com/brunelli/gnome-shell-extension-installer.git
	INSTALLER="gnome-shell-extension-installer/gnome-shell-extension-installer"
	sudo -u $USER chmod +x $INSTALLER
	
	sudo -u $USER $INSTALLER --yes 307 #dash-to-dock
	sudo -u $USER $INSTALLER --yes 19 #User-Themes
	sudo -u $USER $INSTALLER --yes 517 #Caffeine
	sudo -u $USER $INSTALLER --yes 779 #clipboard-indicator
	sudo -u $USER $INSTALLER --yes 4099 #no-overview
	sudo -u $USER $INSTALLER --yes 1465 #desktop-icons
	sudo -u $USER $INSTALLER --yes 277 #impatience
	sudo -u $USER $INSTALLER --yes 3193 #blur-my-shell
	
	if [[ NVIDIA == "TRUE" ]];
	then
		echo "Installing Nvidea drivers"
		dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/fedora36/x86_64/cuda-fedora36.repo
		dnf install kernel-headers kernel-devel tar bzip2 make automake gcc gcc-c++ pciutils elfutils-libelf-devel libglvnd-opengl libglvnd-glx libglvnd-devel acpid pkgconfig dkms -y
	fi
fi




