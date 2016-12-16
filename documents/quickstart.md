## Quick start

### Prerequisites
Install R and shiny package
```
# R code
## install current version
install.packages("shiny", repos='http://cran.us.r-project.org')

## install older version
packageurl <- "https://cran.r-project.org/src/contrib/Archive/shiny/shiny_0.14.tar.gz"
install.packages(packageurl, repos=NULL, type="source")

# check Shiny version 
library("shiny")
packageVersion("shiny")
```
Note that only shiny versions (CRAN) 0.12.0 - 0.14.2 are supported by jShiny server V0.94  
If you are using other shiny versions from github or CRAN (>=0.14), see this [Experimental feature]

#### Install Oracle Java 8 (8u40+) 
 Verify if Java is installed and version 
```
   java -version
```   
If proper Java version is missing, download Java 8 [JRE](https://www.java.com/en/download/manual.jsp) or JDK  ,and install and verify again.

Ubuntu and Debian users can use this [PPA](http://www.webupd8.org/2014/03/how-to-install-oracle-java-8-in-debian.html) to download and install Java 8(JDK which contains JRE)  

You can download releases: https://github.com/statsplot/jshinyserver/releases or the latest (dev): https://github.com/statsplot/jshinyserver/archive/master.zip. The zip and tar.gz files contain the source codes and compiled server files (`source/Objects folder`). These server files can be used directly (Linux/Mac/Windows)  

 * [Windows](#windows)
 * [Linux/Mac](#linuxmac)

### Windows

Download the file and move it into a folder(e.g. `D:\shiny`), extract the file. All the server files are in the folder `D:\shiny\{version}\source\Objects`.  
You can move all the server files to the target directory (e.g. `D:\shiny\server`)  

#### Config

Go to the config folder, open `system_win.conf` with **plain** text editor(e.g., ultraedit, notepad++ ). You need to set rbin .  
Note : File separator should be `/`  
```
#----- rbin [required] absolute path of R bin; 
rbin = F:/Program Files/R/R-3.2.3/bin/x64/R.exe
...
```  
#### Start the server
Open the server folder. Double click `start.bat`. You will see a new command line window. If any error, the window will exit.  
You have to check log `server_cmd.log` or `server_output_{date time}.log` if the server fail to start.  

#### Check if the server is running  
Now start a web browser and point it to http://{ip}:{port}/index.html {ip} is the host ip , {port} is the server port  
If web browser is on the same host, the default url should be http://127.0.0.1:8888/index.html  

#### Stop the server
Close the command line Windows.  
Or double click stop.bat (It will also stop the running R instances started by the server.).

### Linux/Mac
Install with script: https://github.com/statsplot/jshinyserver/blob/master/ins_jshinyserver.sh  

Or [Download], and install:  
Download the file and move it into a folder(e.g. /opt/shiny/download), extract the file. All the server files are in the folder `/opt/shiny/download/{version}/source/Objects`.  
You can move all the server files to the target directory (e.g. `/opt/shiny/server`) or create a soft link for this folder.  
```
ln -s  /opt/shiny/download/{version}/source/Objects /opt/shiny/server 
```

#### Config

Find absolute path of R bin. 
```
  which R
```

`/usr/bin/R` is the default value, if your path is not the same as this one, you need to edit `system_linux.conf` or `system_mac.conf`  in the config folder with plain text editor. You need to set rbin.
```
INS_PATH=/opt/shiny
linux: nano ${INS_PATH}/server/config/system_linux.conf
mac: nano ${INS_PATH}/server/config/system_mac.conf 
  
  #----- rbin  absolute path of R bin
  rbin = /usr/bin/R
  ...
```
#### Start the server

Open a new terminal. 
```
INS_PATH=/opt/shiny
# first argument should be the absolute path to the server folder,  if not provided default value (`/opt/shiny/server`) will be used
/bin/sh ${INS_PATH}/server/start.sh ${INS_PATH}/server
```
You have to check server log `server_cmd.log` or `server_output_{date time}.log` if the server fail to start.
```
INS_PATH=/opt/shiny
cd ${INS_PATH}/server/logs
tail server_cmd.log
tail server_output_{date time}.log
```


#### Check if the server is running
Now start a web browser and point it to http://{ip}:{port}/index.html {ip} is the host ip , {port} is the server port  
If web browser is on the same host, the default url should be http://127.0.0.1:8888/index.html

#### Stop the server
```
INS_PATH=/opt/shiny
# first argument should be the absolute path to the server folder,  if not provided default value (/opt/shiny/server) will be used
/bin/sh ${INS_PATH}/server/stop.sh ${INS_PATH}/server
```
It will also stop the running R instances started by the server.




[Experimental feature]: betafeatures.md#unsupported-shiny-versions
[Download]: ../../../releases
