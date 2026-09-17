#tag Class
Protected Class RevertProject
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("revert_project", "Reverts the current Xojo project to the version saved on disk. Use this after modifying project files (e.g. .xojo_window, .xojo_code) directly on disk to reload them in the IDE. The project is closed and reopened, so unsaved IDE changes are discarded and open editor tabs are lost. On Windows a throwaway project is briefly opened alongside it, because closing the last project window would quit the IDE.")

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
		  // On Windows, closing the last project window quits the IDE, so the close is done
		  // while a throwaway host project holds the IDE open - see the Windows branch below.

		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If

		  #If TargetWindows Then
		    // Windows quits the IDE when its last project window closes, so the target cannot
		    // simply be closed and reopened. A second open workspace window prevents that, and
		    // also keeps CloseProject from tearing down the running script.
		    //
		    // CloseProject acts on the frontmost workspace window, and OpenFile on an
		    // already-open project focuses it without reloading - that is what makes the
		    // ordering below controllable. Every step is measured, not assumed.

		    // 1. Where is the target?
		    Var reachable As Boolean
		    Var targetShell As String = ProjectPathFromIDE(reachable)
		    If Not reachable Then Return IDEFailure("reading the project path")
		    If targetShell = "" Then
		      Return MCPKit.ToolResult.Failure("No project is open in the Xojo IDE, or it has never " + _
		      "been saved to disk. Open a saved project and try again.")
		    End If

		    Var target As FolderItem = FileFromShellPath(targetShell)
		    If target = Nil Then
		      Return MCPKit.ToolResult.Failure("Could not resolve the open project's path: " + targetShell)
		    End If

		    // 2. A second window is only needed if the target is the only one open. When the
		    //    user already has another project open, it holds the IDE up for us.
		    Var windowsBefore As Integer = WindowCountFromIDE
		    Var hostCreated As Boolean = False

		    If windowsBefore = 1 Then
		      // NewConsoleProject opens an unsaved workspace window. Nothing is written to disk
		      // and CloseProject(False) discards it without prompting.
		      Call App.IDE.SendAndReceive("NewConsoleProject" + EndOfLine + "Print ""created""", 30000)

		      If WindowCountFromIDE <= windowsBefore Then
		        Return MCPKit.ToolResult.Failure("Could not open a second workspace window, which is " + _
		        "needed because closing the last project would quit the IDE on Windows. Nothing was " + _
		        "changed. Reload the project manually instead.")
		      End If
		      hostCreated = True
		    ElseIf windowsBefore < 1 Then
		      Return MCPKit.ToolResult.Failure("Could not read how many workspace windows are open, " + _
		      "so closing the project might quit the IDE. Nothing was changed.")
		    End If

		    // 3. Focus the target, then close it. The extra window keeps the IDE running.
		    If Not OpenAndVerify(target) Then
		      If hostCreated Then Call CloseUnsavedWindow
		      Return MCPKit.ToolResult.Failure("Could not focus the project before closing it. " + _
		      "Nothing was changed. Reload the project manually instead.")
		    End If

		    Call CloseFocusedProject

		    Var afterClose As String = ProjectPathFromIDE(reachable)
		    If Not reachable Then
		      Return MCPKit.ToolResult.Failure("The Xojo IDE stopped responding while closing the " + _
		      "project: " + App.IDE.LastErrorMessage + " Reopen the project manually: " + target.NativePath)
		    End If
		    If SamePath(afterClose, target) Then
		      If hostCreated Then Call CloseUnsavedWindow
		      Return MCPKit.ToolResult.Failure("The project did not close, so it has not been " + _
		      "reloaded from disk. Nothing was changed.")
		    End If

		    // 4. Reopen the target from disk.
		    If Not OpenAndVerify(target) Then
		      Return MCPKit.ToolResult.Failure("The project was closed but did not reopen. Another " + _
		      "workspace window is still open, so the IDE is still running. Reopen the project " + _
		      "manually: " + target.NativePath)
		    End If

		    // 5. Drop our extra window, leaving the IDE as we found it. It is the only unsaved
		    //    one, because step 2 only created it when the target was the sole window.
		    If hostCreated Then
		      Call CloseUnsavedWindow
		      Call OpenAndVerify(target)  // restore focus to the user's project

		      If WindowCountFromIDE > windowsBefore Then
		        Return MCPKit.ToolResult.Success("Project reloaded from disk: " + target.NativePath + _
		        " (note: the temporary empty project could not be closed and is still open in the IDE)")
		      End If
		    End If

		    Return MCPKit.ToolResult.Success("Project reloaded from disk: " + target.NativePath)
		  #Else
		    // 1. Learn where the project lives while it is still open.
		    Var reachable As Boolean
		    Var shellPath As String = ProjectPathFromIDE(reachable)
		    If Not reachable Then Return IDEFailure("reading the project path")
		    If shellPath = "" Then
		      Return MCPKit.ToolResult.Failure("No project is open in the Xojo IDE, or it has never " + _
		      "been saved to disk. Open a saved project and try again.")
		    End If

		    // 2. Resolve the path once: needed as a long path for the reopen and for messages,
		    //    and as a FolderItem to compare against what the IDE reports later.
		    Var target As FolderItem = FileFromShellPath(shellPath)
		    Var nativePath As String = shellPath
		    If target <> Nil And target.Exists Then nativePath = target.NativePath

		    // 3. Close, discarding unsaved IDE changes: reloading from disk is the whole point.
		    //    The False suppresses the save prompt. The reply is ignored - closing the project
		    //    tears down the script host that would have answered it, so step 4 is the test.
		    Call App.IDE.SendAndReceive("CloseProject(False)" + EndOfLine + "Print ""closed""", 20000)

		    // Compare against the target, not against "" - if the IDE has another project open
		    // it becomes the current one after the close, so an empty path is not the signal.
		    Var afterClose As String = ProjectPathFromIDE(reachable)
		    If reachable And SamePath(afterClose, target) Then
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

		    If Not SamePath(ProjectPathFromIDE(reachable), target) Then
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
		Private Function CloseFocusedProject() As Boolean
		  /// Closes the frontmost project, discarding unsaved changes. The reply is not
		  /// reliable - on some platforms closing the project takes the script host with it -
		  /// so callers verify with ProjectPathFromIDE instead.

		  Call App.IDE.SendAndReceive("CloseProject(False)" + EndOfLine + "Print ""closed""", 20000)
		  Return True

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FileFromShellPath(shellPath As String) As FolderItem
		  If shellPath.Trim = "" Then Return Nil

		  Try
		    Return New FolderItem(shellPath, FolderItem.PathModes.Shell)
		  Catch e As RuntimeException
		    Return Nil
		  End Try

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function CloseUnsavedWindow() As Boolean
		  /// Closes the one workspace window that has no path on disk - the empty project this
		  /// tool created. Only called when we created it, so there is no other unsaved window
		  /// to confuse it with.
		  ///
		  /// Selecting the window and closing it are separate requests: CloseProject tears down
		  /// the script that would have reported back.

		  Var findScript As String = "Dim found As Integer = -1" + EndOfLine + _
		  "Dim i As Integer" + EndOfLine + _
		  "For i = 0 To WindowCount - 1" + EndOfLine + _
		  "  SelectWindow(i)" + EndOfLine + _
		  "  If ProjectShellPath = """" Then" + EndOfLine + _
		  "    found = i" + EndOfLine + _
		  "    Exit" + EndOfLine + _
		  "  End If" + EndOfLine + _
		  "Next" + EndOfLine + _
		  "Print Str(found)"

		  Var response As JSONItem = App.IDE.SendAndReceive(findScript, 20000)
		  If response = Nil Or Not response.HasKey("response") Then Return False

		  Var resp As Variant = response.Value("response")
		  If resp.Type <> Variant.TypeString Then Return False
		  If resp.StringValue.Trim = "-1" Then Return False

		  // The loop left that window selected, so this closes it.
		  Return CloseFocusedProject

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function WindowCountFromIDE() As Integer
		  /// How many workspace windows the IDE has open, or -1 if it could not be read.
		  ///
		  /// This is what makes closing a project safe on Windows: with more than one window
		  /// open, closing one cannot quit the IDE.

		  Var response As JSONItem = App.IDE.SendAndReceive("Print Str(WindowCount)")
		  If response = Nil Or Not response.HasKey("response") Then Return -1

		  Var resp As Variant = response.Value("response")
		  If resp.Type <> Variant.TypeString Then Return -1

		  Var text As String = resp.StringValue.Trim
		  If text = "" Then Return -1

		  Return text.ToInteger

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function OpenAndVerify(project As FolderItem) As Boolean
		  /// Opens (or focuses, if already open) a project and confirms it became current.

		  If project = Nil Then Return False

		  Call App.IDE.SendAndReceive("OpenFile """ + project.NativePath + """" + EndOfLine + _
		  "Print ""opened""", 60000)

		  Var reachable As Boolean
		  Return SamePath(ProjectPathFromIDE(reachable), project)

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SamePath(shellPathFromIDE As String, expected As FolderItem) As Boolean
		  /// Compares a path reported by the IDE with one we hold. Both are normalised through
		  /// FolderItem first: the IDE hands back shell paths, which are escaped on macOS and
		  /// the 8.3 short form on Windows, so string comparison would fail on both.

		  If expected = Nil Then Return False

		  Var reported As FolderItem = FileFromShellPath(shellPathFromIDE)
		  If reported = Nil Then Return False

		  Return reported.NativePath = expected.NativePath

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
