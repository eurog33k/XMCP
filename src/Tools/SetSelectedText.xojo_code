#tag Class
Protected Class SetSelectedText
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("set_selected_text", "Replaces the currently selected text in the Xojo IDE code editor with new text. You can also set the selection position and length first.")

		  Parameters.Add(New MCPKit.ToolParameter("text", MCPKit.ToolParameterTypes.String_, _
		  "The replacement text to insert.", _
		  False, "", True))

		  Parameters.Add(New MCPKit.ToolParameter("selection_start", MCPKit.ToolParameterTypes.Integer_, _
		  "Optional character offset to set the selection start before replacing.", _
		  True, -1, False))

		  Parameters.Add(New MCPKit.ToolParameter("selection_length", MCPKit.ToolParameterTypes.Integer_, _
		  "Optional number of characters to select before replacing.", _
		  True, 0, False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var text As String = ""
		  Var selStart As Integer = -1
		  Var selLength As Integer = 0
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "text" Then
		      text = arg.Value.StringValue
		    ElseIf arg.Name = "selection_start" Then
		      selStart = arg.Value.IntegerValue
		    ElseIf arg.Name = "selection_length" Then
		      selLength = arg.Value.IntegerValue
		    End If
		  Next arg

		  Var setTextScript As String = BuildStringVariableScript("__text", text) + EndOfLine + _
		  "SelectedText = __text" + EndOfLine + _
		  "Print ""Text replaced successfully."""

		  Var innerScript As String
		  If selStart >= 0 Then
		    innerScript = "SelectionStart = " + selStart.ToString + EndOfLine + _
		    "SelectionLength = " + selLength.ToString + EndOfLine
		  End If
		  innerScript = innerScript + setTextScript

		  Var script As String = _
		  "Try" + EndOfLine + _
		  innerScript + EndOfLine + _
		  "Catch" + EndOfLine + _
		  "  Print ""ERROR: No code editor is active. Navigate to a method or property first.""" + EndOfLine + _
		  "End Try"

		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If
		  
		  Return App.IDE.RunScript(script)

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
