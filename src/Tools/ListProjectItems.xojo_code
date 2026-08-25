#tag Class
Protected Class ListProjectItems
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("list_project_items", "Lists child items at a given project location in the Xojo IDE Navigator. Returns a tab-delimited list of item names. Pass an empty location to list top-level items.")

		  Parameters.Add(New MCPKit.ToolParameter("location", MCPKit.ToolParameterTypes.String_, _
		  "Dot-separated project path (e.g. 'App' or 'Module1.Method1'). Leave empty for top-level items.", _
		  True, "", False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var location As String = ""
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "location" Then
		      location = arg.Value.StringValue
		      Exit
		    End If
		  Next arg

		  Var script As String
		  If location = "" Then
		    script = "Print SubLocations("""")"
		  Else
		    script = "Print SubLocations(""" + location.ReplaceAll("""", """""") + """)"
		  End If

		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If
		  
		  Var response As JSONItem = App.IDE.SendAndReceive(script)
		  If response = Nil Then
		    If App.IDE.LastErrorMessage <> "" Then
		      Return MCPKit.ToolResult.Failure(App.IDE.LastErrorMessage)
		    End If
		    Return MCPKit.ToolResult.Failure("Timeout waiting for IDE response.")
		  End If

		  If response.HasKey("response") Then
		    Var resp As Variant = response.Value("response")
		    Var listing As String = ""
		    If resp.Type = Variant.TypeString Then
		      listing = resp.StringValue
		    Else
		      Var respJSON As JSONItem = response.Value("response")
		      listing = respJSON.ToString
		    End If

		    // SubLocations enumerates contained project ITEMS, so a class - or a module holding
		    // only methods - answers with nothing. That is not an empty container; it is a
		    // question the IDE cannot answer. Fall back to the parsed files, which can.
		    If location <> "" And IsEmptyListing(listing) Then
		      Var fallback As String = MembersFromSource(location)
		      If fallback <> "" Then Return MCPKit.ToolResult.Success(fallback)
		    End If

		    Return MCPKit.ToolResult.Success(listing)
		  End If

		  Return MCPKit.ToolResult.Failure("Unexpected response from IDE: " + response.ToString)

		End Function
	#tag EndMethod


	#tag Method, Flags = &h21
		Private Function IsEmptyListing(listing As String) As Boolean
		  Var trimmed As String = listing.Trim
		  Return trimmed = "" Or trimmed = "{}"

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function MembersFromSource(location As String) As String
		  /// What the item contains according to the project files, or "" if that cannot be
		  /// determined. Saves the project first - see ProjectSource.Load.

		  Var errorMessage As String
		  Var note As String
		  Var project As XKProject = ProjectSource.Load(errorMessage, note)
		  If project = Nil Then Return ""

		  Var item As XKProjectItem = ProjectSource.FindItem(project, location)
		  If item = Nil Then Return ""

		  Var members As String = ProjectSource.DescribeMembers(item)
		  If members = "" Then Return ""

		  Return "The IDE reports no contained project items here, so this is read from the " + _
		  "project files instead. " + note + EndOfLine + EndOfLine + members + EndOfLine + EndOfLine + _
		  "Use describe_item for the same information with more detail."

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
