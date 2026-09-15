#tag Class
Protected Class AnalyzeProject
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("analyze_project", "Analyzes the current Xojo project for compile errors and warnings without building. Reports unused variables, type mismatches, deprecated API usage, and other issues. Pass scope=""item"" to analyze only the currently selected item (faster); default is ""project"" to analyze everything.")
		  Parameters.Add(New MCPKit.ToolParameter("scope", MCPKit.ToolParameterTypes.String_, _
		  "Scope to analyze: ""project"" (default) or ""item"" (currently selected item only).", _
		  True, "project", False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If

		  Var scope As String = "project"
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "scope" Then scope = arg.Value.StringValue.Lowercase
		  Next

		  Var command As String
		  If scope = "item" Then
		    command = "CheckItemErrors"
		  Else
		    command = "CheckProjectErrors"
		  End If

		  Var script As String = "DoCommand """ + command + """" + EndOfLine + _
		  "Print """""

		  Var response As JSONItem = App.IDE.SendAndReceive(script, 60000)
		  If response = Nil Then
		    If App.IDE.LastErrorMessage <> "" Then
		      Return MCPKit.ToolResult.Failure(App.IDE.LastErrorMessage)
		    End If
		    Return MCPKit.ToolResult.Failure("Timeout waiting for IDE response.")
		  End If

		  If response.HasKey("response") Then
		    Var resp As Variant = response.Value("response")

		    If resp.Type = Variant.TypeString Then
		      Var respStr As String = resp.StringValue
		      If respStr.Trim = "" Then
		        Return MCPKit.ToolResult.Success("No errors or warnings found.")
		      End If
		      Try
		        Var resultJSON As New JSONItem(respStr)
		        Return ParseAnalyzeResult(resultJSON)
		      Catch e As JSONException
		        Return MCPKit.ToolResult.Failure("Unexpected non-JSON response: " + respStr)
		      End Try
		    Else
		      Var respJSON As JSONItem = response.Value("response")
		      Return ParseAnalyzeResult(respJSON)
		    End If
		  End If

		  Return MCPKit.ToolResult.Failure("Unexpected response from IDE: " + response.ToString)

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ParseAnalyzeResult(resultJSON As JSONItem) As MCPKit.ToolResult
		  If resultJSON.Count = 0 Then
		    Return MCPKit.ToolResult.Success("No errors or warnings found.")
		  End If

		  If resultJSON.HasKey("buildError") Then
		    Var buildError As JSONItem = resultJSON.Value("buildError")

		    Var lines() As String
		    Var errorCount As Integer = 0
		    Var warningCount As Integer = 0

		    // Errors
		    If buildError.HasKey("errors") Then
		      Var errors As JSONItem = buildError.Value("errors")
		      Var i As Integer
		      For i = 0 To errors.Count - 1
		        Var err As JSONItem = errors.Value(i)
		        Var errType As String = If(err.HasKey("type"), err.Value("type").StringValue, "Error")
		        Var msg As String = If(err.HasKey("message"), err.Value("message").StringValue, "")
		        Var location As String = If(err.HasKey("location"), err.Value("location").StringValue, "")
		        Var position As String = If(err.HasKey("position"), err.Value("position").StringValue, "")
		        Var line As String = errType + ": " + msg
		        If location <> "" Then line = line + " [" + location + "]"
		        If position <> "" And position <> location Then line = line + " (" + position + ")"
		        lines.Add(line)
		        errorCount = errorCount + 1
		      Next i
		    End If

		    // Warnings
		    If buildError.HasKey("warnings") Then
		      Var warnings As JSONItem = buildError.Value("warnings")
		      Var i As Integer
		      For i = 0 To warnings.Count - 1
		        Var w As JSONItem = warnings.Value(i)
		        Var msg As String = If(w.HasKey("message"), w.Value("message").StringValue, "")
		        Var location As String = If(w.HasKey("location"), w.Value("location").StringValue, "")
		        Var position As String = If(w.HasKey("position"), w.Value("position").StringValue, "")
		        Var line As String = "Warning: " + msg
		        If location <> "" Then line = line + " [" + location + "]"
		        If position <> "" And position <> location Then line = line + " (" + position + ")"
		        lines.Add(line)
		        warningCount = warningCount + 1
		      Next i
		    End If

		    If lines.Count = 0 Then
		      Return MCPKit.ToolResult.Success("No errors or warnings found.")
		    End If

		    Var summary As String = ""
		    If errorCount > 0 Then summary = Str(errorCount) + " error(s)"
		    If warningCount > 0 Then
		      If summary <> "" Then summary = summary + ", "
		      summary = summary + Str(warningCount) + " warning(s)"
		    End If

		    Var result As String = "Analysis results (" + summary + "):" + EndOfLine + String.FromArray(lines, EndOfLine)

		    If errorCount > 0 Then
		      Return MCPKit.ToolResult.Failure(result)
		    Else
		      Return MCPKit.ToolResult.Success(result)
		    End If
		  End If

		  Return MCPKit.ToolResult.Failure("Unexpected response: " + resultJSON.ToString)

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
