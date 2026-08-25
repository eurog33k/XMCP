#tag Class
Protected Class DescribeItem
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("describe_item", "Lists what a class, module, window or interface contains: every method with its full signature, plus properties, computed properties, constants, enums, event implementations and notes. This is the only way to enumerate a class's members - IDE scripting cannot do it, which is why list_project_items returns nothing for a class - and the only way to see that a method is overloaded, since a dot path carries no signature. Pass a member path instead of a container path to get every overload of that name and its code. Reads the project FILES as they stand on disk - it does NOT save first, so anything the IDE is holding unsaved will not appear, including an item deleted in the IDE but not yet saved. Call save_project if you need the files to match, bearing in mind that a save makes such a delete permanent. Needs a Text or XML format project, not binary.")

		  Parameters.Add(New MCPKit.ToolParameter("location", MCPKit.ToolParameterTypes.String_, _
		  "Dot-separated path to a container ('IDECommunicator', 'Window1') or to a member ('Module1.GetFileExtention', 'Window1.Button1.Pressed'). Folder names are not part of the path.", _
		  False, "", True))

		  Parameters.Add(New MCPKit.ToolParameter("include_code", MCPKit.ToolParameterTypes.Boolean_, _
		  "For a member path, include each match's body. Default is true. Ignored for a container.", _
		  True, True, False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var location As String = ""
		  Var includeCode As Boolean = True

		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "location" Then
		      location = arg.Value.StringValue.Trim
		    ElseIf arg.Name = "include_code" Then
		      includeCode = arg.Value.BooleanValue
		    End If
		  Next arg

		  If location = "" Then
		    Return MCPKit.ToolResult.Failure("The location parameter is required.")
		  End If

		  Var errorMessage As String
		  Var note As String
		  Var project As XKProject = ProjectSource.Load(errorMessage, note, False)
		  If project = Nil Then
		    Return MCPKit.ToolResult.Failure(errorMessage)
		  End If

		  Var out() As String

		  // A container first: that is the common case and the one IDE scripting cannot answer.
		  Var item As XKProjectItem = ProjectSource.FindItem(project, location)
		  If item <> Nil Then
		    out.Add(ProjectSource.QualifiedName(project, item) + "  (" + item.ItemType + ")")
		    If item.RelativePath <> "" Then out.Add("File: " + item.RelativePath)
		    out.Add("")

		    Var members As String = ProjectSource.DescribeMembers(item)
		    If members = "" Then
		      // "No members" and "the file behind it could not be read" look identical from here,
		      // and saying the first when the second is true is how an unreadable external item
		      // got mistaken for an empty one. Check the file before claiming emptiness.
		      out.Add(EmptyReason(item))
		    Else
		      out.Add(members)
		    End If

		    out.Add("")
		    out.Add(note)
		    Return MCPKit.ToolResult.Success(String.FromArray(out, EndOfLine))
		  End If

		  // Otherwise treat it as a member path, which is where overloads show up.
		  Var ownerPath As String
		  Var matches() As Variant = ProjectSource.FindMembers(project, location, ownerPath)

		  If matches.Count = 0 Then
		    If ownerPath = "" Then
		      // Say what was actually searched, and do not repeat advice that cannot apply. This
		      // message used to assert two things that were often false at once: that the item
		      // does not exist, when list_project_items shows it perfectly well, and that the
		      // project needs saving as Text or XML, on a project that already was. That sent a
		      // reader after the wrong problem for two rounds.
		      Return MCPKit.ToolResult.Failure("Not found in the project files: " + location + _
		      ". The IDE may still know it - list_project_items asks the IDE, this reads the files, " + _
		      "and the two can disagree. Most likely causes, in order: the item is EXTERNAL, and an " + _
		      "external item inside an XML project is not followed yet; folder names are not part of " + _
		      "a path, so drop them; the item exists only in the IDE and has not been saved; or the " + _
		      "path is misspelt. " + note)
		    End If

		    Var pathParts() As String = location.Split(".")
		    Var memberName As String = pathParts(pathParts.LastIndex)
		    Return MCPKit.ToolResult.Failure(ownerPath + " exists but has no member called """ + _
		    memberName + """. Call describe_item on " + ownerPath + " to see what it does contain.")
		  End If

		  If matches.Count = 1 Then
		    out.Add(location + " in " + ownerPath)
		  Else
		    out.Add(location + " is overloaded - " + matches.Count.ToString + " declarations in " + _
		    ownerPath + ". get_code returns whichever the IDE resolves the bare name to, which is " + _
		    "the first declared; the file order is below.")
		  End If
		  out.Add("")

		  Var index As Integer = 0
		  For Each member As Variant In matches
		    index = index + 1
		    If matches.Count > 1 Then out.Add("--- " + index.ToString + " of " + matches.Count.ToString)
		    out.Add(ProjectSource.MemberSignature(member))

		    If includeCode Then
		      Var code As String = ProjectSource.MemberCode(member)
		      If code.Trim = "" Then
		        out.Add("  (empty body)")
		      Else
		        out.Add(code)
		      End If
		    End If
		    out.Add("")
		  Next member

		  out.Add(note)
		  Return MCPKit.ToolResult.Success(String.FromArray(out, EndOfLine))

		End Function
	#tag EndMethod


	#tag Method, Flags = &h21
		Private Function EmptyReason(item As XKProjectItem) As String
		  /// Why an item shows no members: because it has none, or because whatever holds them
		  /// could not be read.
		  
		  If item.RelativePath = "" Then Return "This item contains no code members."
		  
		  Var lower As String = item.RelativePath.Lowercase
		  
		  If lower.EndsWith(".xojo_binary_code") Or lower.EndsWith(".xojo_binary_window") Or _
		    lower.EndsWith(".xojo_binary_menu") Then
		    Return "This item is stored in Xojo's binary format (" + item.RelativePath + "), which " + _
		    "cannot be read as text, so its members cannot be listed. In the IDE, right-click the " + _
		    "item and save it as XML or text to make it readable."
		  End If
		  
		  Var f As FolderItem
		  Try
		    f = New FolderItem(item.RelativePath, FolderItem.PathModes.Native)
		  Catch e As RuntimeException
		    f = Nil
		  End Try
		  
		  If f = Nil Or Not f.Exists Then
		    Return "The file this item points at is not there: " + item.RelativePath + ". An " + _
		    "external item lives outside the project, so it can go missing on a machine that does " + _
		    "not have it - check it out alongside the project, or re-point the reference in the IDE."
		  End If
		  
		  Return "This item contains no code members."
		  
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
