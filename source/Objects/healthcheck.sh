#!/bin/sh
# unix format file ANSI
# test on Ubuntu 14.04lts

defdir=$1
if [ "$#" -lt 1 ]; then
  defdir=/opt/shiny/server
fi
cd ${defdir}

if [ -f pid/server.pid ]; then
    echo ""
else
	echo ""
	#echo "pid file not exist"
	exit 0
fi
# check if  last modification of the file is less than 55 seconds
if [ $(( $(date +%s) - $(date +%s -r www/servertimestamp.html) )) -le 55 ]; then
	echo ""
else
    echo "$(date +%s) Health check failed. Restart server now" >> logs/server_restart.log
	/bin/sh restart.sh $1
fi
