#tag Class
Protected Class BuildProject
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("build_project", "Builds the current Xojo project. Returns the path to the built application on success, or build errors on failure.")

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

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var buildType As Integer = 0
		  Var reveal As Boolean = False
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "build_type" Then
		      buildType = arg.Value.IntegerValue
		    ElseIf arg.Name = "reveal" Then
		      reveal = arg.Value.BooleanValue
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

		  // Builds can take a long time — use a 120 second timeout.
		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If

		  Var response As JSONItem = App.IDE.SendAndReceive(script, 120000)
		  If response = Nil Then
		    If App.IDE.LastErrorMessage <> "" Then
		      Return MCPKit.ToolResult.Failure(App.IDE.LastErrorMessage)
		    End If
		    Return MCPKit.ToolResult.Failure("Timeout waiting for build to complete (120s).")
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
		        // Not JSON, so it is the path to the built app.
		        Return MCPKit.ToolResult.Success("Build succeeded: " + respStr)
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
		  /// Parses a JSON object returned in place of a build path.
		  /// Failure: {"buildError": {"errors": [...]}} → formatted error list.

		  If resultJSON.Count = 0 Then
		    Return MCPKit.ToolResult.Failure("The IDE returned an empty result, so nothing was " + _
		    "built. Check that the requested build type is a valid, enabled target for this project.")
		  End If

		  If resultJSON.HasKey("buildError") Then
		    Var buildError As JSONItem = resultJSON.Value("buildError")
		    If buildError.HasKey("errors") Then
		      Var errors As JSONItem = buildError.Value("errors")
		      Var lines() As String
		      Var i As Integer
		      For i = 0 To errors.Count - 1
		        Var err As JSONItem = errors.Value(i)
		        Var errType As String = If(err.HasKey("type"), err.Value("type").StringValue, "Error")
		        Var msg As String = If(err.HasKey("message"), err.Value("message").StringValue, "")
		        Var location As String = If(err.HasKey("location"), err.Value("location").StringValue, "")
		        Var position As String = If(err.HasKey("position"), err.Value("position").StringValue, "")
		        Var line As String = errType + ": " + msg
		        If location <> "" Then line = line + " [" + location + "]"
		        If position <> "" And position <> location Then line = line + " (" + position + ")"
		        lines.Add(line)
		      Next i
		      Return MCPKit.ToolResult.Failure("Build errors (" + errors.Count.ToString + "):" + EndOfLine + String.FromArray(lines, EndOfLine))
		    End If
		    Return MCPKit.ToolResult.Failure("Build failed: " + buildError.ToString)
		  End If

		  // Unknown JSON structure — return raw for debugging.
		  Return MCPKit.ToolResult.Failure("Build failed: " + resultJSON.ToString)

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
