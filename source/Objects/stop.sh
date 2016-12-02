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
## stop the server
kill -9 `cat pid/server.pid`
## kill all child processes
pkill -P `cat pid/server.pid` R
## del server.pid
rm pid/server.pid
## remove tmp files
# ...