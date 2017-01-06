Type=StaticCode
Version=4.7
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@

' HttpUtils2 code moudule modified  
' Combined apache HttpClient(jHTTP) and OkHttpClient(OkHttp)
' OkHttpClient is default http client. If you need to use apache HttpClient, add apachehc to the build configuration and select correct library(jHTTP), deselect OkHttpClient library(OkHttp) 

Sub Process_Globals
	
#if apachehc	
	Private hc As HttpClient
#else
	Private hc As OkHttpClient
#end if

	Private TaskIdToJob As Map
	Public TempFolder As String
	Private taskCounter As Int
		
	Private timercleantmp As Timer
		
End Sub


Sub Initialize(tmpfoldername As String)
	Dim isdelayedcleantmp As Boolean =True 'always clear expired data ( when job.release is not called manually ) 
	If hc.IsInitialized = False Then
		
		TempFolder = FileUtils.File_CreateSubFolder(Main.DirTemp , tmpfoldername)
		
		hc.Initialize("hc")
		
#if apachehc	
#else
		Dim jo As JavaObject = hc
		Dim nativeClient As JavaObject = jo.GetField("client")
		nativeClient.RunMethodJO("getDispatcher", Null).RunMethod("setMaxRequests", Array (50))
		nativeClient.RunMethodJO("getDispatcher", Null).RunMethod("setMaxRequestsPerHost", Array (50))
#end if
			
		TaskIdToJob.Initialize
		If isdelayedcleantmp = True Then
			timercleantmp.Initialize("timercleantmp",120*1000)
			timercleantmp.Enabled = True	
		End If	
	End If
		
End Sub



Public Sub SubmitJob(job As HttpJob) As Int
	taskCounter = taskCounter + 1
	If taskCounter>1e6 Then
		taskCounter = 1
	End If
	TaskIdToJob.Put(taskCounter, job)
	If job.Username <> "" And job.Password <> "" Then
		hc.ExecuteCredentials(job.GetRequest, taskCounter, job.Username, job.Password)
	Else
		hc.Execute(job.GetRequest, taskCounter)
	End If
	Return taskCounter
End Sub

#if apachehc	
Sub hc_ResponseSuccess (Response As HttpResponse, TaskId As Int)
#else
Sub hc_ResponseSuccess (Response As OkHttpResponse, TaskId As Int)	
#end if

	Response.GetAsynchronously("response", File.OpenOutput(TempFolder, TaskId, False), _
		True, TaskId)
			
'get Content-Disposition	 for download files	
	Dim headerMap As Map = Response.GetHeaders
	If CltUtils.check_map_size(headerMap,1) Then
		Dim contentdispositionMap As Map 
		contentdispositionMap.Initialize	
		For Each headerNamestr As String In headerMap.Keys
			If headerNamestr.ToLowerCase.Trim  = "content-disposition" Then
				Dim tmp_list As List = headerMap.Get(headerNamestr)
				contentdispositionMap.Put( "content-disposition", tmp_list ) 
			End If
		Next		
		
		If contentdispositionMap.Size >0 Then
			B4XWriteObj(TempFolder, TaskId&".header",contentdispositionMap)	
		End If
	End If

		
End Sub

Sub Response_StreamFinish (Success As Boolean, TaskId As Int)
	If Success Then
		CompleteJob(TaskId, Success, "")
	Else
		CompleteJob(TaskId, Success, LastException.Message)
	End If
End Sub


#if apachehc

	Sub hc_ResponseError (Response As HttpResponse, Reason As String, StatusCode As Int, TaskId As Int)	
		If Response <> Null Then
			Try			
				Reason = $"${Response.GetString("UTF8")} "$
			Catch
				Reason = $" hc_ResponseError Failed to read error message."$
			End Try
			Response.Release
		End If
		CompleteJob(TaskId, False, Reason)
	End Sub

#else

	Sub hc_ResponseError (Response As OkHttpResponse, Reason As String, StatusCode As Int, TaskId As Int)	
		If Response <> Null Then
			Try
				Reason = $"${Response.ErrorResponse} ${Reason}"$
			Catch
				Reason = $"hc_ResponseError Failed to read error message. ${Reason}"$
			End Try
			Response.Release
		End If
		CompleteJob(TaskId, False, Reason)
	End Sub

#end if


Sub CompleteJob(TaskId As Int, success As Boolean, errorMessage As String)
	Dim job As HttpJob
	job = TaskIdToJob.Get(TaskId)
	
	Dim appn2 As String = job.JobName
	If appn2 <> "" And success = False Then
		comFunMod.AppLg(appn2, "error", "", $"${errorMessage}"$)
	End If
	
	TaskIdToJob.Remove(TaskId)
	job.success = success
	job.errorMessage = errorMessage
	job.Complete(TaskId)
End Sub





' modified

'timer to clean tmp files not removed (job.release not executed)
Sub	timercleantmp_tick
Try
	
	comFunMod.LogFmt("debug", "timercleantmp", $"clean temp files"$)
	
	Dim extFilterMap As Map = CreateMap(".header":"")
	FileDelFilesbyConditions( TempFolder , 5 , extFilterMap , True )
	
	'temp files in windows
	If Main.OSName="win" Then
		FileDelFilesStartwith(File.DirTemp, 5 , "Rscript", False)
	End If
	
Catch
	comFunMod.LogFmt("error", "timercleantmp", $"LastException"$)
	Log(LastException)
End Try

End Sub

Sub FileDelFilesStartwith(Temp2 As String, ExpireMin As Int, startwith As String , isDelFolder As Boolean )
	
	Dim fl As List = File.ListFiles(Temp2)
	If CltUtils.check_list_size(fl,1) = False Then Return
	

	Dim expire_dt As Long = DateTime.Now - ExpireMin*60*1000 
	Dim filenameOrg As String
	Dim is2del As Boolean
	For i = 0 To fl.Size -1
		filenameOrg = fl.Get(i)		
		
		is2del = False
		Try
			If filenameOrg.StartsWith( startwith ) Then
				If File.IsDirectory(Temp2,filenameOrg) Then 
					If isDelFolder Then is2del = True
				Else
					is2del = True
				End If
			End If
	
						
			If is2del Then
				
				If getLastModifiedTime( File.Combine(Temp2,filenameOrg) ) < expire_dt Then
					File.Delete(Temp2,filenameOrg)
				End If
					
			End If				
		Catch
			comFunMod.LogFmt("error", "FileDelFilesStartwith", $"LastException"$)
			Log(LastException)
		End Try

	Next	
	
End Sub

Sub FileDelFilesbyConditions(Temp2 As String, ExpireMin As Int , extMap As Map , isDelNumberFileName As Boolean )
	
	Dim fl As List = File.ListFiles(Temp2)
	If CltUtils.check_list_size(fl,1) = False Then Return 
	
	Dim expire_dt As Long = DateTime.Now - ExpireMin*60*1000
	Dim tmp_filename As String 
	Dim is2del As Boolean
	For i = 0 To fl.Size -1
		tmp_filename = fl.Get(i)
		is2del = False
		Try
			If isDelNumberFileName And IsNumber(tmp_filename) Then
				is2del = True
			End If
		
			For Each ext As String In extMap.Keys
				If tmp_filename.EndsWith( ext) Then is2del = True
			Next			
						
			If is2del And File.IsDirectory(Temp2,tmp_filename) = False Then
				
				If getLastModifiedTime( File.Combine(Temp2,tmp_filename) ) < expire_dt Then
					File.Delete(Temp2,tmp_filename)
				End If
					
			End If				
		Catch
			comFunMod.LogFmt("error", "FileDelFilesbyConditions", $"LastException"$)
			Log(LastException)
		End Try

	Next	
	
End Sub

Sub B4XWriteObj(filepath As String,filename As String,obj2write As Object)
	File.Delete(filepath,filename)
	Dim raf As RandomAccessFile
    raf.Initialize(filepath,filename,False)

    raf.WriteB4XObject(obj2write, raf.CurrentPosition)
	raf.Close
End Sub


'error return Null ( this may cause another exception )
Sub getLastModifiedTime(fileName As String ) As Long
	Private NativeMe As JavaObject
	NativeMe = Me
	Try
		Dim lastmoddt As Long = NativeMe.RunMethod("getLastModifiedTime", Array(fileName))
		Return lastmoddt
	Catch
		comFunMod.LogFmt("error", "getLastModifiedTime", $"${fileName}"$)
		Log(LastException)
		Return Null
	End Try
End Sub	

#If JAVA
import java.io.*;
import java.nio.file.*;

  public static long getLastModifiedTime(String fileName)
    throws IOException
  {
    return Files.getLastModifiedTime(Paths.get(fileName, new String[0]), new LinkOption[0]).toMillis();
  }
#End If

