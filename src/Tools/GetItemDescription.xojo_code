#tag Class
Protected Class GetItemDescription
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("get_item_description", "Gets or sets the description of the currently selected project item (method, property, event, etc.) in the Xojo IDE. Pass a value to set the description, or omit it to read the current description.")

		  Parameters.Add(New MCPKit.ToolParameter("location", MCPKit.ToolParameterTypes.String_, _
		  "Optional dot-separated path to navigate to before reading/writing (e.g. 'App.MyMethod'). If empty, uses current location.", _
		  True, "", False))

		  Parameters.Add(New MCPKit.ToolParameter("value", MCPKit.ToolParameterTypes.String_, _
		  "If provided, sets the description to this value. If omitted, returns the current description.", _
		  True, "", False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var location As String = ""
		  Var value As String = ""
		  Var hasValue As Boolean = False

		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "location" Then
		      location = arg.Value.StringValue
		    ElseIf arg.Name = "value" Then
		      value = arg.Value.StringValue
		      hasValue = True
		    End If
		  Next arg

		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If

		  // The body runs inside an If/Else rather than after a bare "End" to abort early:
		  // "End" on its own is not a statement in XojoScript, and emitting it made every
		  // call that passed a location fail with a syntax error.
		  //
		  // Navigation assigns Location first, which reaches methods, properties and event
		  // implementations; SelectProjectItem, used alone here before, only reaches top-level
		  // items, so a member path could not have worked even once the syntax was valid.
		  Var body As String
		  If hasValue Then
		    body = "ItemDescription = """ + value.ReplaceAll("""", """""") + """" + EndOfLine + _
		    "Print ""OK"""
		  Else
		    body = "Print ItemDescription"
		  End If

		  Var script As String
		  If location <> "" Then
		    Var target As String = location.ReplaceAll("""", """""")
		    script = "Dim target As String = """ + target + """" + EndOfLine + _
		    "Dim ok As Boolean = True" + EndOfLine + _
		    "Location = target" + EndOfLine + _
		    "If Location <> target Then" + EndOfLine + _
		    "  ok = SelectProjectItem(target)" + EndOfLine + _
		    "End If" + EndOfLine + _
		    "If Not ok Then" + EndOfLine + _
		    "  Print ""ERROR: Could not navigate to: " + target + """" + EndOfLine + _
		    "Else" + EndOfLine + _
		    IndentLines(body, "  ") + EndOfLine + _
		    "End If"
		  Else
		    script = body
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

		    // An item with no description makes the script print nothing, and the IDE answers
		    // with an empty object. Returning a bare "{}" reads like a value rather than the
		    // absence of one.
		    If resp = "" Or resp = "{}" Then
		      Return MCPKit.ToolResult.Success("(no description set)")
		    End If

		    Return MCPKit.ToolResult.Success(resp)
		  End If

		  Return MCPKit.ToolResult.Failure("Unexpected response from IDE: " + response.ToString)

		End Function
	#tag EndMethod


	#tag Method, Flags = &h21
		Private Function IndentLines(value As String, indent As String) As String
		  Var lines() As String = SplitLines(value)

		  For i As Integer = 0 To lines.LastIndex
		    If lines(i) <> "" Then lines(i) = indent + lines(i)
		  Next i

		  Return String.FromArray(lines, EndOfLine)

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
