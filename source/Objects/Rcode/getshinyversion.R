# R cod to get shiny version and full path to shared folder

## .gfilename is (full path) of input/output file (without ext)
	.gfilename <- '#g_filename#'
#	.gfilename <- 'H:/test/genshinyversion'

##  setlocale for LC_ALL (set before jsonlite::fromJSON) ; this value may not work on some system , see help("locales")
    .g_locale_LC_ALL <- '#g_locale_LC_ALL#'
	
	tryCatch(
		{
			if (.g_locale_LC_ALL != ""){
				Sys.setlocale( category = "LC_ALL", locale = .g_locale_LC_ALL )
			}		
			library("jsonlite")	
			library("shiny")
			.arglist <- list()
				
			.arglist$rversion <- paste0(R.Version()$major,".",R.Version()$minor) 			
			.arglist$shinyversion <- as.character( packageVersion("shiny") )		
			.arglist$shinyshared <- system.file("www/shared/", package = "shiny", lib.loc = NULL, mustWork = FALSE) 
			.arglist$getlocale <-  Sys.getlocale()
			
			writeLines(con = paste0(.gfilename,".json"),text=jsonlite::toJSON(.arglist) )	
			
		},
		error =  function(e){
			writeLines( con=paste0(.gfilename,".error"),text=e$message )
		}
	)
	
	
		
	
		