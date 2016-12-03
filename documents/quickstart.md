## Quick start

### Prerequisites
Install R and shiny package
```
  # R code 
  # check Shiny version 
    library("shiny")
    packageVersion("shiny")
```
Note that only shiny versions (CRAN) 0.12.0 - 0.14.2 are supported by jShiny server V0.94  
If you are using other shiny versions from github or CRAN (>=0.14), see this [beta feature]

#### Install Oracle Java 8 (8u40+) 
 Verify if Java is installed and version 
```
   java -version
```   
If proper Java version is missing, download Java 8 [JRE](https://www.java.com/en/download/manual.jsp) or JDK  ,and install and verify again.

Ubuntu and Debian users can use this [PPA](http://www.webupd8.org/2014/03/how-to-install-oracle-java-8-in-debian.html) to download and install Java 8(JDK which contains JRE)

 * [Windows](#windows)
 * [Linux/Mac](#linuxmac)

### Windows
[Download]

#### Config
Move the downloaded file to a folder (e.g. `F:/shiny/`). Unzip the file.  
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
[Download]  or install with scripts 
```

#replace the version number 
#server is installed to /opt/shiny/server
VER="v0.94-beta.1"

DL_PATH=/opt/shiny/download/${VER}
INS_PATH=/opt/shiny
mkdir -p ${DL_PATH}
mkdir -p ${INS_PATH}

if [ -L "${INS_PATH}/server" ] ; then
    echo "Remove previous symbolic link to ${INS_PATH}/server"
	rm -rf "${INS_PATH}/server"
fi

if [ -d "${INS_PATH}/server" ]; then
	DATE=`date +%Y-%m-%d-%H-%M-%S`
	PREV_VER_PATH=/opt/shiny/previous/${DATE}
	mkdir -p ${PREV_VER_PATH}
	mv -f ${INS_PATH}/server ${PREV_VER_PATH}
	echo "Previous files are moved to ${PREV_VER_PATH}"
fi

wget -nv -O  ${DL_PATH}/${VER}-build.tar.gz https://github.com/statsplot/jshinyserver/releases/download/${VER}/${VER}-build.tar.gz

tar zxf ${DL_PATH}/${VER}-build.tar.gz -C ${DL_PATH}

ln -s  ${DL_PATH}/server ${INS_PATH}/server 

if [ -L "${INS_PATH}/server" ] ; then
    echo "jShiny server ${VER} installed to ${INS_PATH}/server"
else
	echo "Error. Fail to installed jShiny server ${VER}"
fi

# cd ${INS_PATH}/server

```


#### Config
Move the downloaded file to a folder with proper read and write permission (e.g. `/opt/shiny`). Untar the file.  
Find absolute path of R bin
```
  which R
```

Edit `system_linux.conf` or `system_mac.conf`  in the config folder with plain text editor. You need to set rbin.
```
linux: nano ${installationpath}/server/config/system_linux.conf
mac: nano ${installationpath}/server/config/system_mac.conf 
  
  #----- rbin  absolute path of R bin
  rbin = /usr/bin/R
  ...
```
#### Start the server

Open a new terminal. 
```
# first argument should be the absolute path to the server folder,  if not provided default value (`/opt/shiny/server`) will be used
/bin/sh /opt/shiny/server/start.sh /opt/shiny/server. 
```
You have to check server log `server_cmd.log` or `server_output_{date time}.log` if the server fail to start.

#### Check if the server is running
Now start a web browser and point it to http://{ip}:{port}/index.html {ip} is the host ip , {port} is the server port  
If web browser is on the same host, the default url should be http://127.0.0.1:8888/index.html

#### Stop the server
```
# first argument should be the absolute path to the server folder,  if not provided default value (/opt/shiny/server) will be used
/bin/sh /opt/shiny/server/stop.sh /opt/shiny/server
```
It will also stop the running R instances started by the server.




[beta feature]: betafeatures.md#unsupported-shiny-versions
[Download]: ../../../releases
