Type=Class
Version=4.7
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'Handler class
Sub Class_Globals

	Private appname As String ' should be FULL app name

	Private appFolderName As String ' the shiny app folder name ( url-decoded  )
	Private WorkerIdinURL As String

	
	Private mResp As ServletResponse
	Private timerwaitappinit As Timer
	Private timerwaitTimeoutDt As Long = 8000
	Private timerwaitExpireDt As Long
	Private isShinyRunning As Boolean = False
	
	Private requestType As String
	Private requestMethod As String 
	

	Private enableETag As Boolean	
	Private previousHash As String	
	Private newHash As String	

	
	Private shiny_ver As String
		


End Sub

Public Sub Initialize
	
End Sub




Sub Handle(req As ServletRequest, resp As ServletResponse)
	 
    'important: need to call req.InputStream before calling req.GetParameter. Otherwise the complete stream will be internally read as the server looks for the parameter in the request body. This will not happen if we first call req.InputStream.
	Dim req_InputStream As InputStream = req.InputStream	
	
	Dim FULLURI As String = req.FullRequestURI
	
	Dim nTH_SLASH_APPFN As Int = 4  'APP folder name starts at 4th(begins with 1) slash(/) 
	Dim nTH_SLASH_WID As Int = nTH_SLASH_APPFN + 1  'WID starts at 5th (when exists)
	
	Dim FULLURI_WID_REMOVED As String = comFunMod.URL_Remove_WID(FULLURI,nTH_SLASH_WID)
	
'            fulluri http://127.0.0.1:8888/shiny/012-datatables(0)/{_._workerid}(1)/datatables-binding-0.1(2)/datatables.js?_k=v&__w__=xyz&__app__=123#ref
'fulluri_WID_REMOVED http://127.0.0.1:8888/shiny/012-datatables(0)/datatables-binding-0.1/datatables.js?_k=v&__w__=xyz&__app__=123#ref
	
	
	Dim REQUEST_URI As String = req.RequestURI          
	'/shiny/012-datatables(0)/{_._workerid}(1)/datatables-binding-0.1(2)/datatables.js  (no queryString)
	

'reject any request like /shiny & /shiny/ which should not be handled by this thread
	Dim startPath As String = "/" & Main.htmlRootPath & "/"   '
	If REQUEST_URI.StartsWith(startPath) And REQUEST_URI.Length>startPath.Length  Then		
	Else		
		resp.SendRedirect("/404.html")
		Return
	End If
	
'http method post/get LowerCase	
	requestMethod = req.Method
	requestMethod = requestMethod.ToLowerCase

'reject any requests other than GET and POST
	If requestMethod <> "get" And requestMethod <> "post" Then
		resp.Status = 405
		Return	
	End If	
		
'reject any get request url end with .js.map / .css.map
	If requestMethod = "get" Then
		If REQUEST_URI.EndsWith(".js.map") Or REQUEST_URI.EndsWith(".css.map") Then
			resp.Status = 404
			Return
		End If		
	End If	
	
'remove Main.htmlRootPath(/shiny/) in url
	Dim Request_tmpURL As String = REQUEST_URI.SubString((Main.htmlRootPath.Length+2))
	'url = 012-datatables(0)/datatables-binding-0.1(1)/datatables.js  (without query string)

'parse the url(not url decoded) by "/"
	Dim urlpathList As List =CltUtils.String2List_mod(Request_tmpURL,"/", False , False,False)
	
	Dim urlpathList_Size As Int = urlpathList.Size
	
	'/{appfoldername}/index.html is the rquest for index page (need to start a R session when needed)
	'/{appfoldername}/{_._workerid}(0)/index.html	
	WorkerIdinURL = ""	
	If urlpathList_Size>=2 Then	
		Dim tmpstr2 As String = urlpathList.Get(1)
		tmpstr2 = comFunMod.URL_Decode(tmpstr2)
		tmpstr2 = comFunMod.getWorkerId(tmpstr2)
		If tmpstr2 <> "" Then
			WorkerIdinURL = tmpstr2
			
			'remove {_._workerid} in the list
			urlpathList.RemoveAt(1)
			urlpathList_Size = urlpathList.Size
		End If
	End If

'	'appFolderName is app folder name (url decoded) {appFolderName} = 012-datatables	
	appFolderName = urlpathList.Get(0)
	appFolderName = comFunMod.URL_Decode(appFolderName)
	
'	'workerid (url decoded) param, {randnumberwokerid}  not exist: empty ""
	'WorkerIdinURL

	Dim redURL As String
	redURL = comFunMod.URL_getRed(appFolderName,WorkerIdinURL)

'	'appname is full appname(url decoded).  {appFolderName}{_._workerid} = 012-datatables{_._}{randnumberwokerid} 
	appname = comFunMod.getFullAppname(appFolderName,WorkerIdinURL)
	 
	
	'Buildin app are a special shiny app (used in demo.html or somewhere else in the jShiny Server) 
	'Buildin app names start with special string
	Dim isBuildinAppB As Boolean = comFunMod.isBuildinApp(appname)
	
	'any app contained in conf/MultiSessionApp run in a new R session
	Dim isNewRSession As Boolean = appM.isStartNewRInstance(appFolderName)	
	

	'/shiny/{appname}/index.html is the rquest for index page (need to start a R session when needed)
	Dim isIndex As Boolean = False
	If ( (urlpathList_Size = 2) And ( urlpathList.Get(1) = "index.html" )) Then
		isIndex = True
	End If

	'subapp in rmd files (beta)
	'http://localhost:8888/shiny/026-shiny-inline_subapp/appafd043c42f0ae7013759ab507ea1c8ee/?w=&__subapp__=1 
	' redirect to 
	'http://localhost:8888/shiny/026-shiny-inline_subapp/appafd043c42f0ae7013759ab507ea1c8ee/?w=&__subapp__=1&__app__=026-shiny-inline_subapp&__w__=&__subws__=%2Fappafd043c42f0ae7013759ab507ea1c8ee%2F&__subsearch__=w%3D%26__subapp__%3D1
	Dim isRmdSubapp As Boolean = False 
	If FULLURI.Contains("__subapp__") Then
		Dim match1 As Matcher = Regex.Matcher("\?.*__subapp__=(\d)" , FULLURI ) 
		If match1.Find Then
			isRmdSubapp = True	
		End If 	
	End If
	If req.GetParameter("__subws__")<>"" Then
		isRmdSubapp = True
	End If
	
	
	Dim apptype As String
	If isBuildinAppB And isIndex Then
		apptype="buildin"  'index.html with workerid /shiny/001-hello/_._demo_001-hello/index.html?__w__=demo_001-hello
	Else If isNewRSession And isIndex Then		
		apptype="newsession"  'index.html  with/without workerid
	Else
		apptype="common" 'app which is not demo and newsession (index.html or others)
	End If



' for url/server bookmark; if the url contains workerid; redirect the url(without workerid) 
'http://127.0.0.1:8888/shiny/{appFoldername}_._{workerid}/index.html?_inputs_&n=191 
'http://127.0.0.1:8888/shiny/{appFoldername}_._{workerid}/index.html?_state_id_=f63a29c29959f3aa
'redirect to
'http://127.0.0.1:8888/shiny/{appFoldername}/index.html?_state_id_=f63a29c29959f3aa
	Dim BookmarkQueryString As String 
	BookmarkQueryString = comFunMod.URL_getBookmarkQS(FULLURI)
	Dim BmQs As String =""
	If BookmarkQueryString<>"" Then
		BmQs = "?"&BookmarkQueryString
	End If



    'return 404 page if this request (index) is apptype="common" but paramWorkerid is not empty	
	If isIndex And apptype="common" Then
		If WorkerIdinURL<>"" Then
			resp.SendError(404,"/404.html")
			Return				
		End If
	End If
	
	If isIndex Then
		If comFunMod.URL_checkIndex(appFolderName,WorkerIdinURL,req,isNewRSession) = False Then
			resp.SendError(404,"/404.html")
			Return
		End If
	End If

	
	
	If apptype="newsession" Then
		If WorkerIdinURL<>"" Then
			' check fullappname(R session) with wid Is running(validated)
			If appM.TSappnameRunningStatus(appname) <> appM.ST_RUNNING Then
				'r session not running redirect to the empty page (to start a new R session)
				'[bug fixed] appname -> appFolderName
				resp.SendRedirect($"/${Main.htmlRootPath}/${comFunMod.URL_Encode(appFolderName)}/index.html${BmQs}"$)								
				Return
			Else
				'when it's running ,make sure the exsiting r session keep running
				appM.TSappnameUpdate(appname)
			End If
		Else
			appname = comFunMod.genFullAppName(appFolderName)
			WorkerIdinURL = comFunMod.getAppWorkerID( appname )
			redURL = comFunMod.URL_getRed(appFolderName,WorkerIdinURL)							
		End If
	End If	
	
' not apply to Buildin app (index and other requests)
If isBuildinAppB=False Then
	If apptype="newsession" Or apptype="common" Then
		If appM.inFolderAppnameTsMap.ContainsKey(appFolderName) = False Then
			resp.SendError(404,"/404.html")
			timerwaitappinit = Null
			Return		
		End If		
	End If	
End If




' if server failed to launch a R process in last 60sec, show appinitfailed	page
	If appM.TSisAppInitFailed(appname) = True Then
		writeErrorPage("appinitfailed.html",resp)
		Return 
	End If
	
'check if system is too busy
Try
	Dim ServerBusy As Int = appM.TScheckServerBusy
Catch
    
End Try

	timerwaitTimeoutDt = appM.msAppInitTimeout
	 

'index.html : start new R session and wait to continue (when is not running)
	If isIndex And appM.TSappnameRunningStatus(appname) <> appM.ST_RUNNING Then
			 
		If ServerBusy<>20 Then
			writeErrorPage("serverbusy.html",resp)
			timerwaitappinit = Null
			Return			
		End If
		
		 
		'start new R session (runs in main thread) 
		CallSubDelayed2(appM,"ShinyStartbyAppname",appname)

		timerwaitExpireDt = DateTime.Now + timerwaitTimeoutDt				
		timerwaitappinit.Initialize("timerwaitappinit", 300)
		timerwaitappinit.Enabled = True

		'timerwaitappinit will check if new R session is runing. the http thread stop and wait
		StartMessageLoop	
		If timerwaitappinit <> Null And timerwaitappinit.IsInitialized Then 
			timerwaitappinit.Enabled = False	
		End If
		timerwaitappinit = Null
		
		'R session is started sucessfully or failed/timeout
		
		If appM.TSappnameRunningStatus(appname) = appM.ST_RUNNING Then
			isShinyRunning = True
		End If
		
		If isShinyRunning = False Then 
			'failed/timeout
			writeErrorPage("appinitfailed.html",resp)
			comFunMod.AppLg(appFolderName, "error", "", $"initShinyApp timeout"$) 
			Return 
		End If		
		
	End If
		
'destory timerwaitappinit
	If timerwaitappinit <> Null And timerwaitappinit.IsInitialized Then 
		timerwaitappinit.Enabled = False	
	End If
	timerwaitappinit = Null
		
'get the configmap of this R session	
	Try	
		Dim confmap2 As Map = appM.AppnameConfTsMap.Get(appname)
		Dim wscPort As Int =confmap2.Get("port")
	Catch
		'catch if appname is not in AppnameConfTsMap
		resp.SendError(404,"/404.html")
		Return
	End Try
	
	shiny_ver = confmap2.GetDefault("shinyversion","")
	
'upload and download and datatable(form request)	

	'sb2 to build url (get/post to R session)		
	Dim sb2 As StringBuilder
	sb2.Initialize
	sb2.Append("http://127.0.0.1:").Append(wscPort).Append("/")


	If urlpathList_Size>3 And urlpathList.Get(1)="session" Then
		Dim actions As String = urlpathList.Get(3) ''download upload dataobj
		requestType = "session"
		If actions = "dataobj" Then resp.ContentType = "application/json"
	
	Else if isRmdSubapp Then
		'http://127.0.0.1:8888/shiny/026-shiny-inline_subapp/app83efa12c86ab568d3d81f6fba706aef9/?w=&__subapp__=1
		requestType = "index_subapp"
		resp.ContentType = "text/html"
		resp.CharacterEncoding = "utf-8"
		If req.GetParameter("__subws__") = "" Then		
			Dim subappQS As String = comFunMod.URL_RmdSubQS(FULLURI_WID_REMOVED,nTH_SLASH_APPFN+1)
 
			'Redirect to http:// will cause "mixed content" when running behind Nginx with https
			'use RemoteAddr + relative URL(with query string)	 instead of FULLURI 
			Dim RemoteAddr As String = getRemoteAddr(req)

			resp.SendRedirect($"${RemoteAddr}${FULLURI.SubString(comFunMod.StringIndexOfNth(FULLURI, "/", 3)	)}&__app__=${comFunMod.URL_Encode(appFolderName)}&__w__=${comFunMod.URL_Encode(confmap2.GetDefault("workerid",""))}&${subappQS}"$)			 		
			Return
		End If												
	Else If isIndex=True Then
		'index
		If ServerBusy=0 Then
			writeErrorPage("serverbusy.html",resp)
			Return			
		End If
		If req.GetParameter("__app__") = "" Then
			Dim cQS As String = comFunMod.getQueryString(FULLURI)
			If cQS <> "" Then cQS = "&" & cQS 
			resp.SendRedirect($"/${Main.htmlRootPath}/${redURL}/index.html?__app__=${comFunMod.URL_Encode(appFolderName)}&__w__=${comFunMod.URL_Encode(confmap2.GetDefault("workerid",""))}${cQS}"$)			 		
			Return
		End If
		requestType = "index"
		resp.ContentType = "text/html"
		resp.CharacterEncoding = "utf-8"				
	
	Else if (urlpathList_Size >0) Then
		requestType = "others"
		resp.ContentType = comFunMod.getContentTypeByExt(FULLURI)
		
		
	Else
		'should not happen 
		resp.Status = 404
		resp.Write("wrong location") 	 
		Return
	End If
	
	If Not(requestType = "index" Or requestType = "index_subapp") Then

		sb2.Append(comFunMod.URL_suburl(FULLURI_WID_REMOVED,nTH_SLASH_APPFN+1))
		
	End If

' for url/server bookmark	
'http://127.0.0.1:10001/?_inputs_&n=191 
'http://127.0.0.1:10001/?_state_id_=f5723683f6a9c868
	If requestType = "index" Then
		sb2.Append(BmQs)		
	End If
	
	appM.TSappnameUpdate(appname)
		
'http request to R process

	mResp = resp
	Dim linkstr As String = sb2.ToString
	
	'isRmdSubapp use different url
	If isRmdSubapp Then
		Dim tmppara_subws As String = req.GetParameter("__subws__")
		Dim tmppara_subsearch As String = req.GetParameter("__subsearch__")	
		If tmppara_subsearch<>"" Then
			tmppara_subws = tmppara_subws&"?"&tmppara_subsearch
		End If
		'http://127.0.0.1:10001/app09b181ddd865dc86a78db29477cd3005(__subws__)/?w=&__subapp__=1(tmppara_subsearch)
		linkstr = $"http://127.0.0.1:${wscPort}${tmppara_subws}"$  
		
	End If
 	' Log(linkstr)
	Dim j As HttpJob
	j.Initialize("j", Me , "httptasks")
	j.JobName = appname 'linkstr
	 
	
	Dim out As OutputStream 	
	If requestMethod = "post" Then
	    out.InitializeToBytesArray(1000)
	    File.Copy2(req_InputStream, out) 'actual copying					
		j.PostBytes(linkstr, out.ToBytesArray)		
		j.GetRequest.SetContentType( req.ContentType & "; "& req.CharacterEncoding)
		 
	Else

		
		newHash = ""
		If requestType = "others" Then
			previousHash = req.GetHeader("If-None-Match")
			 
		End If 
	
		enableETag = True		
		j.Download(linkstr)
		
		
	End If
	'this thread stop and wait for http job to finish / timeout	
	StartMessageLoop
	'http request finished / timeout. continue 
#if not(debugmacos)
	If (enableETag=True) And (requestType = "others") And (requestMethod = "get") Then
		'comFunMod.LogFmt("error", "", $" [Etag---] ${linkstr} ${newHash} ${previousHash} "$)
		If (newHash<>"") And isEtagIdentical(newHash,previousHash) Then
		'resource hash not changed return 304	
			resp.Status = 304					
		End If
	End If
#end if
	
	'destory out object
	If out<>Null And out.IsInitialized Then
		out.Close
	End If
	out = Null
	
	' http request ends here (after mResp.OutputStream is finished)
End Sub

Sub JobDone(Job As HttpJob)
	 
	If Job.Success Then

		'write header content-disposition to download file
		Dim DirTmp46 As String = HttpUtils2Service.TempFolder
		Dim tmp_filename As String = Job.currentTaskId&".header"
		
		If File.Exists(DirTmp46, tmp_filename) Then
			Dim headerMap As Map = comFunMod.B4XreadObj(DirTmp46, tmp_filename )
			If headerMap.ContainsKey("__error__") = False And headerMap<>Null And headerMap.IsInitialized And headerMap.Size >0 Then
				For Each headerNamestr As String In headerMap.Keys
					If headerNamestr.ToLowerCase.Trim  = "content-disposition" Then
						Dim tmp_list As List = headerMap.Get(headerNamestr)
						If CltUtils.check_list_size(tmp_list,1) Then
							For j = 0 To tmp_list.Size-1
								mResp.SetHeader(headerNamestr,tmp_list.Get(j))
							Next		
						End If
					End If
				Next
			End If
		End If
			  	
		If (requestType = "index" Or requestType = "index_subapp") Then
	  		Dim indexstr As String = Job.GetString
			
			'rewrite index.html page contents ( js css links)
			indexstr = comFunMod.shiny_HtmlReplaced(indexstr,shiny_ver,"notsupported")
			If indexstr = "" Then
				'shiny version is not supported
				writeErrorPage("shinyvererror.html",mResp)
			Else
				mResp.Write(indexstr)
			End If
			
				
		Else if (enableETag=True) And (requestType="others") And (requestMethod="get") Then
			
			
			Dim md5str As String = comFunMod.getFileHash(HttpUtils2Service.TempFolder,Job.currentTaskId,"MD5")
			md5str = md5str.ToLowerCase.Trim
			newHash = md5str
			If newHash<>""  Then
				'Etag not match need to set new one and write body
				
				If Not(isEtagIdentical(newHash,previousHash)) Then
					
					'http://stackoverflow.com/questions/16532728/how-do-i-send-an-http-response-without-transfer-encoding-chunked					
					mResp.SetHeader("ETag",newHash)
					mResp.SetHeader("Content-Length", File.Size(HttpUtils2Service.TempFolder,Job.currentTaskId) )
				    							
					File.Copy2(Job.GetInputStream, mResp.OutputStream)	
				End If

			End If
	
		Else		
			File.Copy2(Job.GetInputStream, mResp.OutputStream)
		End If

				
		appM.TSappnameUpdate(appname)	
	Else
	  	mResp.SendError(500, Job.ErrorMessage)
	End If
	StopMessageLoop
	
End Sub



Sub timerwaitappinit_tick
	Dim IsStopLoop As Boolean = False
	If appM.TSappnameRunningStatus(appname) =  appM.ST_RUNNING Then
		IsStopLoop = True 
	End If

'20160709	
	If appM.TSisAppInitFailed(appname) = True Then
		IsStopLoop = True	
	End If
	
	If DateTime.Now > timerwaitExpireDt Then
		IsStopLoop = True
	End If
	
	If IsStopLoop = True Then
		timerwaitappinit.Enabled = False
		StopMessageLoop
		Return 		
	End If
	
End Sub





Private Sub writeErrorPage(errorPage As String, srvrResp As ServletResponse)
	Dim errorpagefn As String = ""
	Dim errorStr As String = "Error"
	srvrResp.Status = 500
	srvrResp.ContentType = "text/html"
	srvrResp.CharacterEncoding = "utf-8"
		
	Select errorPage
		Case "appinitfailed.html"
			errorpagefn = errorPage
			errorStr = "The app is not running yet, please try later. Check the log if this app is supported."			
		Case "serverbusy.html"
			errorpagefn = errorPage
			errorStr = "Server is busy. Please try later"
		Case "shinyvererror.html"	
			errorpagefn = errorPage
			errorStr = "Shiny version is not supported by the server"										
		Case Else
			
	End Select
	
	If errorpagefn<>"" And File.Exists(Main.staticFilesPath,errorpagefn) Then
		errorStr = File.ReadString(Main.staticFilesPath,errorpagefn) 
	End If
	srvrResp.Write(errorStr)		

End Sub



'return "" if X-Forwarded-Proto or X-Forwarded-Host is not set
'return http(s)://hostname{:port}  (port is optional)
Sub getRemoteAddr(req As ServletRequest) As String
	Dim RemoteAddr As String = ""		
	Dim RemoteSch As String = ""
	If req.GetHeader("X-Forwarded-Proto")="https" Then
		RemoteSch = "https"
	End If
	Dim RemoteDomain As String = ""
	If req.GetHeader("X-Forwarded-Host") <> "" Then
		RemoteDomain = req.GetHeader("X-Forwarded-Host")
	End If
	
	
	Dim RemotePort As String = req.GetHeader("X-Forwarded-Port")
	If RemoteSch<>"" And RemoteDomain<>"" Then
		RemoteAddr = RemoteSch & "://" & RemoteDomain		
		If RemotePort<>"" Then 	RemoteAddr = RemoteAddr & ":" & RemotePort
	End If	
	
	Return RemoteAddr
End Sub

' requirement : NewETag is not empty
Sub isEtagIdentical(NewETag As String, PreviousETag As String) As Boolean
	'If NewETag="" Then Return False
	Return (NewETag = PreviousETag Or NewETag&"--gzip"=PreviousETag)
End Sub
