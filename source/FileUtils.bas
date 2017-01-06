Type=StaticCode
Version=4.7
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@

Sub Process_Globals
	
End Sub


'F:\a bc\d.txt -> F:/a bc/d.txt
Sub File_FullPath(path As String ) As String 
	path = File_GetCanonicalPath(path) 
	Return path.Replace("\","/")
End Sub

Sub File_GetCanonicalPath(Path As String) As String
   Dim fileO As JavaObject
   fileO.InitializeNewInstance("java.io.File", Array As Object(Path))
   Return fileO.RunMethod("getCanonicalPath", Null)

End Sub


Sub File_ListSubFolderName(TmpDir As String) As List

	Dim folderList As List 
	folderList.Initialize
	Dim fl As List = File.ListFiles(TmpDir)
	If fl.IsInitialized=False Then fl.Initialize
	If fl.Size=0 Then
		Return folderList
	Else
		For i=0 To fl.Size-1
			If File.IsDirectory(TmpDir,fl.Get(i)) Then
				folderList.Add( fl.Get(i) )
			End If
		Next	
	End If

	Return folderList
		
End Sub


'clear files in a folder; subfolders(with files inside) will not be cleared
Sub File_ClearFolder(TargetTmpDir As String)
	If File.Exists(TargetTmpDir,"") =False Or File.IsDirectory(TargetTmpDir,"")=False Then
		Return 
	End If 
	
	Dim fl As List =File.ListFiles(TargetTmpDir)
	If fl=Null Or fl.IsInitialized=False Then fl.Initialize
	If fl.Size=0 Then 
	Else
		For i=0 To fl.Size-1
			File.Delete(TargetTmpDir,fl.Get(i))
		Next	
	End If
End Sub 

'extMap {".pid":"", ".input":"",".script":""}
Sub File_ClearFolder_extfilter(TargetTmpDir As String, extMap As Map)
	If File.Exists(TargetTmpDir,"") =False Or File.IsDirectory(TargetTmpDir,"")=False Then
		Return 
	End If 
	
	Dim fl As List =File.ListFiles(TargetTmpDir)
	If fl=Null Or fl.IsInitialized=False Then fl.Initialize
	Dim tmp_filename As String 
	
	
	If fl.Size=0 Then 
	Else
		For i=0 To fl.Size-1
			tmp_filename = fl.Get(i)
			For Each ext As String In extMap.Keys
				If tmp_filename.EndsWith(ext) Then
					File.Delete(TargetTmpDir,tmp_filename)
				End If
			Next
		Next	
	End If
End Sub 

'fnWithoutExt  233/abc
'extMap {".pid":"", ".input":"",".script":""}
Sub File_DelFile_NameAndExtfilter(TargetTmpDir As String, fnWithoutExt As String, extMap As Map)

	If File.Exists(TargetTmpDir,"") =False Or File.IsDirectory(TargetTmpDir,"")=False Then
		Return 
	End If 
	fnWithoutExt = fnWithoutExt.Trim
	If fnWithoutExt = "" Then Return
	
	Dim fn As String 
	For Each ext As String In extMap.Keys
		fn = fnWithoutExt & ext
		File.Delete(TargetTmpDir,fn)
	Next	

End Sub 




'create a sub folder
'fail return currentFolder
'success return full path of subfoldername
Sub File_CreateSubFolder(currentFolder As String ,  subfoldername As String ) As String
	Dim tmp_folder As String = subfoldername
	File.MakeDir(currentFolder, tmp_folder)
	If File.Exists(currentFolder, tmp_folder) And File.IsDirectory(currentFolder, tmp_folder ) Then
		Return File.Combine( Main.DirTemp , tmp_folder )	
	Else
		Return currentFolder
	End If	
	
End Sub

Sub File_CreateFolderIfNotExsit(parentFolder As String ,  subfoldername As String )
	If File.Exists(parentFolder,subfoldername)=False Then
		File.MakeDir(parentFolder, subfoldername)
	End If
End Sub

'checkIsFolder true  check target is folder
'checkIsFolder false  check target is file
'not exist return false
Sub File_checkFolder(parentPath As String,Foldername As String, checkIsFolder As Boolean) As Boolean	
	If File.Exists(parentPath,Foldername)=False Then Return False
	
	If checkIsFolder Then
		Return File.IsDirectory(parentPath,Foldername)
	Else
		Return Not( File.IsDirectory(parentPath,Foldername) )
	End If
			
End Sub


'File.readMap read files use ISO 8859-1 encoding, unicode words in utf8 will not work correctly 
'File_readMap_utf8 use file.List and parse the file
'ignore empty lines and lines start with # or !
'key and value are trimmed
'error return not initialized map
'NOTE Unicode like \u0009 and backslash \(multiple lines) are not supported
'for map/properties files that modified by hand
'allowKeyOnlyLine is true means that if a line doesn't contain = 'equal sign' , it's taken as key with value is empty string 
Sub File_readMap_utf8(dir As String ,filename As String,allowKeyOnlyLine As Boolean) As Map
	Dim resMap As Map
	resMap.Initialize
	
	Dim uninitilizedMap As Map
	If File_checkFolder(dir,filename,False)=False Then 
        LogFmt_local("error", "File_readMap_utf8", $"file not found ${File.Combine(dir,filename)}"$)
		Return uninitilizedMap
	End If
	
	
	Dim alist As List = File.ReadList(dir,filename)
	If alist=Null Or alist.Size=0 Then Return resMap
	
	Dim line As String
	Dim key As String
	Dim value As String
	Dim index As Int
	For i = 0 To alist.Size-1
		line = alist.Get(i)
		line = line.Trim
		If line.StartsWith("#") Or line.StartsWith("!") Or line="" Then
			'comments or empty lines
		Else If line.Contains("=")=False  Then 
			key = line
			value = ""
			resMap.Put(key,value)
		Else If line.Contains("=") Then 	
			index = line.IndexOf("=")
			key = line.SubString2(0,index)
			value = line.SubString(index+1)
			key = key.Trim
			value = value.Trim
			If key <> "" Then
				resMap.Put(key,value)
			Else			
				LogFmt_local("error", "File_readMap_utf8", $"empty key found when reading ${File.Combine(dir,filename)}"$)
				Return uninitilizedMap
			End If
		Else
			' not used line ${i} ${line} "$	
		End If				
	Next
	
	Return resMap
End Sub



Public Sub File_CopyFolder(Source As String, targetFolder As String)
  
	If File.Exists(targetFolder, "") = False Then File.MakeDir(targetFolder, "")
	For Each f As String In File.ListFiles(Source)
		If File.IsDirectory(Source, f) Then
			File_CopyFolder(File.Combine(Source, f), File.Combine(targetFolder, f))
			Continue
		End If
		File.Copy(Source, f, targetFolder, f)
	Next

End Sub


Sub FileWriteAppend(filePath As String,filename As String, string2write As String)

	Dim Writer As TextWriter
	Writer.Initialize(File.OpenOutput(filePath,filename , True))
	Writer.WriteLine(string2write)
	Writer.Close
	
End Sub


' custom log format here 
private Sub LogFmt_local(msgType As String, msgTag As String, msg As String)  
	
	comFunMod.LogFmt(msgType , msgTag, msg) 
	
End Sub