Type=Class
Version=4.7
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'WebSocket class
Sub Class_Globals
	Private ws As WebSocket
	Private wsc As wsclientClassMod

	Private appname As String	'FULL app name
	Private msg2ShinyQ As List
	Private wscIsDisconnected As Boolean
	Private wscPort As Int
	
	Private timerIsAlive As Timer

	Private ManualCloseDt As Long = 0
	Private ManualCloseMs As Long = 4000
	
	Private lastMsg2ShinyDt As Long = 0
	Private lastIsAliveDt As Long
	
	Private WSDiscFired As Boolean = False
	
	Private paramWorkerid As String
	Private appFolderName As String
	Private RemoteIP As String
End Sub

Public Sub Initialize
	msg2ShinyQ.Initialize
End Sub



'this sub is called when (browser <-ws-> server )
'then the relay connection ( server <-wsc-> R session/shiny) is made 
Private Sub WebSocket_Connected (WebSocket1 As WebSocket)
	
Try
	wscIsDisconnected = True
	ws = WebSocket1
	comFunMod.ws_SetMaxTextMessage(ws, appM.wsMaxTextSizeKb)
	
	'get remote IP, checking X-Forwarded-For
	If ws.UpgradeRequest.GetHeader("X-Forwarded-For")<>"" Then
		RemoteIP = ws.UpgradeRequest.GetHeader("X-Forwarded-For")
	Else
		RemoteIP = ws.UpgradeRequest.RemoteAddress
	End If
	
	appFolderName =ws.UpgradeRequest.GetParameter("__app__")
	paramWorkerid =ws.UpgradeRequest.GetParameter("__w__")
	
	appFolderName = comFunMod.URL_Decode(appFolderName)
	paramWorkerid = comFunMod.URL_Decode(paramWorkerid)
	'full app name (url encoded)
	appname = comFunMod.getFullAppname(appFolderName,paramWorkerid)

	If appname="" Or appM.AppnameConfTsMap.ContainsKey(appname) = False Then		
		comFunMod.LogFmt("info", "wrong_appname", $"${RemoteIP} port=${wscPort} ${appname}"$)
		ws.Close
		Return		
	End If
	
	Dim confmap As Map = appM.AppnameConfTsMap.Get(appname)
	wscPort =confmap.Get("port")	
	Dim serverLink As String = "ws://127.0.0.1:"&wscPort&"/websocket/"
	
	Dim param_subws As String = ws.UpgradeRequest.GetParameter("__subws__")
	If param_subws<>"" Then
		'for sub app serverlink is different		
		serverLink =$"ws://127.0.0.1:${wscPort}${param_subws}websocket/"$ 
	End If
	
	

	'the relay connection ( server <-wsc-> R session/shiny) is made 
	wsc.Initialize(Me,"wsc",serverLink, appM.secClientMaxidleTimeout+120, appM.wscMaxTextSizeKb) 
	wsc.Connect
	'make sure the R session keep running
	appM.TSappnameUpdate(appname)
	
	comFunMod.AppLg(appname, "info", "wsConneted", $"${RemoteIP} port=${wscPort} "$) 
	
	
	'timer to check if the connection to R session is alive
	timerIsAlive.Initialize("timerIsAlive", appM.msClientTimerIsAlive)
	timerIsAlive.Enabled = True
	lastMsg2ShinyDt = DateTime.Now
	
Catch
	comFunMod.AppLg(appname, "error", "WebSocket_Connected", $"LastException"$) 
	Log(LastException)
End Try
	
End Sub


Private Sub WebSocket_Disconnected
	'only enter this sub once
	If WSDiscFired=True Then
		Return
	Else
		WSDiscFired = True
	End If

Try	
	wscIsDisconnected = True
	timerIsAlive.Enabled = False	
	msg2ShinyQ.Clear
	
	comFunMod.AppLg(appname, "info", "wsDisconnected", $"threadid=${Main.srvr.CurrentThreadIndex}"$) 
	appM.ThreadidAppnameTsMap.Remove(Main.srvr.CurrentThreadIndex)
	appM.ThreadStatTsMap.put(Main.srvr.CurrentThreadIndex,wscIsDisconnected)
		
	If wsc<>Null And wsc.IsInitialized Then 
		wsc.Close
	End If
	
	'destroy objects
	wsc = Null
	ws = Null
	timerIsAlive = Null
	

Catch

	comFunMod.AppLg(appname, "error", "WebSocket_Disconnected", $"LastException"$) 
	Log(LastException)
End Try
	
End Sub

' all message send to this sub are not forwarded to R session
' b4j consume all the messages
Private Sub b4jcustom_event (Params As Map) 		
	
	Dim type_str As String = Params.GetDefault("type","")
	type_str = type_str.ToLowerCase
	Select type_str
		Case "ping"
			'browsers send ping at certain interval to keep the ws connection open
			appM.TSappnameUpdate(appname)
	
		Case Else
				
	End Select

End Sub

'all messages received in this sub will be forwarded to R session(shiny)
Private Sub b4jwsclient_event (Params As Map) 		
	
	Dim msg As String = Params.GetDefault("para","")	
	sendMsg2Shiny(msg)
End Sub

'send messages (string) to R session(shiny)
'return a boolean
'true : before wsc connection is made ,msg is added to queue
'false : wsc is connected , msg is sent immediately
Sub sendMsg2Shiny(msg As String) As Boolean	

	If msg = "" Then 
		Return False
	End If
		
	If wscIsDisconnected = False Then
		lastMsg2ShinyDt = DateTime.Now
		wsc.SendText(msg)
		Return False
	End If
	
	'add to queue
	msg2ShinyQ.Add(msg)
	Return True
	
End Sub

'check if wsc is alive
'if ManualCloseDt is not 0. close the connection(browser and server)
Sub timerIsAlive_tick
	
	If wscIsDisconnected Then
	Else
		lastIsAliveDt = DateTime.Now
		appM.TSappnameUpdate(appname)				
	End If
	
	'if wscIsDisconnected = true for a very long time, close the connnection
	If ( ( lastIsAliveDt + 120*1000 ) < DateTime.Now ) Then
		If ManualCloseDt = 0 Then ManualCloseDt = DateTime.Now + ManualCloseMs
	End If
	
	' if not message is send to shiny(R process) for a time(secClientMaxidleTimeout), close the connnection
	If  ( (lastMsg2ShinyDt + appM.secClientMaxidleTimeout*1000) < DateTime.Now ) Then
		If ManualCloseDt = 0 Then ManualCloseDt = DateTime.Now + ManualCloseMs	
	End If
		
	If ManualCloseDt<>0 Then
		'close browser and server connection
		ws.Close
	Else
		'ping client to test ws connection
		Try
			If WSDiscFired=False Then
				ws.Eval("null;",Null)
	   			ws.flush
			End If
		Catch
			'Log(LastException)
		End Try
	End If

End Sub

' check msg2ShinyQ when wsc connected , send messages in the queue
Sub checkMsg2ShinyQ
	
	If wscIsDisconnected = False Then
		Do While msg2ShinyQ.Size>0
			Dim msg As String = msg2ShinyQ.Get(0)
			msg2ShinyQ.RemoveAt(0)
			lastMsg2ShinyDt = DateTime.Now
			wsc.SendText(msg)
		Loop		
	End If
	
End Sub


Private Sub wsc_Connected
	wscIsDisconnected = False
	'appM.TSaddThreadStatTsMap(Main.srvr.CurrentThreadIndex , wscIsDisconnected , appname ,wscPort)
	appM.ThreadStatTsMap.Put(Main.srvr.CurrentThreadIndex , wscIsDisconnected)
	appM.TSappnameUpdate(appname)
	appM.ThreadidAppnameTsMap.Put(Main.srvr.CurrentThreadIndex,appname)
	checkMsg2ShinyQ  'send messages in the queue

End Sub

Private Sub wsc_Closed (Reason As String)
	If wscIsDisconnected = False And WSDiscFired=False Then
		ws.Eval("socket.close();",Null)  'send singal to browser to close the connection (browser and server)
		ws.Flush		
	End If
	wscIsDisconnected = True
	
	If ManualCloseDt = 0 Then ManualCloseDt = DateTime.Now + ManualCloseMs

End Sub
'R sesion(shiny) messages -> Server
Private Sub wsc_newText (text As String)
	addNewMsg2ClientQ(text)
End Sub

'Server -> browser
Sub addNewMsg2ClientQ( msg As String)
	If msg = "" Then Return 

If WSDiscFired=False Then	
	ws.Eval(msg,Array As Object("__shinymsgs__"))
	ws.Flush
End If
End Sub




