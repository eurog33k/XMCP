#tag Class
Protected Class BuildProject
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("build_project", "Builds the current Xojo project. Returns the path to the built application on success, or build errors on failure. " + _
		  "The IDE is blocked for the whole build and answers no other tool until it is done; a large project can take many minutes. " + _
		  "If the build outlasts the timeout, it still completes in the IDE - the connection is kept open so the IDE can finish safely - " + _
		  "and every tool refuses with a 'still executing an earlier request' message until it has. Wait, then check the Builds folder or build again.")

		  // Values per IDE Scripting > Building commands > BuildApp. Getting these wrong
		  // is silent: an unavailable target simply does not build.
		  Parameters.Add(New MCPKit.ToolParameter("build_type", MCPKit.ToolParameterTypes.Integer_, _
		  "Build target: 3=Windows 32-bit, 19=Windows 64-bit Intel, 25=Windows 64-bit ARM, " + _
		  "9=macOS Universal, 16=macOS 64-bit Intel, 24=macOS 64-bit ARM, " + _
		  "17=Linux 64-bit Intel, 18=Linux 32-bit ARM, 26=Linux 64-bit ARM, 4=Linux 32-bit Intel. " + _
		  "Omit to build for the platform XMCP is running on. The target must be enabled in Build Settings.", _
		  True, 0, False))

		  Parameters.Add(New MCPKit.ToolParameter("reveal", MCPKit.ToolParameterTypes.Boolean_, _
		  "Whether to reveal the built app in Finder/Explorer after building. Default is false.", _
		  True, False, False))

		  Parameters.Add(New MCPKit.ToolParameter("timeout", MCPKit.ToolParameterTypes.Integer_, _
		  "How long to wait for the build, in milliseconds. Default is 1800000 (30 minutes). " + _
		  "Set it generously: giving up does not stop the build, it only means the result is not reported.", _
		  True, CType(kDefaultTimeoutMS, Integer), False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var buildType As Integer = 0
		  Var reveal As Boolean = False
		  Var timeoutMS As Integer = CType(kDefaultTimeoutMS, Integer)
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "build_type" Then
		      buildType = arg.Value.IntegerValue
		    ElseIf arg.Name = "reveal" Then
		      reveal = arg.Value.BooleanValue
		    ElseIf arg.Name = "timeout" Then
		      If arg.Value.IntegerValue > 0 Then timeoutMS = arg.Value.IntegerValue
		    End If
		  Next arg

		  // 0 is not a valid IDE build type, so it means "not specified": resolve it to the
		  // target for the platform XMCP - and therefore the IDE - is running on.
		  If buildType = 0 Then
		    #If TargetMacOS Then
		      buildType = 9   // macOS Universal
		    #ElseIf TargetWindows Then
		      buildType = 19  // Windows 64-bit Intel
		    #Else
		      buildType = 17  // Linux 64-bit Intel
		    #EndIf
		  End If

		  // BuildApp(type, reveal) is a function that returns the shell path of the built
		  // app, so success is verifiable. DoCommand "BuildApp ..." is deliberately not
		  // used: it answers {} both when the build succeeded and when the IDE ignored the
		  // command (an invalid or disabled target), which reads as a false success.
		  // A build error still arrives as a buildError object in the response value.
		  Var revealStr As String = If(reveal, "True", "False")
		  Var script As String = _
		  "Print BuildApp(" + buildType.ToString + ", " + revealStr + ")"

		  // A build blocks the IDE's main thread, so it answers nothing until it is done.
		  // The timeout is generous by default and only decides when we stop *waiting*:
		  // the IDE finishes the build either way, and IDECommunicator keeps the socket
		  // open so the IDE's late reply cannot kill it (see AddPending there). The old
		  // 120 s limit, on a project that took 2.5 minutes, did exactly that.
		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If

		  Var response As JSONItem = App.IDE.SendAndReceive(script, timeoutMS)
		  If response = Nil Then
		    If App.IDE.LastErrorMessage <> "" Then
		      Return MCPKit.ToolResult.Failure(App.IDE.LastErrorMessage)
		    End If
		    Var timeoutS As Integer = timeoutMS / 1000
		    Return MCPKit.ToolResult.Failure("No answer from the IDE within " + timeoutS.ToString + " s. " + _
		    "The build is still running in the IDE; wait for it to finish before calling any other tool.")
		  End If

		  If response.HasKey("response") Then
		    Var resp As Variant = response.Value("response")

		    If resp.Type = Variant.TypeString Then
		      Var respStr As String = resp.StringValue.Trim
		      If respStr = "" Then
		        // BuildApp returned no path: the IDE accepted the script but built nothing.
		        Return MCPKit.ToolResult.Failure("The IDE returned no build path, so nothing " + _
		        "was built. Build type " + buildType.ToString + " is most likely not a valid " + _
		        "target for this project, or is not enabled in Build Settings. See the " + _
		        "build_type parameter for the valid values.")
		      End If
		      Try
		        Var resultJSON As New JSONItem(respStr)
		        Return ParseBuildResult(resultJSON)
		      Catch e As JSONException
		        // Not JSON, so it is the path to the built app. BuildApp answers it
		        // shell-escaped on macOS and Linux ("Builds\ \-\ XMCP"); report it usable.
		        Var message As String = "Build succeeded: " + App.IDE.UnescapeShellPath(respStr)
		        Var warnings As String = App.IDE.ReplyWarnings(response)
		        If warnings <> "" Then message = message + EndOfLine + "Warnings:" + EndOfLine + warnings
		        Return MCPKit.ToolResult.Success(message)
		      End Try
		    Else
		      // A build error arrives as a JSON object in the response envelope.
		      Var respJSON As JSONItem = response.Value("response")
		      Return ParseBuildResult(respJSON)
		    End If
		  End If

		  Return MCPKit.ToolResult.Failure("Unexpected response from IDE: " + response.ToString)

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ParseBuildResult(resultJSON As JSONItem) As MCPKit.ToolResult
		  /// Parses a JSON object returned in place of a build path: buildError with its
		  /// errors and warnings, missingFiles (something must be configured first, e.g. an
		  /// Android key store), openErrors and loadError. The formatting lives in
		  /// IDECommunicator so every tool reports the same shapes the same way.

		  If resultJSON.Count = 0 Then
		    Return MCPKit.ToolResult.Failure("The IDE returned an empty result, so nothing was " + _
		    "built. Check that the requested build type is a valid, enabled target for this project.")
		  End If

		  // Wrap the object the way the IDE delivers it so the shared classifier can read it.
		  Var envelope As New JSONItem
		  envelope.Value("response") = resultJSON
		  Var diagnostics As String = App.IDE.ReplyDiagnostics(envelope)
		  If diagnostics <> "" Then
		    Var warnings As String = App.IDE.ReplyWarnings(envelope)
		    If warnings <> "" Then diagnostics = diagnostics + EndOfLine + "Warnings:" + EndOfLine + warnings
		    Return MCPKit.ToolResult.Failure(diagnostics)
		  End If

		  // buildError with warnings only: BuildApp itself never reports warnings, so this is
		  // rare, but it is not a failure. Nothing was built either, though, or a path would
		  // have come back instead of an object.
		  Return MCPKit.ToolResult.Failure("The IDE returned no build path: " + resultJSON.ToString)

		End Function
	#tag EndMethod


	#tag Constant, Name = kDefaultTimeoutMS, Type = Double, Dynamic = False, Default = \"1800000", Scope = Private
	#tag EndConstant


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
