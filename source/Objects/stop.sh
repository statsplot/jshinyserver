#!/bin/sh
# unix format file ANSI
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

## stop r instances
if [ -f "../jre/bin/java" ]; then
  ../jre/bin/java -Dfile.encoding=UTF-8 -jar server.jar "stopr" >> logs/server_stop.log 2>&1
elif [ -f "/opt/jre/bin/java" ]; then
  /opt/jre/bin/java -Dfile.encoding=UTF-8 -jar server.jar "stopr" >> logs/server_stop.log 2>&1
else
  java -Dfile.encoding=UTF-8 -jar server.jar "stopr" >> logs/server_stop.log 2>&1
fi

## stop the server
kill -9 `cat pid/server.pid`
## kill all child processes
pkill -P `cat pid/server.pid` R
## del server.pid
rm pid/server.pid
## remove tmp files
# ...