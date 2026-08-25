#tag Class
Protected Class CreateProjectItem
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("create_project_item", "Creates a new project item in the Xojo IDE. First navigates to the target location (if specified), then creates the item using a DoCommand.")

		  Parameters.Add(New MCPKit.ToolParameter("item_type", MCPKit.ToolParameterTypes.String_, _
		  "The type of item to create. Valid values: NewClass, NewModule, NewMethod, NewProperty, " + _
		  "NewConstant, NewEvent, NewNote, NewMenuHandler, NewComputedProperty, NewSharedMethod, " + _
		  "NewSharedProperty, NewEnum, NewStructure, NewDelegate, NewInterface, NewWindow, " + _
		  "NewContainerControl, NewFolder. AddEventImplementation is documented by Xojo but " + _
		  "unusable: it never answers and stalls the connection for the full timeout, so it is " + _
		  "rejected here rather than attempted.", _
		  False, "", True))

		  Parameters.Add(New MCPKit.ToolParameter("parent_location", MCPKit.ToolParameterTypes.String_, _
		  "Optional dot-separated path to navigate to before creating the item (e.g. 'Module1').", _
		  True, "", False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var itemType As String = ""
		  Var parentLocation As String = ""
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "item_type" Then
		      itemType = arg.Value.StringValue
		    ElseIf arg.Name = "parent_location" Then
		      parentLocation = arg.Value.StringValue
		    End If
		  Next arg

		  If itemType = "" Then
		    Return MCPKit.ToolResult.Failure("The item_type parameter is required.")
		  End If

		  // Validate the item type.
		  Var validTypes() As String = Array("NewClass", "NewModule", "NewMethod", "NewProperty", _
		  "NewConstant", "NewEvent", "NewNote", "NewMenuHandler", "NewComputedProperty", _
		  "NewSharedMethod", "NewSharedProperty", "NewEnum", "NewStructure", "NewDelegate", _
		  "NewInterface", "NewWindow", "NewContainerControl", "NewFolder")

		  // Refuse this one by name rather than letting it hang. Verified on Windows 11 with Xojo
		  // 2026r1.1: DoCommand "AddEventImplementation" returns nothing at all and the pipe sits
		  // there for the full 10s timeout, after which the IDE recovers and no handler has been
		  // added. Failing in a fraction of a second with the reason beats a stall that looks like
		  // a broken connection.
		  If itemType = "AddEventImplementation" Then
		    Return MCPKit.ToolResult.Failure("AddEventImplementation is documented by Xojo but does " + _
		    "not work: it never answers, and waiting for it stalls every other request for the full " + _
		    "timeout. Nothing was created. To add an event handler, edit the .xojo_window or " + _
		    ".xojo_code file on disk - the handler goes in a #tag Events block for a control, or a " + _
		    "#tag Event block for the window or class itself - then call revert_project. This is also " + _
		    "why describe_item cannot show window-level handlers that do not exist yet: there is no " + _
		    "scriptable way to create one.")
		  End If

		  Var isValid As Boolean = False
		  For Each vt As String In validTypes
		    If vt = itemType Then
		      isValid = True
		      Exit
		    End If
		  Next vt

		  If Not isValid Then
		    Return MCPKit.ToolResult.Failure("Invalid item_type: " + itemType + ". See tool description for valid values.")
		  End If

		  Var script As String = ""

		  If parentLocation <> "" Then
		    script = "Dim result As Boolean = SelectProjectItem(""" + _
		    parentLocation.ReplaceAll("""", """""") + """)" + EndOfLine + _
		    "If Not result Then" + EndOfLine + _
		    "  Print ""ERROR: Could not navigate to: " + parentLocation.ReplaceAll("""", """""") + """" + EndOfLine + _
		    "Else" + EndOfLine + _
		    "  DoCommand """ + itemType + """" + EndOfLine + _
		    "  Print ""Created " + itemType + " at: "" + Location" + EndOfLine + _
		    "End If"
		  Else
		    script = "DoCommand """ + itemType + """" + EndOfLine + _
		    "Print ""Created " + itemType + " at: "" + Location"
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
		    Var resp As String
		    Var respVar As Variant = response.Value("response")
		    If respVar.Type = Variant.TypeString Then
		      resp = respVar.StringValue
		    Else
		      Var respJSON As JSONItem = response.Value("response")
		      resp = respJSON.ToString
		    End If

		    If resp.BeginsWith("ERROR:") Then
		      Return MCPKit.ToolResult.Failure(resp)
		    End If
		    Return MCPKit.ToolResult.Success(resp)
		  End If

		  Return MCPKit.ToolResult.Failure("Unexpected response from IDE: " + response.ToString)

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
