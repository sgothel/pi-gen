#!/bin/sh
echo "\n"
# sudo /etc/rc.local &
# Change work directory
cd /home/pi
# load background
xloadimage -fullscreen -onroot /home/pi/splash.png &
# setup sound
sudo amixer sset Master 100% 
#sudo modprobe snd_pcm_oss
sudo amixer sset PCM 100%
# disable pointer
unclutter -idle 5 -jitter 1 -root -noevents &
# disable screensaver
xset s 0 &
xset dpms 0 0 0 &
# Sync clock on startup
sudo ntpdate-debian &
# Launch Zafena main application
cd /home/pi/run
#sudo java --illegal-access=warn -Dsun.java2d.xrender=false zaf101openrdbarcodecommunicator.ZAF101BarcodeCommunicator
glxgears
