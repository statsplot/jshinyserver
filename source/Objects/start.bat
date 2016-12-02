rem cd /d "F:/path/to/server"

if not exist logs md logs 
if not exist pid md pid 

IF EXIST jre ( jre\bin\java.exe -Dfile.encoding=UTF-8 -jar server.jar >> logs\server_cmd.log 2>&1 ) ELSE ( java -Dfile.encoding=UTF-8 -jar server.jar >> logs\server_cmd.log 2>&1 )
