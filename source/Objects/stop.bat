rem cd /d "F:/path/to/server"
rem kill server and child processes by server.pid
for /f "delims=" %%i in (pid\server.pid) do (
	taskkill /f /t /pid %%i
    goto a
)
:a

rem del server.pid
del pid\server.pid
