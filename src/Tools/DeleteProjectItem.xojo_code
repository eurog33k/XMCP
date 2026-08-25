#tag Class
Protected Class DeleteProjectItem
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("delete_project_item", "Deletes a project item: a class, module, folder or other top-level item, on both macOS and Windows. Deleting a container deletes everything inside it. MEMBERS (a method, property or constant inside a class or module) can only be deleted this way on macOS; on Windows the tool refuses and tells you to remove the item from the .xojo_code file on disk and call revert_project. An explicit item_path is required - this never acts on whatever happens to be selected. The change is in the IDE only until the project is saved, so revert_project undoes it up to that point; after a save it is permanent.")

		  Parameters.Add(New MCPKit.ToolParameter("item_path", MCPKit.ToolParameterTypes.String_, _
		  "Dot-separated path of the item to delete (e.g. 'Module1.Untitled', 'MyClass').", _
		  False, "", True))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var itemPath As String = ""
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "item_path" Then itemPath = arg.Value.StringValue.Trim
		  Next arg

		  If itemPath = "" Then
		    Return MCPKit.ToolResult.Failure("The item_path parameter is required. delete_project_item " + _
		    "deliberately does not act on the current selection.")
		  End If

		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If

		  // 1. The item has to exist, or there is nothing to confirm afterwards. A folder is
		  //    reachable by neither mechanism - SelectProjectItem returns False for folders and
		  //    Location does not accept them - so distinguish "is a folder" from "does not
		  //    exist" before blaming the caller for a bad path.
		  If Not Reaches(itemPath) Then
		    If ExistsInParent(itemPath) Then
		      Return MCPKit.ToolResult.Failure(itemPath + " exists but cannot be selected through " + _
		      "IDE scripting, which is how folders behave - SelectProjectItem returns False for " + _
		      "them. Nothing was deleted; delete it in the IDE instead.")
		    End If

		    Return MCPKit.ToolResult.Failure("No such project item: " + itemPath + ". Nothing was deleted.")
		  End If

		  // 2. Which of the two mechanisms applies? DoCommand("Delete") acts on the NAVIGATOR
		  //    selection, and only SelectProjectItem moves that - assigning Location moves the
		  //    editor, which is a separate thing. For a member path SelectProjectItem returns
		  //    False and the Navigator stays on the parent, so firing Delete there would delete
		  //    the parent module or class. That is why the two cases are kept strictly apart.
		  Var navigatorItem As String = SelectInNavigator(itemPath)

		  If navigatorItem <> "" Then
		    // A project item. Guard: the Navigator must be sitting on this exact item.
		    Var expected As String = LastPathComponent(itemPath)
		    If navigatorItem <> expected Then
		      Return MCPKit.ToolResult.Failure("Refusing to delete: the IDE reports """ + navigatorItem + _
		      """ selected in the Navigator, not """ + expected + """. Nothing was deleted.")
		    End If

		    // DoCommand("Delete") answers nothing, so step 3 decides. Note it is undocumented -
		    // the manual lists only "DeleteSelection: Not implemented" - but it works on both
		    // macOS and Windows, verified on 2025r3.1 and 2026r1.1.
		    Call App.IDE.SendAndReceive("DoCommand(""Delete"")", 5000)
		  Else
		    // A member: a method, property, constant or event inside a class or module.
		    // SelectProjectItem cannot reach it, so Delete is not an option at any price.
		    // DeleteSelection works on the editor's item, but only on macOS - Xojo documents
		    // it as not implemented and on Windows it does nothing.
		    If Not FocusEditorOn(itemPath) Then
		      Return MCPKit.ToolResult.Failure("Could not open " + itemPath + " in the editor, so it " + _
		      "cannot be deleted. Nothing was deleted.")
		    End If

		    Call App.IDE.SendAndReceive("DoCommand(""DeleteSelection"")", 5000)
		  End If

		  // 3. Gone?
		  If Reaches(itemPath) Then
		    If navigatorItem <> "" Then
		      Return MCPKit.ToolResult.Failure("The item is still present, so nothing was deleted: " + _
		      itemPath + ". Delete it in the IDE instead.")
		    End If

		    Return MCPKit.ToolResult.Failure("Members cannot be deleted through IDE scripting on this " + _
		    "platform, and " + itemPath + " is still present. Nothing was deleted. Remove it on disk " + _
		    "instead: delete its #tag Method (or #tag Property) block from the containing .xojo_code " + _
		    "file, then call revert_project. Do not call save_project first, or the IDE will write its " + _
		    "own copy back over the edit.")
		  End If

		  Return MCPKit.ToolResult.Success("Deleted: " + itemPath + ". This is not saved to disk yet - " + _
		  "revert_project restores it, save_project makes it permanent.")

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ExistsInParent(path As String) As Boolean
		  /// Whether the item is listed among its parent's sub-locations. This is the only way
		  /// to see a folder: SubLocations lists it, while neither Location nor SelectProjectItem
		  /// can select it.

		  Var parts() As String = path.Split(".")
		  If parts.Count = 0 Then Return False

		  Var name As String = parts(parts.LastIndex)
		  parts.RemoveAt(parts.LastIndex)
		  Var parent As String = String.FromArray(parts, ".")

		  Var script As String = "Print SubLocations(""" + parent.ReplaceAll("""", """""") + """)"
		  Var response As JSONItem = App.IDE.SendAndReceive(script)
		  If response = Nil Or Not response.HasKey("response") Then Return False

		  Var resp As Variant = response.Value("response")
		  If resp.Type <> Variant.TypeString Then Return False

		  For Each item As String In resp.StringValue.Split(Chr(9))
		    If item.Trim = name Then Return True
		  Next item

		  Return False

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FocusEditorOn(target As String) As Boolean
		  /// Points the code editor at a member and confirms it landed. Assigning Location moves
		  /// the editor only - the Navigator selection does not follow.

		  Var escaped As String = target.ReplaceAll("""", """""")
		  Var script As String = "Location = """ + escaped + """" + EndOfLine + "Print Location"

		  Var response As JSONItem = App.IDE.SendAndReceive(script)
		  If response = Nil Or Not response.HasKey("response") Then Return False

		  Var resp As Variant = response.Value("response")
		  If resp.Type <> Variant.TypeString Then Return False

		  Return resp.StringValue.Trim = target

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function LastPathComponent(path As String) As String
		  Var parts() As String = path.Split(".")
		  If parts.Count = 0 Then Return path
		  Return parts(parts.LastIndex)

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SelectInNavigator(target As String) As String
		  /// Selects a project item in the Navigator and returns what the IDE says is now
		  /// selected, or "" if SelectProjectItem could not reach it - which is the case for
		  /// every member path.
		  ///
		  /// The returned name is what DoCommand("Delete") will act on, so callers compare it
		  /// with the item they meant before firing anything.

		  Var escaped As String = target.ReplaceAll("""", """""")
		  Var script As String = "Dim s As String = """"" + EndOfLine + _
		  "If SelectProjectItem(""" + escaped + """) Then" + EndOfLine + _
		  "  s = ProjectItem" + EndOfLine + _
		  "End If" + EndOfLine + _
		  "Print s"

		  Var response As JSONItem = App.IDE.SendAndReceive(script)
		  If response = Nil Or Not response.HasKey("response") Then Return ""

		  Var resp As Variant = response.Value("response")
		  If resp.Type <> Variant.TypeString Then Return ""

		  Return resp.StringValue.Trim

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Reaches(target As String) As Boolean
		  /// Whether the IDE can navigate to this path, which is how existence is tested both
		  /// before and after the delete. Assigning Location reaches methods and properties;
		  /// SelectProjectItem is the fallback for folders. A bad path leaves Location alone,
		  /// so it is compared afterwards.

		  Var escaped As String = target.ReplaceAll("""", """""")
		  Var script As String = "Dim target As String = """ + escaped + """" + EndOfLine + _
		  "Dim ok As Boolean = True" + EndOfLine + _
		  "Location = target" + EndOfLine + _
		  "If Location <> target Then" + EndOfLine + _
		  "  ok = SelectProjectItem(target)" + EndOfLine + _
		  "End If" + EndOfLine + _
		  "If ok Then" + EndOfLine + _
		  "  Print ""ok""" + EndOfLine + _
		  "Else" + EndOfLine + _
		  "  Print ""no""" + EndOfLine + _
		  "End If"

		  Var response As JSONItem = App.IDE.SendAndReceive(script)
		  If response = Nil Or Not response.HasKey("response") Then Return False

		  Var resp As Variant = response.Value("response")
		  If resp.Type <> Variant.TypeString Then Return False

		  Return resp.StringValue.Trim = "ok"

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
