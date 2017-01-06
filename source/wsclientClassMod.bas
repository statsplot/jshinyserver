Type=Class
Version=4.7
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'Class module
#Event: Connected
#Event: Closed (Reason As String)
Sub Class_Globals
	Private ws As WebSocketClient
	Private CallBack As Object
	Private EventName As String
	Private wsUrl As String
	
'ping
	'Private lastServerPong As Long
	Public ping_intervl_sec As Int = 60
	Public ping_disconnect_count As Int = 4
		
'reconnect		
	Private ReconnectCount As Int=0		
	
End Sub

Public Sub Initialize (vCallback As Object, vEventName As String , vwsUrl As String , MaxIdleSec As Long , MaxTextSizeKb As Int)
	CallBack = vCallback
	EventName = vEventName
	wsUrl = vwsUrl
	ws.Initialize("ws")
	Set_wsc(ws, MaxIdleSec ,30 , MaxTextSizeKb)
	
End Sub

Public Sub Connect

	ReconnectCount=ReconnectCount+1
	ws.Connect(wsUrl)

End Sub



Public Sub Close
	ws.Close
End Sub

Private Sub ws_TextMessage(msg As String)
	'lastServerPong = DateTime.Now
	CallSub2(CallBack, EventName & "_" & "newText", msg)	
End Sub

Private Sub ws_Connected
	ReconnectCount = 0
	'lastServerPong = DateTime.Now
	CallSub(CallBack,  EventName & "_Connected")

End Sub

Private Sub ws_Closed (Reason As String)
	CallSub2(CallBack, EventName & "_Closed", Reason)
End Sub



Public Sub SendText(text As String )
	 
	ws.SendText(text)
End Sub

Public Sub SendMap(etype As String , text As String )
	Dim mp As Map = CreateMap("etype":etype,"text":text)
	Dim jsong As JSONGenerator
	jsong.Initialize(mp)
	SendText(jsong.ToString)

End Sub


Sub wsh_Pong(Params As List)
	'lastServerPong = DateTime.Now
End Sub

Sub getReconnectCount As Int
	Return ReconnectCount
End Sub 


Public Sub isConnected() As Boolean
	Return ws.Connected
End Sub



'http://download.eclipse.org/jetty/9.3.8.v20160314/apidocs/org/eclipse/jetty/websocket/client/WebSocketClient.html
Sub Set_wsc(wsc As  WebSocketClient , MaxIdleSec As Long ,connecttimeoutSec As Long , MaxTextMessageSizeKb As Int)
	
   Dim jo As JavaObject = wsc
   jo = jo.GetFieldJO("wsc")  

   Dim tmp_int As Int = MaxTextMessageSizeKb *1024
   Dim joSetSize As JavaObject  = jo.RunMethod("getPolicy", Null)
   joSetSize.RunMethod("setMaxTextMessageSize", Array(tmp_int))
      
   Dim tmp_long As Long 
   tmp_long = MaxIdleSec*1000
   jo.RunMethod("setMaxIdleTimeout", Array(tmp_long))
   tmp_long = connecttimeoutSec*1000 
   jo.RunMethod("setConnectTimeout", Array(tmp_long)) 
   
End Sub	
