#tag Class
Protected Class App
Inherits MCPKit.ServerApplication
	#tag Event
		Sub Configure()
		  // Set server identity.
		  Self.Name = "XMCP"
		  
		  // Connect to the Xojo IDE via IPC socket.
		  Try
		    IDE = New IDECommunicator
		    If Verbose Then System.DebugLog("IDE communicator initialized.")
		  Catch e As RuntimeException
		    System.DebugLog("WARNING: Could not connect to Xojo IDE: " + e.Message)
		    System.DebugLog("Make sure the Xojo IDE is running. Looked for its IPC socket at: " + Platform.SocketPathSummary)
		    IDE = Nil
		  End Try
		  
		  // Detect documentation path.
		  Var docsPathStr As String = CommandLineParser.StringValue("docs-path")
		  If docsPathStr <> "" Then
		    // Use explicit --docs-path.
		    DocsPath = New FolderItem(docsPathStr, FolderItem.PathModes.Native)
		    If DocsPath = Nil Or Not DocsPath.Exists Then
		      System.DebugLog("WARNING: Specified docs path does not exist: " + docsPathStr)
		      DocsPath = Nil
		    End If
		  Else
		    // Auto-detect: scan the Xojo application data folder for the newest version.
		    DocsPath = DetectDocsPath
		  End If
		  
		  If DocsPath <> Nil Then
		    If Verbose Then System.DebugLog("Documentation path: " + DocsPath.NativePath)
		  Else
		    If Verbose Then System.DebugLog("WARNING: Xojo documentation not found. Doc tools will be unavailable.")
		  End If
		  
		  // Register all MCP tools.
		  RegisterTools( _
		  New ListProjectItems, _
		  New GetCurrentLocation, _
		  New SelectProjectItem, _
		  New GetCode, _
		  New SetCode, _
		  New GetSelectedText, _
		  New SetSelectedText, _
		  New BuildProject, _
		  New RunProject, _
		  New StopProject, _
		  New CreateProjectItem, _
		  New RunIDEScript, _
		  New GetProjectInfo, _
		  New GetItemDescription, _
		  New ConstantValue, _
		  New SearchDocs, _
		  New LookupClass, _
		  New ListDocTopics, _
		  New RevertProject, _
		  New EstimateRequestCost, _
		  New GetDebugLog _
		  )

		  // get_system_log reads the macOS unified log; there is no equivalent elsewhere,
		  // so it is not advertised on other platforms. RegisterTools appends, so this
		  // simply adds to the list above.
		  #If TargetMacOS Then
		    RegisterTools(New GetSystemLog)
		  #EndIf

		  If Verbose Then System.DebugLog("XMCP server configured with " + mTools.Count.ToString + " tools.")
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub DidParseOptions()
		  If CommandLineParser.HelpRequested Then
		    CommandLineParser.ShowHelp("Options")
		    Print("")
		    // A literal, not mTools.Count: DidParseOptions runs before Configure, so no
		    // tools are registered yet at this point.
		    #If TargetMacOS Then
		      Print("MCP Tools (22):")
		    #Else
		      Print("MCP Tools (21):")
		    #EndIf
		    Print("")
		    Print("  IDE Tools:")
		    Print("  list_project_items   List child items at a project location")
		    Print("  get_current_location Get the current Navigator location and type")
		    Print("  select_project_item  Navigate to a project item by path")
		    Print("  get_code             Read source code at current/specified location")
		    Print("  set_code             Write source code to current/specified location")
		    Print("  get_selected_text    Get selected text in the code editor")
		    Print("  set_selected_text    Replace selected text in the code editor")
		    Print("  build_project        Build the project (returns path or errors)")
		    Print("  run_project          Run the project in debug mode")
		    Print("  stop_project         Stop the running debug session")
		    Print("  create_project_item  Create a new class, method, property, etc.")
		    Print("  run_ide_script       Execute an arbitrary IDE script")
		    Print("  get_project_info     Get project path, Xojo version, and location")
		    Print("  revert_project       Reload project from disk after file changes")
		    Print("  get_item_description Get or set the description of a project item")
		    Print("  constant_value       Get or set the value of a project constant")
		    Print("")
		    Print("  Documentation Tools:")
		    Print("  search_docs          Search Xojo documentation by keyword")
		    Print("  lookup_class         Look up detailed docs for a specific class")
		    Print("  list_doc_topics      List available documentation topics")
		    Print("")
		    Print("  Cost Awareness:")
		    Print("  estimate_request_cost Estimate likely token cost and alternatives")
		    Print("")
		    Print("  Debug Tools:")
		    Print("  get_debug_log        Read crash/exception log from " + Platform.DebugLogPath)
		    #If TargetMacOS Then
		      Print("  get_system_log       Read System.DebugLog output from macOS unified log")
		    #EndIf
		    Print("")
		    Print("Usage:")
		    Print("  The XMCP server communicates via JSON-RPC over stdin/stdout (MCP protocol).")
		    Print("  It connects to the Xojo IDE via an IPC socket. Candidate paths on this")
		    Print("  platform: " + Platform.SocketPathSummary)
		    #If TargetWindows Then
		      Print("  Documentation is auto-detected from %APPDATA%\Xojo\Xojo")
		    #Else
		      Print("  Documentation is auto-detected from ~/Library/Application Support/Xojo/")
		    #EndIf
		    Print("  or can be specified with --docs-path.")
		    Print("")
		    Print("  Make sure the Xojo IDE is running before starting this server.")
		    Print("")
		    Print("Example MCP client configuration (Claude Code):")
		    Print("  {")
		    Print("    ""mcpServers"": {")
		    Print("      ""xmcp"": {")
		    #If TargetWindows Then
		      Print("        ""command"": ""C:\\path\\to\\XMCP.exe""")
		    #Else
		      Print("        ""command"": ""/path/to/XMCP""")
		    #EndIf
		    Print("      }")
		    Print("    }")
		    Print("  }")
		    Quit
		  End If
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub WillParseOptions()
		  CommandLineParser.AppDescription = "MCP server for controlling the Xojo IDE"
		  CommandLineParser.AddOption("d", "docs-path", "Path to Xojo documentation directory (auto-detected if omitted)", MCPKit.OptionTypes.String)
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Function CompareVersionNames(a As String, b As String) As Integer
		  Var aParts() As Integer = ExtractVersionParts(a)
		  Var bParts() As Integer = ExtractVersionParts(b)
		  
		  If aParts.Count > 0 Or bParts.Count > 0 Then
		    Var maxCount As Integer = Max(aParts.Count, bParts.Count)
		    For i As Integer = 0 To maxCount - 1
		      Var aValue As Integer = 0
		      Var bValue As Integer = 0
		      If i <= aParts.LastIndex Then aValue = aParts(i)
		      If i <= bParts.LastIndex Then bValue = bParts(i)
		      
		      If aValue > bValue Then Return 1
		      If aValue < bValue Then Return -1
		    Next i
		    Return 0
		  End If
		  
		  Var aNorm As String = a.Lowercase
		  Var bNorm As String = b.Lowercase
		  If aNorm > bNorm Then Return 1
		  If aNorm < bNorm Then Return -1
		  Return 0
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function DetectDocsPath() As FolderItem
		  // Look for Xojo docs under SpecialFolder.ApplicationData:
		  //   macOS:   ~/Library/Application Support/Xojo/Xojo/<version>/Documentation/
		  //   Windows: %APPDATA%\Xojo\Xojo\<version>\Documentation\
		  Var appSupport As FolderItem = SpecialFolder.ApplicationData
		  If appSupport = Nil Then Return Nil
		  
		  Var xojoDir As FolderItem = appSupport.Child("Xojo").Child("Xojo")
		  If xojoDir = Nil Or Not xojoDir.Exists Then Return Nil
		  
		  // Find the newest version directory that has Documentation/llms-full.txt.
		  Var bestDir As FolderItem = Nil
		  Var bestName As String = ""
		  
		  For i As Integer = 0 To xojoDir.Count - 1
		    Var item As FolderItem = xojoDir.ChildAt(i)
		    If item = Nil Or Not item.IsFolder Then Continue
		    
		    Var docsDir As FolderItem = item.Child("Documentation")
		    If docsDir = Nil Or Not docsDir.Exists Then Continue
		    
		    Var llmsFile As FolderItem = docsDir.Child("llms-full.txt")
		    If llmsFile = Nil Or Not llmsFile.Exists Then Continue
		    
		    // Pick the highest semantic version directory (e.g. 2024r10 > 2024r9).
		    If bestDir = Nil Or CompareVersionNames(item.Name, bestName) > 0 Then
		      bestName = item.Name
		      bestDir = docsDir
		    End If
		  Next i
		  
		  Return bestDir
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ExtractVersionParts(value As String) As Integer()
		  Var parts() As Integer
		  Var currentDigits As String = ""
		  
		  For i As Integer = 0 To value.Length - 1
		    Var ch As String = value.Middle(i, 1)
		    If ch >= "0" And ch <= "9" Then
		      currentDigits = currentDigits + ch
		    ElseIf currentDigits <> "" Then
		      parts.Add(currentDigits.ToInteger)
		      currentDigits = ""
		    End If
		  Next i
		  
		  If currentDigits <> "" Then
		    parts.Add(currentDigits.ToInteger)
		  End If
		  
		  Return parts
		  
		End Function
	#tag EndMethod

	#tag Property, Flags = &h0, Description = 5061746820746F20586F6A6F20646F63756D656E746174696F6E206469726563746F72792E
		DocsPath As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h0, Description = 546865207368617265642049444520636F6D6D756E696361746F7220696E7374616E63652E
		IDE As IDECommunicator
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Name"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Verbose"
			Visible=false
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
