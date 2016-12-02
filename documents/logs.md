## Logs


All logs are in the `logs` folder.  
The default date and time format is yyyy-MM-dd HH_mm_ss (UTC+00:00)

### Http server logs
  - `b4j-yyyy_MM_dd.request.log`  
     Jetty server daily log for all web requests. They will be retained for 10 days.


### R logs
  - `r_stdout.log`/`r_stdout.log`    
     extra error/warning messages (R logs) of R session. They are used for debug. To enable this, set loglevel=debug in config file.


### App logs
  - `app_{appname}.log`   
    Log for each shiny app. If some of the apps fail to work, check the specific app_appname.log file, more information can be found in server logs .

### Server logs
  - `server_stat.log`  
    * system memory, CPU usage, and average load(Linux and Mac)
    * JVM memory and CPU
    * Shiny apps, connections and R instances
    
  - `server_appstat.log`  
Websocket connection numbers of shiny apps

  - `server_cmd.log`   
    If redirect_output = false, stderr and stdout will be redirected to this file. It's specified by the command line
```
java -jar server.jar >> logs\server_cmd.log 2>&1
```

  - `server_output_{yyyy_MM_dd_HH_mm_ss}.log`  
    If redirect_output = true, stderr and stdout will be redirected to this file. {yyyy_MM_dd_HH_mm_ss} is the date and time when the server started (UTC+00:00).

`server_cmd.log` / `server_output_{timestamp}.log`  
```
[info]	2016-12-01T03:00:01Z		 Server starting ============ 
TmpDir = D:\AppData\Local\Temp\rshiny
Time = 2016-12-01 03:00:01 UTC
Serverversion = 0.94.beta1
Java = 1.8.0_92
JavaVendor = Oracle Corporation
JavaRuntime = 1.8.0_92-b14
Processors = 4
System = Windows 7
Arch = amd64
TotalMemory = 16158
-----config loading-------
rbin = F:/Program Files/R/R-3.3.1/bin/x64/R.exe
cpulimit2 = 1
cpulimit1 = 1
client_maxidle_timeout = 300
memlimit2 = 6
app_idle_timeout = 100
memlimit1 = 5
shiny_sanitize_errors = false
formmaxsizekb = 3000
lc_all = 
pandoc = F:/Program Files/RStudio/bin/pandoc
port = 8888
redirect_output = false
wscmaxtextsizekb = 3000
loglevel = debug
htmlroot = shiny
shinyfolder = E:/b4jshinyserver/Objects/shinyapp
r_args = --vanilla
app_init_timeout = 40
wsmaxtextsizekb = 3000
-----config loaded-------
Sys.getlocale=LC_COLLATE=
******************
[info]	2016-12-01T03:00:02Z		Create shiny shared files for shinyversion=0.14.2.9000
[warn]	2016-12-01T03:00:02Z		Shiny version=0.14.2.9000 is not tested, some of the apps may not work properly 
******************
2016-12-01 11:00:02.807:INFO::main: Logging initialized @1696ms
2016-12-01 11:00:02.977:INFO:oejs.Server:main: jetty-9.3.z-SNAPSHOT
2016-12-01 11:00:03.120:INFO:oejsh.ContextHandler:main: Started o.e.j.s.ServletContextHandler@7ca48474{/,file:///E:/b4jshinyserver/Objects/www/,AVAILABLE}
2016-12-01 11:00:03.129:INFO:oejs.AbstractNCSARequestLog:main: Opened E:\b4jshinyserver\Objects\logs\b4j-2016_12_01.request.log
2016-12-01 11:00:03.351:INFO:oejs.ServerConnector:main: Started ServerConnector@39c0f4a{HTTP/1.1,[http/1.1]}{0.0.0.0:8888}
2016-12-01 11:00:03.352:INFO:oejs.Server:main: Started @2244ms
[info]	2016-12-01T03:00:03Z		 Server started ============ 

...
```
