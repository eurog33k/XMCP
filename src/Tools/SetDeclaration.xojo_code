#tag Class
Protected Class SetDeclaration
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("set_declaration", "Sets the declaration of a method or property: its name, parameters, return type, scope, and what it implements. create_project_item creates an unnamed item - a new method arrives as 'Untitled' with no signature - so this is the second half of creating a usable method: create_project_item, set_declaration, then set_code for the body. It also renames existing methods and properties. For a property, pass its default value in 'parameters'.")

		  Parameters.Add(New MCPKit.ToolParameter("name", MCPKit.ToolParameterTypes.String_, _
		  "The new name for the method or property, without parameters or return type.", _
		  False, "", True))

		  Parameters.Add(New MCPKit.ToolParameter("location", MCPKit.ToolParameterTypes.String_, _
		  "Optional dot-separated path to navigate to first (e.g. 'Module1.Untitled'). If empty, the currently selected item is used.", _
		  True, "", False))

		  Parameters.Add(New MCPKit.ToolParameter("parameters", MCPKit.ToolParameterTypes.String_, _
		  "Parameter list as written in Xojo, without brackets (e.g. 'fi As FolderItem, count As Integer'). For a property this is its default value instead. Empty for no parameters.", _
		  True, "", False))

		  Parameters.Add(New MCPKit.ToolParameter("return_type", MCPKit.ToolParameterTypes.String_, _
		  "Return type (e.g. 'String'). Empty for a subroutine or a property.", _
		  True, "", False))

		  Parameters.Add(New MCPKit.ToolParameter("scope", MCPKit.ToolParameterTypes.Integer_, _
		  "0 = Public, 1 = Protected, 2 = Private. Default is 0.", _
		  True, 0, False))

		  Parameters.Add(New MCPKit.ToolParameter("implements", MCPKit.ToolParameterTypes.String_, _
		  "The interface method this implements (e.g. 'Readable.Read'). Empty for an ordinary method.", _
		  True, "", False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var name As String = ""
		  Var location As String = ""
		  Var parameters As String = ""
		  Var returnType As String = ""
		  Var implementsName As String = ""
		  Var scope As Integer = 0

		  For Each arg As MCPKit.ToolArgument In args
		    Select Case arg.Name
		    Case "name"
		      name = arg.Value.StringValue
		    Case "location"
		      location = arg.Value.StringValue
		    Case "parameters"
		      parameters = arg.Value.StringValue
		    Case "return_type"
		      returnType = arg.Value.StringValue
		    Case "implements"
		      implementsName = arg.Value.StringValue
		    Case "scope"
		      scope = arg.Value.IntegerValue
		    End Select
		  Next arg

		  name = name.Trim
		  If name = "" Then
		    Return MCPKit.ToolResult.Failure("The name parameter is required.")
		  End If

		  If scope < 0 Or scope > 2 Then
		    Return MCPKit.ToolResult.Failure("Invalid scope " + scope.ToString + ". Use 0 for Public, " + _
		    "1 for Protected or 2 for Private.")
		  End If

		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If

		  // 1. Navigate if asked, then find out where we actually are. The container is needed
		  //    to predict the resulting path, which is how the change gets verified.
		  If location.Trim <> "" Then
		    If Not Navigate(location.Trim) Then
		      Return MCPKit.ToolResult.Failure("Could not navigate to: " + location.Trim + _
		      ". For window event handlers, edit the .xojo_window file directly on disk.")
		    End If
		  End If

		  Var current As String = CurrentLocation
		  If current = "" Then
		    Return MCPKit.ToolResult.Failure("No project item is selected. Pass a location, or " + _
		    "navigate with select_project_item first.")
		  End If

		  // Everything up to the last dot is the container: "Module1.Untitled" -> "Module1".
		  // String has no LastIndexOf in this Xojo version, hence the split.
		  Var parts() As String = current.Split(".")
		  If parts.Count > 1 Then parts.RemoveAt(parts.LastIndex)  Else parts.RemoveAll

		  Var expected As String = name
		  If parts.Count > 0 Then expected = String.FromArray(parts, ".") + "." + name

		  // 2. Change the declaration. ChangeDeclaration ends script execution where it stands,
		  //    so nothing may follow it in this script - a trailing Print would never run, and
		  //    the IDE would answer with nothing. Step 3 is the verification instead.
		  Var script As String = "ChangeDeclaration(""" + Escape(name) + """, """ + _
		  Escape(parameters) + """, """ + Escape(returnType) + """, " + scope.ToString + ", """ + _
		  Escape(implementsName) + """)"

		  Call App.IDE.SendAndReceive(script, 20000)

		  // 3. Did it take? The declaration change renames the item, so the location moves.
		  Var after As String = CurrentLocation
		  If after <> expected Then
		    Return MCPKit.ToolResult.Failure("The declaration was not changed - the item is still at " + _
		    If(after = "", "an unknown location", after) + " rather than " + expected + ". Check that " + _
		    "the selected item is a method or property, and that the parameter list and return type " + _
		    "are valid Xojo.")
		  End If

		  Var summary As String = "Declaration set: " + after
		  If parameters <> "" Then summary = summary + "(" + parameters + ")"
		  If returnType <> "" Then summary = summary + " As " + returnType
		  Return MCPKit.ToolResult.Success(summary)

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function CurrentLocation() As String
		  /// The IDE's current location, or "" if it could not be read.

		  Var response As JSONItem = App.IDE.SendAndReceive("Print Location")
		  If response = Nil Or Not response.HasKey("response") Then Return ""

		  Var resp As Variant = response.Value("response")
		  If resp.Type <> Variant.TypeString Then Return ""

		  Return resp.StringValue.Trim

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Escape(value As String) As String
		  Return value.ReplaceAll("""", """""")

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Navigate(target As String) As Boolean
		  /// Assigning Location reaches methods, properties and event implementations;
		  /// SelectProjectItem only reaches top-level items and is the fallback. A bad path
		  /// leaves Location untouched rather than raising, so it is compared afterwards.

		  Var escaped As String = Escape(target)
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
