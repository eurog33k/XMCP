#tag Class
Protected Class GetDebugLog
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("get_debug_log", "Reads the XMCP debug log file (/tmp/xmcp_debug.log on macOS and Linux, %TEMP%\xmcp_debug.log on Windows). This file is written by App.UnhandledException handlers in Xojo apps that use the XMCP debug pattern. Returns the file contents or an empty message if no log exists. Call this after a crash or unexpected app termination to retrieve exception details (message, error number, stack trace).")

		  Parameters.Add(New MCPKit.ToolParameter("clear", MCPKit.ToolParameterTypes.Boolean_, _
		  "If true, deletes the log file after reading it. Default is false.", _
		  True, False, False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var clearLog As Boolean = False
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "clear" Then clearLog = arg.Value.BooleanValue
		  Next

		  Var logFile As FolderItem = Platform.DebugLogFile
		  Var logPath As String = Platform.DebugLogPath
		  If logFile = Nil Or Not logFile.Exists Then
		    Return MCPKit.ToolResult.Success("No debug log found at " + logPath + ". Make sure the app has an App.UnhandledException handler that writes to this path.")
		  End If

		  Var content As String
		  Try
		    Var stream As TextInputStream = TextInputStream.Open(logFile)
		    stream.Encoding = Encodings.UTF8
		    content = stream.ReadAll
		    stream.Close
		  Catch e As IOException
		    Return MCPKit.ToolResult.Failure("Failed to read " + logPath + ": " + e.Message)
		  End Try

		  If clearLog Then
		    Try
		      logFile.Remove
		    Catch e As IOException
		      // Non-fatal - return content anyway
		    End Try
		  End If

		  If content.Trim = "" Then
		    Return MCPKit.ToolResult.Success("Log file exists but is empty.")
		  End If

		  Return MCPKit.ToolResult.Success(content)

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
