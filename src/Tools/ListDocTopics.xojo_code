#tag Class
Protected Class ListDocTopics
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("list_doc_topics", "Lists available Xojo documentation topics and pages. Returns an index of all documentation pages, optionally filtered by keyword. Use this to discover what documentation is available before looking up specific classes.")

		  Parameters.Add(New MCPKit.ToolParameter("filter", MCPKit.ToolParameterTypes.String_, _
		  "Optional keyword to filter topics (e.g. 'Desktop', 'database', 'networking'). If empty, returns all topics.", _
		  True, "", False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var filter As String = ""
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "filter" Then
		      filter = arg.Value.StringValue
		      Exit
		    End If
		  Next arg

		  If App.DocsPath = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo documentation not found. Use --docs-path to specify the documentation directory, or ensure the Xojo IDE has been run at least once.")
		  End If

		  Var llmsIndex As FolderItem = App.DocsPath.Child("llms.txt")
		  If llmsIndex = Nil Or Not llmsIndex.Exists Then
		    Return MCPKit.ToolResult.Failure("Could not find llms.txt index in documentation directory.")
		  End If

		  Try
		    Var tis As TextInputStream = TextInputStream.Open(llmsIndex)
		    tis.Encoding = Encodings.UTF8
		    Var content As String = tis.ReadAll
		    tis.Close

		    If filter = "" Then
		      Return MCPKit.ToolResult.Success(content)
		    End If

		    // Filter the lines.
		    Var lines() As String = SplitLines(content)
		    Var matches() As String
		    Var lowerFilter As String = filter.Lowercase

		    For Each line As String In lines
		      If line.Lowercase.IndexOf(lowerFilter) >= 0 Then
		        matches.Add(line)
		      End If
		    Next line

		    If matches.Count = 0 Then
		      Return MCPKit.ToolResult.Success("No topics found matching: " + filter)
		    End If

		    Return MCPKit.ToolResult.Success("Found " + matches.Count.ToString + " topic(s) matching """ + filter + """:" + EndOfLine + String.FromArray(matches, EndOfLine))

		  Catch e As IOException
		    Return MCPKit.ToolResult.Failure("Error reading documentation index: " + e.Message)
		  End Try

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
