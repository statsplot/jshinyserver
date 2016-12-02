# template to generate R file to init a shiny app

## .gfilename is filename of setting file
	.gfilename <- '#g_filename#'
	
##  setlocale for LC_ALL (set before jsonlite::fromJSON) ; this value may not work on some system , see help("locales")
    .g_locale_LC_ALL <- '#g_locale_LC_ALL#'

	tryCatch(
		{
			if (.g_locale_LC_ALL != ""){
				Sys.setlocale( category = "LC_ALL", locale = .g_locale_LC_ALL )
			}
					
			library("jsonlite")	
			
			.args_str <- readLines(con = paste0(.gfilename,".input"), n = -1L, encoding = "UTF-8" )		
			.arglist <- jsonlite::fromJSON(.args_str)
				

			library("shiny")	
			options(shiny.reactlog=FALSE)
			options(shiny.trace=FALSE)
			options(shiny.autoreload=FALSE)
			options(shiny.maxRequestSize=as.integer(.arglist$maxrequestsizekb)*1024)
			options(shiny.minified=TRUE)
			
			options(shiny.sanitize.errors = identical("true", tolower(.arglist$shiny_sanitize_errors)))

			
		  .shiny_a_full_path <- paste0(.arglist$setwd,"/",.arglist$appname)
		  
		  ### -------------------
		  ### ported from shiny-server  SockJSAdapter.R 
		  
		  # Top-level bookmarking directory (for all users)
		  bookmarkStateDir <- .arglist$bookmarkstatedir # "H:/test"
		  # Name of bookmark directory for this app. Uses the basename of the path and
		  # appends a hash of the full path. So if the path is "/path/to/myApp", the
		  # result is "myApp-6fbdbedc4c99d052b538b2bfc3c96550".
		  bookmarkAppDir <- paste0(
			basename(.shiny_a_full_path), "-",
			digest::digest(.shiny_a_full_path, algo = "md5", serialize = FALSE)
		  )

		  if (!is.null(asNamespace("shiny")$shinyOptions)) {
			if (nchar(bookmarkStateDir) > 0) {
			  shiny::shinyOptions(
				save.interface = function(id, callback) {
				  username <- Sys.info()[["effective_user"]]
				  dirname <- file.path(bookmarkStateDir, username, bookmarkAppDir, id)
				  if (dir.exists(dirname)) {
					stop("Directory ", dirname, " already exists")
				  } else {
					dir.create(dirname, recursive = TRUE, mode = "0700")
					callback(dirname)
				  }
				},
				load.interface = function(id, callback) {
				  username <- Sys.info()[["effective_user"]]
				  dirname <- file.path(bookmarkStateDir, username, bookmarkAppDir, id)
				  if (!dir.exists(dirname)) {
					stop("Session ", id, " not found")
				  } else {
					callback(dirname)
				  }
				}
			  )
			} else {
			  shiny::shinyOptions(
				save.interface = function(id, callback) {
				  stop("This server is not configured for saving sessions to disk.")
				},
				load.interface = function(id, callback) {
				  stop("This server is not configured for saving sessions to disk.")
				}
			  )
			}
		  } 

		### -------------------

			
			# .arglist <- list()
			.arglist$pid <- Sys.getpid()
			.arglist$tempdir <- tempdir()
			
			.arglist$rversion <- paste0(R.Version()$major,".",R.Version()$minor) 			
			.arglist$shinyversion <- as.character( packageVersion("shiny") )		
			.tmpsysinfolist <- as.list(Sys.info())
			.arglist$user <- .tmpsysinfolist$user		
			.arglist$effective_user <- .tmpsysinfolist$effective_user				
			
					
			# jsonlite::toJSON(.arglist)
			
			writeLines(con = paste0(.gfilename,".pid"),text=jsonlite::toJSON(.arglist) )	
			
			if (.arglist$pandoc!=""){
				# Sys.setenv(RSTUDIO_PANDOC="F:/Program Files/RStudio/bin/pandoc")
				Sys.setenv(RSTUDIO_PANDOC=.arglist$pandoc)
			}

			if (.arglist$rmdfile==""){	
				setwd(.arglist$setwd)
				runApp(appDir =.arglist$appname ,port  = as.integer(.arglist$port) , launch.browser = FALSE ,display.mode = "normal" , workerId = .arglist$workerid ,host="127.0.0.1")		
			}else{
				
				setwd(.shiny_a_full_path)
				options(shiny.port=as.integer(.arglist$port))
				options(shiny.launch.browser=FALSE)				
#				display.mode
#				workerId
				options(shiny.host="127.0.0.1")
				rmarkdown::run(.arglist$rmdfile)
			}
			
		},
		error =  function(e){
			writeLines( con=paste0(.gfilename,".error"),text=e$message )
		}
	)
	
	
		
	
		