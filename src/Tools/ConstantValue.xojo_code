#tag Class
Protected Class ConstantValue
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("constant_value", "Gets or sets the value of a project constant in the Xojo IDE. The constant must already exist - IDE scripting cannot create a properly named, typed constant. Qualify the name with its owner (e.g. 'App.kVersion'): an unqualified name is only resolved against whatever item happens to be selected in the Navigator. A name the IDE cannot resolve is reported as an error naming the likely cause, and a write is confirmed by reading the value back - the IDE prints OK for an assignment to a name that does not exist, so its OK is not evidence.")

		  Parameters.Add(New MCPKit.ToolParameter("name", MCPKit.ToolParameterTypes.String_, _
		  "The constant name, qualified with its owner: 'App.kVersion', 'Module1.ISNVSYNC'. A bare name like 'kVersion' resolves only against the currently selected project item, so it usually returns nothing - qualify it. Folder names are not part of the path.", _
		  False, "", False))

		  Parameters.Add(New MCPKit.ToolParameter("value", MCPKit.ToolParameterTypes.String_, _
		  "If provided, sets the constant to this value. If omitted, returns the current value.", _
		  True, "", False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var name As String = ""
		  Var value As String = ""
		  Var hasValue As Boolean = False

		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "name" Then
		      name = arg.Value.StringValue
		    ElseIf arg.Name = "value" Then
		      value = arg.Value.StringValue
		      hasValue = True
		    End If
		  Next arg

		  If name = "" Then
		    Return MCPKit.ToolResult.Failure("Parameter 'name' is required.")
		  End If

		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If

		  // The IDE answers a name it cannot resolve with no value at all, which arrived here as
		  // the literal "{}" and was returned as a success - so an unqualified name and a constant
		  // that does not exist both looked like they had worked. Worse on the write path: an
		  // assignment to a name that does not exist still prints OK, so setting
		  // NoSuchOwner.NoSuchConstant reported success and created nothing. Both are checked now.
		  
		  If hasValue Then
		    // Resolve before writing, so a bad name is refused rather than silently accepted.
		    Var existed As Boolean
		    Call ReadConstant(name, existed)
		    
		    If Not existed Then
		      Return MCPKit.ToolResult.Failure(Unresolved(name) + " Nothing was set - IDE scripting " + _
		      "cannot create a constant, so the name has to exist first.")
		    End If
		    
		    Var setScript As String = "ConstantValue(""" + name.ReplaceAll("""", """""") + """) = """ + _
		    value.ReplaceAll("""", """""") + """" + EndOfLine + "Print ""OK"""
		    
		    Var setResponse As JSONItem = App.IDE.SendAndReceive(setScript)
		    If setResponse = Nil Then
		      If App.IDE.LastErrorMessage <> "" Then Return MCPKit.ToolResult.Failure(App.IDE.LastErrorMessage)
		      Return MCPKit.ToolResult.Failure("Timeout waiting for IDE response.")
		    End If
		    
		    // Read it back rather than trusting the script's OK, which it prints either way.
		    Var confirmed As Boolean
		    Var stored As String = ReadConstant(name, confirmed)
		    
		    If Not confirmed Then
		      Return MCPKit.ToolResult.Failure("Set " + name + ", but reading it back returns nothing, " + _
		      "so the value did not take. Check the name and the constant's scope.")
		    End If
		    
		    If stored.Trim <> value.Trim Then
		      Return MCPKit.ToolResult.Failure("Asked to set " + name + " to """ + value + """, but the " + _
		      "IDE now reports """ + stored + """. A typed constant may have converted the value; " + _
		      "anything else means the assignment did not take.")
		    End If
		    
		    Return MCPKit.ToolResult.Success(name + " = " + stored)
		  End If
		  
		  Var found As Boolean
		  Var current As String = ReadConstant(name, found)
		  
		  If Not found Then Return MCPKit.ToolResult.Failure(Unresolved(name))
		  
		  Return MCPKit.ToolResult.Success(current)
		  
		End Function
	#tag EndMethod


	#tag Method, Flags = &h21
		Private Function ReadConstant(name As String, ByRef found As Boolean) As String
		  /// The constant's value, with `found` False when the IDE resolved nothing.
		  ///
		  /// The distinction matters and is available: a name the IDE cannot resolve comes back
		  /// with no response VALUE, while a constant that genuinely holds an empty string comes
		  /// back as an empty string. Treating both as success is what made an unresolvable name
		  /// look like a successful read.
		  
		  found = False
		  
		  Var script As String = "Print ConstantValue(""" + name.ReplaceAll("""", """""") + """)"
		  Var response As JSONItem = App.IDE.SendAndReceive(script)
		  If response = Nil Or Not response.HasKey("response") Then Return ""
		  
		  Var respVar As Variant = response.Value("response")
		  If respVar.Type <> Variant.TypeString Then Return ""
		  
		  Var text As String = respVar.StringValue
		  If text.BeginsWith("ERROR:") Then Return ""
		  
		  found = True
		  Return text
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Unresolved(name As String) As String
		  /// Why a constant name came back with nothing.
		  
		  Var qualified As Boolean = (name.IndexOf(".") >= 0)
		  
		  Var text As String = "The IDE resolved nothing for the constant """ + name + """. "
		  
		  If Not qualified Then
		    text = text + "The name is unqualified, which is the usual cause: an unqualified name is " + _
		    "matched only against whatever item is selected in the Navigator. Qualify it with its " + _
		    "owner - ""App." + name + """ or ""Module1." + name + """."
		  Else
		    text = text + "The owner or the constant does not exist under that path, or the constant " + _
		    "is out of scope from there. describe_item on the owner lists its constants with their " + _
		    "values. Folder names are not part of the path."
		  End If
		  
		  Return text
		  
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
