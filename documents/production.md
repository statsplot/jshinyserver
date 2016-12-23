## Production deployment and troubleshooting


### Environment 
Only tested with latest Firefox and Chrome browsers.  
Java version: Oracle 8u91/8u92 or higher.  
It's developed and tested with Windows 7. It's supposed to work with:
* Mac OS 10.9
* Debian 7
* Debian 8
* Ubuntu 14.04 LTS
* Ubuntu 16.04 LTS
* CentOS 6.8
* CentOS 7.2
* Windows 7
* Windows server 2012 R2

Recommended OS: Ubuntu 14.04 LTS, Ubuntu 16.04 LTS, Windows 7 and Windows server 2012 R2.  


Note 
* Need root privilege to run with port below 1024 with unix-like OS
* Not tested with OpenJDK yet


### Configuration
When servers run at low free memory or high system load, they will be less stable and the performance will be reduced.  

You should at least preserve enough physical memory, set threshold of free memory/cpu usage in config files. You may see a `server is too busy` page when the threshold exceeded. This can prevent jShiny server from been killed by OS.   



### Health check
The server will update the `www/servertimestamp.html` every 3 seconds when it’s running correctly. In certain circumstances 10 or 20sec delays are expected, depends on server load and host infrastructure.   
You can run a cron job to check server health. When the server fail to update the file, server should be restarted.

```
# test on Ubuntu 14.04lts
crontab -e
* * * * * /bin/sh /opt/shiny/server/healthcheck.sh /opt/shiny/server 
```
You can also check server health with http GET requests to `http://{ip/domain}:{port}/servertimestamp.html`


### Security
All the file in `www` folder can be accessed by clients by default. Sensitive files should NOT be included in this folder.
  
  - **SSL**  
B4J HTTP server (Jetty) supports SSL [B4J Server SSL], this feature will not be added soon.   
Recommend to run this server behind a reverse proxy(ex Nginx) which handles the SSL.  

  - **Run as non-root user**  
You can run jShiny server as root or non-root user, and shiny apps run in R instances owned by the same user.  

It's a good practice to run it as a non-root user, but this may cause permission issues when manipulating files/folders or executing external tasks.   
 
Add a user `ruser`(in `ruser` group).  
```
useradd ruser && mkdir /home/ruser && chown -R ruser:ruser /home/ruser
```
In Ubuntu/Debian systems, add `ruser` to `staff` group. This will grante `ruser` write privileges to `/usr/local/lib/R/site.library` without the use of `sudo`   
```
addgroup ruser staff
```


When running as a non-root user `ruser`, make sure `ruser` has privileges to access jShiny server folders/files, tmp folders (TmpDir in server log) or any related files/folders.   
```
## change owner to ruser
INS_PATH=/opt/shiny
TmpDir=/tmp/rshiny
sudo chown -R ruser:ruser ${INS_PATH}
## if TmpDir exists
sudo chown -R ruser:ruser ${TmpDir}
```
A reverse proxy can be used to forward requests from ports below 1024 to jShiny server.  



### Deploy with docker   
  - **non-root user inside container**  
By default, docker daemon starts container with root(superuser). Superuser/non-root inside a container don't get all the [Linux capabilities] as superuser in the host. Most of the time it's safe to run with superuser.  

It's a good practice to run as non-root (the same as running in the host). When starting a container, [specify non-root user] by   
```
docker run -u ruser:ruser ...
```
In the host the user `ruser`(in `ruser` group) should exist. A corresponding  user `ruser`(in `ruser` group) is created in Dockerfile. See comments in Dockerfile for more information.      


  - **Set Linux capabilities**  
[Linux capabilities] provide fine-grained control, drop all capabilities except those needed.  

  - **containers inside VMs**   
[Docker] containers(like OpenVZ,LXC) are not virtual machines(VMs), they share kernel with the host. If untrusted users can control containers (or run arbitrary code), it's recommended to run docker containers inside VMs.   

[Read more about docker security]    


### Troubleshooting

  - **Server fail to start**  
You have to check server log `server_cmd.log` and `server_output_{date time}.log` if the server fail to start. Check any lines start with [Error]

  - **Unicode characters are not displayed correctly**  
You need to check if the OS and R support unicode characters. Typically you need to install language and font packages, and set environment variables.  
A shiny app contains unicode characters, the file format should be UTF-8(without BOM).  
A shiny app folder name contains unicode characters may also cause issues.  
You can run shiny app from R(command line) manually, to see if it works.  

  - **Shiny app with customized index page is not displayed properly**   
If a customized index page ({appname}/www/index.html) is used instead of ui.R, the shiny.js script should exactly be :   
`<script src="shared/shiny.min.js"></script>` or `<script src="shared/shiny.js"></script>`    
It's the case for the demo app in RStudio Github repo `008-html` (`08_html` in shiny package)   
	
  - **Customized resources are not loaded**  
The URL patthern is `http://{ip}:{port}/shiny/{appname}/index.html` which is different from RStudio offical shiny server `http://{ip}:{port}/{appname}/`   
If other resources(js/css/png) locate in `{appname}/www/` folder, make sure to refer them as a relative path to the `index.html`    


#### Common steps
If a shiny app doesn’t work, follow next steps:   
1) Check the following logs:  
`logs/app_{appname}.log`  
`logs/server_cmd.log`  
`logs/server_output_{date time}.log`  

2) If no information can be found in app/server logs, you should set loglevel=debug and shiny_sanitize_errors = false(for shiny version >=0.14).  
Restart the server and run the app. Check `r_stdout.log`/`r_stdout.log`.   
See the detail in **loglevel** section of configuration document.  

3) Run this shiny app from R(command line) manually on the host where the server is running, to see if it works.  
```
library("shiny")
# set working directory to the shinyapp folder, which shiny app folder(ex shinyappname) is in   
setwd("/opt/shiny/server/shinyapp/")
# run shiny app, port number is 9999
runApp(appDir ="shinyappname" ,port=9999,launch.browser = FALSE ,display.mode = "normal" ,host="0.0.0.0")
```
When running inside a docker container, you need to make the port 9999 mapped to an external port
```
# map port 9999 to internal 9999
docker run -d  -p 8888:8888 -p 9999:9999 --name ss jshinyserver
# get the command line inside the container
docker exec -ti ss /bin/bash
# run R code
# press CTRL+P then CTRL+Q to exit 
```
If no error or exception are displayed, test with browser `http://{ip}:9999/`. If it works but not in the jShiny server mode, create an issue for help.

4) If you still can't get it work, create an issue with information which helps to reproduce this issue:   
a  App logs  `logs/app_{appname}.log`    
b  Server logs  `logs/server_cmd.log` or `logs/server_output_{date time}.log`   
c  Shiny app source code if possible   
d  If any other app is not working, attach related files.   




[B4J Server SSL]: https://www.b4x.com/android/forum/threads/server-ssl-connections.40130/#content
[Docker]: https://www.docker.com/
[Linux capabilities]:https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities
[specify non-root user]: https://docs.docker.com/engine/reference/run/#/user
[Read more about docker security]:https://docs.docker.com/engine/security/
