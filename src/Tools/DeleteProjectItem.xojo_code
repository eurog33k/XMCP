#tag Class
Protected Class DeleteProjectItem
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("delete_project_item", "Deletes a project item - a method, property, constant, class, module or folder. WORKS ON macOS ONLY: the underlying IDE scripting command is not implemented on Windows, where this tool reports failure and changes nothing, so ask the user to delete the item in the IDE instead. An explicit item_path is required; this never acts on whatever happens to be selected. Deleting a class, module or folder deletes everything inside it. The change is in the IDE only until the project is saved, so revert_project undoes it up to that point; after a save it is permanent.")

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

		  // 1. The item has to exist, or there is nothing to confirm afterwards.
		  If Not Reaches(itemPath) Then
		    Return MCPKit.ToolResult.Failure("No such project item: " + itemPath + ". Nothing was deleted.")
		  End If

		  // 2. Delete the selection. DoCommand "DeleteSelection" does not answer - deleting the
		  //    item takes the script host with it - so the reply is not waited on for long and
		  //    step 3 is what decides.
		  //
		  //    Xojo documents this command as "Not implemented", and on Windows that is exactly
		  //    what it is: it does nothing (verified on 2026r1.1). On macOS it does delete, and
		  //    deletes precisely the named item - verified with a module holding two methods and
		  //    a sibling class, where only the named method disappeared. It is still fired on
		  //    every platform rather than refused up front, so that the tool starts working by
		  //    itself if a future Xojo implements it; step 3 guarantees no false success.
		  Call App.IDE.SendAndReceive("DoCommand ""DeleteSelection""", 5000)

		  // 3. Gone?
		  If Reaches(itemPath) Then
		    Return MCPKit.ToolResult.Failure("The item is still present, so nothing was deleted: " + _
		    itemPath + ". The IDE scripting command that removes a project item is documented as " + _
		    "not implemented, and on Windows it really does nothing - this tool only works on " + _
		    "macOS. Ask the user to delete the item in the IDE instead.")
		  End If

		  Return MCPKit.ToolResult.Success("Deleted: " + itemPath + ". This is not saved to disk yet - " + _
		  "revert_project restores it, save_project makes it permanent.")

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
