#!/bin/bash
tty -s; if [ $? -ne 0 ]; then gnome-terminal -e "$0"; exit; fi

#
echo "Installing required packages from YUM/APT"
echo
# IF FEDORA
if [ -e "/etc/redhat-release" ]; then
    echo "Enter root password:"
    read -s pass
    echo
    echo $pass|su -c "yum -y install ruby-gtk2 wget rubygem-gtk2 ruby-gnome2"
    echo    
    echo "Copying dinaIP to /usr/local/dinaip ..."
    # check for older version
    id=$(id -u)
    if [ -d "/usr/local/dinaip/" ]; then
        echo $pass|su -c "rm -rf /usr/local/dinaip"
    fi
    # install essential files
    echo $pass|su -c "mkdir /usr/local/dinaip"
    echo $pass|su -c "chown -R $id /usr/local/dinaip"
    cp dinaip /usr/local/dinaip/
    chmod +x /usr/local/dinaip/dinaip
    cp -r i18n /usr/local/dinaip/
    cp cron.rb /usr/local/dinaip/
    cp functions.rb /usr/local/dinaip/
    cp windows.rb /usr/local/dinaip/
    cp dinaip.png /usr/local/dinaip/
    # install launcher
    if [ -e "/usr/share/applications/dinaip.desktop" ]; then
        echo $pass|su -c "rm -rf /usr/share/applications/dinaip.desktop"
    fi
	    echo $pass|su -c "cp dinaip.desktop /usr/share/applications/"
fi
# IF UBUNTU
if [ -e "/etc/debian_version" ]; then
    cat /etc/apt/sources.list|grep universe|grep deb|grep "#"|sed 's/#//g' | sudo tee -a /etc/apt/sources.list
    sudo apt-get update -y
    sudo apt-get install -y ruby-gnome2 wget rubygems ruby-full
    echo
    echo "Copying dinaIP to /usr/local/dinaip ..."
    # check for older version
    id=$(id -u)
    if [ -d "/usr/local/dinaip/" ]; then
        sudo rm -rf /usr/local/dinaip
    fi
    # install essential files
    sudo mkdir /usr/local/dinaip
    sudo chown -R $id /usr/local/dinaip
    cp dinaip /usr/local/dinaip/
    chmod +x /usr/local/dinaip/dinaip
    cp -r i18n /usr/local/dinaip/
    cp cron.rb /usr/local/dinaip/
    cp functions.rb /usr/local/dinaip/
    cp windows.rb /usr/local/dinaip/
    cp dinaip.png /usr/local/dinaip/
    # install launcher
    if [ -e "/usr/share/applications/dinaip.desktop" ]; then
        sudo rm -rf /usr/share/applications/dinaip.desktop
    fi
    sudo cp dinaip.desktop /usr/share/applications/
fi
# install config
if [ -d ~/.dinaip ]; then
    rm -rf ~/.dinaip
fi
mkdir ~/.dinaip
cp config.yml ~/.dinaip
mkdir -p ~/.config/autostart
cp dinaip.desktop ~/.config/autostart
echo
echo "Install complete. You can close this terminal."
sleep 60

