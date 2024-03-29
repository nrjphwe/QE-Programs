#!/bin/bash
#trap 'read -p "run: $BASH_COMMAND "' DEBUG

#set -e
set -x

cd "$(dirname "$0")/.."

# We start the power_check script on boot by using systemd file
sudo cp -v QE-Programs/power_check.service /lib/systemd/system
sudo chmod u+x /lib/systemd/system/power_check.service
sudo systemctl daemon-reload
sudo systemctl enable power_check.service
sudo systemctl start power_check.service
systemctl status power_check.service

# We start the wind script on boot by using systemd file
sudo cp -v QE-Programs/wind.service /lib/systemd/system
sudo chmod u+x /lib/systemd/system/wind.service
sudo systemctl daemon-reload
sudo systemctl enable wind.service
sudo systemctl start wind.service
systemctl status wind.service

# We start the wmg script on boot by using systemd file
sudo cp -v QE-Programs/wmg.service /lib/systemd/system
sudo chmod u+x /lib/systemd/system/wmg.service
sudo systemctl daemon-reload
sudo systemctl enable wmg.service
sudo systemctl start wmg.service
systemctl status wmg.service

echo "=> Installing power check php files at /var/www/html/...\n"
sudo cp -v QE-Programs/w3.css /var/www/html
sudo chmod -R 755 /var/www/html/
sudo chown -R www-data:www-data /var/www/html

echo "=> setup SQL-Mariadb:...\n"
sudo apt -y install mariadb-server mariadb-client
sudo mysql_secure_installation
echo " === Now some manual steps, copy the lines and paste into mysql                  ==="
echo " === after sudo mysql -u root >> then                                               ==="
echo " === UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE User = 'root'; ==="
echo " === create user pi@localhost identified by "password";                          ==="
echo " === grant all privileges on regattastart.* TO pi@localhost;                     ==="
echo " === FLUSH PRIVILEGES;                                                           ==="
echo " === now comes mysql -u root                                                           ==="
sudo mysql -u root

echo "now comes: sudo systemctl stop mariadb"
sudo systemctl stop mariadb
#sudo mysqld_safe --skip-grant-tables --skip-networking &
#sudo systemctl start mysql.service
#sudo systemctl start mariadb

echo "python integration to MYSQL"
sudo pip3 install mariadb
sudo apt install python3-mysql.connector
sudo apt-get install phpmyadmin -y
sudo systemctl start mysql.service
sleep 5
systemctl status mariadb.service

# import/add sql data to db
=======
mysql -h localhost -u pi -p < QE-Programs/mysql.txt

# install Grafana
sudo apt-get install -y adduser libfontconfig1
# for raspberry Pi 3
wget https://dl.grafana.com/oss/release/grafana_7.4.1_armhf.deb
sudo dpkg -i grafana_7.4.1_armhf.deb

# for raspberry pi Zero
#wget https://dl.grafana.com/oss/release/grafana-rpi_7.4.1_armhf.deb
#sudo dpkg -i grafana-rpi_7.4.1_armhf.deb

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable grafana-server
### You can start grafana-server by executing
sudo /bin/systemctl start grafana-server
systemctl status grafana-server

echo "=> setup for ADS1115 ...\n"
sudo apt-get -y install python3-pip
sudo pip3 install adafruit-circuitpython-ads1x15
