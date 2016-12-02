## Production deployment
### Environment  
Only tested with X64 platforms
Java version: Oracle 8u91/8u92 or higher.
It's developed and tested with Windows 7. It's supposed to work with:
* Mac OS X
* Debian 7
* Debian 8
* Ubuntu 14.04 lts
* Ubuntu 16.04 lts
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
The server will update the `www/servertimestamp.html` every three seconds when it’s running correctly. You can run a cron task to check server health. When the server fail to update the file, server should be restarted.

```
# test on Ubuntu 14.04lts
crontab -e
* * * * * /bin/sh /opt/shiny/server/healthcheck.sh /opt/shiny/server 
```
You can also check server health with http GET requests to `http://{ip/domain}:{port}/servertimestamp.html`

