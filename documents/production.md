## Production deployment and troubleshooting


### Environment 
Only tested with latest Firefox and Chrome browsers.  
Java version: Oracle 8u91/8u92 or higher.  
It's developed and tested with Windows 7. It's supposed to work with:
* Mac OS X
* Debian 7
* Debian 8
* Ubuntu 14.04 lts
* Ubuntu 16.04 lts
* CentOS 6.8
* CentOS 7.2
* Windows 7
* Windows server 2012 R2

Recommended OS: Ubuntu 14.04 lts, Ubuntu 16.04 lts, Windows 7 and Windows server 2012 R2.  


Note 
* Need root privilege to run with port below 1024 with unix-like OS
* Not tested with OpenJDK yet


### Configuration
When the server run at low free memory or high system load, server will be less stable and the performance will be reduced

You should at least preserve 20% physical memory, set threshold of free memory/cpu usage in config files. You may see a `server is too busy` page when the threshold exceeded.



### Health check
The server will update the `www/servertimestamp.html` every three seconds when it’s running correctly. You can run a cron job to check server health. When the server fail to update the file, server should be restarted.

```
# test on Ubuntu 14.04lts
crontab -e
* * * * * /bin/sh /opt/shiny/server/healthcheck.sh /opt/shiny/server 
```
You can also check server health with http GET requests to `http://{ip/domain}:{port}/servertimestamp.html`




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
If no information can be found in app/server logs, you should set loglevel=debug and shiny_sanitize_errors = false(for shiny version >=0.14), restart the server and run the app. Check `r_stdout.log`/`r_stdout.log`. See the detail in **loglevel** section of configuration document.  




