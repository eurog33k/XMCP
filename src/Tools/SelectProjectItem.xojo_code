#tag Class
Protected Class SelectProjectItem
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("select_project_item", "Selects and navigates to a specific item in the Xojo IDE Navigator, including methods, properties and event implementations. Use dot-separated paths like 'Module1.MyMethod' or 'App.Opening'. Folders are the exception: IDE scripting cannot select a folder, so this fails for one even though list_project_items can list its contents.")

		  Parameters.Add(New MCPKit.ToolParameter("item_path", MCPKit.ToolParameterTypes.String_, _
		  "Dot-separated path to the project item to select (e.g. 'App', 'Module1.MyMethod').", _
		  False, "", True))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var itemPath As String = ""
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "item_path" Then
		      itemPath = arg.Value.StringValue
		      Exit
		    End If
		  Next arg

		  If itemPath = "" Then
		    Return MCPKit.ToolResult.Failure("The item_path parameter is required.")
		  End If

		  // Assigning Location reaches methods and event implementations, which
		  // SelectProjectItem cannot; it stays as the fallback for folders and other items
		  // Location does not accept. A bad path leaves Location untouched rather than
		  // raising, so compare afterwards.
		  Var target As String = itemPath.ReplaceAll("""", """""")
		  Var script As String = "Dim target As String = """ + target + """" + EndOfLine + _
		  "Dim result As Boolean = True" + EndOfLine + _
		  "Location = target" + EndOfLine + _
		  "If Location <> target Then" + EndOfLine + _
		  "  result = SelectProjectItem(target)" + EndOfLine + _
		  "End If" + EndOfLine + _
		  "If result Then" + EndOfLine + _
		  "  Print ""Selected: "" + Location + "" ("" + TypeOfCurrentLocation + "")""" + EndOfLine + _
		  "Else" + EndOfLine + _
		  "  Print ""ERROR_UNREACHABLE""" + EndOfLine + _
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
		    Var resp As String
		    Var respVar As Variant = response.Value("response")
		    If respVar.Type = Variant.TypeString Then
		      resp = respVar.StringValue
		    Else
		      Var respJSON As JSONItem = response.Value("response")
		      resp = respJSON.ToString
		    End If

		    If resp.Trim = "ERROR_UNREACHABLE" Then
		      Return MCPKit.ToolResult.Failure(UnreachableReason(itemPath))
		    End If

		    If resp.BeginsWith("ERROR:") Then
		      Return MCPKit.ToolResult.Failure(resp)
		    End If
		    Return MCPKit.ToolResult.Success(resp)
		  End If

		  Return MCPKit.ToolResult.Failure("Unexpected response from IDE: " + response.ToString)

		End Function
	#tag EndMethod


	#tag Method, Flags = &h21
		Private Function ExistsInParent(path As String) As Boolean
		  /// Whether the item is listed among its parent's sub-locations. This is the only way to
		  /// see a folder: SubLocations lists it, while neither Location nor SelectProjectItem
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
		Private Function UnreachableReason(itemPath As String) As String
		  /// Why the item could not be selected. Two entirely different conditions used to share
		  /// one message: a folder, which nothing can select, and a member, which get_code and
		  /// set_code reach perfectly well. Telling a caller with a folder to use get_code sent
		  /// them after a workaround that does not apply.
		  
		  If ExistsInParent(itemPath) Then
		    Return itemPath + " exists but cannot be selected through IDE scripting, which is how " + _
		    "folders behave - SelectProjectItem returns False for them and Location does not accept " + _
		    "them. There is no workaround; a folder can only be selected in the IDE by hand. Its " + _
		    "contents are reachable by name, without the folder in the path."
		  End If
		  
		  Return "Could not select '" + itemPath + "'. If it is a method, property or event handler, " + _
		  "the IDE scripting API cannot select it - use get_code or set_code with the full " + _
		  "dot-separated path instead, which navigate there themselves. For window event handlers, " + _
		  "edit the .xojo_window file on disk and call revert_project. Otherwise check the path with " + _
		  "list_project_items or describe_item."
		  
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
