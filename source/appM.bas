Type=StaticCode
Version=4.2
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'Code moudule
Sub Process_Globals

	'Shiny process state : 
	Public Const ST_NEW As Int = 10
	Public Const ST_STARTING As Int = 20
	Public Const ST_RUNNING As Int = 30
	Public Const ST_NOTRESPONSE As Int = 40 'Not response to http ping for a long time
	Public Const ST_TERMINATED As Int = 50  'pid been killed
	
'-------- public threadsafe map
	Public AppnameConfTsMap As Map	  ' {"appname1":confmap1,"appname2":confmap2}
	Public inFolderAppnameTsMap As Map
	Public ThreadStatTsMap As Map	
	Public AppnPingTsMap As Map
	Public AppnActDatetimeTsMap As Map
	Public verifyAppnConfTsMap As Map  ' main thread only
	Public SettingTsMap As Map 	
	Public SysStatTsMap As Map
	Public extMineTsMap As Map  	
'20160709	
	Public AppInitFailedTsMap As Map  ' {"app1":dt1,"app2":dt2}	

	Public ThreadidAppnameTsMap As Map
	
'-------- public 	
	Public OSName As String
	Public wsMaxTextSizeKb As Int = 3000
	Public wscMaxTextSizeKb As Int = 3000
	Public formMaxSizeKb As Int = 3000 
	
	Public secClientMaxidleTimeout As Long = 300 ' 5 mins
	Public msAppInitTimeout As Long = 60*1000
	Public msAppIdleTimeout As Long = 300*1000
	Public msClientTimerIsAlive As Long = 30*1000
	
' ------- private members
	Private app2start As List  'Not threadsafe; main thread only
	Private TimeStampCount As Int = 0
	Private servertimestampIntervalSec As Int = 3
'--------config
	
	Private File2ClearextMap As Map 
	Private File2ClearextMapAfterInit As Map
	 		
	Private appInitHttpJobIntervalDt As Long = 1200
	Private appInitHttpJobIntervalDt2 As Long = 7*DateTime.TicksPerSecond
		
	Private ShinyAppFolder As String
	Private DirPids As String 
	Private isEnableJavasysmon As Boolean = True
	
	
' ----- init port counter	
	Private currentPortNo As Int
	

' -----timer
	Private timercheckstatus As Timer
	Private timeronesec As Timer
	Private timeroneminute As Timer

'' -----print r logs stdout or stderr
	Public isLogDebug As Boolean = False

' -----printThreadStat intervals 
	Private updateInFolderAppname_DT As Long
	Private updateInFolderAppname_Interval As Long = 40*1000

' -----private threadsafemap  ==MultiSessionApp  
	Private MultiSessionAppMap As Map
	Private MultiSessionApp_Filename As String = "r_multisession.conf"

				
End Sub

'Initializes the object. You can add parameters to this method if needed.
' array() string ("stopr") just to stop r instances and server exit
Public Sub Initialize(DirPidstr As String, InputArgs() As String)
	currentPortNo = comFunMod.rndPortMin
	DirPids = DirPidstr
	File2ClearextMap = CreateMap(".pid":"", ".input":"",".script":"",".error":"")
	File2ClearextMapAfterInit = CreateMap(".input":"",".script":"",".error":"")
'	printThreadStat_DT = DateTime.Now
	updateInFolderAppname_DT = DateTime.Now
	OSName = getOSName
	setSettingMap(OSName)


'check input args
	Dim isstopPreRInstances As Boolean = False
	If InputArgs.Length>0 Then
		Dim Actions As String = InputArgs(0)
		If Actions="stopr" Then
			isstopPreRInstances = True	
		End If
	End If


'set stdOut and stdErr redirection

	Dim isRunningFromIDE As Boolean = False
	If FileUtils.File_checkFolder(Main.testPath, "runningfromide",False) Then
		isRunningFromIDE = True 
	End If
	
	Dim redirect_output As String = getSettingMapValue("redirect_output")
	If isstopPreRInstances=False And redirect_output.ToLowerCase ="true" And isRunningFromIDE=False Then
		comFunMod.RedirectOutput(Main.LogsPath,$"server_output_${comFunMod.PrintDT2}.log"$)
	End If
	
	If isstopPreRInstances Then
			
	Else
		comFunMod.LogFmt("info", "", $" Server starting ============ "$)	
	End If

	isEnableJavasysmon = True

	msAppInitTimeout = getSettingMapValue("app_init_timeout" )
	msAppInitTimeout = msAppInitTimeout*1000
	
' loglevel
	Dim loglevel_str As String = getSettingMapValue("loglevel" )
	loglevel_str = loglevel_str.ToLowerCase
	If loglevel_str="debug" Then isLogDebug=True

	
	 
	wsMaxTextSizeKb = getSettingMapValue("wsmaxtextsizekb" )
	wscMaxTextSizeKb = getSettingMapValue("wscmaxtextsizekb" )
	
	secClientMaxidleTimeout = getSettingMapValue("client_maxidle_timeout" )
	secClientMaxidleTimeout = Max(secClientMaxidleTimeout , 120) 
	
	formMaxSizeKb = getSettingMapValue("formmaxsizekb" )
		
	Dim msTimercheckstatusInterval As Long = 10*1000
	
	msAppIdleTimeout = getSettingMapValue("app_idle_timeout" )
	msAppIdleTimeout = msAppIdleTimeout*1000
	Dim msTmpLong As Long = Max(msTimercheckstatusInterval*4 , msClientTimerIsAlive*2 )
	msAppIdleTimeout = Max(msTmpLong,msAppIdleTimeout)

	
	If getSettingMapValue("shinyfolder") = "" Then
		Dim shinyFolderTmp As String = "shinyapp"
	Else
		Dim shinyFolderTmp As String = getSettingMapValue("shinyfolder")
	End If
	If shinyFolderTmp.Contains("/") And File.Exists(shinyFolderTmp,"") And File.IsDirectory(shinyFolderTmp,"") Then
		ShinyAppFolder = shinyFolderTmp
	Else
		ShinyAppFolder = FileUtils.File_FullPath( File.DirApp & "/" & shinyFolderTmp )
	End If
	SettingTsMap.Put("shinyfolder",ShinyAppFolder)
	
	
	stopPreviousRInstances(DirPids)
	FileUtils.File_ClearFolder_extfilter(DirPids,File2ClearextMap)	
	
	If isstopPreRInstances Then
		'Log($"[info]${TAB}${comFunMod.PrintDT}${TAB}stopPreviousRInstances${TAB}stop previous R Instances"$)
		ExitApplication	
	End If
	
	AppnameConfTsMap = Main.srvr.CreateThreadSafeMap
	inFolderAppnameTsMap = Main.srvr.CreateThreadSafeMap
	AppnPingTsMap = Main.srvr.CreateThreadSafeMap
	AppnActDatetimeTsMap = Main.srvr.CreateThreadSafeMap 
	verifyAppnConfTsMap = Main.srvr.CreateThreadSafeMap
	ThreadStatTsMap = Main.srvr.CreateThreadSafeMap
	SysStatTsMap = Main.srvr.CreateThreadSafeMap
	AppInitFailedTsMap = Main.srvr.CreateThreadSafeMap
	ThreadidAppnameTsMap = Main.srvr.CreateThreadSafeMap
	

	initExtMineTsMap

	initAppnewRsession

	app2start.Initialize
		
	timercheckstatus.Initialize("timercheckstatus", msTimercheckstatusInterval)
	timercheckstatus.Enabled = True

	timeronesec.Initialize("timeronesec",1000)
	timeronesec.Enabled = True	

	timeroneminute.Initialize("timeroneminute",1000*60)
	timeroneminute.Enabled = True	
		
End Sub
	
	
Sub startShinyByConfmap(confMap As Map , os_str As String , r_args As String)
	
	
	Dim DirTmp45 As String = DirPids 

	Dim shellRsession As Shell
	Dim tmpFolder As String = File.DirApp
	Dim arglist As List
	arglist.Initialize
	Dim portString As String = confMap.Get("port")
	
	Dim rscript_template_filename As String = FileUtils.File_FullPath(File.Combine(File.DirApp,"Rcode/startjson.R")) 
	Dim rscript_temp As String = File.ReadString(rscript_template_filename,"")
	rscript_temp = rscript_temp.Replace("#g_filename#", FileUtils.File_FullPath(DirTmp45 & "/" & portString))
	rscript_temp = rscript_temp.Replace("#g_locale_LC_ALL#", getSettingMapValue("lc_all") )
	
'   clear previous files .pid .script .input	
	FileUtils.File_DelFile_NameAndExtfilter(DirTmp45 , portString , File2ClearextMap)

	File.WriteString(DirTmp45, portString&".script", rscript_temp)
	Dim scriptFullpath As String = DirTmp45 & "/" & portString&".script"
	scriptFullpath = FileUtils.File_FullPath(scriptFullpath)
	
	Dim inputJson As JSONGenerator
	inputJson.Initialize(confMap)
	File.WriteString(DirTmp45, portString&".input", inputJson.ToString)
	Dim Exe As String = getSettingMapValue("rbin") 
	If r_args<> "" Then
		arglist.Add(r_args)
	End If
	arglist.Add("-q")
	
	arglist.Add("-e")
	arglist.Add("source( '" & scriptFullpath & "' )")	
		
	shellRsession.InitializeDoNotHandleQuotes("shellRsession", Exe, arglist)	
	shellRsession.WorkingDirectory = tmpFolder


	shellRsession.RunWithOutputEvents(-1)
	
End Sub



Private Sub shellRsession_StdOut (Buffer() As Byte, Length As Int)
	If isLogDebug Then
		FileUtils.FileWriteAppend(Main.LogsPath,"r_stdout.log", "[Rsession_stdout]    "& DateTime.Now  & CRLF &  byteArr2string(Buffer,Length,True))	
	End If
End Sub

Private Sub shellRsession_StdErr (Buffer() As Byte, Length As Int)

	If isLogDebug Then
		FileUtils.FileWriteAppend(Main.LogsPath,"r_stderr.log", "[Rsession_stderr]    "& DateTime.Now  & CRLF &  byteArr2string(Buffer,Length,True))	
	End If
End Sub

Private Sub shellRsession_ProcessCompleted (Success As Boolean, ExitCode As Int, so As String, se As String)
'todo R/Rterm terminated
End Sub

'removeNUL true to remove 0x00 chars in the string
Private Sub byteArr2string(Buffer() As Byte, Length As Int , removeNUL As Boolean) As String 
	Dim tmpStr As String = BytesToString(Buffer,0, Buffer.Length - 1, "UTF8")
	If removeNUL = False Then
		Return tmpStr
	End If

	Dim sb As StringBuilder
	sb.Initialize
	Dim C As Char
	For i = 0 To tmpStr.Length - 1
		C = tmpStr.CharAt(i)
		Select c
			Case Chr(0)
			Case Else
				sb.Append(c)
		End Select
	Next
	Return sb.ToString
End Sub


'Note: app2start is not threadsafe . Access by main thread only
public Sub ShinyStartbyAppname(appNametmp As String) 
'removed as it's updating periodically  and checked in httprelayhandler
'	updateInFolderAppname  ...
	
	If app2start.IndexOf(appNametmp)=-1 And verifyAppnConfTsMap.ContainsKey(appNametmp) = False  Then
		app2start.Add(appNametmp)
	End If


End Sub

Private Sub timeroneminute_tick
	Try
		Dim dtmap As Map = comFunMod.getDT(0)
		comFunMod.ServerStatLog(dtmap)
	Catch
		'Log(LastException)
	End Try
	
End Sub

Private Sub timeronesec_tick
	'timeronesec.Enabled = False
	Try
'write timestamp(datetime.now) of server; used for health check	
		TimeStampCount = TimeStampCount + 1
		If TimeStampCount>=servertimestampIntervalSec Then
			
			File.WriteString(Main.staticFilesPath,"servertimestamp.html", DateTime.Now )	
			TimeStampCount = 0  
		End If

		verifyAppInit
	Catch
		comFunMod.LogFmt("error", "verifyAppInit", $"LastException"$)
		Log(LastException)
	End Try
	'timeronesec.Enabled = True
End Sub


private Sub	verifyAppInit
	If app2start.Size =0 And verifyAppnConfTsMap.Size=0 Then
		Return
	End If
	
	Dim AppnameSingle As String = ""
	

'start app 		
	If app2start.Size > 0 Then
		AppnameSingle = app2start.Get(0)
		
		Dim cfmap As Map = CreateConfMap(AppnameSingle)	

		' set for build-in  app 
		If comFunMod.isBuildinApp(AppnameSingle) Then
			cfmap.Put("setwd", FileUtils.File_FullPath(File.Combine(File.DirApp,"shinyapp_buildin")))		
		End If
	
		
		app2start.RemoveAt(0)	
		verifyAppnConfTsMap.Put(	AppnameSingle , cfmap )
			
	    comFunMod.AppLg(AppnameSingle, "info", "verifyAppInit", $" port=${cfmap.Get("port")} "$)
			
		startShinyByConfmap( cfmap ,OSName , getSettingMapValue("r_args"))	
		cfmap.Put("status",ST_STARTING)
	End If

'verfiy status
	Dim verifyAppn2RemoveList As List
	verifyAppn2RemoveList.Initialize
	
	For Each appname As String In verifyAppnConfTsMap.Keys
		Dim confmap As Map = verifyAppnConfTsMap.Get(appname)
		
		Dim status_int As Int = confmap.Get("status")
		Dim start_datetick_long As Long = confmap.Get("startdt")			
		
		Select status_int 
			Case ST_NEW 	
				comFunMod.LogFmt("error", "", $"ST_NEW should not happen ${appname}"$)
			Case ST_STARTING
	
				Dim outputfile As String = confmap.Get("outputfilename")
				If File.Exists(outputfile&".error" ,"") Then
										
					comFunMod.AppLg(appname, "error", "verifyAppInit", $"Init Shiny app failed ${CRLF} ${File.ReadString(outputfile&".error" ,"")}"$) 
					confmap.Put("status",ST_TERMINATED)
					ClearTmpFiles ( confmap.Get("port") )
					
					verifyAppn2RemoveList.Add(appname)
					
					AppInitFailed( appname )
					stopShinyApp( appname , True )			
				Else If ( start_datetick_long + msAppInitTimeout ) < DateTime.Now Then				
					
					
					comFunMod.AppLg(appname, "error", "verifyAppInit", $"Init Shiny app timeout"$) 
					confmap.Put("status",ST_TERMINATED)
					ClearTmpFiles ( confmap.Get("port") )
				
					verifyAppn2RemoveList.Add(appname)
									
					AppInitFailed( appname )
					stopShinyApp( appname , True )	
												
				Else If File.Exists(outputfile&".pid","") Then
					Dim isCheckAppInit As Boolean = False
					If confmap.ContainsKey("lastping") = False Then
						confmap.Put("firstping", DateTime.Now)
						isCheckAppInit = True
					Else
						Dim tmp_dt As Long =  confmap.Get("lastping")
						
						Dim fristpingdt As Long =  confmap.Get("firstping")
						Dim lastpinginterval As Long = appInitHttpJobIntervalDt
						If (fristpingdt + 5*DateTime.TicksPerSecond)<DateTime.Now Then
							lastpinginterval = 	appInitHttpJobIntervalDt2
						End If
						
						If ( tmp_dt + lastpinginterval ) < DateTime.Now  Then
							isCheckAppInit = True
						End If	
					End If 	
					
					If isCheckAppInit Then
						
						Dim linkstr As String = "http://127.0.0.1:"& confmap.Get("port") '& "/"
						Dim j As HttpJob
						j.Initialize("j", Me,"httptasks")
						j.Tag = ST_STARTING
						j.Download(linkstr)	
						j.JobName = appname
						j.GetRequest.Timeout = 3000
						
						comFunMod.AppLg(appname, "info", "verifyAppInit", $"Test if the app is running"$) 
						confmap.Put("lastping",DateTime.Now)
					End If
				End If				
									
			Case ST_RUNNING , ST_TERMINATED ,ST_TERMINATED


		
		End Select			

	Next		


'	remove failed tasks
	For k = 0 To verifyAppn2RemoveList.Size-1
		verifyAppnConfTsMap.Remove(verifyAppn2RemoveList.Get(k))	
	Next

	
End Sub

' clear previous files after app runs : .script .input .error ( .pid excluded )	
Private Sub ClearTmpFiles ( port_str  As String )		
If isLogDebug Then
	FileUtils.File_DelFile_NameAndExtfilter(DirPids , port_str , File2ClearextMapAfterInit )
End If
End Sub

' clear previous files after app is killed : .script .input .error and .pid 	
Private Sub ClearTmpFilesAll ( port_str  As String )		
If isLogDebug Then
	FileUtils.File_DelFile_NameAndExtfilter(DirPids , port_str , File2ClearextMap )
End If
End Sub


'full_appn is made up with appname{APPNDELIM}workerid . which could be 
'001-hello       ->  r processes is shared by appname 
'001-hello{APPNDELIM}xyzworkerid ->  r processes is shared by appname and workerid
Private Sub CreateConfMap (full_appn As String) As Map
	Dim nextport As Int = comFunMod.getNextPortAvail(currentPortNo)	
	currentPortNo = nextport + 1		


	Dim appnMap As Map = comFunMod.getAppnameWorkerID(full_appn)
	Dim appn_tmp As String = appnMap.Get("appname")
	Dim workerid_tmp As String = appnMap.Get("workerid")

	
	Dim output_filepath As String = DirPids & "/" & nextport
	output_filepath = FileUtils.File_FullPath(output_filepath)

	Dim shinyconfmap As Map 
	'shinyconfmap.Initialize
	shinyconfmap = Main.srvr.CreateThreadSafeMap
	shinyconfmap.Put("startdt",DateTime.Now)
	shinyconfmap.Put("status", ST_NEW)
	
	shinyconfmap.Put("setwd",ShinyAppFolder)
	shinyconfmap.Put("appname",appn_tmp)
	shinyconfmap.Put("port",nextport)
	

	shinyconfmap.Put("workerid",workerid_tmp)
	If workerid_tmp<>"" Then
		shinyconfmap.Put("isfullappname",True)
	End If

	shinyconfmap.Put("maxrequestsizekb", wscMaxTextSizeKb )	

	'shinyconfmap.Put("localhost","true")
	shinyconfmap.Put("outputfilename",output_filepath)
	
	Dim appfileMap As Map = checkAppFiles(FileUtils.File_FullPath(File.Combine(ShinyAppFolder,appn_tmp)))
	shinyconfmap.Put("rmdfile",appfileMap.Get("rmdfile"))
	shinyconfmap.Put("pandoc", SettingTsMap.Get("pandoc"))

	Dim shiny_sanitize_errors As String = getSettingMapValue("shiny_sanitize_errors")
	If shiny_sanitize_errors.ToLowerCase ="true" Then
		shinyconfmap.Put("shiny_sanitize_errors","true")
	Else
		shinyconfmap.Put("shiny_sanitize_errors","false")
	End If

	shinyconfmap.Put("bookmarkstatedir", Main.bookmarkstatedir )
	
	Return shinyconfmap
End Sub



Private Sub JobDone(j As HttpJob)
	Dim appn As String = j.JobName
	Dim tag As Int = j.Tag

	If tag = ST_STARTING Then	
		If j.Success Then
			startShinySuccess(appn)
			comFunMod.AppLg(appn, "info", "startShinySuccess", $" Shiny app is running "$)  

		Else

		End If
	else if  tag = ST_RUNNING Then
		If j.Success Then
			AppnActDatetimeTsMap.Put(appn, DateTime.Now) 
		Else

		End If	
	End If
	j.Release
    j = Null
End Sub

Sub updateInFolderAppname(isNoDelay As Boolean)
	
	If isNoDelay = False  Then
		If (DateTime.Now - updateInFolderAppname_DT)>=updateInFolderAppname_Interval Then	
			updateInFolderAppname_DT = DateTime.Now
		Else
			Return
		End If		
	End If
	
	
	Dim tmplist As List = FileUtils.File_ListSubFolderName(ShinyAppFolder)
	If tmplist=Null Or tmplist.IsInitialized =False Or tmplist.Size =0  Then 
		tmplist.Initialize
	Else
		
	End If
	Dim tmpThreadsfMap As Map
	tmpThreadsfMap = Main.srvr.CreateThreadSafeMap
	For i = 0 To tmplist.Size-1

		Dim appn As String = tmplist.Get(i)
		If appn.Contains(comFunMod.APPNDELIM)=False Then tmpThreadsfMap.Put(tmplist.Get(i),"")
			
		
	Next
	inFolderAppnameTsMap = tmpThreadsfMap
End Sub

'return 0 if the appn doesn't exsit
'return statuscode ST_***
Public Sub TSappnameRunningStatus (appn As String ) As Int
	If AppnameConfTsMap.ContainsKey(appn) = False Then Return 0
	Dim confmap_tmp As Map = AppnameConfTsMap.Get(appn)
	Dim status_int  As Int = confmap_tmp.Get("status")
	Return status_int
End Sub


public Sub TSappnameUpdate(appn As String )
	AppnPingTsMap.Put(appn, DateTime.Now) 
	AppnActDatetimeTsMap.Put(appn, DateTime.Now) 
End Sub


Public Sub getThreadStatTsMap As Map
	
	Dim total_th As Int = 0
	'Dim disc_th As Int = 0
	Dim activeTh As Int = 0
	
	For Each thid As Int In ThreadStatTsMap.Keys
		total_th = total_th+1
		If ThreadStatTsMap.Get(thid) = True Then
		Else 
			activeTh = activeTh + 1
		End If
	Next

	Dim appFoldernameMap As Map 
	appFoldernameMap.Initialize
	Dim appFoldername2 As String
	Dim counttmp As Int  
	For Each fullappn As String In AppnameConfTsMap.Keys
		appFoldername2 = comFunMod.getAppFolderName(fullappn)
		counttmp = appFoldernameMap.GetDefault(appFoldername2,0)
		appFoldernameMap.Put(appFoldername2,counttmp+1)
	Next
	
	Return CreateMap("connections":activeTh,"rsessions":AppnameConfTsMap.Size,"apps":appFoldernameMap.Size)
End Sub

'how many threads/connectilons of each app (per app folder name)
'{"app1":2,"app5":3,}
'error return empty map
Public Sub getAppStatTsMap As Map
	
	Dim appFoldernameMap As Map 
	appFoldernameMap.Initialize
	
Try	
	Dim appFoldername2 As String
	Dim counttmp As Int  
	For Each fullappn As String In ThreadidAppnameTsMap.Values
		appFoldername2 = comFunMod.getAppFolderName(fullappn)
		counttmp = appFoldernameMap.GetDefault(appFoldername2,0)
		appFoldernameMap.Put(appFoldername2,counttmp+1)
	Next	
Catch
	appFoldernameMap.Initialize
End Try
	Return appFoldernameMap
End Sub

Private Sub timercheckstatus_tick
	timercheckstatus.Enabled  = False
	
Try	
	AppInitFailedUpdate
	updateInFolderAppname(False)
	


	If File.Exists(Main.configPath, "applist.update") Then
		File.Delete(Main.configPath, "applist.update")
		updateInFolderAppname(True)
		comFunMod.genIndexPage(True,"applist.html")	
	End If
	
	Dim listofappn2remove As List
	listofappn2remove.Initialize

'test if pids still running
'	Dim dtn As Long =  DateTime.Now	
	Dim pidMap As Map = comFunMod.SysGetRPidsByPname(OSName,isEnableJavasysmon)
	Dim getPIDFailed As Boolean = pidMap.Get("error")
	Dim pidList As List
	pidList.Initialize
	
	
	If getPIDFailed Then
		comFunMod.LogFmt("error", "getPIDFailed", $"  "$)
	Else if AppnameConfTsMap.Size>0 Then 
		pidList = pidMap.Get("list")  
		
		If pidList.Size = 0 Then

			AppnameConfTsMap.Clear
			AppnPingTsMap.Clear

		End If
	End If

	For Each appn As String In AppnameConfTsMap.Keys

		Dim confmap As Map = AppnameConfTsMap.Get(appn)
		Dim pidint As Int = confmap.Get("pid")
		If getPIDFailed Or pidList.Size = 0 Then
					
		Else
			If pidint <> -1 And pidList.IndexOf(pidint) = -1 Then
				listofappn2remove.Add(appn)	
				 			
				comFunMod.AppLg(appn,"error", "ProcessNotRunning", $"PID=${pidint}"$) 
			End If
		End If
			
	Next

	For Each appn As String In AppnameConfTsMap.Keys
		If AppnPingTsMap.ContainsKey(appn) Then
			Dim dt As Long = AppnPingTsMap.Get(appn)
			If ( dt + msAppIdleTimeout ) < DateTime.Now Then
				stopShinyApp(appn , True )
'				comFunMod.AppLg(appn, $"[Info]  ${DateTime.Now} stopShinyApp for it's been idle for ${DateTime.Now-dt}ms "$ )
				comFunMod.AppLg(appn, "info", "stopShinyApp", $"idle for ${DateTime.Now-dt}ms"$) 
			
				AppnPingTsMap.Remove(appn)
				
				listofappn2remove.Add(appn)			
			End If
		Else		

			TSappnameUpdate(appn)					
		End If	
	Next
	
	Dim appn2 As String
	For jjj = 0 To listofappn2remove.Size -1
		
		appn2 = listofappn2remove.Get(jjj) 
		
		AppnPingTsMap.Remove(appn2)				
		AppnameConfTsMap.Remove(appn2)
			
	Next
	 	
Catch
	comFunMod.LogFmt("error", "timercheckstatus_tick", $"LastException"$)
	Log(LastException)
End Try

	timercheckstatus.Enabled  = True
End Sub

'only isByCommandLine= True is supported
'todo shell.KillProcess not kill Rterm on win
Private Sub stopShinyApp ( appn As String , isByCommandLine As Boolean)
	isByCommandLine = True
	
	If verifyAppnConfTsMap.ContainsKey(appn) Then
		
		Dim confmap_tmp As Map = verifyAppnConfTsMap.Get(appn)
		Dim extraInfoMap As Map = getExtraInfoMapByPortID( confmap_tmp.Get("port") )
		For Each keystr As String In extraInfoMap.Keys
			confmap_tmp.Put(keystr, extraInfoMap.Get(keystr) )
		Next 		

	else If AppnameConfTsMap.ContainsKey(appn) = False Then 
		Return
	Else
		Dim confmap_tmp As Map = AppnameConfTsMap.Get(appn)
	End If
	

	
	If isByCommandLine = False Then
		
	Else
		Dim pidstr As String = confmap_tmp.Get("pid")
		Dim killsucess As Boolean = comFunMod.killProcessByPID(pidstr, OSName)
		File.Delete(DirPids,confmap_tmp.Get("port")&".pid")	
		ClearTmpFilesAll ( confmap_tmp.Get("port") )
		File.Delete( confmap_tmp.Get("tempdir") ,"")	
		
		comFunMod.AppLg(appn,  "info", "stopShinyApp", $"sucess=${killsucess}"$) 
		
	End If

End Sub

'error empty map
'ExtraInfo: pid tempdir 
private Sub getExtraInfoMapByPortID(port_int As Int) As Map
	Dim resMap As Map 
	resMap.Initialize
	Try	
		Dim cf_str As String = File.ReadString(DirPids , port_int&".pid")
		Dim jsonp As JSONParser
		jsonp.Initialize(cf_str)
		Dim cfmap As Map = jsonp.NextObject

		Dim list2return As List
		list2return.Initialize2(Array As String("pid", "tempdir", "rversion" , "shinyversion" , "user" , "effective_user"))
		For i = 0 To list2return.Size-1
			Dim l As List = cfmap.Get(list2return.Get(i))
			Dim tmpstr As String = l.Get(0)	
			resMap.Put(list2return.Get(i),tmpstr)
		Next
		
		Return resMap
	Catch
		comFunMod.LogFmt("error", "getExtraInfoMapByPortID", $"port=${port_int}"$)
		resMap.Initialize
		resMap.Put("pid",1000000)
		resMap.Put("tempdir","/a/path/not/1/exist/s")		
		Return resMap
	End Try
	
End Sub

Sub startShinySuccess(appname As String) 

	For Each appn As String In AppnameConfTsMap.Keys
		If appname = appn Then
			Dim confmap As Map = AppnameConfTsMap.Get(appname)
			confmap.Put("status",ST_RUNNING)
			Dim extraInfoMap As Map = getExtraInfoMapByPortID(confmap.Get("port"))
			For Each keystr As String In extraInfoMap.Keys
				confmap.Put(keystr, extraInfoMap.Get(keystr) )
			Next
			
			ClearTmpFiles ( confmap.Get("port") )

		End If
	Next


	For Each appn As String In verifyAppnConfTsMap.Keys
		If appname = appn Then
			Dim confmap As Map = verifyAppnConfTsMap.Get(appname)
			confmap.Put("status",ST_RUNNING)

			Dim extraInfoMap As Map = getExtraInfoMapByPortID(confmap.Get("port"))
			For Each keystr As String In extraInfoMap.Keys
				confmap.Put(keystr, extraInfoMap.Get(keystr) )
			Next
						
			AppnameConfTsMap.put(appn,confmap)
			ClearTmpFiles ( confmap.Get("port") )
			
		End If
	Next
	
	If verifyAppnConfTsMap.ContainsKey(appname) Then
		verifyAppnConfTsMap.Remove(appname)
	End If
	
End Sub




Sub initExtMineTsMap
	extMineTsMap = Main.srvr.CreateThreadSafeMap
	extMineTsMap.Put("js","application/javascript")
	extMineTsMap.Put("css","text/css")
	extMineTsMap.Put("png","image/png")
	extMineTsMap.Put("jpe","image/jpeg")
	extMineTsMap.Put("jpeg","image/jpeg")
	extMineTsMap.Put("jpg","image/jpeg")
	extMineTsMap.Put("zip","application/zip")
	extMineTsMap.Put("csv","text/csv")
	extMineTsMap.Put("svg","mage/svg+xml")
	extMineTsMap.Put("pdf","application/pdf")
	extMineTsMap.Put("xls","application/vnd.ms-excel")
	extMineTsMap.Put("xlsx","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
	extMineTsMap.Put("docx","application/vnd.openxmlformats-officedocument.wordprocessingml.document")
	extMineTsMap.Put("doc","application/msword"	)

	Dim settingPath As String = Main.configPath 
	
	If File.Exists(settingPath, "mime.types.map") Then
		Dim extmineMap As Map
		extmineMap = File.ReadMap(settingPath, "mime.types.map")
		For Each ext As String In extmineMap.Keys
			extMineTsMap.Put(ext , extmineMap.Get(ext))
		Next
	End If
	
End Sub




public Sub getOSName As String

	Dim OS As String = GetSystemProperty("os.name", "").ToLowerCase
	 
	If OS.Contains("win") Then
		Return "win"
	Else If OS.Contains("mac") Then
		Return "mac"
	Else
	    Return "linux"
	End If
	
End Sub

private Sub setSettingMap(os_t As String) 
	Dim Conf_Path As String = Main.configPath 
	
	If FileUtils.File_checkFolder(Main.testPath, "testsuit",False) Then
		Dim testSuit As String = File.ReadString(Main.testPath, "testsuit")
		If FileUtils.File_checkFolder(Main.testPath, testSuit,True) Then						
			Conf_Path = File.Combine(Main.testPath, testSuit)
			Conf_Path = FileUtils.File_FullPath(Conf_Path)
			Main.testConfigPath = Conf_Path
			Log($"******************"$)
			comFunMod.LogFmt("warn", "testing", $" load test config from ${Conf_Path} "$)
			Log($"******************"$)		
		End If
			
	End If	
	
	Dim readSettingMap As Map = loadSettingMap(os_t,Conf_Path)
		
	SettingTsMap = Main.srvr.CreateThreadSafeMap
	For Each keystr As String In readSettingMap.Keys
		SettingTsMap.Put(keystr , readSettingMap.Get(keystr))	
	Next
End Sub

'load production/test setting config in test/test_1/
Private Sub loadSettingMap(os_t As String,config_Path As String) As Map
	
	Dim settingPath As String = config_Path
	Dim readSettingMap As Map
	If File.Exists(settingPath, "system_common.conf") Then
		readSettingMap = FileUtils.File_readMap_utf8(settingPath, "system_common.conf",False)
	Else
		readSettingMap.Initialize
	End If
	
	Dim OSsettingfilename As String
	OSsettingfilename = $"system_${os_t}.conf"$ 

	Dim osmap As Map = FileUtils.File_readMap_utf8(settingPath, OSsettingfilename,False)
	For Each keys As String In osmap.Keys
		readSettingMap.Put(keys, osmap.Get(keys))
	Next
	
	Return readSettingMap	
End Sub

'when not found return empty string
public Sub getSettingMapValue(keystr As String ) As Object
	Dim str As String = SettingTsMap.GetDefault(keystr, "")	
	Return str
	
End Sub


public Sub printSettingMapValue
	Log("-----config loading-------")	
	For Each configkey As String In SettingTsMap.Keys
		Log($"${configkey} = ${SettingTsMap.Get(configkey)}"$)	
	Next	
	Log("-----config loaded-------")			
End Sub




'Note :  use try catch to prevent exceptions on MAC OS
'task1 : make new ws connection to existing shiny app
'task2 : init new R shiny app
'return value : allowed tasks
'0            : none      (limit1)
'10           : Task1     (limit2)
'20           : Task1 Task2 
' http request(js css post get) not limited
Public Sub TScheckServerBusy As Int

	Dim Statstmp As Map = comFunMod.getServerStat
	Dim tsmap As Map 
	tsmap = Main.srvr.CreateThreadSafeMap
	For Each keys As String In  Statstmp.Keys
		tsmap.Put(keys , Statstmp.Get(keys))	
	Next
	SysStatTsMap = tsmap		

	'If (isLog) Then comFunMod.ServerStatLog(Statstmp)
	
	Dim cpu As Double = SysStatTsMap.Get("cpu")
	Dim freem As Double = SysStatTsMap.Get("freem") 
'	Dim totalm As Double = SysStatTsMap.Get("totalm") 
'	StatisticsCPUMap.Put(DateTime.Now,cpu)
	Dim cpuLimit1 As Double = getSettingMapValue("cpulimit1") '0.01-1 ; 1 for not checking 
	Dim cpuLimit2 As Double = getSettingMapValue("cpulimit2") '0.01-1 ; 1 for not checking 
	Dim memLimit1 As Double = getSettingMapValue("memlimit1") '0 - totalm ; 0 for not checking  
	Dim memLimit2 As Double = getSettingMapValue("memlimit2") '0 - totalm ; 0 for not checking 
	
	If cpu>cpuLimit1 Or freem<memLimit1 Then
		Return 0
	Else If cpu>cpuLimit2 Or freem<memLimit2 Then
		Return 10
	End If
	
	Return 20
	
End Sub






Sub stopPreviousRInstances(TargetTmpDir As String)
	If File.Exists(TargetTmpDir,"") =False Or File.IsDirectory(TargetTmpDir,"")=False Then
		Return 
	End If 
	
	Dim fl As List =File.ListFiles(TargetTmpDir)
	If CltUtils.check_list_size(fl,1)=False Then 
		Return
	End If
	
	Dim tmp_filename As String 
	Dim ext As String = ".pid"
	Dim previousPIDMap As Map
	previousPIDMap.Initialize

	For i=0 To fl.Size-1
		tmp_filename = fl.Get(i)
					
		If tmp_filename.EndsWith(ext) Then
			'File.Delete(TargetTmpDir,tmp_filename)
			Dim extraInfoMap As Map = getExtraInfoMapByPortID(tmp_filename.SubString2(0,tmp_filename.LastIndexOf(".")))
			Dim PIDstr As String  = extraInfoMap.Get("pid")
			previousPIDMap.Put(PIDstr,"")
		End If
	Next	

	Dim pidMap As Map = comFunMod.SysGetRPidsByPname(OSName,isEnableJavasysmon)
	Dim getPIDFailed As Boolean = pidMap.Get("error")
	Dim pidList As List = pidMap.Get("list") 
	
	If getPIDFailed Then
		comFunMod.LogFmt("error", "getPIDFailed", $"stopPreviousRIstances"$)
	Else If CltUtils.check_list_size(pidList,1) Then
		For Each PID2kill As String In pidList
			If previousPIDMap.ContainsKey(PID2kill) Then
				Dim killsucess As Boolean = comFunMod.killProcessByPID(PID2kill, OSName)

				comFunMod.LogFmt("info", "", $"stopPreviousRInstances pid=${PID2kill} sucess=${killsucess}"$)
			End If
		Next
	End If
	
End Sub 




'20160709 if the app is stopped return proper status	
Public Sub TSisAppInitFailed (appn As String ) As Boolean
	Return AppInitFailedTsMap.ContainsKey(appn)
End Sub

Private Sub AppInitFailed (appn As String )
	AppInitFailedTsMap.Put(appn , DateTime.Now)
End Sub

Private Sub AppInitFailedUpdate
	Dim dt As Long 
	Dim expirems As Long = 60*1000
	Dim expireList As List
	expireList.Initialize
	For Each appstr As String In AppInitFailedTsMap.Keys
		dt =  AppInitFailedTsMap.Get(appstr)
		If (dt+expirems) < DateTime.Now Then
			expireList.Add(appstr)
		End If
	Next
	
	If expireList.Size>0 Then
		For i = 0 To expireList.Size -1
			AppInitFailedTsMap.Remove(expireList.Get(i))	
		Next
	End If
	 
End Sub


'when server.r and (ui.r, www/index.html); app.r not exist, this app may be a rmd file
'when index.rmd exist, rmdfile = filename ( case sensitive) or rmdfile=""
'{"error":T-F,"type":app-server-rmd,"rmdfile":"filenamecasesensitive"}
Private Sub checkAppFiles(app_fullpath As String) As Map
	Dim respMap As Map = CreateMap("error":False,"type":"server","rmdfile":"")
	If File.Exists(app_fullpath,"") And File.IsDirectory(app_fullpath,"") Then
	Else
		respMap.Put("error", True)
		Return respMap
	End If
	
	Dim fl As List = File.ListFiles(app_fullpath)
	If CltUtils.check_list_size(fl,1)=False Then
		respMap.Put("error", True)
		Return respMap
	End If
	
	Dim fn As String
	Dim fnLC As String
	For i = 0 To fl.Size-1
		fn = fl.Get(i)
		fnLC = fn.ToLowerCase
		Select fnLC
			Case "server.r"
				Return respMap 
			Case "app.r"
				respMap.Put("type", "app")
				Return respMap				
			Case "index.rmd"
				respMap.Put("type", "rmd")
				respMap.Put("rmdfile",fn)			
				Return respMap						
			Case Else
				 
		End Select
		
	Next
	
	Return respMap		
End Sub





'used after main.srvr init
private Sub initAppnewRsession
	MultiSessionAppMap = Main.srvr.CreateThreadSafeMap
	
	Dim path2 As String = Main.configPath
	
	If File.Exists(Main.testConfigPath, MultiSessionApp_Filename) Then
		path2 = Main.testConfigPath
	Else If File.Exists(Main.configPath, MultiSessionApp_Filename) Then
		path2 = Main.configPath
	Else 
		Return
	End If
	
	
	Dim fmap As Map = FileUtils.File_readMap_utf8(path2, MultiSessionApp_Filename,False)
	For Each appstr As String In fmap.Keys
		MultiSessionAppMap.Put(appstr, fmap.Get(appstr))
	Next
	
End Sub

Public Sub isStartNewRInstance(appInURL As String) As Boolean
	Return MultiSessionAppMap.ContainsKey(appInURL)
End Sub

