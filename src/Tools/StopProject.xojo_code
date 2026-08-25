#tag Class
Protected Class StopProject
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("stop_project", "Stops the currently running Xojo debug session and verifies it actually stopped. The IDE's Kill command stops a desktop app but leaves a console debug build running, so if a debug build of the open project is still alive afterwards this terminates the process directly. It reports which of the two happened, and never touches the XMCP process itself.")

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  #Pragma Unused args

		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If

		  // Where the debug build lives, so a running one can be recognised. Without it there
		  // is nothing to check against and the old behaviour is all that is left.
		  Var projectFolderName As String = ""
		  Var projectDir As String = ProjectDirectory(projectFolderName)

		  // 1. What was running before? Without this the two outcomes are indistinguishable:
		  //    "the Kill worked" and "there was nothing to kill" both end with no process, and
		  //    reporting them in the same words tells the caller nothing about what happened.
		  Var before() As String
		  If projectDir <> "" Then before = DebugProcesses(projectDir, projectFolderName)

		  // 2. Ask the IDE. This is the polite route and it is enough for a desktop app.
		  Call App.IDE.SendAndReceive("DoCommand ""Kill""" + EndOfLine + "Print ""killed""", 20000)

		  If projectDir = "" Then
		    Return MCPKit.ToolResult.Success("Asked the IDE to stop the running app. No project path " + _
		    "was available, so this could not be verified - check that the app has actually exited.")
		  End If

		  Thread.SleepCurrent(1500)

		  // 3. Did that work? DoCommand "Kill" does stop a desktop app but leaves a CONSOLE debug
		  //    build running, and it reports nothing either way - which is why this tool used to
		  //    print "Debug session stopped." whether or not anything had stopped.
		  Var running() As String = DebugProcesses(projectDir, projectFolderName)
		  If running.Count = 0 Then
		    If before.Count = 0 Then
		      Return MCPKit.ToolResult.Success("Nothing to stop: no debug build of this project was " + _
		      "running before the Kill or after it. The IDE was asked anyway, in case it held a " + _
		      "session this cannot see.")
		    End If

		    Return MCPKit.ToolResult.Success("Debug session stopped by the IDE, verified: " + _
		    before.Count.ToString + " debug process(es) were running and none are now.")
		  End If

		  // 4. Still there, so stop it directly.
		  Var killed() As String
		  Var failed() As String

		  For Each entry As String In running
			 Var parts() As String = entry.Split("|")
			 If parts.Count < 2 Then Continue

			 If TerminateProcess(parts(0)) Then
			   killed.Add(parts(0) + " (" + parts(1) + ")")
			 Else
			   failed.Add(parts(0) + " (" + parts(1) + ")")
			 End If
		  Next entry

		  Thread.SleepCurrent(1000)
		  Var stillRunning() As String = DebugProcesses(projectDir, projectFolderName)

		  If stillRunning.Count = 0 Then
		    Return MCPKit.ToolResult.Success("The IDE's Kill command did not stop it - that command " + _
		    "leaves a console debug build running - so the process was terminated directly: " + _
		    String.FromArray(killed, ", ") + ". Verified stopped.")
		  End If

		  Return MCPKit.ToolResult.Failure("Could not stop the debug build. The IDE's Kill command did " + _
		  "nothing and terminating the process directly failed for: " + _
		  String.FromArray(stillRunning, ", ") + ". Quit it yourself, or stop it from the IDE.")

		End Function
	#tag EndMethod


	#tag Method, Flags = &h21
		Private Function DebugProcesses(projectDir As String, projectFolderName As String) As String()
		  /// Live debug builds of the open project, as "pid|path" entries.
		  ///
		  /// Recognised by an executable that sits under the project folder and is named the way
		  /// Xojo names a debug build. The process list is filtered here rather than in the shell,
		  /// so no path ever has to be quoted.
		  ///
		  /// Both halves of that test used to be wrong on Windows, and the tool reported "nothing
		  /// was running" for a process confirmed by PID. The naming differs by platform - macOS
		  /// and Linux produce "AppName.debug", Windows produces "DebugAppName.exe", which
		  /// contains no ".debug" at all - and the path comparison was case-sensitive against a
		  /// path that may have arrived in 8.3 form. Measured on Windows 11 with Xojo 2026r1.1:
		  /// C:\tmptest\browntest6\Debuguseit\Debuguseit.exe was live and matched neither test.

		  Var found() As String

		  Var listing As String = ProcessListing
		  If listing = "" Then Return found

		  Var ownPath As String = ""
		  If App.ExecutableFile <> Nil Then ownPath = App.ExecutableFile.NativePath

		  Var dirNeedle As String = projectDir.Lowercase
		  Var nameNeedle As String = projectFolderName.Lowercase

		  For Each line As String In listing.ReplaceLineEndings(Chr(10)).Split(Chr(10))
		    Var text As String = line.Trim
		    If text = "" Then Continue

		    // Under the project folder - by full path, or by the folder's own name when the two
		    // sides disagree about 8.3 versus long form.
		    Var lower As String = text.Lowercase
		    Var underProject As Boolean = (dirNeedle <> "" And lower.IndexOf(dirNeedle) >= 0)
		    If Not underProject And nameNeedle <> "" Then
		      underProject = lower.IndexOf(nameNeedle) >= 0
		    End If
		    If Not underProject Then Continue

		    If Not LooksLikeDebugBuild(text) Then Continue

		    // Never target the process answering this request. If XMCP itself is being run from
		    // the IDE, stopping it would kill the server mid-call.
		    If ownPath <> "" And text.IndexOf(ownPath) >= 0 Then Continue

		    // Each line is a pid followed by the executable path.
		    Var space As Integer = text.IndexOf(" ")
		    If space <= 0 Then Continue

		    Var pid As String = text.Left(space).Trim
		    Var path As String = text.Middle(space + 1).Trim
		    If pid.ToInteger <= 0 Then Continue

		    found.Add(pid + "|" + path)
		  Next line

		  Return found

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function LooksLikeDebugBuild(processLine As String) As Boolean
		  /// Whether this process line names a Xojo debug build, in whichever form this platform
		  /// produces. macOS and Linux append ".debug" to the app name; Windows prefixes the
		  /// executable with "Debug" instead, so looking for ".debug" there never matches.
		  
		  Var lower As String = processLine.Lowercase
		  
		  #If TargetWindows Then
		    // Test the executable's own name, not the whole line: a project living under a folder
		    // that happens to contain "debug" should not make every process in it a candidate.
		    Var parts() As String = lower.Split("\")
		    If parts.Count = 0 Then Return False
		    
		    Var fileName As String = parts(parts.LastIndex)
		    Return fileName.BeginsWith("debug")
		  #Else
		    Return lower.IndexOf(".debug") >= 0
		  #EndIf
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ProcessListing() As String
		  /// Every process as "pid path", one per line.

		  Var sh As New Shell
		  sh.TimeOut = 15000

		  Try
		    #If TargetWindows Then
		      // Get-CimInstance rather than the deprecated wmic, which recent Windows drops.
		      sh.Execute("powershell -NoProfile -Command ""Get-CimInstance Win32_Process | " + _
		      "Where-Object { $_.ExecutablePath } | ForEach-Object { $_.ProcessId.ToString() + ' ' + " + _
		      "$_.ExecutablePath }""")
		    #Else
		      sh.Execute("ps -A -o pid=,command=")
		    #EndIf
		  Catch e As RuntimeException
		    Return ""
		  End Try

		  Return sh.Result

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ProjectDirectory(ByRef folderName As String) As String
		  /// The folder holding the open project, or "" if it cannot be determined.
		  ///
		  /// folderName comes back as the folder's real name. On Windows ProjectShellPath is the
		  /// 8.3 short form and NativePath can carry that through - "C:\tmptest\BROWNT~1" for
		  /// "C:\tmptest\browntest6" - while Win32_Process reports long paths, so a filter built
		  /// from the path alone matches nothing. FolderItem.Name is the real directory entry
		  /// either way, which gives the match something to fall back on.

		  Var response As JSONItem = App.IDE.SendAndReceive("Print ProjectShellPath")
		  If response = Nil Or Not response.HasKey("response") Then Return ""

		  Var resp As Variant = response.Value("response")
		  If resp.Type <> Variant.TypeString Then Return ""

		  Var shellPath As String = resp.StringValue.Trim
		  If shellPath = "" Then Return ""

		  Try
		    Var manifest As New FolderItem(shellPath, FolderItem.PathModes.Shell)
		    If manifest = Nil Or manifest.Parent = Nil Then Return ""
		    folderName = manifest.Parent.Name
		    Return manifest.Parent.NativePath
		  Catch e As RuntimeException
		    Return ""
		  End Try

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function TerminateProcess(pid As String) As Boolean
		  /// Ends one process by id. A polite signal first, then a forced one.

		  If pid.ToInteger <= 0 Then Return False

		  Var sh As New Shell
		  sh.TimeOut = 10000

		  Try
		    #If TargetWindows Then
		      sh.Execute("taskkill /PID " + pid.ToInteger.ToString + " /F")
		    #Else
		      sh.Execute("kill " + pid.ToInteger.ToString)
		      Thread.SleepCurrent(500)
		      sh.Execute("kill -9 " + pid.ToInteger.ToString + " 2>/dev/null")
		    #EndIf
		  Catch e As RuntimeException
		    Return False
		  End Try

		  Return True

		End Function
	#tag EndMethod

	#tag ViewBehavior
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Description"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
