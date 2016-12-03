rem cd /d "F:/path/to/server"
rem kill server and child processes by server.pid
for /f "delims=" %%i in (pid\server.pid) do (
	taskkill /f /t /pid %%i
    goto a
)
:a

IF EXIST jre ( jre\bin\java.exe -Dfile.encoding=UTF-8 -jar server.jar "stopr" >> logs\server_stop.log 2>&1 ) ELSE ( java -Dfile.encoding=UTF-8 -jar server.jar "stopr" >> logs\server_stop.log 2>&1 )

rem del server.pid
del pid\server.pid
