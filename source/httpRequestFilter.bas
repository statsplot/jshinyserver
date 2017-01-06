Type=Class
Version=4.7
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'Filter class
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

'Return True to allow the request to proceed.
Public Sub Filter(req As ServletRequest, resp As ServletResponse) As Boolean
'reject all the *.js.map *.css.map files http requests	
#if not(debugmacos)	
	Dim RequestURI As String = req.RequestURI 
	If RequestURI.StartsWith("/shared_") Then
		If RequestURI.EndsWith(".js.map") Or RequestURI.EndsWith(".css.map") Then
			Return False
		End If
	End If
#end if	
	Return True
End Sub