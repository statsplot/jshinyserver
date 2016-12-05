## Experimental features
  Experimental features could be removed in future versions.
  
### Unsupported shiny versions
  jShiny server served the shiny `shared` files as static files, this makes the page loading speed faster. 
  The side-effect is that these files are copied to the static folder (`www`) of jShiny server, different shiny versions requires different files.
  If a new shiny version is released or you are using github development versions, these `shared` files are not available. The server will fail to start and you will find log info similar to  
```
[error]	2016-12-01T08:29:59Z	checkandPrepareShinyFiles	 Shiny version not supported: shinyversion=0.14.2.9000 
```

  Since jShiny server 0.94, it's possible to handle these files by the server, this is supposed to work for shiny version(>=0.14) from github and CRAN
  
#### Enable this feature
  Create an empty file with `extrashinyversion.support` name in the config folder. When the server starts, it will try to handle `shared` files, and you can find some lines in the log :
  
```
[info]	2016-12-01T03:00:01Z		 Server starting ============ 
...
******************
[info]	2016-12-01T03:00:02Z		Create shiny shared files for shinyversion=0.14.2.9000
[warn]	2016-12-01T03:00:02Z		Shiny version=0.14.2.9000 is not tested, some of the apps may not work properly 
******************
...
``` 

Every time the server restart, you can find the following warning:

```
...
******************
[warn]	2016-12-01T03:03:19Z		 Shiny version=0.14.2.9000 is not tested, some of the apps may not work properly 
******************
...
```


### Interactive document
Running shiny app in R markdown is enabled by default. This feature is not fully tested


