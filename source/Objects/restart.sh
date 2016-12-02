#!/bin/sh
# unix format file ANSI
defdir=$1
if [ "$#" -lt 1 ]; then
  defdir=/opt/shiny/server
fi
cd ${defdir}

sh stop.sh ${defdir}
sh start.sh ${defdir}