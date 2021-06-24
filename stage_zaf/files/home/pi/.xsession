rm .xsession-errors
ln -s /dev/null .xsession-errors

cd /home/pi/
sh run.sh 2>&1 > system.log
#lxterm -geometry 128x35+10+10 -e /home/pi/update.sh
st -geometry 128x35+10+10

