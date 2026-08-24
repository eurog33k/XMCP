#tag Class
Protected Class GetSystemLog
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("get_system_log", "Reads recent System.DebugLog output from the macOS unified log for a running Xojo debug app. The process name is the app name with '.debug' suffix (e.g. 'MyApp.debug'). Use this to retrieve diagnostic messages written with System.DebugLog() in the app's code.")

		  Parameters.Add(New MCPKit.ToolParameter("process_name", MCPKit.ToolParameterTypes.String_, _
		  "The process name to filter by. For Xojo debug builds this is the app name with '.debug' suffix, e.g. 'MyApp.debug'. Use get_project_info to find the project name.", _
		  False, "", True))

		  Parameters.Add(New MCPKit.ToolParameter("seconds", MCPKit.ToolParameterTypes.Integer_, _
		  "How many seconds back to search the log. Default is 60.", _
		  True, 60, False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  #If TargetMacOS Then
		  Var processName As String = ""
		  Var seconds As Integer = 60
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "process_name" Then processName = arg.Value.StringValue
		    If arg.Name = "seconds" Then seconds = arg.Value.IntegerValue
		  Next

		  If processName = "" Then
		    Return MCPKit.ToolResult.Failure("process_name is required. For Xojo debug builds use the app name with '.debug' suffix, e.g. 'MyApp.debug'.")
		  End If

		  // Whitelist process_name to prevent shell injection.
		  // Only allow characters valid in a macOS process name.
		  Var rx As New RegEx
		  rx.SearchPattern = "^[A-Za-z0-9_. -]+$"
		  If rx.Search(processName) = Nil Then
		    Return MCPKit.ToolResult.Failure("Invalid process_name: only letters, digits, spaces, dots, hyphens and underscores are allowed.")
		  End If

		  If seconds < 1 Then seconds = 60
		  If seconds > 3600 Then seconds = 3600

		  Var sh As New Shell
		  sh.Execute("log show --last " + seconds.ToString + "s " + _
		    "--predicate 'process == """ + processName + """' 2>/dev/null")
		  Var output As String = sh.Result

		  // Filter to only System.DebugLog messages.
		  // System.DebugLog always writes with "(XojoFramework)" as the sender.
		  Var lines() As String = output.Split(Chr(10))
		  Var result() As String
		  For Each line As String In lines
		    If line.Contains("(XojoFramework)") Then result.Add(line)
		  Next

		  If result.Count = 0 Then
		    Return MCPKit.ToolResult.Success("No log entries found for process '" + processName + "' in the last " + seconds.ToString + " seconds.")
		  End If

		  Return MCPKit.ToolResult.Success(String.FromArray(result, Chr(10)))

		  #Else
		    // App.Configure only registers this tool on macOS, so this is just a backstop.
		    // There is no equivalent of the unified log elsewhere: on Windows
		    // System.DebugLog goes to OutputDebugString, which only an attached debugger
		    // sees, and on Linux it goes to stderr.
		    #Pragma Unused args
		    Return MCPKit.ToolResult.Failure("get_system_log is only available on macOS, " + _
		    "where it reads the unified log. Instead, have the app write to " + Platform.DebugLogPath + _
		    " from an App.UnhandledException handler and read it with get_debug_log.")
		  #EndIf

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
