#!/usr/bin/env bash

##############################
#run as:                     #
#sudo bash ubuntu_setup.sh   #
##############################

#functions
CHECK_SHA256SUM () {
	local SHA256_DOWNLOAD=$(sha256sum $1)
	echo "$SHA256_DOWNLOAD"
	}


REBOOT=".reboot" #hidden file to mark if system has been rebooted

if [[ ! -f "$REBOOT" ]]; 
then
	echo "Updating system"
	apt update
	apt upgrade -y
	touch $REBOOT
	echo "Rebooting system in 5 seconds (CTRL + C to abort)"
	sleep 5
	reboot
else
	echo "Installing neofetch"
	apt install neofetch -y
	
	echo "Installing gnome-tweaks-tool"
	apt install gnome-tweaks -y
	
	echo "Installing Timeshift"
	apt install timeshift
	
	echo "Installing R"
	add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran35/"
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
	apt update
	apt install r-base
	
	echo "Installing R packages"
	for PACKAGE in tidyverse reshape2 caret BiocManager
	do
		sudo -u $USER R -e "install.packages('$PACKAGE',repos='http://cran.rstudio.com/')"
	done
	
	echo "Installing RStudio"
	URL="https://download1.rstudio.org/electron/jammy/amd64/rstudio-2022.12.0-353-amd64.deb"
	FILE=$(echo $URL | awk -F "/" '{print $NF}')
	sudo -u $USER wget $URL
	SHA256="8bc3f84dd3ad701e43bc4fac0a5c24066c8e08a9345821cceb012514be242221"
	SHA256_DOWNLOAD=$(CHECK_SHA256SUM $FILE)
	while [[ SHA256 != SHA256_DOWNLOAD ]]:
	do	
		sudo -u $USER wget $URL
		SHA256_DOWNLOAD=$(CHECK_SHA256SUM $FILE)
	done
	dpkg -i $FILE
	rm $FILE
	
fi




