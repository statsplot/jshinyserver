Type=StaticCode
Version=4.2
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'common functions


Sub Process_Globals
	Public rndPortMin As Int = 10000
	Private rndPortMax As Int = 40000
	
	Private shinyvMap As Map
	Public AppLgAllinOne As Boolean = False 'True	

	Public ServerStat_headerList As List = Array As String("date","time","loadavg","cpu","freem","totalm")
	Public ServerStat_headerList_jvm As List = Array As String("date","time" ,"loadavg","cpu","freem","totalm","jvmcpu","jvmhp","jvmhpcmt","connections","rsessions","apps")
	
	Public const LOGDELIM As String =  TAB '","
	
	' the follwing strings should  
	' no unicode allowded in this string and should not be changed after url_encoded
	Public const APPNDELIM As String =  "_._"  
	Public const buildinPre As String = "b__" 
	Public const buildinPre_LOG As String = "app_" 
	
End Sub


'error return the last port(which is not available) 
Sub getNextPortAvail (portno As Int) As Int
	Dim tmp_port As Int 
	For i = 0 To 30
		tmp_port = portno + i
		If isPortAvail(tmp_port,True) Then
			Return tmp_port
		End If
	Next

	For i = 0 To 300
		tmp_port = Rnd(rndPortMin,rndPortMax)
		If isPortAvail(tmp_port,True) Then
			Return tmp_port
		End If
	Next	
	'error return  a port which is not available 
	LogFmt("error", "getNextPortAvail", $"port=${tmp_port}"$)
	Return tmp_port 
End Sub

'port rndPortMin-rndPortMax :isCheckRange
Sub isPortAvail (portno As Int, isCheckRange As Boolean) As Boolean
	If isCheckRange=True Then
		If (portno < rndPortMin) Or (portno > rndPortMax) Then 
			Return False
		End If
	Else
		If (portno < 2) Or (portno > 65534) Then 
			Return False
		End If		
	End If
	
	Dim srvSocket As ServerSocket
	Dim isInUse As Boolean = True
	Try
		srvSocket.Initialize(portno,"")
		isInUse=False
	Catch
		isInUse=True
	End Try
	
	srvSocket.Close
	srvSocket = Null
	Return Not(isInUse)
End Sub



'killProcessByPID with commandline
'"win" "mac" "linux"
'Note: RunSynchronous may block the thread for no more than 4sec (average is less than 100ms)
Sub killProcessByPID(pid As String , os_str As String ) As Boolean

	Dim exe As String 	
	Dim sh2 As Shell
	Dim arglist As List
	arglist.Initialize
	
	Select os_str
		Case "win"
			'taskkill /f /pid PID

			exe ="taskkill"	
			arglist.Add("/f")
			arglist.Add("/pid")
			arglist.Add(pid)			
		Case "mac","linux"
			'kill -9 PID	
			exe = "kill"
			arglist.Add("-9")
			arglist.Add(pid)				
	End Select
	
	If arglist.Size=0 Then
		sh2.Initialize("sh2", exe , Null)
	Else
		sh2.Initialize("sh2", exe , arglist)
	End If
	
	sh2.WorkingDirectory = File.DirApp
	Dim Result As ShellSyncResult = sh2.RunSynchronous(4000)
	
	Dim isSuccess As Boolean = False
	If Result.Success And Result.ExitCode = 0 Then isSuccess = True
	
	sh2 = Null 
	Result = Null 
			
	Return isSuccess
			
End Sub 

'list of pids (int)
'none found size 0
'error null
'{"error": true/false , "list": [pid1,pid2] }
'Note: RunSynchronous may block the thread for no more than 4sec (average is less than 100ms)
Sub sysGetRPidsByPname(  os_str As String , isJavasysmon As Boolean) As Map
	Dim PidsList As List
	PidsList.Initialize
	Dim resMap As Map 
	resMap.Initialize 
		
	Dim Pname As String 
	Dim exeFullPath As String 	
	Dim sh2 As Shell
	Dim arglist As List
	arglist.Initialize

	Dim delimiter As String 
	Dim minrow As Int  'including header
	Dim pidposition As Int 
	
	Select os_str
		Case "win"
			'tasklist	
			delimiter = ","
			minrow = 2  'output with header
			pidposition = 1
						
			Pname = "Rterm.exe"	 ' on windows need to kill Rterm.exe instead of R.exe
			sh2.InitializeDoNotHandleQuotes("", "tasklist", Array As String("/FI", $""IMAGENAME eq ${Pname}""$ , "/FO" , "CSV"))
				
		Case "linux"

			'ps -o pid -C R (full match; output with header)
			'PID
			'464

			delimiter = " "
			minrow = 2 'has header
			pidposition = 0	
					
			Pname = "R"	
			exeFullPath= "ps"
			arglist.Add("-o")
			arglist.Add("pid")
			arglist.Add("-C")
			arglist.Add(Pname)			
			sh2.InitializeDoNotHandleQuotes("", exeFullPath, arglist)
		Case "mac"				
			Pname = "R"	
			
	End Select
	
	If isJavasysmon Or os_str="mac" Then
		Dim resMap33 As Map = sysGetRPidsByPnameJavasysmon(Pname)
	
		Return resMap33
	End If
	
	Dim tmpdir22 As String = Main.DirTemp
	sh2.WorkingDirectory = tmpdir22
	Dim Result As ShellSyncResult = sh2.RunSynchronous(4000)

	Dim ResultStdOut As String = Result.StdOut 

 
	If os_str="linux" Then
		ResultStdOut = ResultStdOut.Trim	
		
	End If

		
	Dim isSuccessful As Boolean = False
	If Result.Success And Result.ExitCode = 0 Then 
		isSuccessful = True
	Else
		'bugfix if all R session is killed pidList.Size = 0 
		If os_str="linux" Then
			If ResultStdOut.ToLowerCase.StartsWith("pid") Then isSuccessful = True
			
		End If
	End If
	
	If isSuccessful=False Then
		LogFmt("error", "GetRPidsFail", $" ResultStdOut=${ResultStdOut}  Result.StdErr=${Result.StdErr} Result.ExitCode=${Result.ExitCode} "$)
	End If
	
	sh2 = Null  
	Result = Null  
	
	If isSuccessful = False Then		
		resMap = CreateMap( "error": True  , "list": PidsList)
		Return resMap
	End If
	
	Dim isParseFail As Boolean = True
	Try
		
		Dim filename_tmp As String = DateTime.Now&"_"&Rnd(10000,20000)
		File.WriteString( tmpdir22 , filename_tmp , ResultStdOut)
				
						
		Dim su As StringUtils
		Dim list2 As List = su.LoadCSV( tmpdir22 , filename_tmp, delimiter )	
		If CltUtils.check_list_size(list2,minrow) = False Then
			 File.Delete( tmpdir22 , filename_tmp)
			 Return  CreateMap( "error": False  , "list": PidsList)
		End If
		
		
		Dim pidint As Int 
		For i = 0 To list2.Size-1
			Dim arrstr() As String =list2.Get(i) 
			If arrstr.Length>=(pidposition+1) And IsNumber( arrstr(pidposition)) Then
				pidint = arrstr(pidposition)
				PidsList.Add(pidint)
			End If	
		Next	
			
		isParseFail = False			
	Catch
		LogFmt("error", "sysGetRPidsByPname", $" LastException"$)
		Log(LastException)
		PidsList.Initialize
		isParseFail = True
	End Try	
	
	File.Delete( tmpdir22 , filename_tmp)

	Return CreateMap( "error": isParseFail  , "list": PidsList)
End Sub





'remove isb4x
'error return map {"__error__": "Data format error"}
Sub B4XReadObj(filepath As String,filename As String) As Object
	Dim raf As RandomAccessFile
	Try	
		
	    raf.Initialize(filepath, filename,True)   
	    	Dim obj As Object=raf.ReadB4XObject(raf.CurrentPosition)
		raf.Close	
		Return obj
	Catch
		raf.Close
		Dim emptymap As Map 
		emptymap.Initialize
		emptymap.Put("__error__","Data format error")
		Dim obj2 As Object=emptymap
		
		Return obj2
	End Try

End Sub



public Sub Server_RemoveVersionFromResponses (Server As Server)
   Dim jo As JavaObject = Server
   jo = jo.GetField("server")
   Dim connectors() As Object = jo.RunMethod("getConnectors", Null)
   For Each co As JavaObject In connectors
     Dim connections() As Object = co.RunMethodJO("getConnectionFactories", Null).RunMethod("toArray", Null)
     For Each connection As JavaObject In connections
       If GetType(connection) = "org.eclipse.jetty.server.HttpConnectionFactory" Then
         Dim configuration As JavaObject = connection.RunMethod("getHttpConfiguration", Null)
         configuration.RunMethod("setSendServerVersion", Array(False))
       End If
     Next
   Next
End Sub	

public Sub Server_setFormMaxSize(Server2 As Server,sizeKB As Int)
	Dim jo As JavaObject = Server2
	jo.GetFieldJO("context").RunMethod("setMaxFormContentSize", Array(1000*sizeKB))
End Sub

Public Sub ws_SetMaxTextMessage(ws2 As WebSocket ,sizeKb As Int)
   Dim jo As JavaObject = ws2
   jo = jo.GetFieldJO("session").RunMethod("getPolicy", Null)
   jo.RunMethod("setMaxTextMessageSize", Array(sizeKb*1000))
End Sub

public Sub Server_setStaticAndErrorpages (Server2 As Server)
	Dim staticfilemap As Map =CreateMap("gzip":True,"dirAllowed":False,"etags":True,"cacheControl":"max-age=300","acceptRanges":False)
	Server2.SetStaticFilesOptions(staticfilemap)	
	Dim err As Map
	err.Initialize
	err.Put(404, "/404.html") 'page not found
	err.Put(500, "/500.html") 'server error
	err.Put("org.eclipse.jetty.server.error_page.global", "/errors.html")
	Server2.SetCustomErrorPages(err)	
End Sub





Sub ServerStatLog(dtmap As Map)
	
	Dim sb As StringBuilder
	sb.Initialize
	
	Dim mp As Map = getServerStat
	
	For Each key As String In mp.Keys
		dtmap.Put(key,mp.Get(key))
	Next
	
	Dim threadsmap As Map = appM.getThreadStatTsMap
	For Each key As String In threadsmap.Keys
		dtmap.Put(key,threadsmap.Get(key))
	Next	
	
	Dim ServerStat_header As List = ServerStat_headerList_jvm
	
	
	Dim key As String
	For i=0 To ServerStat_header.Size-1
		key=ServerStat_header.Get(i)
		sb.Append(dtmap.Get(key))
		If i<>ServerStat_header.Size-1 Then sb.Append(LOGDELIM)
	Next	
	
	Dim logFilename As String = "server_stat.log"
	
	If File.Exists(Main.LogsPath,logFilename)=False Then
		Dim sbh As StringBuilder
		sbh.Initialize
		Dim key As String
		For j=0 To ServerStat_header.Size-1
			key=ServerStat_header.Get(j)
			sbh.Append(key)
			If j<>ServerStat_header.Size-1 Then sbh.Append(LOGDELIM)
		Next		
		FileUtils.FileWriteAppend(Main.LogsPath,logFilename,sbh.ToString)			
	End If
	
	FileUtils.FileWriteAppend(Main.LogsPath,logFilename, sb.ToString )	
	
	AppStatLog(dtmap)

End Sub

Sub AppStatLog(dtmap As Map)

	Dim m3 As Map = appM.getAppStatTsMap
	'If m3.Size>0 Then
		Dim jsg As JSONGenerator
		jsg.Initialize(m3)
		FileUtils.FileWriteAppend(Main.LogsPath,"server_appstat.log",dtmap.Get("date") & LogDelim &dtmap.Get("time") & LogDelim &  jsg.ToString)	
	'End If
	
End Sub

Sub getServerStat As Map 
	
	Dim mp As Map
	mp.Initialize

	Dim Staticsmap As Map = getStatics
	
	Dim NewKey As String
	Dim tmpDouble As Double
	For Each keystr As String In Staticsmap.Keys
		tmpDouble = Staticsmap.Get(keystr)
		If keystr.EndsWith("_byte") Then 
			NewKey = keystr.Replace("_byte", "")		
			tmpDouble = tmpDouble/(1024*1024)
		Else
			NewKey = keystr
		End If
		
		mp.Put(NewKey, Format2(tmpDouble))	
	Next
	
	Return mp
End Sub

'Get pid of current Java process ; May not work on all JVM
' Tested: win 7 64bit ; ubuntu 14.04 lts 64bit ; mac os
'error -1 
'http://www.golesny.de/p/code/javagetpid
Sub getPID As Int
	Dim jo As JavaObject 
	jo.InitializeStatic("java.lang.management.ManagementFactory")
	Dim pidstr As String = jo.RunMethodJO("getRuntimeMXBean",Null).RunMethod("getName",Null) 
	pidstr = pidstr.SubString2(0,pidstr.IndexOf("@"))
	Dim pid As Int = -1
	If IsNumber(pidstr) Then
		pid = pidstr
	End If
	Return pid
End Sub


Sub Format2(d As Double) As String
	Return NumberFormat2(d,1,3, 3, False)
End Sub

public Sub getStatics As Map
	Dim NativeMe As JavaObject
	NativeMe = Me
	Dim m As Map = NativeMe.RunMethod("getStatics", Null)
	Dim cpu_double As Double = m.Get("cpu")
	If cpu_double<0 Then 
		m.Put("cpu",0) 
	End If
	Return m
End Sub


public Sub getSystemProcessInfoJavasysmon(processName As String) As List
	
	Private NativeMe As JavaObject
	NativeMe = Me
	Dim resPidList As List
	resPidList.Initialize
	
	Dim taskmap As Map
	Try
		Dim b As Map  = NativeMe.RunMethod("getSystemProcessInfo", Null)
		Dim taskList As List = b.Get("tasklist")
		Dim pidint As Int
		
		If taskList=Null Or taskList.IsInitialized = False Then
			taskList.Initialize
		Else
			For jjj=0 To taskList.Size-1
				taskmap = taskList.Get(jjj)
					
				If taskmap.Get("getName") = processName Then
					pidint = taskmap.Get("getPid") 
					
					resPidList.Add( 	pidint )	
				End If
			Next			
		End If

	Catch
		LogFmt("error", "getSystemProcessInfoJavasysmon", $"LastException"$)
		Log(LastException)
		Return Null
	End Try	
	
	Return resPidList
End Sub

'{"error": true/false , "list": [pid1,pid2] }
Sub sysGetRPidsByPnameJavasysmon(processName As String) As Map

	Dim RpidList As List = getSystemProcessInfoJavasysmon(processName)
	
	
	If RpidList = Null Or RpidList.IsInitialized=False Then
		LogFmt("error", "sysGetRPidsByPnameJavasysmon", $"  "$)
		RpidList.Initialize
		Return CreateMap("error": True, "list":RpidList )
	End If

	Return CreateMap("error": False, "list":RpidList )
	
End Sub

Public Sub printSystemInformation
	
	

	DateTime.SetTimeZone(0)
	DateTime.DateFormat="yyyy-MM-dd"
 	DateTime.TimeFormat="HH:mm:ss"	
	Log($"Time = ${DateTime.Date(DateTime.Now)} ${DateTime.Time(DateTime.Now)} UTC"$)	
	Log($"Serverversion = ${Main.ShinyServerVersion}.${Main.ShinyServerVersion_Minor}"$)
	Dim NativeMe As JavaObject
	NativeMe = Me
	Dim SystemInfoMap As Map = NativeMe.RunMethod("getSystemInfomation", Null)
	For Each key As String In SystemInfoMap.Keys
		Log($"${key} = ${SystemInfoMap.Get(key)}"$)
	Next
	
End Sub



#If JAVA
import java.io.*;
import com.sun.management.OperatingSystemMXBean;
import java.lang.management.*;
import anywheresoftware.b4a.objects.collections.Map;


  public static Object getStatics() {

	anywheresoftware.b4a.objects.collections.Map m = new anywheresoftware.b4a.objects.collections.Map();
	m.Initialize();
	
    OperatingSystemMXBean operatingSystemMXBean = (OperatingSystemMXBean)ManagementFactory.getPlatformMXBean(OperatingSystemMXBean.class); 
	m.Put("loadavg", operatingSystemMXBean.getSystemLoadAverage());
	m.Put("jvmcpu", operatingSystemMXBean.getProcessCpuLoad() );
    m.Put("cpu", operatingSystemMXBean.getSystemCpuLoad() );
	m.Put("freem_byte", operatingSystemMXBean.getFreePhysicalMemorySize() ); 
	m.Put("totalm_byte", operatingSystemMXBean.getTotalPhysicalMemorySize() );
	

    MemoryMXBean memoryMXBean = ManagementFactory.getMemoryMXBean();
	m.Put("jvmhp_byte", memoryMXBean.getHeapMemoryUsage().getUsed() );
	m.Put("jvmhpcmt_byte", memoryMXBean.getHeapMemoryUsage().getCommitted() );
	
	return m.getObject();
  }


  public static Object getSystemInfomation() {

	anywheresoftware.b4a.objects.collections.Map m = new anywheresoftware.b4a.objects.collections.Map();
	m.Initialize();
	
    OperatingSystemMXBean operatingSystemMXBean = (OperatingSystemMXBean)ManagementFactory.getPlatformMXBean(OperatingSystemMXBean.class); 
	m.Put("Java", System.getProperty("java.version"));
	m.Put("JavaVendor", System.getProperty("java.vendor"));
	m.Put("JavaRuntime", System.getProperty("java.runtime.version"));
	m.Put("Processors", Runtime.getRuntime().availableProcessors() );
	
	OperatingSystemMXBean localOSB = (OperatingSystemMXBean)ManagementFactory.getPlatformMXBean(OperatingSystemMXBean.class);
	m.Put("System", localOSB.getName() ); 
	m.Put("Arch", localOSB.getArch() ); 
		
	m.Put("TotalMemory", operatingSystemMXBean.getTotalPhysicalMemorySize()/1024/1024 );
	return m.getObject();
  }
		  	
#End If



#If JAVA


import java.util.*;
import anywheresoftware.b4a.objects.collections.Map;
import com.jezhumble.javasysmon.*;




public static Object getSystemProcessInfo() {

	anywheresoftware.b4a.objects.collections.Map m = new anywheresoftware.b4a.objects.collections.Map();
	m.Initialize();
	
	JavaSysMon monitor = new JavaSysMon();	
	ProcessInfo pinfos[] = monitor.processTable();
	
	List<Object> listPID = new ArrayList<Object>();	
	for (int j = 0; j < pinfos.length; j++) {  
	  	ProcessInfo pinfo = pinfos[j];  

		anywheresoftware.b4a.objects.collections.Map taskmap = new anywheresoftware.b4a.objects.collections.Map();
		taskmap.Initialize();	
		taskmap.Put("getName",pinfo.getName());	 
			 
		taskmap.Put("getOwner",pinfo.getOwner() );	 
		taskmap.Put("getPid",pinfo.getPid()  );	 
		//System.out.println(taskmap); 
		
		taskmap.Put("getParentPid",pinfo.getParentPid()  );	
		
		// may not available with Mac OSX 
		taskmap.Put("getCommand",pinfo.getCommand() );
		// Mac OSX only for current process
		taskmap.Put("getUserMillis",pinfo.getUserMillis()  );	 
		taskmap.Put("getSystemMillis",pinfo.getSystemMillis()  );	 
		taskmap.Put("getResidentBytes",pinfo.getResidentBytes()  );	 
		taskmap.Put("getTotalBytes",pinfo.getTotalBytes()  );	 
		 
			
	  	listPID.add(taskmap.getObject());
	} 
	
	m.Put("tasklist", listPID );
	return m.getObject();
}

          	
#End If




Sub genIndexPage(isWrite2staticFilesPath As Boolean , filename As String ) As String
	
	
	Dim sb As StringBuilder
	sb.Initialize
	Dim fl As List
	fl.Initialize
	Dim ap As String
	
	For Each ap As String In appM.inFolderAppnameTsMap.Keys
		fl.Add(ap)		
	Next
	fl.Sort(True)

	Dim unsupportedList As List
	Dim unsupportedListPrint As List
	unsupportedListPrint.Initialize
	unsupportedList.Initialize

	
	For i = 0 To fl.Size -1
		ap = fl.Get(i)
		If unsupportedList.IndexOf(ap) = -1 Then	
			sb.Append($" <a href='/${Main.htmlRootPath}/${URL_Encode(ap)}/index.html'>${ap}</a></br> "$ )
			sb.Append(CRLF)

		End If
	Next
	
	For k = 0 To unsupportedList.Size -1
		ap = unsupportedList.Get(k)
		If fl.IndexOf(ap)>-1 Then
			unsupportedListPrint.Add(ap)
		End If
	Next
	
	Dim sb2 As StringBuilder
	sb2.Initialize
	If CltUtils.check_list_size(unsupportedListPrint,1) Then
		sb2.Append(CRLF)
		sb2.Append($" <mark>The following apps do not work due to R package or server dependency issues (might be fixed later)</mark> "$)
		sb2.Append(CRLF).Append("<ul>")
		For j=0 To unsupportedListPrint.Size-1
			Dim ap2 As String = unsupportedListPrint.Get(j)
			ap2=ap2.Trim
			If ap2<>"" Then
				sb2.Append($"<li> ${ap2} </li>"$).Append(CRLF)
			End If
		Next
		sb2.Append("</ul>").Append(CRLF)	
	End If
	
	Dim indexPageTemplate As String
	indexPageTemplate = File.ReadString( Main.configPath , "index.template")

	indexPageTemplate = indexPageTemplate.Replace("$applist$", sb.ToString)
	indexPageTemplate = indexPageTemplate.Replace("$unsupportedlist$", sb2.ToString)
	
	If isWrite2staticFilesPath Then 
		File.Delete( Main.staticFilesPath , filename)
		File.WriteString(Main.staticFilesPath, filename , indexPageTemplate)
	End If
	
	Return 	indexPageTemplate
	
End Sub


Public Sub URL_Encode (url As String ) As String
	Dim su As StringUtils
	Return su.EncodeUrl(url,"UTF8")
End Sub

Public Sub URL_Decode (url As String ) As String
	Dim su As StringUtils
	Return su.DecodeUrl(url,"UTF8")
End Sub





'used after srvr init
'return true 
'return false when failed
'currently defaultversion is not used
Public Sub initshinyvMap(versionFile As String, isMustWork As Boolean) As Boolean
	If shinyvMap = Null Or shinyvMap.IsInitialized=False  Then
		shinyvMap = Main.srvr.CreateThreadSafeMap
	End If
	
	
	
	Try	
		If File.Exists( Main.configPath  , versionFile) Then
			Dim tmpMap As Map = File.ReadMap( Main.configPath  , versionFile)
			
			If CltUtils.check_map_size(tmpMap,1)=False Then
				If isMustWork Then Return False
			End If
					
			For Each key As String In tmpMap.Keys
				Dim versionmap As Map
				Dim jsonp As JSONParser	
				Dim jsonstring As String = tmpMap.Get(key)			
				jsonp.Initialize(jsonstring)
				versionmap = jsonp.NextObject
				versionmap.Put("jsonstring",jsonstring)
				shinyvMap.Put(key,map2TreadsafeMap(versionmap))
			Next
			
		End If
	Catch
		If isMustWork Then Return False
	End Try
	
'	If shinyvMap.ContainsKey(defaultversion)=False Then
'		Return False
'	End If
'	
'	shinyvMap.Put("default", defaultversion)	
	Return True
	
End Sub

'used after main.srvr init
'error return an empty map
'key:string value: string
Public Sub map2TreadsafeMap(commonMap As Map) As Map
	Dim tmpTSMap As Map 
	tmpTSMap = Main.srvr.CreateThreadSafeMap
	If commonMap=Null Or commonMap.IsInitialized=False Then 
		Return tmpTSMap
	End If
	For Each key As String In commonMap.Keys
		Dim tmpstring As String = commonMap.Get(key)
		tmpTSMap.Put(key, tmpstring)	
	Next
	Return tmpTSMap
End Sub


'input arg wsurl removed
'add input arg shinyver string, default "" 0.13
'shinyver not found Error return "" 
'v2 load from shinyversion.conf   0.14 = {"init":"","utils":"","mod":"0.14","base":"0.14","sharedpath":"0.14"}
'shinyvnotsupported string  currently only supported "notsupported"
public Sub shiny_HtmlReplaced(str As String, shinyver As String, shinyvnotsupported As String) As String
	shinyvnotsupported = "notsupported"
	
	Dim iscontainVersion As Boolean = True
	If shinyvMap.ContainsKey(shinyver) = False Then
		iscontainVersion = False
		
		If shinyvnotsupported = "notsupported" Or shinyvMap.ContainsKey(shinyvnotsupported)=False Then
			'notsupported  not found : show shiny version not supported page
			Return ""			
		End If
		
		Dim shinyver_org As String = shinyver		
		shinyver = shinyver_org				
		'LogFmt("info", "shiny_HtmlReplaced", $" shinyver=${shinyver_org} is not supported. Default version=${shinyver} is used "$)
	End If
	
If iscontainVersion=True Then
	Dim versionmap As Map = shinyvMap.Get(shinyver)
	Dim shinyverJsonStr As String = versionmap.Get("jsonstring")
	
	Dim shinyver_Init As String = versionmap.GetDefault("init","")

	Dim rep_str As String = $"<script>var _g_shinyver = "${shinyver}"; ${CRLF} var _g_shinyvermap = ${shinyverJsonStr}; ${CRLF} </script> <script src="/shared_mod/shiny.init_${shinyver_Init}.js"></script>"$
#if stringReplace
	str = str.Replace($"<script src="shared/shiny.min.js"></script>"$ , rep_str )
	str = str.Replace($"<script src="shared/shiny.js"></script>"$ , rep_str )
#else	
	Dim regPat As String = $"<script ( |.)*?(src=["'](shared\/shiny(.min)?.js)["'])( |.)*?>( )*?<\/script>"$
	str = ReplacePattern(str,regPat,rep_str)
#end if	
	str = str.Replace($"script src="shared/"$,$"script src="/shared_${versionmap.GetDefault("sharedpath","")}/"$)
	str = str.Replace($"link href="shared/"$,$"link href="/shared_${versionmap.GetDefault("sharedpath","")}/"$)
	
	Return str
Else
	
	Return ""		
End If

End Sub


Sub shiny_JSReWrite(dir As String,filename As String)

	Dim res As String = File.ReadString(dir,filename)
	res = ReplacePattern(res,"this\.createSocket\s*=\s*function\s*\(","this.createSocket = socket_ShinyAppM.createSocket || function (")
	res = ReplacePattern(res,"this\.\$sendMsg\s*=\s*function\s*\(","this.$sendMsg = socket_ShinyAppM.$sendMsg || function (")
	File.WriteString(dir,filename,res)

End Sub

Sub RandomString(Length As Int, LowerCase As Boolean, UpperCase As Boolean, Numbers As Boolean, AdditionalChars As String) As String
    Dim source As String
    If LowerCase = True Then
        source = source &"abcdefghijklmnopqrstuvwxyz"
    End If
    If UpperCase = True Then
        source = source &"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    End If
    If Numbers = True Then
        source = source &"0123456789"
    End If
    If AdditionalChars.Length > 0 Then
        source = source&AdditionalChars
    End If

    Dim SB As StringBuilder
	SB.Initialize
	For i = 1 To Length
	Dim R As Int = Rnd(0,source.Length-1)
	    SB.Append(source.SubString2(R,R+1))
	Next
	Return SB.ToString
End Sub


'adapt from webutils ReplaceMap
Public Sub ReplacePattern(Base As String, regexstr As String, replacestr As String) As String
	Dim pattern As StringBuilder
	pattern.Initialize
	pattern.Append(regexstr)
	
	
	Dim m As Matcher = Regex.Matcher(pattern.ToString, Base)
	Dim result As StringBuilder
	result.Initialize
	Dim lastIndex As Int
	Do While m.Find
		result.Append(Base.SubString2(lastIndex, m.GetStart(0)))
		'If m.Match.ToLowerCase.StartsWith("$h_") Then replace = EscapeHtml(replace)
		result.Append(replacestr)
		lastIndex = m.GetEnd(0)
	Loop
	If lastIndex < Base.Length Then result.Append(Base.SubString(lastIndex))
	Return result.ToString
End Sub






Public Sub getFullAppname(AppFoldername As String,wid As String) As String
	AppFoldername = AppFoldername.Trim
	wid = wid.Trim
	
	If wid<>"" Then
		Return AppFoldername & APPNDELIM & wid
	Else	
		Return AppFoldername
	End If
End Sub

Public Sub getAppnameWorkerID(fullappn As String) As Map
	Dim tmpmap As Map = CreateMap("appname":"","workerid":"")
	
	Dim i As Int = fullappn.IndexOf(APPNDELIM)
	If i=-1 Then
		tmpmap.Put("appname",fullappn)
	Else			
		tmpmap.Put("appname",fullappn.SubString2(0,i))
		tmpmap.Put("workerid",fullappn.SubString(i+APPNDELIM.Length))
	End If
	Return tmpmap	
End Sub

Public Sub getAppFolderName(fullappn As String) As String 
	Dim tmpmap As Map = getAppnameWorkerID(fullappn)
	Return tmpmap.Get("appname")
End Sub

Public Sub getAppWorkerID(fullappn As String) As String 
	Dim tmpmap As Map = getAppnameWorkerID(fullappn)
	Return tmpmap.Get("workerid")
End Sub

Public Sub genFullAppName(appn As String) As String 
	Return appn & APPNDELIM & RandomString(12,True,False,True,"")
End Sub

Public Sub isBuildinApp(FullAppn As String) As Boolean
	Return FullAppn.StartsWith(buildinPre)
End Sub

Public Sub isAppwithID(FullAppn As String) As Boolean
	Return FullAppn.Contains(APPNDELIM)
End Sub



'fullRequestURL http(s)://www.example.com:port/ab/cd/xy.js?k=v#ref
'requestURL /ab/cd/xy.js
'error notfound return ""
'ok return "k=v"
'NOTE: input must be URL-encoded 
Sub getQueryString(fullRequestURL As String) As String
	If fullRequestURL.Contains("?") = False Then Return ""
	Dim indexLastQu As Int = fullRequestURL.LastIndexOf("?")
	Dim indexLastSharp As Int = fullRequestURL.LastIndexOf("#")
	If indexLastSharp=-1 Or indexLastQu>indexLastSharp Then
		Return fullRequestURL.SubString(indexLastQu+1)
	Else
		Return fullRequestURL.SubString2(indexLastQu+1,indexLastSharp)
	End If
End Sub








'error return ""
'alg = "MD5" "SHA-1" "SHA-256" "SHA-512" 
Sub getFileHash(Dir As String, fileName As String, alg As String) As String
	If File.Exists(Dir,fileName)=False Or File.IsDirectory(Dir,fileName) Then
		Return ""
	End If
	
	Dim in As InputStream 
	in = File.OpenInput(Dir,fileName)
	Dim buffer(File.Size(Dir, fileName)) As Byte
	'Dim count As Long
	in.ReadBytes(buffer, 0, buffer.length)
	Dim Bconv As ByteConverter
	Dim data(buffer.Length) As Byte 
	Dim md As MessageDigest
	data = md.GetMessageDigest(buffer, alg) 
	
	Return Bconv.HexFromBytes(data)
	
End Sub



'remove workerid in the url 
'http://127.0.0.1:8888/shiny/012-datatables(0)/{_._workerid}(1)/datatables-binding-0.1(2)/datatables.js?_k=v&__w__=xyz&__app__=123#ref
'wid in query string is not changed
'fullurl is not url-decoded
Sub URL_Remove_WID(fullurl As String, nTh As Int) As String

	Dim ind As Int = StringIndexOfNth(fullurl,"/",nTh)
	If ind<0 Then Return fullurl
	
	If fullurl.IndexOf(APPNDELIM) = (ind+1) Then
		Dim next_index As Int = StringIndexOfNth(fullurl,"/",nTh+1)
		If next_index<=ind Then Return fullurl
		Return fullurl.SubString2(0,ind) & fullurl.SubString(next_index)
	Else
		Return fullurl
	End If
	
End Sub


'http://127.0.0.1:8888/shiny/012-datatables(0)/datatables-binding-0.1(2)/datatables.js?_k=v&__w__=xyz&__app__=123#ref
'== 
'datatables-binding-0.1(2)/datatables.js?_k=v&__w__=xyz&__app__=123#ref
'NOTE :fullRequestURL should not contain workerid /_._{workerid} 
'error return empty stirng
Sub URL_suburl(fullURL_NO_WID As String, nTH As Int) As String
	
	Try	
		Dim ind As Int = StringIndexOfNth(fullURL_NO_WID, "/", nTH)		
		If ind<0 Then Return ""	
		Return fullURL_NO_WID.SubString(ind+1) 'datatables-binding-0.1/datatables.js?_k=v
	Catch
		Return ""
	End Try
		
End Sub



' return __subws__=URL-encoded{xyz}&__subsearch__URL-encoded{123}
'error return __subws__=&__subsearch__
' url-encoded  string
'   full_url=http://127.0.0.1:8888/shiny/026-shiny-inline_subapp/app83efa12c86ab568d3d81f6fba706aef9/?w=&__subapp__=1		
'	__subws__=encode(/app83efa12c86ab568d3d81f6fba706aef9/)
'	__subsearch__=encode( w=&__subapp__=1 )
'NOTE: input url must be URL-encoded
Sub URL_RmdSubQS(fullURL_NO_WID As String ,ws_nth As Int) As String 
	'Dim resmap As Map = CreateMap("__subws__":"","__subsearch__":"")

	Dim sub_ws As String
	Dim sub_search As String
Try
	
	Dim index_search As Int = fullURL_NO_WID.LastIndexOf("?")
	If index_search = -1 Then
		sub_search = ""
	Else
		sub_search = fullURL_NO_WID.SubString(index_search+1)
	End If
	
	'Dim idxofslash As Int =5 

	Dim ind As Int = StringIndexOfNth(fullURL_NO_WID,"/",ws_nth)
	If ind<0 Then 
		sub_ws=""
	Else
					
		If index_search = -1 Then
			sub_ws = fullURL_NO_WID.SubString(ind)
		Else
			sub_ws = fullURL_NO_WID.SubString2(ind,index_search)
		End If
		
	End If
	
Catch
	sub_ws = ""
	sub_search = ""			 		
End Try
	
	sub_ws = URL_Encode(sub_ws)
	sub_search = URL_Encode(sub_search)
	
	Return $"__subws__=${sub_ws}&__subsearch__=${sub_search}"$
End Sub



'get bookmark querystring 
'http://127.0.0.1:8888/shiny/{appFoldername}_._{workerid}/index.html?{__w__=xyz}&{__app__=zyx}&{_inputs_&}{_state_id_=f63a29c29959f3aa}	
'return {_inputs_&...}  or {_state_id_=f63a29c29959f3aa} 'NOT URL encoded
'not found return empty string 	
Sub URL_getBookmarkQS(fullurl2 As String) As String
		Dim cQS As String = getQueryString(fullurl2)
		Dim indexInputs As Int = cQS.LastIndexOf("_inputs_&")
		If indexInputs = -1 Then
			indexInputs = cQS.LastIndexOf("_state_id_=")	
		End If
		If cQS <> "" And indexInputs > -1 Then
			Return cQS.SubString(indexInputs)
		Else
			Return ""	 
		End If	
	
End Sub



'not found -1
'error -2
'nth starts with 1
public Sub StringIndexOfNth(str As String, targetchar As Char , nth As Int) As Int
	If nth <= 0 Then Return -2
	If (str.Length=0) Then Return -2
	Dim count As Int = 0

	For i = 0 To str.Length - 1
		Dim C As Char = str.CharAt(i)
		Select C
			Case targetchar
				count = count + 1
				If count = nth Then 
					Return i
				End If			
			Case Else

		End Select
	Next
	
	Return -1
End Sub


'port from getContentTypeByExt  
' no ToLowerCase
'not found ""
'NOTE: input must be URL-encoded 
Sub getUrlExt(filename As String) As String
	'filename = filename.ToLowerCase.Trim
	filename = filename.Trim
	'Dim default As String = "application/octet-stream"
	' http//ip:port/x/y/z.js?k=v
	' http//ip:port/x/y/z?k=v
	Dim lastindexquery As Int = filename.LastIndexOf("?")
	Dim lastindexext As Int = filename.LastIndexOf(".")
	If lastindexquery>0 And lastindexquery>lastindexext Then
		filename = filename.SubString2(0,lastindexquery)
	End If
	
	If filename.Contains(".") = False Or ( lastindexext = filename.Length ) Then 
		Return ""
	End If
	
	Dim ext As String = filename.SubString( filename.LastIndexOf(".") + 1 )

	Return ext.Trim
End Sub


'/x/y/z.js?k=v -> /z.js
'z.css?k=v -> z.css
'z.js -> z.js
'NOTE: input must be URL-encoded 
Sub URL_RemoveQueryString(filename As String) As String
	filename = filename.Trim
		
	Dim lastindexquery As Int = filename.LastIndexOf("?")
	'Dim lastindexSlash As Int = filename.LastIndexOf("/")
	If lastindexquery>0 Then
		filename = filename.SubString2(0,lastindexquery)
	End If
	
	Return filename
End Sub

'NOTE: input must be URL-encoded 
Sub getContentTypeByExt(filename As String) As String
	filename = filename.ToLowerCase.Trim
	Dim default As String = "application/octet-stream"
	' http//ip:port/x/y/z.js?k=v
	' http//ip:port/x/y/z?k=v
	Dim lastindexquery As Int = filename.LastIndexOf("?")
	Dim lastindexext As Int = filename.LastIndexOf(".")
	If lastindexquery>0 And lastindexquery>lastindexext Then
		filename = filename.SubString2(0,lastindexquery)
	End If
	
	If filename.Contains(".") = False Or ( lastindexext = filename.Length ) Then 
		Return default
	End If
	
	Dim ext As String = filename.SubString( filename.LastIndexOf(".") + 1 )
	ext = ext.Trim

	Return appM.extMineTsMap.GetDefault(ext,default)
End Sub




'---error return empty map	
'---parseUrl("http://example.com:80/docs/books/tutorial/index.html?name=networking#DOWNLOADING")
'protocol = http
'authority = example.com:80
'host = example.com
'port = 80
'path = /docs/books/tutorial/index.html
'query = name=networking&k2=a?Fb
'filename = /docs/books/tutorial/index.html?name=networking&k2=a?Fb
'ref = DOWNLOADING
Sub URL_parse(url As String) As Map
	Dim NativeMe As JavaObject
	NativeMe = Me
	Try
		Dim urlMap As Map = NativeMe.RunMethod("parseUrl", Array(url))
	Catch
		urlMap.Initialize
		Log(LastException)
	End Try
	

	

	
	Return urlMap	
End Sub

	
#If JAVA

	import java.net.*;
	import java.io.*;

    public static Object parseUrl(String urlstring) throws Exception {

        URL aURL = new URL(urlstring);

		anywheresoftware.b4a.objects.collections.Map m = new anywheresoftware.b4a.objects.collections.Map();
		m.Initialize();
		
		m.Put("protocol", aURL.getProtocol());
		m.Put("authority", aURL.getAuthority());
		m.Put("host", aURL.getHost());
		m.Put("port", aURL.getPort());
		m.Put("path", aURL.getPath());
		m.Put("query", aURL.getQuery());
		m.Put("filename", aURL.getFile());
		m.Put("ref", aURL.getRef());
						   
		return m.getObject();
    }


#End If









Sub checkInput( value As String, checkMap As Object ) As String
	If checkMap Is String Then
		Return ""
	Else If checkMap Is Map Then	
	Else
		Return ""
	End If
	
	Dim map1 As Map = checkMap
	If CltUtils.check_map_size(map1,1) = False Then Return ""
	
	Dim typeString As String = map1.GetDefault("type","string")
	Dim minString As String = map1.GetDefault("min","")
	Dim maxString As String = map1.GetDefault("max","")

	Select typeString
		Case "long","double"
			Dim isLong As Boolean = True
			If typeString ="double" Then  isLong= False 
			Return CheckInputNum(value, isLong , minString,maxString)
		Case "string"
			value = value.Trim
			If minString<>"0" And value.Length=0 Then
				Return "String is empty"
			Else
				Return ""
			End If
		Case Else
			Return ""
	End Select
	


End Sub


'typeInt to typeLong
Sub CheckInputNum(NumToCheck As String,typeLong As Boolean,mini As String,maxi As String) As String 
	Dim tmpDouble As Double
	
	Dim str0 As String = "Input is not a valid number" 
	Dim str1 As String = "Input Number Should be an Integer"
	Dim str2 As String = "Input Number Should be No Less than "&mini
	Dim str3 As String = "Input Number Should be No Greater than "&maxi
	
	
	If IsNumber(NumToCheck)=False Then
	   Return str0
	End If

' fix e , +  in a float/int
	Dim Valid As Boolean
	Valid = Regex.IsMatch("^(-?\d+)(\.\d+)?$", NumToCheck)            
	If Valid=False Then
		Return str0
	End If

	If typeLong Then 
	   	If NumToCheck.Contains(".") Or  NumToCheck.ToLowerCase.Contains("e") Then
	   		Return str1
	  	End If
	Else
'20140625 fix e in a float
		If NumToCheck.ToLowerCase.Contains("e") Then
	   		Return str0
	   	End If
	End If
	
	tmpDouble=NumToCheck

	If IsNumber(mini) Then
		Dim miniDouble As Double =mini
		If tmpDouble < miniDouble Then	   	
		    Return str2
		End If
	End If

	If IsNumber(maxi) Then
		Dim maxiDouble As Double =maxi
		If tmpDouble > maxiDouble Then	   	
		    Return str3
		End If				   
	End If
	Return ""
	
End Sub



'error return empty map 
public Sub getShinyVersion(RbinFullPath As String,r_args As String, lc_all As String) As Map
	
	Dim DirTmp As String = Main.DirTemp	
	Dim Filename As String = "getshinyversion"	
	
	Dim rscript_template_filename As String = FileUtils.File_FullPath(File.Combine(File.DirApp,"Rcode/getshinyversion.R")) 
	Dim rscript_temp As String = File.ReadString(rscript_template_filename,"")
	rscript_temp = rscript_temp.Replace("#g_filename#", FileUtils.File_FullPath(DirTmp & "/" & Filename))
	rscript_temp = rscript_temp.Replace("#g_locale_LC_ALL#", lc_all)		

	Dim shellgetShinyversion As Shell
	Dim tmpFolder As String = File.DirApp
	Dim arglist As List
	arglist.Initialize

	
'   clear previous files .json .error	
	File.Delete(DirTmp,Filename&".json")
	File.Delete(DirTmp,Filename&".error")

	File.WriteString(DirTmp, Filename&".script", rscript_temp)
	Dim scriptFullpath As String = DirTmp & "/" & Filename &".script"
	scriptFullpath = FileUtils.File_FullPath(scriptFullpath)
	

	Dim Exe As String = RbinFullPath 
	If r_args<> "" Then
		arglist.Add(r_args)
	End If
	arglist.Add("-q")
	
	arglist.Add("-e")
	arglist.Add("source( '" & scriptFullpath & "' )")	
		
	shellgetShinyversion.InitializeDoNotHandleQuotes("", Exe, arglist)	
	shellgetShinyversion.WorkingDirectory = tmpFolder

	Dim Result As ShellSyncResult = shellgetShinyversion.RunSynchronous(20*1000)
	
	'Dim isSuccess As Boolean = False
	
	Dim resMap As Map 
	resMap.Initialize
	
	If File.Exists(DirTmp,Filename&".error")=True Or File.Exists(DirTmp,Filename&".json")=False Then
		Return resMap	
	End If
	
	Try
		Dim jsonp As JSONParser
		Dim jsonstr As String = File.ReadString(DirTmp,Filename&".json")
		jsonp.Initialize(jsonstr)
		Dim tmpmap As Map = jsonp.NextObject
		Dim list1 As List = tmpmap.Get("shinyversion")
		Dim list2 As List = tmpmap.Get("shinyshared")
		resMap.Put(	"shinyversion" , list1.Get(0))
		resMap.Put(	"shinyshared" , list2.Get(0))		
		Dim list3 As List = tmpmap.Get("getlocale")
		If CltUtils.check_list_size(list3,1) Then
			resMap.Put(	"getlocale" , list3.Get(0))
		Else
			resMap.Put(	"getlocale" , "NOT FOUND")		
		End If
	Catch
		resMap.Initialize
		'Log(LastException)
		LogFmt("error", "getShinyVersion", $"LastException"$)
		Log(LastException)
	End Try

	Return resMap		
End Sub


public Sub checkShinyVer(ShinyVer As String) As Boolean
	Return shinyvMap.ContainsKey(ShinyVer)
End Sub

public Sub clearshinyvMap
	shinyvMap.Clear
End Sub

'yyyy-MM-ddTHH:mm:ssZ
public Sub PrintDT As String
	DateTime.SetTimeZone(0)
	DateTime.DateFormat="yyyy-MM-dd"
 	DateTime.TimeFormat="HH:mm:ss"	
	Dim dt As Long = DateTime.Now
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append(DateTime.Date(dt))
	sb.Append("T")
	sb.Append(DateTime.Time(dt))
	sb.Append("Z")
	Return sb.ToString
End Sub

'yyyy_MM_dd_HH_mm_ss so it can be used in a file/folder name
public Sub PrintDT2 As String
	Dim dtmap As Map = getDT(0)
	Dim date As String = dtmap.Get("date")
	Dim time As String = dtmap.Get("time")
	Dim delim As String = "_"
	date = date.Replace("-",delim)
	time = time.Replace(":",delim)
	Return date & delim & time
End Sub

'{date:"yyyy-MM-dd",time:"HH:mm:ss"}
public Sub getDT(tz As Int) As Map
	DateTime.SetTimeZone(tz)
	DateTime.DateFormat="yyyy-MM-dd"
 	DateTime.TimeFormat="HH:mm:ss"	
	Dim dt As Long = DateTime.Now
	Return CreateMap("date":DateTime.Date(dt),"time":DateTime.Time(dt))
End Sub


'msgType : fatal error warn info debug other (case insenitive)
'msgTag  : msg Tag( could be sub name or empty string)
public Sub FormatLog(msgType As String, msgTag As String, msg As String) As String
	msgType = msgType.ToLowerCase
	Select msgType
		Case "fatal","error","warn","info","debug"
			
		Case Else
			msgType = "other"
	End Select
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("[").Append(msgType).Append("]")
	sb.Append(TAB)
	sb.Append(PrintDT)
	sb.Append(TAB)	
	sb.Append(msgTag)
	sb.Append(TAB)
	sb.Append(msg)
	
	Return sb.ToString
End Sub

public Sub LogFmt(msgType As String, msgTag As String, msg As String) 
	If msgType = "debug" And appM.isLogDebug=False Then Return
	Log(FormatLog(msgType, msgTag, msg))
End Sub

public Sub AppLg(appname3 As String, msgType As String, msgTag As String, msg As String ) 
	If msgType = "debug" And appM.isLogDebug=False Then Return
	WriteShinyLogByAppname(appname3, FormatLog(msgType, msgTag, msg) )	
End Sub

public Sub WriteShinyLogByAppname(appname As String , string2write As String)

Try
	Dim workerid As String
	Dim logname As String = "app_"
	If isBuildinApp(appname) Then
		logname = buildinPre_LOG
	End If
			
	If isAppwithID(appname) Then	
		workerid = getAppWorkerID(appname)	
		appname = getAppFolderName(appname)		
		string2write = $"${string2write} workerid=${workerid}"$
	End If
	
	If AppLgAllinOne Then
		FileUtils.FileWriteAppend(Main.LogsPath, "app_000logallinone.log", appname & TAB & string2write)
	Else
		FileUtils.FileWriteAppend(Main.LogsPath, logname & appname & ".log", string2write)	
	End If
		

Catch
	'in case some words in appname is not support by some OS
	LogFmt("error", "WriteShinyLogByAppname", $" error write log : ${appname} ${string2write} "$)
End Try

End Sub


'check the appname(full) and paraM app(appFoldername) and w (workerid)
'if not it is not in MultiSessionAppand  paramW<>"" return false
'if it is in MultiSessionApp, paramW and paramApp should be empty or not empty at the same time
public Sub URL_checkIndex(appninURL As String, WIDinUrl As String, req As ServletRequest, isNewRS As Boolean) As Boolean

	Dim paramApp As String =req.GetParameter("__app__")
	Dim paramW As String =req.GetParameter("__w__")
	
	paramApp = URL_Decode(paramApp)
	paramW = URL_Decode(paramW)

	If paramW<>"" And WIDinUrl <> paramW Then
		Return False
	End If

	If paramApp<>"" And appninURL <> paramApp Then
		Return False
	End If
			
	If isNewRS=False Then
		If paramW<>"" Then
		    Return False
		End If
	Else
		If paramApp="" And paramW="" Then
		else if paramApp<>"" And paramW<>"" Then
		Else
			Return False
		End If	
	End If
	
	If appninURL="" Then
		Return False
	End If
	Return True	
	
End Sub

' any string with APPNDELIM is workerid;  return workerid (without APPNDELIM)
' not workerid return empty string
public Sub getWorkerId(str As String) As String
	If str.StartsWith(APPNDELIM) Then
		Return str.SubString(APPNDELIM.Length)
	Else
		Return ""
	End If
End Sub


public Sub URL_WorkerId2URLElement(WorkerId As String) As String
	Return APPNDELIM & WorkerId 
End Sub

Sub URL_getRed(afn As String,WIdinURL As String) As String
	Dim redURL2 As String = URL_Encode(afn)
	If WIdinURL <> "" Then
		redURL2 = $"${redURL2}/${URL_Encode(URL_WorkerId2URLElement(WIdinURL))}"$ 
	End If	
	Return redURL2
End Sub





Public Sub CopyShinySharedFiles(shinyPkgSharedFolder As String, shinyver As String) As Boolean
	shinyPkgSharedFolder = FileUtils.File_FullPath(shinyPkgSharedFolder)
	
	shinyver = shinyver.Trim
	If shinyver = "" Then
		LogFmt("error", "CopyShinySharedFiles", $"shinyver is empty string"$)
		Return False
	End If
	
	Dim serverwwwFolder As String = Main.staticFilesPath
	Dim targetFolderName As String = "shared_" & shinyver
	Dim targetFolder As String = FileUtils.File_FullPath(File.Combine(serverwwwFolder,targetFolderName))
	Dim source As String = shinyPkgSharedFolder

'check target folder	
	If File.Exists(targetFolder, "") = True Then
		LogFmt("error", "CopyShinySharedFiles", $" targetfolder=${targetFolder} already exsits "$)
		Return False
	End If
	
'check source folder	
	If FileUtils.File_checkFolder(source,"",True) = False Then
		LogFmt("error", "CopyShinySharedFiles", $"sourcefolder=${source} not exsit"$)
		Return False		
	End If
'check source/shiny.js
	If FileUtils.File_checkFolder(source,"shiny.js",False) = False Then
		LogFmt("error", "CopyShinySharedFiles", $"shiny.js not exsit"$)
		Return False			
	End If
 	
	
'check www/shared_mod/shiny.base_${sv}.js
		
	Dim sharedmodbase_filename As String = $"shiny.base_${shinyver}.js"$
	Dim sharedmodbase_dir As String = File.Combine(serverwwwFolder,"shared_mod")
	If File.Exists(sharedmodbase_dir,sharedmodbase_filename) Then
		LogFmt("error", "CopyShinySharedFiles", $"sharedmodbase_filename=${sharedmodbase_filename} exsits"$)
		Return False	
	End If
	
'copy source to target	
	Dim isSuccess As Boolean = True
'	Try 
'		isSuccess = File_CopyFolder(source,targetFolder)
'	Catch
'		isSuccess = False   
'	End Try
	
	FileUtils.File_CopyFolder(source,targetFolder)
	
	If isSuccess=False Then 
		LogFmt("error", "CopyShinySharedFiles", $"copy sourcefolder=${source} to targetfolder=${targetFolder} Failed"$)
		Return False
	End If	
	
'create  www/shared_mod/shiny.base_${sv}.js
	File.Copy(source,"shiny.js",sharedmodbase_dir,sharedmodbase_filename)
	shiny_JSReWrite(sharedmodbase_dir,sharedmodbase_filename)
	
'add new shiny version to  config/shinyversion_additional.conf	
	Dim configStr As String = $"${Chr(13)&Chr(10)}${shinyver}   = {"init":"v1","utils":"v1","mod":"0.14","base":"${shinyver}","sharedpath":"${shinyver}"}"$ 	
	FileUtils.FileWriteAppend(Main.configPath,"shinyversion_additional.conf",configStr)


	Return True
	
End Sub





' main---------

'Redirect stdOut stdErr to a file
Sub RedirectOutput (Dir As String, FileName As String)
#if RELEASE
   Dim out As OutputStream = File.OpenOutput(Dir, FileName, False) 'Set to True to append the logs
   Dim ps As JavaObject
   ps.InitializeNewInstance("java.io.PrintStream", Array(out, True, "utf8"))
   Dim jo As JavaObject
   jo.InitializeStatic("java.lang.System")
   jo.RunMethod("setOut", Array(ps))
   jo.RunMethod("setErr", Array(ps))
#end if
End Sub


'pass return true
'error return false
Sub checkConfigAvailable As Boolean
	Dim isAvailable As Boolean = True
	
'check fields
	Dim kvMap As Map 
	kvMap.Initialize
'long	
	kvMap.Put("port",CreateMap("type":"long","min":1,"max":65535))
	
	Dim longMap As Map = CreateMap("type":"long","min":1,"max":1000000000)		
	kvMap.Put("wsmaxtextsizekb",longMap)	
	kvMap.Put("wscmaxtextsizekb",longMap)	
	kvMap.Put("formmaxsizekb",longMap)	
	kvMap.Put("memlimit1",longMap)	
	kvMap.Put("memlimit2",longMap)	
	
	Dim longMap2 As Map = CreateMap("type":"long","min":120,"max":1000000000)		
	kvMap.Put("client_maxidle_timeout",longMap2)
'	Dim longMap3 As Map = CreateMap("type":"long","min":10,"max":1000000000)
'	kvMap.Put("checkstatusinterval",longMap3)
	Dim longMap4 As Map = CreateMap("type":"long","min":40,"max":1000000000)
	kvMap.Put("app_idle_timeout",longMap4)	
	Dim longMap5 As Map = CreateMap("type":"long","min":10,"max":50)
	kvMap.Put("app_init_timeout",longMap5)
		
'double	
	Dim doubleMap As Map = CreateMap("type":"double","min":0.1,"max":1)
	kvMap.Put("cpulimit1",doubleMap)	
	kvMap.Put("cpulimit2",doubleMap)
'string
	Dim stringMap As Map = CreateMap("type":"string","min":1)
	kvMap.Put("shinyfolder",stringMap)	
	kvMap.Put("redirect_output",stringMap)	
	kvMap.Put("htmlroot",stringMap)	
	kvMap.Put("rbin",stringMap)
	kvMap.Put("shiny_sanitize_errors",stringMap)
	kvMap.Put("loglevel",stringMap)
			
'string (could be empty) 	
	Dim stringMap As Map = CreateMap("type":"string","min":0)
	kvMap.Put("pandoc",stringMap)	
	kvMap.Put("lc_all",stringMap)	
	kvMap.Put("r_args",stringMap)	

		
	Dim isMissingKey As Boolean = False
	For Each key As String In kvMap.Keys
		If appM.SettingTsMap.ContainsKey(key) = False Then
			isMissingKey = True
			LogFmt("error", "checkConfigAvailable", $"config key is missing : ${key}"$)
		End If
	Next
	If isMissingKey = True Then
		Return False
	End If
	
	Dim isExtraKey As Boolean = False
	For Each key As String In appM.SettingTsMap.Keys
		If kvMap.ContainsKey(key) = False Then
			LogFmt("error", "checkConfigAvailable", $"Unexpected config key : ${key}"$)
			isExtraKey = True
		End If
	Next	
	If isExtraKey = True Then
		Return False
	End If
	
	Dim isError As Boolean = False
	For Each key As String In kvMap.Keys
		Dim tmpValue As String = appM.getSettingMapValue( key ) 
		Dim errorMsg As String = checkInput(tmpValue,kvMap.Get(key))
		If errorMsg<> "" Then
			LogFmt("error", "checkConfigAvailable", $" config ${key}=${tmpValue} : ${errorMsg} "$)
			isError = True
			
		End If
	Next
	If isError = True Then
		Return False
	End If	
		
	Dim srvrPort1 As String = appM.getSettingMapValue("port" )  					
	If isPortAvail(srvrPort1,False)=False Then
		LogFmt("error", "checkConfigAvailable", $"port=${srvrPort1} is not available. Server will not start."$)
		isAvailable = False
	End If

	Dim rPath As String = appM.getSettingMapValue("rbin")
	If File.Exists(rPath,"") And File.IsDirectory(rPath,"")=False Then
	Else
		LogFmt("error", "checkConfigAvailable", $"R exe is not found at rbin=${rPath}"$)
		isAvailable = False
	End If	
	
	Dim ShinyAppFolder As String = appM.getSettingMapValue("shinyfolder")
	If File.Exists(ShinyAppFolder,"") And File.IsDirectory(ShinyAppFolder,"") Then
	Else
		LogFmt("error", "checkConfigAvailable", $" Shiny app folder is not available shinyfolder=${ShinyAppFolder} "$)
		isAvailable = False			
	End If		
	
	Dim PandocFolder As String = appM.getSettingMapValue("pandoc")
	PandocFolder = PandocFolder.Trim
	If PandocFolder = "" Then
	Else If File.Exists(PandocFolder,"") And File.IsDirectory(PandocFolder,"") Then
	Else
		LogFmt("error", "checkConfigAvailable", $" Pandoc folder is not available pandoc=${PandocFolder}  "$)
		isAvailable = False			
	End If		

' htmlroot should be a-z0-9
	Dim htmlroot_str As String = appM.getSettingMapValue("htmlroot")
	If htmlroot_str <> "" Then
		If Regex.IsMatch("^[a-zA-Z0-9]+$", htmlroot_str) = False Then
			LogFmt("error", "checkConfigAvailable", $" Wrong htmlroot format : htmlroot=${htmlroot_str} "$)
			isAvailable = False				
		End If
	End If
		
	Return isAvailable
End Sub




'check if the shiny version is supported 
Sub checkandPrepareShinyFiles

	Dim getshinyvermap As Map = getShinyVersion(appM.getSettingMapValue("rbin"),appM.getSettingMapValue("r_args"),appM.getSettingMapValue("lc_all"))
	If getshinyvermap.Size = 0 Then 
		LogFmt("error", "", $" check shiny version file Failed "$)
		ExitApplication	
	End If
	
	Log($"Sys.getlocale=${getshinyvermap.Get("getlocale")}"$)

	Dim createshinyfiles_success As Boolean = True
	Dim shinyver2 As String = getshinyvermap.Get("shinyversion")   '"0.14.1"
	Dim shinysharedpath As String = getshinyvermap.Get("shinyshared")   '"F:\Program Files\R\R-3.3.1\library\shiny\www\shared"
	Dim isShinyverAdditional As Boolean = False
	
	
'get exsiting shinyversions in config/shinyversion.config and config/shinyversion_additional.conf
	If initshinyvMap("shinyversion.conf",True) = False Then
		LogFmt("error", "checkandPrepareShinyFiles", $" initshinyvMap failed. Server exit "$)
		ExitApplication
	End If
	isShinyverAdditional = Not( checkShinyVer(shinyver2) )
	initshinyvMap("shinyversion_additional.conf",False)	
	
'check if shinyver is supported; supported exit this sub
	If checkShinyVer(shinyver2) Then

		If isShinyverAdditional Then
			Log($"******************"$)
			LogFmt("warn", "", $" Shiny version=${shinyver2} is not tested, some of the apps may not work properly "$)
			Log($"******************"$)			
		Else
			Log($"Shiny version=${shinyver2}"$)
		End If
		Return	
	End If

'check if config/extrashinyversion.support exsits. if not server exit
	If File.Exists(Main.configPath,"extrashinyversion.support") = False Then
		LogFmt("error", "checkandPrepareShinyFiles", $" Shiny version not supported: shinyversion=${shinyver2} "$)
		ExitApplication			
	End If
	
'try to get shiny shared folders per shiny version
	'File.Delete(Main.configPath,"extrashinyversion.support")
	
'clear shinyvMap (will be loaded later)
	clearshinyvMap
	
	Try	
		createshinyfiles_success = CopyShinySharedFiles(shinysharedpath,shinyver2)
	Catch
		createshinyfiles_success = False 
	End Try
	
	If createshinyfiles_success = False Then
		LogFmt("error", "prepareShinyFiles", $" create files Failed "$)
		ExitApplication
	Else
		Log($"******************"$)
		LogFmt("info", "", $"Create shiny shared files for shinyversion=${shinyver2}"$)
		LogFmt("warn", "", $"Shiny version=${shinyver2} is not tested, some of the apps may not work properly "$)		
		Log($"******************"$)	
	End If
	
End Sub



