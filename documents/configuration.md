## Configuration

* [Server settings](#server-settings)
  - [system_common.conf](#system_commonconf)
  - [system_OS.conf](#system_linuxconf-system_macconf-system_winconf)  
  
* [Multiple R instances](#multiple-r-instances)

* [Troubleshooting](#troubleshooting)


### Server settings
All server settings files can be found in `config` folder Config files start with `system_` contain the server settings :

   `system_common.conf` contains the common configuration for all platforms. The other three files(linux mac and win) are OS specific.
      `system_linux.conf`
      `system_mac.conf`
      `system_win.conf`
      
When you run the server on linux, only `system_common.conf` and `system_linux.conf` will be used.

The config files are plain text in key-value format, delimiter is `=` . Any line starts with `#` is a comment line.
```
#----- this is a comment 
port = 8888 
```

#### `system_common.conf`
  - **port** 
    server port (http) linux port below 1024 need root privilege
    
  - **shinyfolder**  
    the path of shiny apps; could be relative path (to the server.jar) or absolute path. File separator should be / (including Windows)

  - **redirect_output**  
Default value is true. Possible value: true/false
You need to change the default value when run the server from B4J IDE (in release mode). Set redirect_output=false so that the log will be printed in IDE log section.
If redirect_output=true stderr and stdout will be redirected to a separated file server_output_{yyyy_MM_dd_HH_mm_ss}.log each time the server starts. 



  - **app_idle_timeout** 
time(seconds) to close a R instance after no connection to it;
min value is 40

  - **app_init_timeout**  
if a new shiny app(R instance) starts, if it doesn’t response after app_init_timeout(seconds), this R instance will be killed ;
min value is 10, max value is 50

  - **htmlroot**  
app url format : http(s)://{ip/domain}:port/{htmlroot}/{appname}/index.html; should be English letters (Not allowed: share, shared_*, download , cache , doc )

  - **client_maxidle_timeout**  
when the connection to a client(browser) is not active(no traffic) more than client_maxidle_timeout (seconds), the websocket connection to this client will be disconnected;
min value = 120

  - **wsmaxtextsizekb/wscmaxtextsizekb**  
the max size(kB) for websocket message; they should be the same most of the time; if one of the message size exceeds, the websocket connection will be closed default value = 3000

  - **formmaxsizekb**  
max size(kB) for post request to the server, e.g. upload file size, ajax request size. If the request size exceeds the request will be rejected default value = 3000

  - **cpulimit1 cpulimit2 memlimit1 memlimit2**  
Only need to set these if the system is running low on memory/cpu. OS will try to kill some processes when not enough memory is available.  
memlimit1 memlimit2 : threshold of free memory(MB)  
cpulimit1 cpulimit2 : threshold of cpu usage (percentage*100),should be a float number between 0 and 1.  
When the threshold exceeded, a `server is too busy` page will be shown.  
You may have 1 or more cpu cores, only the overall usage is counted , 0 means 0% of all cores, 0.5 means half of all cores , 1 means not to check cpu usage  
When the server run at low free memory, server performance will be reduced, you should at least preserve 20% system memory  
limit1 : threshold for starting new R process.  
limit2 : threshold for new websocket connection to existing R process  

  - **shiny_sanitize_errors**  
sanitize_errors options added in shiny 0.14. set it true to enable it. possible value: true/false

  - **loglevel**  
set loglevel=debug to save extra error/warning messages (R logs) of R session to `r_stdout.log` and `r_stdout.log` files. These messages are supposed to be logged into app/server logs. If one app doesn’t work properly and no information can be found in app/server logs, you should set loglevel=debug, restart the server, run the app and check these R logs. These logs may grow very fast, the default value is false possible value: debug/error

  - **lc_all**
Only need to set this if characters are not display properly, it’s default value is an empty string
```
Sys.setlocale( category = "LC_ALL", locale = lc_all )
```


  - **r_args**  
Only need to set this if the server is not running correctly.
A single argument to initialized R processes. You can run `R --help` in command line to find possible options
default value `r_args = --vanilla`  
```
R ${r_args} -q -e source('/path/to/script/init/shiny.R')
```




#### `system_linux.conf` `system_mac.conf` `system_win.conf`
  - **rbin**  
absolute path of R bin
Note : File separator should be `/` for Windows in config files. Example, rbin = F:/Program Files/R/R-3.2.3/bin/x64/R.exe

  - **pandoc**  
absolute path which contains pandoc files. Only need to set it when pandoc is not working properly, it’s default value is an empty string  
Example  
```
pandoc = F:/Program Files/RStudio/bin/pandoc
```




Note: The OS specific config file has higher priority. Server port of the example below is 80  
```
## system_common.conf
  port = 8888
  ...
 
## system_linux.conf
  port = 80
  ...
```



### Multiple R instances
The server start a single R instance for each shiny app by default.  
Since version 0.94, you can start a new R instances for each visitor. 
Add shiny app name to `config/r_multisession.conf` in a new line, without heading/tailing spaces. It will take effect after the server is restarted.    
```
006-tabsets
008-html
```
The shiny app can be accessed like normal ones with url like this:  
`http://{ip/domain}:{port}/shiny/001-hello/index.html`  
The page will be redirected to url with extra workerid (wakyko4rqn2u) :   
`http://{ip/domain}:{port}/shiny/001-hello/_._wakyko4rqn2u/index.html?__app__=001-hello&__w__=wakyko4rqn2u` 




### Troubleshooting

  - **Server fail to start**  
You have to check server log `server_cmd.log` and `server_output_{date time}.log` if the server fail to start. Check any lines start with [Error]

  - **Unicode characters are not displayed correctly**  
You need to check if the OS and R programme support unicode characters. Typically you need to install language and font packages, and set environment variables.  
A shiny app contains unicode characters, the file format should be UTF-8(without BOM).  
A shiny app folder contains unicode characters may also cause issues.  
You can run shiny app from R(command line) manually, to see whether it works.  

  - **Some shiny apps don't work**  
This usually happens when dependencies are not met, or R packages are not installed. 
You can run this shiny app from R(command line) manually on the host where the server is running, to see whether it works.  
If a shiny app doesn’t work, you need to check the following logs:  
`logs/app_{appname}.log`  
`logs/server_cmd.log`  
`logs/server_output_{date time}.log`  
If no information can be found in app/server logs, you should set loglevel=debug. See the detail in **loglevel** section of configuration document.








