#tag Class
Protected Class XKJSONVisitor
Implements XKVisitor
	#tag Method, Flags = &h0, Description = 437265617465732061206E6577204A534F4E2076697369746F722E
		Sub Constructor()
		  /// Creates a new JSON visitor.
		  
		  mNodeStack.Add(New Dictionary)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1, Description = 45736361706573207370656369616C206368617261637465727320666F72204A534F4E2E
		Protected Function EscapeJSON(s As String) As String
		  /// Escapes special characters for JSON.
		  
		  s = s.ReplaceAll("\", "\\")
		  s = s.ReplaceAll("""", "\""")
		  s = s.ReplaceAll(Chr(10), "\n")
		  s = s.ReplaceAll(Chr(13), "\r")
		  s = s.ReplaceAll(Chr(9), "\t")
		  
		  Return s
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1, Description = 47656E657261746573204A534F4E20666F72206120737472696E672061727261792073746F72656420696E20612056617269616E742E
		Protected Function GenerateArrayJSON(arr As Variant, indent As Integer) As String
		  /// Generates JSON for a string array stored in a Variant.
		  
		  #Pragma Unused indent
		  
		  // Convert the Variant to a String array.
		  Var stringArr() As String = arr
		  
		  If stringArr.Count = 0 Then
		    Return "[]"
		  End If
		  
		  Var items() As String
		  For Each s As String In stringArr
		    items.Add(Quote(EscapeJSON(s)))
		  Next s
		  
		  Return "[" + String.FromArray(items, ", ") + "]"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1, Description = 47656E657261746573204A534F4E20666F7220746865206368696C6472656E2064696374696F6E6172792E
		Protected Function GenerateChildrenJSON(children As Dictionary, indent As Integer) As String
		  /// Generates JSON for the children dictionary.
		  
		  Var prefix As String = ""
		  For i As Integer = 1 To indent
		    prefix = prefix + "  "
		  Next i
		  
		  If children.KeyCount = 0 Then
		    Return "{}"
		  End If
		  
		  Var lines() As String
		  lines.Add("{")
		  
		  Var keys() As Variant
		  For Each entry As DictionaryEntry In children
		    keys.Add(entry.Key)
		  Next entry
		  
		  For i As Integer = 0 To keys.LastIndex
		    Var key As String = keys(i).StringValue
		    Var childDict As Dictionary = children.Value(key)
		    Var childJSON As String = GenerateJSON(childDict, indent + 1).Trim
		    Var line As String = prefix + "  " + Quote(key) + ": " + childJSON
		    
		    If i < keys.LastIndex Then
		      line = line + ","
		    End If
		    
		    lines.Add(line)
		  Next i
		  
		  lines.Add(prefix + "}")
		  
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1, Description = 47656E6572617465732061204A534F4E20737472696E672066726F6D20612064696374696F6E6172792E
		Protected Function GenerateJSON(d As Dictionary, indent As Integer = 0) As String
		  /// Generates a JSON string from a dictionary.
		  
		  Var lines() As String
		  Var prefix As String = ""
		  For i As Integer = 1 To indent
		    prefix = prefix + "  "
		  Next i
		  
		  lines.Add(prefix + "{")
		  
		  Var keys() As Variant
		  For Each entry As DictionaryEntry In d
		    keys.Add(entry.Key)
		  Next entry
		  
		  For i As Integer = 0 To keys.LastIndex
		    Var key As String = keys(i).StringValue
		    Var value As Variant = d.Value(key)
		    Var line As String = prefix + "  " + Quote(key) + ": "
		    
		    If value IsA Dictionary Then
		      Var childDict As Dictionary = Dictionary(value)
		      If key = "children" Then
		        // Children is a dictionary of child nodes.
		        line = line + GenerateChildrenJSON(childDict, indent + 1)
		      Else
		        line = line + GenerateJSON(childDict, indent + 1).Trim
		      End If
		    ElseIf value.IsArray Then
		      line = line + GenerateArrayJSON(value, indent + 1)
		    ElseIf value.Type = Variant.TypeBoolean Then
		      If value.BooleanValue Then
		        line = line + "true"
		      Else
		        line = line + "false"
		      End If
		    ElseIf value.Type = Variant.TypeInt32 Or value.Type = Variant.TypeInt64 Then
		      line = line + value.StringValue
		    Else
		      line = line + Quote(EscapeJSON(value.StringValue))
		    End If
		    
		    If i < keys.LastIndex Then
		      line = line + ","
		    End If
		    
		    lines.Add(line)
		  Next i
		  
		  lines.Add(prefix + "}")
		  
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1, Description = 506F7073207468652063757272656E74206E6F64652066726F6D2074686520737461636B20616E642072656D6F76657320746865206C617374207061746820636F6D706F6E656E742E
		Protected Sub PopNode()
		  /// Pops the current node from the stack and removes the last path component.
		  
		  If mNodeStack.Count > 1 Then
		    mNodeStack.RemoveAt(mNodeStack.LastIndex)
		  End If
		  
		  If mPathComponents.Count > 1 Then
		    mPathComponents.RemoveAt(mPathComponents.LastIndex)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1, Description = 5075736865732061206E6577206E6F64652064696374696F6E617279206F6E746F2074686520737461636B20616E64206164647320697420746F2074686520706172656E742773206368696C6472656E2E
		Protected Sub PushNode(d As Dictionary)
		  /// Pushes a new node dictionary onto the stack and adds it to the parent's children.
		  
		  If mNodeStack.Count > 0 Then
		    Var parent As Dictionary = mNodeStack(mNodeStack.LastIndex)
		    If Not parent.HasKey("children") Then
		      parent.Value("children") = New Dictionary()
		    End If
		    Var children As Dictionary = parent.Value("children")
		    children.Value(d.Value("id").StringValue) = d
		  End If
		  
		  mNodeStack.Add(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1, Description = 5772617073206120737472696E6720696E20646F75626C652071756F7465732E
		Protected Function Quote(s As String) As String
		  /// Wraps a string in double quotes.
		  
		  Return """" + s + """"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E732074686520616363756D756C61746564204A534F4E206173206120737472696E672E
		Function ToJSON() As String
		  /// Returns the accumulated JSON as a string.
		  
		  If mNodeStack.Count > 0 Then
		    Return GenerateJSON(mNodeStack(0))
		  Else
		    Return "{}"
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 56697369747320612070726F6A65637420616E6420616C6C20697473206368696C6472656E2E
		Sub Visit(project As XKProject)
		  /// Visits a project and all its children.
		  
		  project.Accept(Self)
		  
		  // Visit all children.
		  For Each child As XKNode In project.Children
		    VisitNode(child)
		  Next child
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 5669736974732061206275696C642073746570206E6F64652E
		Sub VisitBuildStep(node As XKBuildStep)
		  /// Visits a build step node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "BuildStep"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":BuildStep"
		  d.Value("name") = node.Name
		  
		  If node.StepType <> "" Then
		    d.Value("stepType") = node.StepType
		  End If
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 5669736974732061206275696C642073746570206C697374206E6F64652E
		Sub VisitBuildStepList(node As XKBuildStepList)
		  /// Visits a build step list node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "BuildStepList"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":BuildStepList"
		  d.Value("name") = node.Name
		  d.Value("platform") = node.PlatformName
		  d.Value("stepCount") = node.Steps.Count
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 566973697473206120636C617373206E6F64652E
		Sub VisitClass(node As XKClass)
		  /// Visits a class node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Class"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":Class"
		  d.Value("name") = node.Name
		  d.Value("access") = node.AccessModifierName
		  
		  If node.SuperClassName <> "" Then
		    d.Value("superclass") = node.SuperClassName
		  End If
		  
		  If node.Interfaces.Count > 0 Then
		    d.Value("interfaces") = node.Interfaces
		  End If
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 566973697473206120636F6D70757465642070726F7065727479206E6F64652E
		Sub VisitComputedProperty(node As XKComputedProperty)
		  /// Visits a computed property node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "ComputedProperty"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":ComputedProperty"
		  d.Value("name") = node.Name
		  d.Value("access") = node.AccessModifierName
		  d.Value("dataType") = node.DataType
		  d.Value("hasGetter") = node.HasGetter
		  d.Value("hasSetter") = node.HasSetter
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 566973697473206120636F6E7374616E74206E6F64652E
		Sub VisitConstant(node As XKConstant)
		  /// Visits a constant node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Constant"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":Constant"
		  d.Value("name") = node.Name
		  d.Value("dataType") = node.DataType
		  d.Value("isDynamic") = node.IsDynamic
		  
		  If node.Scope <> "" Then
		    d.Value("scope") = node.Scope
		  End If
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 566973697473206120636F6E7374616E7420696E7374616E6365206E6F64652E
		Sub VisitConstantInstance(node As XKConstantInstance)
		  /// Visits a constant instance node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "ConstantInstance"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":ConstantInstance"
		  d.Value("name") = node.Name
		  
		  If node.Platform <> "" Then
		    d.Value("platform") = node.Platform
		  End If
		  
		  If node.Language <> "" Then
		    d.Value("language") = node.Language
		  End If
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 566973697473206120636F6E74726F6C206E6F64652E
		Sub VisitControl(node As XKControl)
		  /// Visits a control node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Control"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":Control"
		  d.Value("name") = node.Name
		  d.Value("controlType") = node.ControlType
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 566973697473206120636F6E74726F6C206576656E742067726F7570206E6F64652E
		Sub VisitControlEventGroup(node As XKControlEventGroup)
		  /// Visits a control event group node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "ControlEventGroup"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":ControlEventGroup"
		  d.Value("name") = node.Name
		  d.Value("controlName") = node.ControlName
		  d.Value("eventCount") = node.Events.Count
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 56697369747320616E20656E756D206E6F64652E
		Sub VisitEnum(node As XKEnum)
		  /// Visits an enum node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Enum"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":Enum"
		  d.Value("name") = node.Name
		  d.Value("dataType") = node.DataType
		  d.Value("valueCount") = node.Values.Count
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 56697369747320616E20656E756D2076616C7565206E6F64652E
		Sub VisitEnumValue(node As XKEnumValue)
		  /// Visits an enum value node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "EnumValue"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":EnumValue"
		  d.Value("name") = node.Name
		  d.Value("value") = node.Value
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 56697369747320616E206576656E74206E6F64652E
		Sub VisitEvent(node As XKEvent)
		  /// Visits an event node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Event"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":Event"
		  d.Value("name") = node.Name
		  d.Value("isFunction") = node.IsFunction
		  
		  If node.ReturnType <> "" Then
		    d.Value("returnType") = node.ReturnType
		  End If
		  
		  If node.ControlName <> "" Then
		    d.Value("controlName") = node.ControlName
		  End If
		  
		  // Include parameter signatures (without defaults).
		  If node.Parameters.Count > 0 Then
		    Var params() As String
		    For Each p As XKParameter In node.Parameters
		      Var paramName As String = p.Name
		      If p.IsArray Then
		        paramName = paramName + "()"
		      End If
		      Var sig As String = paramName + " As " + p.DataType
		      If p.IsByRef Then
		        sig = "ByRef " + sig
		      End If
		      params.Add(sig)
		    Next p
		    d.Value("parameters") = params
		  End If
		  
		  d.Value("lineCount") = node.CodeLines.Count
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 56697369747320612066696C652074797065206E6F64652E
		Sub VisitFileType(node As XKFileType)
		  /// Visits a file type node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "FileType"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":FileType"
		  d.Value("name") = node.Name
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 56697369747320612066696C65207479706520736574206E6F64652E
		Sub VisitFileTypeSet(node As XKFileTypeSet)
		  /// Visits a file type set node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "FileTypeSet"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":FileTypeSet"
		  d.Value("name") = node.Name
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 566973697473206120666F6C646572206E6F64652E
		Sub VisitFolder(node As XKFolder)
		  /// Visits a folder node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Folder"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":Folder"
		  d.Value("name") = node.Name
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 56697369747320616E20696D61676520726570726573656E746174696F6E206E6F64652E
		Sub VisitImageRepresentation(node As XKImageRepresentation)
		  /// Visits an image representation node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "ImageRepresentation"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":ImageRepresentation"
		  d.Value("name") = node.Name
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 56697369747320616E20696E74657266616365206E6F64652E
		Sub VisitInterface(node As XKInterface)
		  /// Visits an interface node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Interface"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":Interface"
		  d.Value("name") = node.Name
		  d.Value("access") = node.AccessModifierName
		  
		  If node.Interfaces.Count > 0 Then
		    d.Value("extends") = node.Interfaces
		  End If
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 5669736974732061206D656E7520626172206E6F64652E
		Sub VisitMenuBar(node As XKMenuBar)
		  /// Visits a menu bar node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "MenuBar"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":MenuBar"
		  d.Value("name") = node.Name
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 5669736974732061206D656E75206974656D206E6F64652E
		Sub VisitMenuItem(node As XKMenuItem)
		  /// Visits a menu item node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "MenuItem"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":MenuItem"
		  d.Value("name") = node.Name
		  
		  If node.Text <> "" Then
		    d.Value("text") = node.Text
		  End If
		  
		  If node.MenuItemType <> "" Then
		    d.Value("menuItemType") = node.MenuItemType
		  End If
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 5669736974732061206D6574686F64206E6F64652E
		Sub VisitMethod(node As XKMethod)
		  /// Visits a method node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Method"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":Method"
		  d.Value("name") = node.Name
		  d.Value("access") = node.AccessModifierName
		  d.Value("isFunction") = node.IsFunction
		  d.Value("isShared") = node.IsShared
		  
		  If node.ReturnType <> "" Then
		    d.Value("returnType") = node.ReturnType
		  End If
		  
		  // Include parameter signatures (without defaults).
		  If node.Parameters.Count > 0 Then
		    Var params() As String
		    For Each p As XKParameter In node.Parameters
		      Var paramName As String = p.Name
		      If p.IsArray Then
		        paramName = paramName + "()"
		      End If
		      Var sig As String = paramName + " As " + p.DataType
		      If p.IsByRef Then
		        sig = "ByRef " + sig
		      End If
		      If p.IsOptional Then
		        sig = "Optional " + sig
		      End If
		      If p.IsParamArray Then
		        sig = "ParamArray " + sig
		      End If
		      params.Add(sig)
		    Next p
		    d.Value("parameters") = params
		  End If
		  
		  d.Value("lineCount") = node.CodeLines.Count
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 5669736974732061206D6F64756C65206E6F64652E
		Sub VisitModule(node As XKModule)
		  /// Visits a module node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Module"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":Module"
		  d.Value("name") = node.Name
		  d.Value("access") = node.AccessModifierName
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 5669736974732061206D756C74692D696D616765206E6F64652E
		Sub VisitMultiImage(node As XKMultiImage)
		  /// Visits a multi-image node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "MultiImage"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":MultiImage"
		  d.Value("name") = node.Name
		  d.Value("representationCount") = node.Representations.Count
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1, Description = 5265637572736976656C79207669736974732061206E6F646520616E6420697473206368696C6472656E2E
		Protected Sub VisitNode(node As XKNode)
		  /// Recursively visits a node and its children.
		  
		  node.Accept(Self)
		  
		  // Visit all children.
		  For Each child As XKNode In node.Children
		    VisitNode(child)
		  Next child
		  
		  // Pop back to parent after visiting children.
		  PopNode()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 5669736974732061206E6F7465206E6F64652E
		Sub VisitNote(node As XKNote)
		  /// Visits a note node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Note"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":Note"
		  d.Value("name") = node.Name
		  // Note: Content is excluded for LLM summary (can be requested by ID).
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 566973697473206120706172616D65746572206E6F64652E204E6F74653A20506172616D657465727320617265207479706963616C6C7920696E636C7564656420696E6C696E6520696E206D6574686F642F6576656E74207369676E6174757265732C20736F2074686973206D6179206E6F742062652063616C6C656420647572696E67206E6F726D616C2074726176657273616C2E
		Sub VisitParameter(node As XKParameter)
		  /// Visits a parameter node.
		  /// Note: Parameters are typically included inline in method/event signatures,
		  /// so this may not be called during normal traversal.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Parameter"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":Parameter"
		  d.Value("name") = node.Name
		  d.Value("dataType") = node.DataType
		  d.Value("isByRef") = node.IsByRef
		  d.Value("isOptional") = node.IsOptional
		  d.Value("isParamArray") = node.IsParamArray
		  d.Value("isArray") = node.IsArray
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 56697369747320612070726F6A656374206E6F64652E
		Sub VisitProject(node As XKProject)
		  /// Visits a project node.
		  
		  // Initialize path with project name.
		  mPathComponents.RemoveAll
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Project"
		  d.Value("id") = node.Name
		  d.Value("name") = node.Name
		  d.Value("projectType") = node.ProjectType
		  
		  // Replace the root with this node.
		  If mNodeStack.Count > 0 Then
		    mNodeStack(0) = d
		  Else
		    mNodeStack.Add(d)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 56697369747320612070726F7065727479206E6F64652E
		Sub VisitProperty(node As XKProperty)
		  /// Visits a property node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Property"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":Property"
		  d.Value("name") = node.Name
		  d.Value("access") = node.AccessModifierName
		  
		  // Include array indicator in dataType for clarity.
		  If node.IsArray Then
		    d.Value("dataType") = node.DataType + "()"
		  Else
		    d.Value("dataType") = node.DataType
		  End If
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 566973697473206120746F6F6C626172206E6F64652E
		Sub VisitToolbar(node As XKToolbar)
		  /// Visits a toolbar node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "Toolbar"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":Toolbar"
		  d.Value("name") = node.Name
		  
		  If node.SuperClassName <> "" Then
		    d.Value("superclass") = node.SuperClassName
		  End If
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 566973697473206120746F6F6C62617220627574746F6E206E6F64652E
		Sub VisitToolbarButton(node As XKToolbarButton)
		  /// Visits a toolbar button node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "ToolbarButton"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":ToolbarButton"
		  d.Value("name") = node.Name
		  
		  If node.ButtonType <> "" Then
		    d.Value("buttonType") = node.ButtonType
		  End If
		  
		  If node.Caption <> "" Then
		    d.Value("caption") = node.Caption
		  End If
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 566973697473206120766965772070726F7065727479206E6F64652E
		Sub VisitViewProperty(node As XKViewProperty)
		  /// Visits a view property node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  d.Value("type") = "ViewProperty"
		  d.Value("id") = String.FromArray(mPathComponents, ".") + ":ViewProperty"
		  d.Value("name") = node.Name
		  d.Value("dataType") = node.DataType
		  
		  If node.Group <> "" Then
		    d.Value("group") = node.Group
		  End If
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 566973697473206120776562207061676520286F7220636F6E7461696E657229206E6F64652E
		Sub VisitWebPage(node As XKWebPage)
		  /// Visits a web page or container node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  If node.IsContainer Then
		    d.Value("type") = "WebContainer"
		    d.Value("id") = String.FromArray(mPathComponents, ".") + ":WebContainer"
		  Else
		    d.Value("type") = "WebPage"
		    d.Value("id") = String.FromArray(mPathComponents, ".") + ":WebPage"
		  End If
		  d.Value("name") = node.Name
		  
		  Var title As String = node.GetAttribute("Title", "")
		  If title <> "" Then
		    d.Value("title") = title
		  End If
		  
		  PushNode(d)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 56697369747320612077696E646F77206E6F64652E
		Sub VisitWindow(node As XKWindow)
		  /// Visits a window or container node.
		  
		  mPathComponents.Add(node.Name)
		  
		  Var d As New Dictionary
		  
		  If node.IsContainer Then
		    d.Value("type") = "ContainerControl"
		    d.Value("id") = String.FromArray(mPathComponents, ".") + ":ContainerControl"
		  Else
		    d.Value("type") = "Window"
		    d.Value("id") = String.FromArray(mPathComponents, ".") + ":Window"
		  End If
		  d.Value("name") = node.Name
		  
		  Var title As String = node.GetAttribute("Title", "")
		  If title <> "" Then
		    d.Value("title") = title
		  End If
		  
		  PushNode(d)
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected mNodeStack() As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mPathComponents() As String
	#tag EndProperty


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
	#tag EndViewBehavior
End Class
#tag EndClass
