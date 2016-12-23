## jShiny server
  jShiny Server is an alternative shiny server. It's written in [B4J](https://b4x.com/b4j.html)  
   It's similar to the official open-source shiny server.
   
### Features   
   *  Available for Windows/Linux/Mac
   *  Serve the static files to improve page load speed
   *  Support to start new R instances for each user 

### Caveat
   *  Users need to use browsers with websocket support, no fallback to long polling. Tested with latest Firefox and Chrome.
   *  All file format should be UTF-8(without BOM) unless stated otherwise
   *  The server depends on the system time(timestamp). Adjust the time before the shiny server starts, change system time during the running period may cause unexpected results.
   *  Linux file system is case-sensitive, Windows and Mac are not. It’s recommended to use lower-case file/folder names across platforms.
   *  Shiny app (folder) names should not contain special strings `b__` and `_._`, and should not start/end with spaces. Unicode characters should work, if it's supported by the OS and R programme
   
 
 
* [Quick start] 
* [Configuration]
* [Logs]
* [Production deployment and troubleshooting]
* [Html pages and shiny app folder]
* [Experimental features]
* [Build from source]

### Download
  [Download jShiny Server]
  
### Docker
  Use the image in docker hub :  
```  
docker run -d -p 8888:8888 --name shinyserver statsplot/jshinyserver:latest  
```
  Or clone/download this repo and then build the images with
  
```bash
git clone https://github.com/statsplot/jshinyserver.git
cd jshinyserver/docker
docker build --tag {yourname}/jshinyserver .
docker run -d -p 8888:8888 --name shinyserver {yourname}/jshinyserver
```

And then visit http://127.0.0.1:8888/applist.html for the list of Shiny apps.  

Add your apps to the server with `docker -v` option. See also [Html pages and shiny app folder],

```bash
docker run -d -p 8888:8888 --name shinyserver -v {/path/to/yourapps}:/opt/shiny/server/shinyapp {yourname}/jshinyserver
## update applist.html
docker exec shinyserver touch /opt/shiny/server/config/applist.update
```

See `Deploy with docker` in [Production deployment and troubleshooting] for more details.   


### Change logs
* [Change logs] 
  
### License
   Free and open source AGPLv3
   


[Download jShiny Server]: ../../releases
[Change logs]: documents/changelogs.md

[Quick start]: documents/quickstart.md
[Configuration]: documents/configuration.md
[Logs]: documents/logs.md
[Html pages and shiny app folder]: documents/htmlpages.md
[Production deployment and troubleshooting]: documents/production.md
[Experimental features]: documents/betafeatures.md
[Build from source]: documents/build.md
