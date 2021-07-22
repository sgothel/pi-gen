# rm .xsession-errors
# ln -s /dev/null .xsession-errors

#while true ; do
    cd /home/pi/
    sh run.sh > data/system.log 2>&1 
    #lxterm -geometry 128x35+10+10 -e /home/pi/update.sh
    st -g 128x35
    #dwm
#done

