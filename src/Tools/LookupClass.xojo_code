#tag Class
Protected Class LookupClass
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("lookup_class", "Looks up detailed documentation for a specific Xojo class, control, data type, or API by name. Returns the full structured reference including properties, methods, events, and examples.")

		  Parameters.Add(New MCPKit.ToolParameter("class_name", MCPKit.ToolParameterTypes.String_, _
		  "The name of the class to look up (e.g. 'DesktopButton', 'JSONItem', 'FolderItem', 'String').", _
		  False, "", True))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var className As String = ""
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "class_name" Then
		      className = arg.Value.StringValue
		      Exit
		    End If
		  Next arg

		  If className = "" Then
		    Return MCPKit.ToolResult.Failure("The class_name parameter is required.")
		  End If

		  If App.DocsPath = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo documentation not found. Use --docs-path to specify the documentation directory, or ensure the Xojo IDE has been run at least once.")
		  End If

		  Var sourcesDir As FolderItem = App.DocsPath.Child("_sources")
		  If sourcesDir = Nil Or Not sourcesDir.Exists Then
		    Return MCPKit.ToolResult.Failure("Documentation _sources directory not found.")
		  End If

		  // Search for the RST file matching the class name.
		  Var targetName As String = className.Lowercase + ".rst.txt"
		  Var foundFile As FolderItem = FindFileRecursive(sourcesDir, targetName)

		  If foundFile = Nil Then
		    // Try without "Desktop" prefix (e.g., "Button" -> "desktopbutton.rst.txt").
		    targetName = "desktop" + className.Lowercase + ".rst.txt"
		    foundFile = FindFileRecursive(sourcesDir, targetName)
		  End If

		  If foundFile = Nil Then
		    // Try without "Web" prefix.
		    targetName = "web" + className.Lowercase + ".rst.txt"
		    foundFile = FindFileRecursive(sourcesDir, targetName)
		  End If

		  If foundFile = Nil Then
		    Return MCPKit.ToolResult.Failure("No documentation found for class: " + className + ". Try using search_docs or list_doc_topics to find the correct name.")
		  End If

		  Const kMaxOutputChars = 102400 // ~100 K characters; counted by character so UTF-8 is never split mid-codepoint

		  // Read the RST file.
		  Try
		    Var tis As TextInputStream = TextInputStream.Open(foundFile)
		    tis.Encoding = Encodings.UTF8
		    Var content As String = tis.ReadAll
		    tis.Close

		    If content.Length > kMaxOutputChars Then
		      Var truncated As String = content.Left(kMaxOutputChars)
		      Var footer As String = EndOfLine + "[truncated to first " + kMaxOutputChars.ToString + " of " + content.Length.ToString + " characters — use search_docs to find specific topics within this class]"
		      Return MCPKit.ToolResult.Success(truncated + footer)
		    End If

		    Return MCPKit.ToolResult.Success(content)
		  Catch e As IOException
		    Return MCPKit.ToolResult.Failure("Error reading documentation file: " + e.Message)
		  End Try

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FindFileRecursive(folder As FolderItem, targetName As String) As FolderItem
		  If folder = Nil Or Not folder.Exists Then Return Nil

		  For i As Integer = 0 To folder.Count - 1
		    Var item As FolderItem = folder.ChildAt(i)
		    If item = Nil Then Continue

		    If item.IsFolder Then
		      Var result As FolderItem = FindFileRecursive(item, targetName)
		      If result <> Nil Then Return result
		    Else
		      If item.Name.Lowercase = targetName Then
		        Return item
		      End If
		    End If
		  Next i

		  Return Nil

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
