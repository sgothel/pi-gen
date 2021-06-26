#!/bin/sh

echo "\nZafena Connector is checking for system updates"
echo "\n\n"
sudo reboot
echo "Update starting in 5 seconds"
sleep 5
sudo killall java

sudo rm -rf update > /dev/null
mkdir -p update
cd update
wget http://labb.zafena.se:8080/ZAF101BarcodeCommunicator/deploy.tar
tar xvf deploy.tar

sudo rm -rf ../run > /dev/null
mkdir -p ../run
cd ../run

ln -s /home/pi/data data
for z in ../update/*.jar; do unzip -o $z; done
for z in ../update/lib/*.jar; do unzip -o $z; done
rm -r update
echo "\n\n"
echo "Restarting system"
echo "\n"
sleep 5
sudo reboot
