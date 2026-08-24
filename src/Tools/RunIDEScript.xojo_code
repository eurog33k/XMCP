#tag Class
Protected Class RunIDEScript
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("run_ide_script", "Executes an arbitrary Xojo IDE script. This is an escape hatch for any IDE scripting command not covered by other tools. Use Print to return a value - but note that only the FIRST Print in a script is returned and later ones are discarded, so print once, at the point whose value you want. To check the effect of a command, print afterwards in a separate call rather than adding a second Print.")

		  Parameters.Add(New MCPKit.ToolParameter("script", MCPKit.ToolParameterTypes.String_, _
		  "The IDE script code to execute. Use XojoScript syntax with IDE scripting commands. " + _
		  "Use Print to return output values.", _
		  False, "", True))

		  Parameters.Add(New MCPKit.ToolParameter("timeout", MCPKit.ToolParameterTypes.Integer_, _
		  "Timeout in milliseconds to wait for a response. Default is 10000 (10 seconds).", _
		  True, 10000, False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var script As String = ""
		  Var timeoutMS As Integer = 10000
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "script" Then
		      script = arg.Value.StringValue
		    ElseIf arg.Name = "timeout" Then
		      timeoutMS = arg.Value.IntegerValue
		    End If
		  Next arg

		  If script = "" Then
		    Return MCPKit.ToolResult.Failure("The script parameter is required.")
		  End If

		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If
		  
		  Var response As JSONItem = App.IDE.SendAndReceive(script, timeoutMS)
		  If response = Nil Then
		    If App.IDE.LastErrorMessage <> "" Then
		      Return MCPKit.ToolResult.Failure(App.IDE.LastErrorMessage)
		    End If
		    Return MCPKit.ToolResult.Failure("Timeout waiting for IDE response (" + timeoutMS.ToString + "ms).")
		  End If

		  // Check for script errors.
		  If response.HasKey("response") Then
		    Var resp As Variant = response.Value("response")
		    If resp.Type = Variant.TypeString Then
		      If resp.StringValue = "" Then Return NoOutputResult
		      Return MCPKit.ToolResult.Success(resp.StringValue)
		    Else
		      // Could be a scriptError object.
		      Var respJSON As JSONItem = response.Value("response")
		      If respJSON.HasKey("scriptError") Then
		        Return MCPKit.ToolResult.Failure("Script error: " + respJSON.ToString)
		      End If

		      // An empty object is what the IDE answers when the script printed nothing. It is
		      // not necessarily a failure, but returning a bare "{}" reads like output.
		      If respJSON.Count = 0 Then Return NoOutputResult

		      Return MCPKit.ToolResult.Success(respJSON.ToString)
		    End If
		  End If

		  Return MCPKit.ToolResult.Failure("Unexpected response from IDE: " + response.ToString)

		End Function
	#tag EndMethod


	#tag Method, Flags = &h21
		Private Function NoOutputResult() As MCPKit.ToolResult
		  /// The script ran but produced no value. Says so, and names the trap behind most
		  /// cases of it.
		  ///
		  /// Measured on Xojo 2025r3.1: the IDE returns the value of the FIRST Print in a
		  /// script and discards the rest - "Print ""one""" followed by "Print ""two""" answers
		  /// "one". Xojo's own protocol documentation says the last value, so do not trust the
		  /// docs here. This is why a script whose only output comes after an IDE command can
		  /// look as though the command killed it.

		  Return MCPKit.ToolResult.Success("The script ran but produced no value." + EndOfLine + _
		  EndOfLine + _
		  "Two things to check. The IDE returns only the FIRST Print in a script and discards " + _
		  "any later ones, so print once, and print the thing you actually want back. And some " + _
		  "commands simply have no value to give - PropertyValue returns nothing for an item it " + _
		  "does not support, since it only reads framework properties of items such as App or a " + _
		  "Window. Neither case means the script failed: verify the effect in a separate call.")

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
