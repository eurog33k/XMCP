#tag Class
Protected Class DeleteProjectItem
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("delete_project_item", "Deletes a project item: a class, module, folder or other top-level item, on both macOS and Windows. Deleting a container deletes everything inside it. MEMBERS (a method, property or constant inside a class or module) are deleted through the IDE where that works (macOS) and by editing the project file where it does not (Windows) - in the latter case the deletion is already on disk when it returns, so source control is the way back, and the tool says which route it took. It refuses rather than guess if the member name is overloaded. An explicit item_path is required - this never acts on whatever happens to be selected. The change is in the IDE only until the project is saved, so revert_project undoes it up to that point; after a save it is permanent.")

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
		  Var answered As Boolean
		  If Not Reaches(itemPath, answered) Then
		    If Not answered Then
		      Return MCPKit.ToolResult.Failure("The IDE did not answer when asked whether " + itemPath + _
		      " exists, so nothing was attempted.")
		    End If

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
		    //
		    // Ask about overloads BEFORE touching anything. Both routes end up having to pick
		    // one of them, and neither has any basis for the choice.
		    Var refusal As String = OverloadRefusal(itemPath)
		    If refusal <> "" Then Return MCPKit.ToolResult.Failure(refusal)

		    #If TargetMacOS Then
		      // DeleteSelection removes the editor's member here. Everywhere else Xojo documents
		      // it as not implemented, and on Windows it is worse than a no-op: it edits the TEXT
		      // at the caret. Verified on Windows 11 with Xojo 2026r1.1 - a character vanished
		      // from the body of the focused method, the save that the file route performs next
		      // committed that to disk, and the tool still reported that nothing was deleted.
		      // Only build_project noticed. So it is sent on macOS and nowhere else.
		      If Not FocusEditorOn(itemPath) Then
		        Return MCPKit.ToolResult.Failure("Could not open " + itemPath + " in the editor, so it " + _
		        "cannot be deleted. Nothing was deleted.")
		      End If

		      Call App.IDE.SendAndReceive("DoCommand(""DeleteSelection"")", 5000)
		    #Else
		      // Nothing here can delete a member, and trying is destructive. Go straight to the
		      // file, which is the only route that works on this platform anyway.
		      Return DeleteViaFile(itemPath)
		    #EndIf
		  End If

		  // 3. Gone? DeleteSelection suppresses the output of the script that follows it, so the
		  //    first check often goes unanswered - which is not evidence either way. Ask again
		  //    until the IDE answers. Reporting an unanswered check as success is exactly the
		  //    bug this tool used to have; treating it as failure would send every macOS member
		  //    delete down the file route unnecessarily.
		  If StillPresent(itemPath) Then
		    If navigatorItem <> "" Then
		      Return MCPKit.ToolResult.Failure("The item is still present, so nothing was deleted: " + _
		      itemPath + ". Delete it in the IDE instead.")
		    End If

		    // The IDE could not remove it - DeleteSelection is not implemented on Windows - so
		    // take the route a human would: cut the member's #tag block out of the file and
		    // reload. ProjectSource.Load saves first, so the file matches the IDE before it is
		    // edited, and the reload afterwards is what stops the IDE writing the member back.
		    Return DeleteViaFile(itemPath)
		  End If

		  Return MCPKit.ToolResult.Success("Deleted: " + itemPath + ". This is not saved to disk yet - " + _
		  "revert_project restores it, save_project makes it permanent.")

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function StillPresent(itemPath As String) As Boolean
		  /// Whether the item can still be reached, asked until the IDE actually answers.
		  ///
		  /// A delete leaves the next script's output suppressed, so a single check frequently
		  /// comes back unanswered. That is not evidence of anything: treating it as gone
		  /// invents a success, and treating it as present sends a working delete down the
		  /// fallback path. So ask again, and only conclude from an answer.

		  For attempt As Integer = 1 To 4
		    Var answered As Boolean
		    Var reachable As Boolean = Reaches(itemPath, answered)
		    If answered Then Return reachable

		    Thread.SleepCurrent(400)
		  Next attempt

		  // Never answered. Assume it is still there rather than claim a deletion.
		  Return True

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function DeleteViaFile(itemPath As String) As MCPKit.ToolResult
		  /// Removes a member by editing the project file, then reloads so the IDE agrees.

		  Var loadError As String
		  Var note As String
		  Var project As XKProject = ProjectSource.Load(loadError, note)
		  If project = Nil Then
		    Return MCPKit.ToolResult.Failure("The IDE cannot delete a member on this platform, and " + _
		    "the project files could not be read to do it directly: " + loadError + " Nothing was deleted.")
		  End If

		  Var editError As String
		  If Not ProjectSource.RemoveMemberFromFile(project, itemPath, editError) Then
		    Return MCPKit.ToolResult.Failure("The IDE cannot delete a member on this platform, and " + _
		    "editing the file directly did not work: " + editError + " Nothing was deleted.")
		  End If

		  // The member is gone from disk but the IDE still holds it. Reload, or the next save
		  // writes it straight back.
		  Var reverter As New RevertProject
		  Var noArgs() As MCPKit.ToolArgument
		  Var reload As MCPKit.ToolResult = reverter.Run(noArgs)

		  If StillPresent(itemPath) Then
		    Return MCPKit.ToolResult.Failure("Removed " + itemPath + " from the project file, but the " + _
		    "IDE still has it - the reload did not take. Call revert_project, and do not call " + _
		    "save_project first or the member will be written back.")
		  End If

		  Return MCPKit.ToolResult.Success("Deleted: " + itemPath + ". The IDE cannot delete a member " + _
		  "on this platform, so its block was removed from the project file and the project reloaded. " + _
		  "This one IS on disk already, unlike a delete the IDE performs - use source control to undo it.")

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function OverloadRefusal(itemPath As String) As String
		  /// A refusal message when the member name is declared more than once, or "" to proceed.
		  ///
		  /// Read WITHOUT saving the project, deliberately. This runs before anything has been
		  /// touched and its answer is only ever used to decline, so it should not be the reason
		  /// unrelated pending edits get written to disk. If the files cannot be read at all the
		  /// answer is "proceed" - whichever route follows reports the real problem in its own
		  /// words, and this check has no business inventing one.
		  
		  Var loadError As String
		  Var note As String
		  Var project As XKProject = ProjectSource.Load(loadError, note, False)
		  If project = Nil Then Return ""
		  
		  Var countError As String
		  Var declarations As Integer = ProjectSource.CountMemberDeclarations(project, itemPath, countError)
		  If declarations <= 1 Then Return ""
		  
		  Return LastPathComponent(itemPath) + " is declared " + declarations.ToString + " times in the " + _
		  "project file, and nothing here can tell which one you mean. Nothing was deleted, and no file " + _
		  "was touched. describe_item lists the declarations with their signatures - remove the right " + _
		  "#tag block by hand and call revert_project."
		  
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
		Private Function Reaches(target As String, ByRef answered As Boolean) As Boolean
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

		  answered = False

		  Var response As JSONItem = App.IDE.SendAndReceive(script)
		  If response = Nil Or Not response.HasKey("response") Then Return False

		  Var resp As Variant = response.Value("response")
		  If resp.Type <> Variant.TypeString Then Return False

		  // Only now is the answer trustworthy. Before this flag existed, an IDE that did not
		  // reply was indistinguishable from an item that was gone - and since DeleteSelection
		  // suppresses the output of the script that follows it, that is exactly what happened
		  // after a delete: the check went unanswered and the tool reported a success it had
		  // not achieved.
		  answered = True

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
