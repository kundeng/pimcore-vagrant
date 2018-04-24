#!/usr/bin/env bash

apt-get update
apt-get install -y apache2
if ! [ -L /var/www ]; then
  rm -rf /var/www
  ln -fs /vagrant /var/www
fi

apt-get install -y php
apt-get install -y php-zip
apt-get install -y composer

apt-get install -y debconf-utils

# Mysql create tmp password and reset to empty root password later
# Pimcore initial setup will only work (with this script) with an empty root password on mysql
debconf-set-selections <<< "mysql-server mysql-server/root_password password tmp"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password tmp"
apt-get install -y mysql-server
mysqladmin -u root -p'tmp' password ''

# Pimcore Reqs
apt-get install -y php-simplexml
apt-get install -y php-bz2 
apt-get install -y php-dom
apt-get install -y php-gd
apt-get install -y php-mbstring
apt-get install -y php-mysqli
apt-get install -y php-pdo
apt-get install -y php-xml
apt-get install -y php-curl
apt-get install -y php-intl


# Create web folder
mkdir /web
mkdir /web/dev
cp -R /vagrant/projects/* /web/dev/

# Delete default site enabled
rm -f /etc/apache2/sites-enabled/*
cp /vagrant/apache_hosts/* /etc/apache2/sites-available/
sudo a2ensite pimdev.conf

service apache2 reload

# PHP 7 Fix - not executing
sudo a2enmod rewrite
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php7.0-fpm
sudo service apache2 restart

# Download and install pimcore
composer create-project pimcore/pimcore /web/dev/pimdev
cd /web/dev/pimdev
composer dumpautoload -o
cd /


#CREATE DATABASE pimdev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
mysql -u root -e "CREATE DATABASE pimdev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"


# Set www-data Permissions
chown www-data:www-data -R /web/dev
chmod 777 -R /web/dev/

# Setup Pimcore per Browser with
# db: localhost, user: root, pw: none