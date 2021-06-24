#!/bin/sh

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
sudo rm -r ../update
sudo sync
