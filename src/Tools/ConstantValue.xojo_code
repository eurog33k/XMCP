#tag Class
Protected Class ConstantValue
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("constant_value", "Gets or sets the value of a project constant in the Xojo IDE. The constant must already exist - IDE scripting cannot create a properly named, typed constant. Qualify the name with its owner (e.g. 'App.kVersion'), because an unqualified name is only resolved against whatever item happens to be selected in the Navigator and otherwise returns nothing.")

		  Parameters.Add(New MCPKit.ToolParameter("name", MCPKit.ToolParameterTypes.String_, _
		  "The constant name, qualified with its owner: 'App.kVersion', 'Module1.ISNVSYNC'. A bare name like 'kVersion' resolves only against the currently selected project item, so it usually returns nothing - qualify it. Folder names are not part of the path.", _
		  False, "", False))

		  Parameters.Add(New MCPKit.ToolParameter("value", MCPKit.ToolParameterTypes.String_, _
		  "If provided, sets the constant to this value. If omitted, returns the current value.", _
		  True, "", False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var name As String = ""
		  Var value As String = ""
		  Var hasValue As Boolean = False

		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "name" Then
		      name = arg.Value.StringValue
		    ElseIf arg.Name = "value" Then
		      value = arg.Value.StringValue
		      hasValue = True
		    End If
		  Next arg

		  If name = "" Then
		    Return MCPKit.ToolResult.Failure("Parameter 'name' is required.")
		  End If

		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If

		  Var script As String
		  If hasValue Then
		    script = "ConstantValue(""" + name.ReplaceAll("""", """""") + """) = """ + value.ReplaceAll("""", """""") + """" + EndOfLine + _
		    "Print ""OK"""
		  Else
		    script = "Print ConstantValue(""" + name.ReplaceAll("""", """""") + """)"
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
