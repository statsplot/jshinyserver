#!/bin/sh
# unix format file ANSI
defdir=$1
if [ "$#" -lt 1 ]; then
  defdir=/opt/shiny/server
fi
cd ${defdir}

mkdir -p logs
mkdir -p pid

if [ -f "../jre/bin/java" ]; then
#  chmod +x ../jre/bin/java
  ../jre/bin/java -version || echo "../jre/bin/java not executeable"
  nohup ../jre/bin/java -Dfile.encoding=UTF-8 -jar server.jar >> logs/server_cmd.log 2>&1 &
elif [ -f "/opt/jre/bin/java" ]; then
#  chmod +x /opt/jre/bin/java
  /opt/jre/bin/java -version || echo "/opt/jre/bin/java not executeable"
  nohup /opt/jre/bin/java -Dfile.encoding=UTF-8 -jar server.jar >> logs/server_cmd.log 2>&1 &
else
  java -version || echo "Java not found"
  nohup java -Dfile.encoding=UTF-8 -jar server.jar >> logs/server_cmd.log 2>&1 &
fi

# wait for 7sec then check is the server is running
sleep 7
PID_SRV=`cat pid/server.pid`
if [ -n "$(ps -p ${PID_SRV} -o pid=)" ] > /dev/null
then
   echo "[Info] jShiny server is running. PID is ${PID_SRV}"
else
   echo "[Error] jShiny server fail to start. Please check the logs"   
fi

