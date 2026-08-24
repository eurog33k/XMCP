#tag Class
Protected Class SetCode
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("set_code", "Writes source code to the current or specified location in the Xojo IDE. This replaces the entire code content at that location.")

		  Parameters.Add(New MCPKit.ToolParameter("code", MCPKit.ToolParameterTypes.String_, _
		  "The source code to write.", _
		  False, "", True))

		  Parameters.Add(New MCPKit.ToolParameter("location", MCPKit.ToolParameterTypes.String_, _
		  "Optional dot-separated path to navigate to before writing code. If empty, writes to current location.", _
		  True, "", False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var code As String = ""
		  Var location As String = ""
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "code" Then
		      code = arg.Value.StringValue
		    ElseIf arg.Name = "location" Then
		      location = arg.Value.StringValue
		    End If
		  Next arg

		  If code = "" Then
		    Return MCPKit.ToolResult.Failure("The code parameter is required.")
		  End If
		  
		  Var writeCodeScript As String = BuildStringVariableScript("__code", code) + EndOfLine + _
		  "Text = __code" + EndOfLine + _
		  "Print ""Code written to: "" + Location"
		  
		  Var script As String

		  If location <> "" Then
		    // Assigning Location reaches methods and event implementations, which
		    // SelectProjectItem cannot; it is kept as the fallback for folders and other
		    // items Location does not accept. A bad path leaves Location untouched rather
		    // than raising, so compare afterwards.
		    Var target As String = location.ReplaceAll("""", """""")
		    script = "Dim target As String = """ + target + """" + EndOfLine + _
		    "Dim ok As Boolean = True" + EndOfLine + _
		    "Location = target" + EndOfLine + _
		    "If Location <> target Then" + EndOfLine + _
		    "  ok = SelectProjectItem(target)" + EndOfLine + _
		    "End If" + EndOfLine + _
		    "If Not ok Then" + EndOfLine + _
		    "  Print ""ERROR: Could not navigate to: " + target + ". For window event handlers, edit the .xojo_window file directly on disk and call revert_project.""" + EndOfLine + _
		    "Else" + EndOfLine + _
		    "  Try" + EndOfLine + _
		    IndentLines(writeCodeScript, "    ") + EndOfLine + _
		    "  Catch" + EndOfLine + _
		    "    Print ""ERROR: No code editor is active. Navigate to a method or property first, or use get_project_info to find the project directory and edit the .xojo_code file directly, then call revert_project.""" + EndOfLine + _
		    "  End Try" + EndOfLine + _
		    "End If"
		  Else
		    script = _
		    "Try" + EndOfLine + _
		    IndentLines(writeCodeScript, "  ") + EndOfLine + _
		    "Catch" + EndOfLine + _
		    "  Print ""ERROR: No code editor is active. Navigate to a method or property first, or use get_project_info to find the project directory and edit the .xojo_code file directly, then call revert_project.""" + EndOfLine + _
		    "End Try"
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

	#tag Method, Flags = &h21
		Private Function IndentLines(value As String, indent As String) As String
		  Var lines() As String = value.Split(EndOfLine)
		  
		  For i As Integer = 0 To lines.LastIndex
		    If lines(i) <> "" Then
		      lines(i) = indent + lines(i)
		    End If
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
