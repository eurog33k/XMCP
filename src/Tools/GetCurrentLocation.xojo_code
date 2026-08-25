#tag Class
Protected Class GetCurrentLocation
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("get_current_location", "Returns the currently selected location in the Xojo IDE Navigator and its type (e.g. Class, Method, Window).")

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  #Pragma Unused args

		  // Report an empty location as such. Printing "loc (typ)" unconditionally produced a
		  // bare "()" whenever nothing was selected - which happens straight after a delete -
		  // and that reads like a malformed answer rather than an empty one.
		  Var script As String = "Dim loc As String = Location" + EndOfLine + _
		  "Dim typ As String = TypeOfCurrentLocation" + EndOfLine + _
		  "If loc = """" Then" + EndOfLine + _
		  "  Print ""Nothing is selected in the Navigator.""" + EndOfLine + _
		  "Else" + EndOfLine + _
		  "  Print loc + "" ("" + typ + "")""" + EndOfLine + _
		  "End If"

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
		    If resp.Type = Variant.TypeString Then
		      Return MCPKit.ToolResult.Success(resp.StringValue)
		    Else
		      Var respJSON As JSONItem = response.Value("response")
		      Return MCPKit.ToolResult.Success(respJSON.ToString)
		    End If
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
