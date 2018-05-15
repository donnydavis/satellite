#!/bin/bash
#Set this value to y if you have already setup your exports
export skipinquisition=n

if [[ $skipinquisition =~ ^[Nn]$ ]]
then
  read -p "Skip questions and use export variables? (y/n)" skipinquisition
fi
if [[ $skipinquisition =~ ^[Nn]$ ]]
then
  read -p "RHN Username:" name
  read -s -p "RHN password (doesn't echo):" password ; echo
  read -p "Subscritpion pool id:" pool_id
  read -p "What is your Org Name:" org
  read -p "What is your Location:" location
  read -p "What admin username would you like for Satellite:" satuser
  read -s -p "What admin password would you like for Satellite(doesn't echo):" satpasswd ; echo
  read -p "Which interface are you using for Satellite:" interface
  read -p "What is your Satellite Hostname:" sathost
  read -p "Is this the first time you are setting up your Satellite? (y/n)" initalize
  read -p "Do you want to setup Satellite? (y/n)" satinstall
  read -p "Do you want to initalize an export? (y/n)" initexport
fi
########################################################
# Enter these values if you want to skip the questions #
########################################################
if [[ $skipinquisition =~ ^[Yy]$ ]]
then
  export name=rhn_user_name
  export password=rhn_password
  export pool_id=rhn_pool_id
  export org=cyber
  export location=connected
  export satuser=admin
  export satpasswd=admin
  export interface=eth0
  export sathost=satellite.lab.local
  export initalize=y
  export satinstall=y
  export initexport=y
fi
if [[ $initalize =~ ^[Yy]$ ]]
then
  echo "##########################################################"
  echo "# Setting Up Your Subscriptions and installing Satellite #"
  echo "##########################################################"
  hostnamectl set-hostname $sathost
  subscription-manager register --username=$name --password=$password
  subscription-manager attach --pool $pool_id
  subscription-manager release --unset
  subscription-manager repos --disable "*"
  subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-server-rhscl-7-rpms --enable=rhel-7-server-satellite-6.3-rpms
  yum clean all
  yum -y update
  yum -y install satellite
  reboot
fi

if [[ $satinstall =~ ^[Yy]$ ]]
then
  echo "#########################################"
  echo "# Configuring Satellite for your system #"
  echo "#########################################"
  echo "$(ip a |grep $interface |grep inet|awk '{print $2}'|cut -d "/" -f1)  $(hostname) $(hostname --short)" >> /etc/hosts
  cat /etc/hosts |grep $(hostname)
  satellite-installer --scenario satellite --foreman-initial-organization "$org" --foreman-initial-location "$location" --foreman-admin-username $satuser --foreman-admin-password $satpasswd --foreman-proxy-dns-managed=false --foreman-proxy-dhcp-managed=false
  firewall-cmd --add-port="53/udp" --add-port="53/tcp" --add-port="67/udp" --add-port="69/udp" --add-port="80/tcp"  --add-port="443/tcp" --add-port="5000/tcp" --add-port="5647/tcp" --add-port="8000/tcp" --add-port="8140/tcp" --add-port="9090/tcp"
  firewall-cmd --permanent --add-port="53/udp" --add-port="53/tcp" --add-port="67/udp" --add-port="69/udp" --add-port="80/tcp"  --add-port="443/tcp" --add-port="5000/tcp" --add-port="5647/tcp" --add-port="8000/tcp" --add-port="8140/tcp" --add-port="9090/tcp"
fi

if [[ $initexport =~ ^[Yy]$ ]]
then
  echo "########################################################"
  echo "# Creating Directories and initializing for the export #"
  echo "########################################################"
  mkdir -p /var/www/html/pub/exports/
  chcon --verbose --recursive --reference /var/lib/pulp/katello-export/ /var/www/html/pub/exports/
  chmod --verbose --recursive --reference /var/lib/pulp/katello-export/ /var/www/html/pub/exports/
  chown --verbose --recursive --reference /var/lib/pulp/katello-export/ /var/www/html/pub/exports/
  hammer settings set --name pulp_export_destination --value /var/www/html/pub/exports/
fi
