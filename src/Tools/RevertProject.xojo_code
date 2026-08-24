#tag Class
Protected Class RevertProject
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("revert_project", "Reverts the current Xojo project to the version saved on disk. Use this after modifying project files (e.g. .xojo_window, .xojo_code) directly on disk to reload them in the IDE.")

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  #Pragma Unused args

		  // Reloading a project through IDE scripting has exactly one non-interactive route:
		  // CloseProject(False) followed by OpenFile. Everything else was tested and rejected
		  // (Xojo 2025r3.1, verified by adding a module to the project file on disk and
		  // checking whether the IDE picked it up):
		  //
		  //   DoCommand "Revert"      - always raises a modal confirmation dialog. A human has
		  //                             to click it, and while it is up the IDE's script engine
		  //                             is blocked, so every XMCP tool hangs. Not automatable,
		  //                             and triggering it saves the user nothing over using the
		  //                             menu item themselves.
		  //   OpenFile <same project> - returns normally and reloads nothing.
		  //
		  // CloseProject cannot be used on Windows: closing the last project window quits the
		  // IDE, which takes the IPC socket - and any chance of reopening - with it.

		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If

		  #If TargetWindows Then
		    // Deliberately attempts nothing: there is no route that leaves the IDE running.
		    Return MCPKit.ToolResult.Failure("revert_project is not supported on Windows, and " + _
		    "nothing was changed. Reloading a project through IDE scripting needs CloseProject, " + _
		    "which on Windows closes the IDE's last window and so quits the IDE. Ask the user to " + _
		    "reload the project themselves - File > Revert to Saved (confirming the dialog), or " + _
		    "closing and reopening the project. Edits already written to disk will be picked up, " + _
		    "and the rest of the direct-file-editing workflow is unaffected.")
		  #Else
		    // 1. Learn where the project lives while it is still open.
		    Var reachable As Boolean
		    Var shellPath As String = ProjectPathFromIDE(reachable)
		    If Not reachable Then Return IDEFailure("reading the project path")
		    If shellPath = "" Then
		      Return MCPKit.ToolResult.Failure("No project is open in the Xojo IDE, or it has never " + _
		      "been saved to disk. Open a saved project and try again.")
		    End If

		    // 2. Normalise to a native long path for the reopen and for error messages. On
		    //    Windows ProjectShellPath is the 8.3 short path; OpenFile takes either form.
		    Var nativePath As String = shellPath
		    Try
		      Var projectFile As New FolderItem(shellPath, FolderItem.PathModes.Shell)
		      If projectFile <> Nil And projectFile.Exists Then nativePath = projectFile.NativePath
		    Catch e As RuntimeException
		      // Keep the shell path - OpenFile accepts it too.
		    End Try

		    // 3. Close, discarding unsaved IDE changes: reloading from disk is the whole point.
		    //    The False suppresses the save prompt. The reply is ignored - closing the project
		    //    tears down the script host that would have answered it, so step 4 is the test.
		    Call App.IDE.SendAndReceive("CloseProject(False)" + EndOfLine + "Print ""closed""", 20000)

		    If ProjectPathFromIDE(reachable) <> "" Then
		      Return MCPKit.ToolResult.Failure("CloseProject did not take effect - the project is " + _
		      "still open and has not been reloaded from disk. Nothing was changed.")
		    End If

		    If Not reachable Then
		      Return MCPKit.ToolResult.Failure("The Xojo IDE stopped responding after the project " + _
		      "was closed: " + App.IDE.LastErrorMessage + " Reopen the project manually: " + nativePath)
		    End If

		    // 4. Reopen from disk, then confirm by asking the IDE rather than trusting the reply.
		    Var openResponse As JSONItem = App.IDE.SendAndReceive( _
		    "OpenFile """ + nativePath + """" + EndOfLine + "Print ""reopened""", 30000)

		    If ProjectPathFromIDE(reachable) = "" Then
		      Var detail As String = ""
		      If openResponse = Nil Then
		        detail = App.IDE.LastErrorMessage
		      Else
		        detail = ScriptErrorText(openResponse)
		      End If
		      If detail <> "" Then detail = " (" + detail + ")"

		      Return MCPKit.ToolResult.Failure("The project was closed but did not reopen" + detail + _
		      ". Reopen it manually: " + nativePath)
		    End If

		    Return MCPKit.ToolResult.Success("Project reloaded from disk: " + nativePath)
		  #EndIf

		End Function
	#tag EndMethod


	#tag Method, Flags = &h21
		Private Function IDEFailure(whileDoing As String) As MCPKit.ToolResult
		  If App.IDE.LastErrorMessage <> "" Then
		    Return MCPKit.ToolResult.Failure("IDE communication failed while " + whileDoing + ": " + _
		    App.IDE.LastErrorMessage)
		  End If

		  Return MCPKit.ToolResult.Failure("Timeout waiting for the IDE while " + whileDoing + ".")

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ProjectPathFromIDE(ByRef ideReachable As Boolean) As String
		  /// The open project's shell path, or "" if no project is open.
		  ///
		  /// ideReachable distinguishes "no project open" from "no IDE answering" - both of
		  /// which return "". Conflating them turns a vanished IDE into an apparent successful
		  /// close, so callers must check it.

		  ideReachable = False

		  Var response As JSONItem = App.IDE.SendAndReceive("Print ProjectShellPath")
		  If response = Nil Then Return ""

		  ideReachable = True

		  If ScriptErrorText(response) <> "" Then Return ""
		  If Not response.HasKey("response") Then Return ""

		  Return response.Value("response").StringValue.Trim

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ScriptErrorText(response As JSONItem) As String
		  /// Returns the IDE's error text if the response carries one, otherwise "".
		  ///
		  /// A successful script answers with a string (whatever it printed). Anything else
		  /// is an object such as {"scriptError": [...]}, which must not be mistaken for
		  /// success - the previous version of this tool reported it as one.

		  If response = Nil Or Not response.HasKey("response") Then Return ""

		  Var resp As Variant = response.Value("response")
		  If resp.Type = Variant.TypeString Then Return ""

		  Try
		    Var respJSON As JSONItem = response.Value("response")
		    Return respJSON.ToString
		  Catch e As RuntimeException
		    Return "unrecognised IDE response"
		  End Try

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
