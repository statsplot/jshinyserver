Type=StaticCode
Version=4.7
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
' collection utils
Sub Process_Globals
	
End Sub



Sub check_map_size (tmp_map As Map, minsize As Int ) As Boolean
	
	If tmp_map<>Null And tmp_map.IsInitialized  Then
		If minsize<=0 Then 
			Return True
		Else
			If tmp_map.Size>=minsize Then 
				Return True
			End If
		End If
	End If	
	
	Return False
	
End Sub

'minsize included ; less than 0 not check
Sub check_list_size (tmp_list As List, minsize As Int ) As Boolean

	If tmp_list<>Null And tmp_list.IsInitialized  Then
		If minsize<=0 Then 
			Return True
		Else
			If tmp_list.Size>=minsize Then 
				Return True
			End If
		End If
	End If	
	
	Return False
End Sub




'add input_arg isIgnoreemptystring allow emptystring
'add input_arg isIgnoreEmptystringFirst
'not replace [ and ]
'not trim string
Public Sub String2List_mod (str As String,delimiter As String,checkIsNumber As Boolean, isIgnoreEmptyString As Boolean,isIgnoreFirstEmptyString As Boolean) As List
	Dim resList As List
	resList.Initialize
	'str=str.Trim
	If str.Length=0 Then Return resList
	'str=str.Replace("[","")
	'str=str.Replace("]","")	
	Dim arr() As String
	arr=Regex.Split(delimiter, str)
	For i=0 To arr.Length-1
		Dim strt  As String=arr(i)
		'strt=strt.Trim
		If checkIsNumber Then
			If IsNumber(strt)=False Then 
				resList.Initialize
				Return resList
			End If
		End If
		If isIgnoreEmptyString=False Then
			If isIgnoreFirstEmptyString=True And strt="" And i=0 Then
			Else
				resList.Add(strt)	
			End If
			
		Else
			If strt<> "" Then
				resList.Add(strt)
			End If			
		End If

	Next
	
	Return resList
End Sub




