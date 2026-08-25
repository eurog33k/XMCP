#tag Class
Protected Class XKParser
	#tag Method, Flags = &h21, Description = 457874726163747320746865204465736372697074696F6E2076616C75652066726F6D206120746167206C696E6520616E64206465636F6465732069742066726F6D206865782E
		Private Function ExtractDescription(tagLine As String) As String
		  /// Extracts the Description value from a tag line and decodes it from hex.
		  
		  Var hexDesc As String = ExtractTagAttribute(tagLine, "Description")
		  If hexDesc = "" Then Return ""
		  
		  Return XKParserUtils.DecodeHexString(hexDesc)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 45787472616374732074686520466C6167732076616C75652066726F6D206120746167206C696E652E
		Private Function ExtractFlags(tagLine As String) As Integer
		  /// Extracts the Flags value from a tag line.
		  
		  Var flagsStr As String = ExtractTagAttribute(tagLine, "Flags")
		  If flagsStr = "" Then Return 0
		  
		  // Handle &h prefix.
		  If flagsStr.Lowercase.BeginsWith("&h") Then
		    Return Val(flagsStr)
		  Else
		    Return Val(flagsStr)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 457874726163747320616E206174747269627574652076616C75652066726F6D206120746167206C696E652E
		Private Function ExtractTagAttribute(tagLine As String, attrName As String) As String
		  /// Extracts an attribute value from a tag line.
		  
		  // Look for "attrName = value" or "attrName=value".
		  Var searchStr As String = attrName + " = "
		  Var pos As Integer = tagLine.IndexOf(searchStr)
		  
		  If pos < 0 Then
		    searchStr = attrName + "="
		    pos = tagLine.IndexOf(searchStr)
		  End If
		  
		  If pos < 0 Then Return ""
		  
		  Var afterAttr As String = tagLine.Middle(pos + searchStr.Length)
		  
		  // Value ends at comma or end of line.
		  Var commaPos As Integer = afterAttr.IndexOf(",")
		  If commaPos >= 0 Then
		    Return afterAttr.Left(commaPos).Trim
		  Else
		    Return afterAttr.Trim
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 45787472616374732074686520746167206E616D652066726F6D2061206C696E65206C696B65202223746167205461674E616D65222E
		Private Function ExtractTagName(line As String) As String
		  /// Extracts the tag name from a line like "#tag TagName".
		  
		  If Not line.BeginsWith("#tag ") Then Return ""
		  
		  Var afterTag As String = line.Middle(5).Trim
		  
		  // Tag name ends at comma, space, or end of line.
		  Var commaPos As Integer = afterTag.IndexOf(",")
		  Var spacePos As Integer = afterTag.IndexOf(" ")
		  
		  Var endPos As Integer = afterTag.Length
		  If commaPos >= 0 And commaPos < endPos Then endPos = commaPos
		  If spacePos >= 0 And spacePos < endPos Then endPos = spacePos
		  
		  Return afterTag.Left(endPos)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 52657475726E73205472756520696620746865206B657920697320612070726F6A656374206974656D20747970652E
		Private Function IsItemType(key As String) As Boolean
		  /// Returns True if the key is a project item type.
		  
		  Select Case key
		  Case "Folder", "Class", "Module", "Interface", "DesktopWindow", "MenuBar", _
		    "DesktopToolbar", "MultiImage", "FileTypeSet", "BuildSteps", "WebSession", "WebView"
		    Return True
		  Else
		    Return False
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E7320746865206C617374206572726F72206D6573736167652069662070617273696E67206661696C65642E
		Function LastError() As String
		  /// Returns the last error message if parsing failed.
		  
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061206275696C64206175746F6D6174696F6E2066696C652E
		Private Sub ParseBuildAutomationFile(buildAutomation As XKBuildAutomation, content As String, filePath As String)
		  /// Parses a build automation file.
		  
		  buildAutomation.SourceFile = filePath
		  
		  Var lines() As String = content.ReplaceLineEndings(EndOfLine).Split(EndOfLine)
		  
		  Var lineNum As Integer = 0
		  Var totalLines As Integer = lines.Count
		  
		  While lineNum < totalLines
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("#tag EndBuildAutomation") Then
		      Exit
		    ElseIf line.BeginsWith("Begin BuildStepList ") Then
		      Var stepList As XKBuildStepList = ParseBuildStepList(lines, lineNum)
		      If stepList <> Nil Then
		        buildAutomation.AddStepList(stepList)
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573206120426567696E20537465705479706520626C6F636B2E
		Private Function ParseBuildStep(lines() As String, ByRef lineNum As Integer) As XKBuildStep
		  /// Parses a Begin StepType block.
		  
		  Var beginLine As String = lines(lineNum).Trim
		  
		  // Extract step type and name from "Begin StepType StepName".
		  Var parts() As String = beginLine.Split(" ")
		  If parts.Count < 3 Then Return Nil
		  
		  Var buildStep As New XKBuildStep
		  buildStep.StepType = parts(1)
		  buildStep.Name = parts(2)
		  buildStep.SourceLine = lineNum + 1
		  
		  lineNum = lineNum + 1
		  
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum)
		    Var trimmed As String = line.Trim
		    
		    If trimmed = "End" Then
		      Exit
		    ElseIf trimmed.IndexOf("=") >= 0 Then
		      // Step attribute.
		      Var eqPos As Integer = trimmed.IndexOf("=")
		      Var attrName As String = trimmed.Left(eqPos).Trim
		      Var attrValue As String = trimmed.Middle(eqPos + 1).Trim
		      buildStep.SetAttribute(attrName, attrValue)
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		  
		  Return buildStep
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573206120426567696E204275696C64537465704C69737420626C6F636B2E
		Private Function ParseBuildStepList(lines() As String, ByRef lineNum As Integer) As XKBuildStepList
		  /// Parses a Begin BuildStepList block.
		  
		  Var beginLine As String = lines(lineNum).Trim
		  
		  // Extract platform name from "Begin BuildStepList PlatformName".
		  Var platformName As String = beginLine.Middle(20).Trim
		  
		  Var stepList As New XKBuildStepList
		  stepList.PlatformName = platformName
		  stepList.SourceLine = lineNum + 1
		  
		  lineNum = lineNum + 1
		  
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum).Trim
		    
		    If line = "End" Then
		      Exit
		    ElseIf line.BeginsWith("Begin ") Then
		      Var buildStep As XKBuildStep = ParseBuildStep(lines, lineNum)
		      If buildStep <> Nil Then
		        stepList.AddStep(buildStep)
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		  
		  Return stepList
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061202E786F6A6F5F636F64652066696C652028636C6173732C206D6F64756C652C206F7220696E74657266616365292E
		Private Sub ParseCodeFile(container As XKCodeContainer, content As String, filePath As String)
		  /// Parses a .xojo_code file (class, module, or interface).
		  
		  container.SourceFile = filePath
		  
		  Var lines() As String = content.ReplaceLineEndings(EndOfLine).Split(EndOfLine)
		  
		  Var lineNum As Integer = 0
		  Var totalLines As Integer = lines.Count
		  
		  While lineNum < totalLines
		    Var line As String = lines(lineNum)
		    Var trimmed As String = line.Trim
		    
		    // Look for declaration line (e.g., "Protected Class ClassName Inherits Parent").
		    If trimmed.IndexOf("Class ") >= 0 Or trimmed.IndexOf("Module ") >= 0 Or trimmed.IndexOf("Interface ") >= 0 Then
		      ParseContainerDeclaration(container, trimmed)
		    End If
		    
		    // Parse #tag blocks.
		    If trimmed.BeginsWith("#tag ") Then
		      Var tagName As String = ExtractTagName(trimmed)
		      
		      Select Case tagName
		      Case "Method"
		        Var m As XKMethod = ParseMethod(lines, lineNum)
		        If m <> Nil Then container.AddMethod(m)
		        
		      Case "Property"
		        Var p As XKProperty = ParseProperty(lines, lineNum)
		        If p <> Nil Then container.AddProperty(p)
		        
		      Case "ComputedProperty"
		        Var cp As XKComputedProperty = ParseComputedProperty(lines, lineNum)
		        If cp <> Nil Then container.AddComputedProperty(cp)
		        
		      Case "Event"
		        Var ev As XKEvent = ParseEvent(lines, lineNum)
		        If ev <> Nil Then container.AddEvent(ev)
		        
		      Case "Note"
		        Var n As XKNote = ParseNote(lines, lineNum)
		        If n <> Nil Then container.AddNote(n)
		        
		      Case "Constant"
		        Var c As XKConstant = ParseConstant(lines, lineNum)
		        If c <> Nil Then container.AddConstant(c)
		        
		      Case "Enum"
		        Var en As XKEnum = ParseEnum(lines, lineNum)
		        If en <> Nil Then container.AddEnum(en)
		        
		      Case "ViewBehavior"
		        ParseViewBehavior(container, lines, lineNum)
		        
		      End Select
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061202374616720436F6D707574656450726F706572747920626C6F636B2E
		Private Function ParseComputedProperty(lines() As String, ByRef lineNum As Integer) As XKComputedProperty
		  /// Parses a #tag ComputedProperty block.
		  
		  Var startLine As Integer = lineNum
		  Var tagLine As String = lines(lineNum)
		  
		  // Extract attributes from tag line.
		  Var flags As Integer = ExtractFlags(tagLine)
		  Var description As String = ExtractDescription(tagLine)
		  
		  // Create the computed property node.
		  Var cp As New XKComputedProperty
		  cp.Flags = flags
		  cp.Description = description
		  cp.SourceLine = startLine + 1
		  
		  lineNum = lineNum + 1
		  
		  // Parse until #tag EndComputedProperty.
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("#tag EndComputedProperty") Then
		      Exit
		    ElseIf line.BeginsWith("#tag Getter") Then
		      cp.HasGetter = True
		      Var getterCode() As String = ParseGetterSetterCode(lines, lineNum, "EndGetter")
		      cp.GetterCode = getterCode
		    ElseIf line.BeginsWith("#tag Setter") Then
		      cp.HasSetter = True
		      Var setterCode() As String = ParseGetterSetterCode(lines, lineNum, "EndSetter")
		      cp.SetterCode = setterCode
		    ElseIf line.IndexOf(" As ") >= 0 And Not line.BeginsWith("#tag") Then
		      // Property declaration line.
		      Var asPos As Integer = line.IndexOf(" As ")
		      cp.Name = line.Left(asPos).Trim
		      cp.DataType = line.Middle(asPos + 4).Trim
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		  
		  Return cp
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061202374616720436F6E7374616E7420626C6F636B2E
		Private Function ParseConstant(lines() As String, ByRef lineNum As Integer) As XKConstant
		  /// Parses a #tag Constant block.
		  
		  Var startLine As Integer = lineNum
		  Var tagLine As String = lines(lineNum)
		  
		  // Extract attributes from tag line.
		  Var constName As String = ExtractTagAttribute(tagLine, "Name")
		  Var constType As String = ExtractTagAttribute(tagLine, "Type")
		  Var isDynamic As Boolean = (ExtractTagAttribute(tagLine, "Dynamic").Lowercase = "true")
		  Var defaultValue As String = ExtractTagAttribute(tagLine, "Default")
		  Var scope As String = ExtractTagAttribute(tagLine, "Scope")
		  
		  // Create the constant node.
		  Var c As New XKConstant
		  c.Name = constName
		  c.DataType = constType
		  c.IsDynamic = isDynamic
		  c.DefaultValue = defaultValue
		  c.Scope = scope
		  c.SourceLine = startLine + 1
		  
		  // Parse instances if dynamic.
		  lineNum = lineNum + 1
		  
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("#tag EndConstant") Then
		      Exit
		    ElseIf line.BeginsWith("#tag Instance") Then
		      Var inst As New XKConstantInstance
		      inst.Platform = ExtractTagAttribute(line, "Platform")
		      inst.Language = ExtractTagAttribute(line, "Language")
		      inst.Definition = ExtractTagAttribute(line, "Definition")
		      c.AddInstance(inst)
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		  
		  Return c
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320746865206465636C61726174696F6E206C696E65206F66206120636C6173732F6D6F64756C652F696E7465726661636520746F2065787472616374206163636573732C207375706572636C6173732C20616E6420696E74657266616365732E
		Private Sub ParseContainerDeclaration(container As XKCodeContainer, line As String)
		  /// Parses the declaration line of a class/module/interface to extract access, superclass, and interfaces.
		  
		  // Extract access modifier.
		  If line.IndexOf("Private ") >= 0 Then
		    container.Flags = &h21
		  ElseIf line.IndexOf("Protected ") >= 0 Then
		    container.Flags = &h1
		  Else
		    container.Flags = &h0  // Public
		  End If
		  
		  // Extract Inherits clause.
		  Var inheritsPos As Integer = line.IndexOf(" Inherits ")
		  If inheritsPos >= 0 Then
		    Var afterInherits As String = line.Middle(inheritsPos + 10)
		    Var implementsPos As Integer = afterInherits.IndexOf(" Implements ")
		    If implementsPos >= 0 Then
		      container.SuperClassName = afterInherits.Left(implementsPos).Trim
		    Else
		      container.SuperClassName = afterInherits.Trim
		    End If
		  End If
		  
		  // Extract Implements clause.
		  Var implementsPos As Integer = line.IndexOf(" Implements ")
		  If implementsPos >= 0 Then
		    Var afterImplements As String = line.Middle(implementsPos + 12).Trim
		    Var interfaces() As String = afterImplements.Split(",")
		    For Each iface As String In interfaces
		      container.Interfaces.Add(iface.Trim)
		    Next iface
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573206120426567696E20436F6E74726F6C4E616D6520626C6F636B2E
		Private Function ParseControl(lines() As String, ByRef lineNum As Integer) As XKControl
		  /// Parses a Begin ControlName block.
		  
		  Var beginLine As String = lines(lineNum).Trim
		  
		  // Extract control type and name from "Begin ControlType ControlName".
		  Var parts() As String = beginLine.Split(" ")
		  If parts.Count < 3 Then Return Nil
		  
		  Var control As New XKControl
		  control.ControlType = parts(1)
		  control.Name = parts(2)
		  control.SourceLine = lineNum + 1
		  
		  lineNum = lineNum + 1
		  
		  // Parse until matching End.
		  Var depth As Integer = 1
		  
		  While lineNum < lines.Count And depth > 0
		    Var line As String = lines(lineNum)
		    Var trimmed As String = line.Trim
		    
		    If trimmed.BeginsWith("Begin ") Then
		      // Nested control.
		      Var nestedControl As XKControl = ParseControl(lines, lineNum)
		      If nestedControl <> Nil Then
		        control.AddNestedControl(nestedControl)
		      End If
		    ElseIf trimmed = "End" Then
		      depth = depth - 1
		      If depth = 0 Then Exit
		    ElseIf trimmed.IndexOf("=") >= 0 And Not trimmed.BeginsWith("#tag") Then
		      // Control attribute.
		      Var eqPos As Integer = trimmed.IndexOf("=")
		      Var attrName As String = trimmed.Left(eqPos).Trim
		      Var attrValue As String = trimmed.Middle(eqPos + 1).Trim
		      control.SetAttribute(attrName, attrValue)
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		  
		  Return control
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320612023746167204576656E747320436F6E74726F6C4E616D6520626C6F636B2E
		Private Function ParseControlEventGroup(lines() As String, ByRef lineNum As Integer) As XKControlEventGroup
		  /// Parses a #tag Events ControlName block.
		  
		  Var tagLine As String = lines(lineNum).Trim
		  
		  // Extract control name from "#tag Events ControlName".
		  Var controlName As String = ""
		  If tagLine.BeginsWith("#tag Events ") Then
		    controlName = tagLine.Middle(12).Trim
		  End If
		  
		  Var ceg As New XKControlEventGroup
		  ceg.ControlName = controlName
		  ceg.SourceLine = lineNum + 1
		  
		  lineNum = lineNum + 1
		  
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("#tag EndEvents") Then
		      Exit
		    ElseIf line.BeginsWith("#tag Event") Then
		      Var ev As XKEvent = ParseEvent(lines, lineNum)
		      If ev <> Nil Then
		        ev.ControlName = controlName
		        ceg.AddEvent(ev)
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		  
		  Return ceg
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061202374616720456E756D20626C6F636B2E
		Private Function ParseEnum(lines() As String, ByRef lineNum As Integer) As XKEnum
		  /// Parses a #tag Enum block.
		  
		  Var startLine As Integer = lineNum
		  Var tagLine As String = lines(lineNum)
		  
		  // Extract attributes from tag line.
		  Var enumName As String = ExtractTagAttribute(tagLine, "Name")
		  Var enumType As String = ExtractTagAttribute(tagLine, "Type")
		  Var flags As Integer = ExtractFlags(tagLine)
		  
		  // Create the enum node.
		  Var en As New XKEnum
		  en.Name = enumName
		  en.DataType = enumType
		  en.Flags = flags
		  en.SourceLine = startLine + 1
		  
		  // Parse values.
		  lineNum = lineNum + 1
		  
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("#tag EndEnum") Then
		      Exit
		    ElseIf line <> "" And Not line.BeginsWith("#") Then
		      // Parse enum value: ValueName = IntegerValue
		      Var eqPos As Integer = line.IndexOf(" = ")
		      If eqPos >= 0 Then
		        Var ev As New XKEnumValue
		        ev.Name = line.Left(eqPos).Trim
		        Var valueStr As String = line.Middle(eqPos + 3).Trim
		        ev.Value = Val(valueStr)
		        en.AddValue(ev)
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		  
		  Return en
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320612023746167204576656E7420626C6F636B2E
		Private Function ParseEvent(lines() As String, ByRef lineNum As Integer) As XKEvent
		  /// Parses a #tag Event block.
		  
		  Var startLine As Integer = lineNum
		  
		  // Create the event node.
		  Var ev As New XKEvent
		  ev.SourceLine = startLine + 1
		  
		  // Move to the signature line.
		  lineNum = lineNum + 1
		  If lineNum >= lines.Count Then Return Nil
		  
		  // Parse signature line.
		  Var sigLine As String = lines(lineNum).Trim
		  ParseEventSignature(ev, sigLine)
		  
		  // Collect code lines until End Sub/Function.
		  lineNum = lineNum + 1
		  Var codeLines() As String
		  
		  While lineNum < lines.Count
		    Var currentLine As String = lines(lineNum)
		    Var trimmed As String = currentLine.Trim
		    
		    If trimmed.BeginsWith("End Sub") Or trimmed.BeginsWith("End Function") Then
		      lineNum = lineNum + 1
		      Exit
		    End If
		    
		    codeLines.Add(currentLine)
		    lineNum = lineNum + 1
		  Wend
		  
		  ev.SetCodeLines(codeLines)
		  
		  // Skip to #tag EndEvent.
		  While lineNum < lines.Count
		    If lines(lineNum).Trim.BeginsWith("#tag EndEvent") Then
		      Exit
		    End If
		    lineNum = lineNum + 1
		  Wend
		  
		  Return ev
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320706172616D65746572732066726F6D20616E206576656E7420706172616D6574657220737472696E672E
		Private Sub ParseEventParameters(ev As XKEvent, paramStr As String)
		  /// Parses parameters from an event parameter string.
		  
		  If paramStr.Trim = "" Then Return
		  
		  Var params() As String = XKParserUtils.SplitParameters(paramStr)
		  
		  For Each param As String In params
		    Var p As XKParameter = XKParserUtils.ParseSingleParameter(param.Trim)
		    If p <> Nil Then
		      ev.AddParameter(p)
		    End If
		  Next param
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320616E206576656E74207369676E6174757265206C696E652E
		Private Sub ParseEventSignature(ev As XKEvent, sigLine As String)
		  /// Parses an event signature line.
		  
		  // Determine if Function or Sub.
		  If sigLine.IndexOf("Function ") >= 0 Then
		    ev.IsFunction = True
		    sigLine = sigLine.ReplaceAll("Function ", "")
		  ElseIf sigLine.IndexOf("Sub ") >= 0 Then
		    ev.IsFunction = False
		    sigLine = sigLine.ReplaceAll("Sub ", "")
		  End If
		  
		  // Extract event name.
		  Var parenPos As Integer = sigLine.IndexOf("(")
		  If parenPos < 0 Then
		    ev.Name = sigLine.Trim
		    Return
		  End If
		  
		  ev.Name = sigLine.Left(parenPos).Trim
		  
		  // Extract parameters by finding the matching closing paren.
		  // We track depth to handle nested parens like "args() As String".
		  Var closeParenPos As Integer = -1
		  Var depth As Integer = 0
		  For i As Integer = parenPos To sigLine.Length - 1
		    Var c As String = sigLine.Middle(i, 1)
		    If c = "(" Then
		      depth = depth + 1
		    ElseIf c = ")" Then
		      depth = depth - 1
		      If depth = 0 Then
		        closeParenPos = i
		        Exit
		      End If
		    End If
		  Next i
		  If closeParenPos > parenPos Then
		    Var paramStr As String = sigLine.Middle(parenPos + 1, closeParenPos - parenPos - 1)
		    ParseEventParameters(ev, paramStr)
		  End If
		  
		  // Extract return type.
		  If ev.IsFunction Then
		    // Find the last ") As " which is the return type,
		    // not a parameter type like "args() As String".
		    Var asPos As Integer = -1
		    Var searchStart As Integer = 0
		    Do
		      Var pos As Integer = sigLine.IndexOf(searchStart, ") As ")
		      If pos < 0 Then Exit
		      asPos = pos
		      searchStart = pos + 1
		    Loop
		    If asPos >= 0 Then
		      ev.ReturnType = sigLine.Middle(asPos + 5).Trim
		    End If
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573206120237461672046696C655479706520626C6F636B2E
		Private Function ParseFileType(lines() As String, ByRef lineNum As Integer) As XKFileType
		  /// Parses a #tag FileType block.
		  
		  Var ft As New XKFileType
		  ft.SourceLine = lineNum + 1
		  
		  lineNum = lineNum + 1
		  
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("#tag EndFileType") Then
		      Exit
		    Else
		      // Parse attribute=value.
		      Var eqPos As Integer = line.IndexOf("=")
		      If eqPos >= 0 Then
		        Var attrName As String = line.Left(eqPos).Trim
		        Var attrValue As String = line.Middle(eqPos + 1).Trim
		        
		        ft.SetAttribute(attrName, attrValue)
		        
		        If attrName = "CodeName" Then
		          ft.CodeName = attrValue
		        End If
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		  
		  Return ft
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061202E786F6A6F5F66696C65747970657365742066696C652E
		Private Sub ParseFileTypeSetFile(fileTypeSet As XKFileTypeSet, content As String, filePath As String)
		  /// Parses a .xojo_filetypeset file.
		  
		  fileTypeSet.SourceFile = filePath
		  
		  Var lines() As String = content.ReplaceLineEndings(EndOfLine).Split(EndOfLine)
		  
		  Var lineNum As Integer = 0
		  Var totalLines As Integer = lines.Count
		  
		  While lineNum < totalLines
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("#tag EndFileTypeSet") Then
		      Exit
		    ElseIf line.BeginsWith("#tag FileType") Then
		      Var ft As XKFileType = ParseFileType(lines, lineNum)
		      If ft <> Nil Then
		        fileTypeSet.AddFileType(ft)
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320676574746572206F722073657474657220636F646520696E736964652061202374616720626C6F636B2E
		Private Function ParseGetterSetterCode(lines() As String, ByRef lineNum As Integer, endTag As String) As String()
		  /// Parses getter or setter code inside a #tag block.
		  
		  Var codeLines() As String
		  
		  lineNum = lineNum + 1
		  
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("#tag " + endTag) Then
		      Exit
		    ElseIf line = "Get" Or line = "Set" Then
		      // Skip.
		    ElseIf line = "End Get" Or line = "End Set" Then
		      // Skip.
		    Else
		      codeLines.Add(lines(lineNum))
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		  
		  Return codeLines
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061202E786F6A6F5F696D6167652066696C652E
		Private Sub ParseImageFile(image As XKMultiImage, content As String, filePath As String)
		  /// Parses a .xojo_image file.
		  
		  image.SourceFile = filePath
		  
		  Var lines() As String = content.ReplaceLineEndings(EndOfLine).Split(EndOfLine)
		  
		  Var lineNum As Integer = 0
		  Var totalLines As Integer = lines.Count
		  
		  // Skip to the Image line.
		  While lineNum < totalLines
		    Var line As String = lines(lineNum).Trim
		    If line.BeginsWith("Image ") Then
		      // Extract image name.
		      image.Name = line.Middle(6).Trim
		      lineNum = lineNum + 1
		      Exit
		    End If
		    lineNum = lineNum + 1
		  Wend
		  
		  // Parse image representations.
		  While lineNum < totalLines
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("End Image") Then
		      Exit
		    ElseIf line.BeginsWith("#tag ImageRepresentation") Then
		      Var rep As XKImageRepresentation = ParseImageRepresentation(lines, lineNum)
		      If rep <> Nil Then
		        image.AddRepresentation(rep)
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061202374616720496D616765526570726573656E746174696F6E20626C6F636B2E
		Private Function ParseImageRepresentation(lines() As String, ByRef lineNum As Integer) As XKImageRepresentation
		  /// Parses a #tag ImageRepresentation block.
		  
		  Var rep As New XKImageRepresentation
		  rep.SourceLine = lineNum + 1
		  
		  lineNum = lineNum + 1
		  
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("#tag EndImageRepresentation") Then
		      Exit
		    ElseIf line.BeginsWith("#tag ImageSpecification") Then
		      // Parse specification.
		      lineNum = lineNum + 1
		      While lineNum < lines.Count
		        Var specLine As String = lines(lineNum).Trim
		        If specLine.BeginsWith("#tag EndImageSpecification") Then
		          Exit
		        End If
		        
		        Var eqPos As Integer = specLine.IndexOf("=")
		        If eqPos >= 0 Then
		          Var attrName As String = specLine.Left(eqPos).Trim
		          Var attrValue As String = specLine.Middle(eqPos + 1).Trim
		          
		          Select Case attrName
		          Case "HSize"
		            rep.HSize = Val(attrValue)
		          Case "VSize"
		            rep.VSize = Val(attrValue)
		          Case "PPI"
		            rep.PPI = Val(attrValue)
		          Case "Device"
		            rep.Device = Val(attrValue)
		          Case "Platform"
		            rep.Platform = Val(attrValue)
		          Case "Orientation"
		            rep.Orientation = attrValue
		          Case "Comment"
		            rep.Comment = attrValue
		          End Select
		        End If
		        
		        lineNum = lineNum + 1
		      Wend
		    Else
		      // Parse top-level attributes.
		      Var eqPos As Integer = line.IndexOf("=")
		      If eqPos >= 0 Then
		        Var attrName As String = line.Left(eqPos).Trim
		        Var attrValue As String = line.Middle(eqPos + 1).Trim
		        
		        Select Case attrName
		        Case "SaveInfo"
		          rep.SaveInfo = attrValue
		        Case "FullPath"
		          rep.FullPath = attrValue
		        Case "PartialPath"
		          rep.PartialPath = attrValue
		        End Select
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		  
		  Return rep
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320616E206974656D206465636C61726174696F6E206C696E6520616E642072657475726E732074686520617070726F707269617465206E6F646520747970652E
		Private Function ParseItemDeclaration(itemType As String, value As String, lineNum As Integer) As XKProjectItem
		  /// Parses an item declaration line and returns the appropriate node type.
		  ///
		  /// Format: Name;RelativePath;&hGUID;&hParentGUID;InheritedFlag
		  
		  Var parts() As String = value.Split(";")
		  If parts.Count < 5 Then
		    mLastError = "Invalid item declaration at line " + lineNum.ToString + ": " + value
		    Return Nil
		  End If
		  
		  Var itemName As String = parts(0)
		  Var relativePath As String = parts(1)
		  Var guid As String = parts(2)
		  Var parentGUID As String = parts(3)
		  Var inherited As Boolean = (parts(4).Lowercase = "true")
		  
		  // Create the appropriate item type.
		  Var item As XKProjectItem
		  
		  Select Case itemType
		  Case "Folder"
		    item = New XKFolder
		  Case "Class"
		    item = New XKClass
		  Case "Module"
		    item = New XKModule
		  Case "Interface"
		    item = New XKInterface
		  Case "DesktopWindow"
		    item = New XKWindow
		  Case "MenuBar"
		    item = New XKMenuBar
		  Case "DesktopToolbar"
		    item = New XKToolbar
		  Case "MultiImage"
		    item = New XKMultiImage
		  Case "FileTypeSet"
		    item = New XKFileTypeSet
		  Case "BuildSteps"
		    item = New XKBuildAutomation
		  Case "WebSession"
		    item = New XKClass
		  Case "WebView"
		    item = New XKWebPage
		  Else
		    // Unknown type, create generic item.
		    item = New XKProjectItem
		  End Select
		  
		  item.ItemType = itemType
		  item.Name = itemName
		  item.RelativePath = relativePath
		  item.GUID = guid
		  item.ParentGUID = parentGUID
		  item.Inherited = inherited
		  
		  Return item
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573207468652065787465726E616C2066696C6520666F722074686520737065636966696564206974656D2E
		Private Sub ParseItemExternalFile(item As XKProjectItem)
		  /// Parses the external file for the specified item.
		  
		  // Skip folders (they don't have external files).
		  If item IsA XKFolder Then Return
		  
		  // Skip items without a relative path.
		  If item.RelativePath = "" Then Return
		  
		  // Resolve the file path.
		  Var filePath As String = XKParserUtils.ResolveRelativePath(mProjectDirectory, item.RelativePath)
		  If filePath = "" Then Return
		  
		  Var f As FolderItem = New FolderItem(filePath, FolderItem.PathModes.Native)
		  If f = Nil Or Not f.Exists Then Return
		  
		  // Read the file contents.
		  Var content As String = XKParserUtils.ReadFileContents(f)
		  If content = "" Then Return
		  
		  // Parse based on item type and file extension.
		  If item IsA XKClass Then
		    ParseCodeFile(XKClass(item), content, filePath)
		  ElseIf item IsA XKModule Then
		    ParseCodeFile(XKModule(item), content, filePath)
		  ElseIf item IsA XKInterface Then
		    ParseCodeFile(XKInterface(item), content, filePath)
		  ElseIf item IsA XKWindow Then
		    ParseWindowFile(XKWindow(item), content, filePath)
		  ElseIf item IsA XKWebPage Then
		    ParseWebPageFile(XKWebPage(item), content, filePath)
		  ElseIf item IsA XKMenuBar Then
		    ParseMenuFile(XKMenuBar(item), content, filePath)
		  ElseIf item IsA XKToolbar Then
		    ParseToolbarFile(XKToolbar(item), content, filePath)
		  ElseIf item IsA XKMultiImage Then
		    ParseImageFile(XKMultiImage(item), content, filePath)
		  ElseIf item IsA XKFileTypeSet Then
		    ParseFileTypeSetFile(XKFileTypeSet(item), content, filePath)
		  ElseIf item IsA XKBuildAutomation Then
		    ParseBuildAutomationFile(XKBuildAutomation(item), content, filePath)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061202E786F6A6F5F6D656E752066696C652E
		Private Sub ParseMenuFile(menuBar As XKMenuBar, content As String, filePath As String)
		  /// Parses a .xojo_menu file.
		  
		  menuBar.SourceFile = filePath
		  
		  Var lines() As String = content.ReplaceLineEndings(EndOfLine).Split(EndOfLine)
		  
		  Var lineNum As Integer = 0
		  Var totalLines As Integer = lines.Count
		  
		  // Skip to the Begin Menu line.
		  While lineNum < totalLines
		    Var line As String = lines(lineNum).Trim
		    If line.BeginsWith("Begin Menu ") Then
		      // Extract menu bar name.
		      menuBar.Name = line.Middle(11).Trim
		      lineNum = lineNum + 1
		      Exit
		    End If
		    lineNum = lineNum + 1
		  Wend
		  
		  // Parse menu items.
		  While lineNum < totalLines
		    Var line As String = lines(lineNum).Trim
		    
		    If line = "End" Then
		      Exit
		    ElseIf line.BeginsWith("Begin ") Then
		      Var item As XKMenuItem = ParseMenuItem(lines, lineNum)
		      If item <> Nil Then
		        menuBar.AddMenuItem(item)
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573206120426567696E204D656E754974656D20626C6F636B2E
		Private Function ParseMenuItem(lines() As String, ByRef lineNum As Integer) As XKMenuItem
		  /// Parses a Begin MenuItem block.
		  
		  Var beginLine As String = lines(lineNum).Trim
		  
		  // Extract menu item type and name from "Begin MenuItemType ItemName".
		  Var parts() As String = beginLine.Split(" ")
		  If parts.Count < 3 Then Return Nil
		  
		  Var item As New XKMenuItem
		  item.MenuItemType = parts(1)
		  item.Name = parts(2)
		  item.SourceLine = lineNum + 1
		  
		  lineNum = lineNum + 1
		  
		  // Parse until matching End.
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum)
		    Var trimmed As String = line.Trim
		    
		    If trimmed = "End" Then
		      Exit
		    ElseIf trimmed.BeginsWith("Begin ") Then
		      // Nested menu item (submenu).
		      Var subItem As XKMenuItem = ParseMenuItem(lines, lineNum)
		      If subItem <> Nil Then
		        item.AddSubItem(subItem)
		      End If
		    ElseIf trimmed.IndexOf("=") >= 0 Then
		      // Menu item attribute.
		      Var eqPos As Integer = trimmed.IndexOf("=")
		      Var attrName As String = trimmed.Left(eqPos).Trim
		      Var attrValue As String = trimmed.Middle(eqPos + 1).Trim
		      
		      item.SetAttribute(attrName, attrValue)
		      
		      If attrName = "Text" Then
		        item.Text = attrValue
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		  
		  Return item
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320612023746167204D6574686F6420626C6F636B2E
		Private Function ParseMethod(lines() As String, ByRef lineNum As Integer) As XKMethod
		  /// Parses a #tag Method block.
		  
		  Var startLine As Integer = lineNum
		  Var tagLine As String = lines(lineNum)
		  
		  // Extract attributes from tag line.
		  Var flags As Integer = ExtractFlags(tagLine)
		  Var description As String = ExtractDescription(tagLine)
		  
		  // Create the method node.
		  Var m As New XKMethod
		  m.Flags = flags
		  m.Description = description
		  m.SourceLine = startLine + 1
		  
		  // Move to the signature line.
		  lineNum = lineNum + 1
		  If lineNum >= lines.Count Then Return Nil
		  
		  // Parse signature line.
		  Var sigLine As String = lines(lineNum).Trim
		  ParseMethodSignature(m, sigLine)
		  
		  // Collect code lines until End Sub/Function.
		  lineNum = lineNum + 1
		  Var codeLines() As String
		  
		  While lineNum < lines.Count
		    Var currentLine As String = lines(lineNum)
		    Var trimmed As String = currentLine.Trim
		    
		    If trimmed.BeginsWith("End Sub") Or trimmed.BeginsWith("End Function") Then
		      // Found the end of the method body.
		      lineNum = lineNum + 1
		      Exit
		    End If
		    
		    codeLines.Add(currentLine)
		    lineNum = lineNum + 1
		  Wend
		  
		  m.SetCodeLines(codeLines)
		  
		  // Skip to #tag EndMethod.
		  While lineNum < lines.Count
		    If lines(lineNum).Trim.BeginsWith("#tag EndMethod") Then
		      Exit
		    End If
		    lineNum = lineNum + 1
		  Wend
		  
		  Return m
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061206D6574686F64207369676E6174757265206C696E6520616E6420706F70756C61746573207468652058504D6574686F64206E6F64652E
		Private Sub ParseMethodSignature(m As XKMethod, sigLine As String)
		  /// Parses a method signature line and populates the XKMethod node.
		  
		  // Check for Shared.
		  If sigLine.IndexOf("Shared ") >= 0 Then
		    m.IsShared = True
		    sigLine = sigLine.ReplaceAll("Shared ", "")
		  End If
		  
		  // Check for access modifier.
		  If sigLine.IndexOf("Private ") >= 0 Then
		    m.Flags = &h21
		    sigLine = sigLine.ReplaceAll("Private ", "")
		  ElseIf sigLine.IndexOf("Protected ") >= 0 Then
		    m.Flags = &h1
		    sigLine = sigLine.ReplaceAll("Protected ", "")
		  ElseIf sigLine.IndexOf("Public ") >= 0 Then
		    m.Flags = &h0
		    sigLine = sigLine.ReplaceAll("Public ", "")
		  End If
		  
		  // Determine if Function or Sub.
		  If sigLine.IndexOf("Function ") >= 0 Then
		    m.IsFunction = True
		    sigLine = sigLine.ReplaceAll("Function ", "")
		  ElseIf sigLine.IndexOf("Sub ") >= 0 Then
		    m.IsFunction = False
		    sigLine = sigLine.ReplaceAll("Sub ", "")
		  End If
		  
		  // Extract method name.
		  Var parenPos As Integer = sigLine.IndexOf("(")
		  If parenPos < 0 Then
		    m.Name = sigLine.Trim
		    Return
		  End If
		  
		  m.Name = sigLine.Left(parenPos).Trim
		  
		  // Extract parameters by finding the matching closing paren.
		  // We track depth to handle nested parens like "args() As String".
		  Var closeParenPos As Integer = -1
		  Var depth As Integer = 0
		  For i As Integer = parenPos To sigLine.Length - 1
		    Var c As String = sigLine.Middle(i, 1)
		    If c = "(" Then
		      depth = depth + 1
		    ElseIf c = ")" Then
		      depth = depth - 1
		      If depth = 0 Then
		        closeParenPos = i
		        Exit
		      End If
		    End If
		  Next i
		  If closeParenPos > parenPos Then
		    Var paramStr As String = sigLine.Middle(parenPos + 1, closeParenPos - parenPos - 1)
		    ParseParameters(m, paramStr)
		  End If
		  
		  // Extract return type.
		  If m.IsFunction Then
		    // Find the last ") As " which is the return type,
		    // not a parameter type like "args() As String".
		    Var asPos As Integer = -1
		    Var searchStart As Integer = 0
		    Do
		      Var pos As Integer = sigLine.IndexOf(searchStart, ") As ")
		      If pos < 0 Then Exit
		      asPos = pos
		      searchStart = pos + 1
		    Loop
		    If asPos >= 0 Then
		      m.ReturnType = sigLine.Middle(asPos + 5).Trim
		    End If
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320612023746167204E6F746520626C6F636B2E
		Private Function ParseNote(lines() As String, ByRef lineNum As Integer) As XKNote
		  /// Parses a #tag Note block.
		  
		  Var startLine As Integer = lineNum
		  Var tagLine As String = lines(lineNum)
		  
		  // Extract name from tag line: #tag Note, Name = NoteName
		  Var noteName As String = ExtractTagAttribute(tagLine, "Name")
		  
		  // Create the note node.
		  Var n As New XKNote
		  n.Name = noteName
		  n.SourceLine = startLine + 1
		  
		  // Collect content lines until #tag EndNote.
		  lineNum = lineNum + 1
		  Var contentLines() As String
		  
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum)
		    Var trimmed As String = line.Trim
		    
		    If trimmed.BeginsWith("#tag EndNote") Then
		      Exit
		    End If
		    
		    contentLines.Add(line)
		    lineNum = lineNum + 1
		  Wend
		  
		  n.Content = String.FromArray(contentLines, EndOfLine)
		  
		  Return n
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320706172616D65746572732066726F6D206120706172616D6574657220737472696E672E
		Private Sub ParseParameters(m As XKMethod, paramStr As String)
		  /// Parses parameters from a parameter string.
		  
		  If paramStr.Trim = "" Then Return
		  
		  // Split by comma, but be careful about nested generics.
		  Var params() As String = XKParserUtils.SplitParameters(paramStr)
		  
		  For Each param As String In params
		    Var p As XKParameter = XKParserUtils.ParseSingleParameter(param.Trim)
		    If p <> Nil Then
		      m.AddParameter(p)
		    End If
		  Next param
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 506172736573206120586F6A6F2070726F6A6563742066726F6D2074686520737065636966696564202E786F6A6F5F70726F6A6563742066696C6520706174682E
		Function ParseProject(projectFilePath As String) As XKProject
		  /// Parses a Xojo project from the specified .xojo_project file path.
		  ///
		  /// Returns the parsed XKProject node representing the entire project tree,
		  /// or Nil if parsing fails.
		  
		  // Validate the file exists.
		  Var f As FolderItem = New FolderItem(projectFilePath, FolderItem.PathModes.Native)
		  If f = Nil Or Not f.Exists Then
		    mLastError = "Project file not found: " + projectFilePath
		    Return Nil
		  End If
		  
		  // Store the project directory for resolving relative paths.
		  mProjectDirectory = f.Parent
		  
		  // Read the file contents.
		  Var content As String = XKParserUtils.ReadFileContents(f)
		  If content = "" Then
		    mLastError = "Could not read project file: " + projectFilePath
		    Return Nil
		  End If
		  
		  // Create the project node.
		  Var project As New XKProject
		  project.ProjectFilePath = projectFilePath
		  project.SourceFile = projectFilePath
		  
		  // Extract project name from filename.
		  Var filename As String = f.Name
		  If filename.EndsWith(".xojo_project") Then
		    project.Name = filename.Left(filename.Length - 13)
		  Else
		    project.Name = filename
		  End If
		  
		  // Parse the project file line by line.
		  Var lines() As String = content.ReplaceLineEndings(EndOfLine).Split(EndOfLine)
		  
		  // First pass: parse settings and collect items.
		  Var items() As XKProjectItem
		  
		  For lineNum As Integer = 0 To lines.LastIndex
		    Var line As String = lines(lineNum).Trim
		    
		    // Skip empty lines.
		    If line = "" Then Continue
		    
		    // Check for key=value format.
		    Var eqPos As Integer = line.IndexOf("=")
		    If eqPos < 1 Then Continue
		    
		    Var key As String = line.Left(eqPos).Trim
		    Var value As String = line.Middle(eqPos + 1).Trim
		    
		    // Check if this is an item declaration.
		    If IsItemType(key) Then
		      // Parse item specification: Name;RelativePath;&hGUID;&hParentGUID;InheritedFlag
		      Var item As XKProjectItem = ParseItemDeclaration(key, value, lineNum + 1)
		      If item <> Nil Then
		        item.SourceFile = projectFilePath
		        item.SourceLine = lineNum + 1
		        items.Add(item)
		        project.RegisterItem(item)
		      End If
		    Else
		      // Regular setting.
		      project.SetSetting(key, value)
		      
		      // Handle special settings.
		      Select Case key
		      Case "Type"
		        project.ProjectType = value
		      Case "RBProjectVersion"
		        project.RBProjectVersion = value
		      Case "MinIDEVersion"
		        project.MinIDEVersion = value
		      Case "OrigIDEVersion"
		        project.OrigIDEVersion = value
		      End Select
		    End If
		  Next lineNum
		  
		  // Second pass: build the hierarchy based on parent GUIDs.
		  Var rootGUID As String = "&h0000000000000000"
		  
		  For Each item As XKProjectItem In items
		    If item.ParentGUID = rootGUID Or item.ParentGUID = "" Then
		      // Top-level item.
		      project.AddChild(item)
		    Else
		      // Find parent and add as child.
		      Var parentItem As XKProjectItem = project.ItemByGUID(item.ParentGUID)
		      If parentItem <> Nil Then
		        parentItem.AddChild(item)
		      Else
		        // Parent not found, add to root.
		        project.AddChild(item)
		      End If
		    End If
		  Next item
		  
		  // Third pass: parse external files for each item.
		  For Each item As XKProjectItem In items
		    ParseItemExternalFile(item)
		  Next item
		  
		  Return project
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573206120237461672050726F706572747920626C6F636B2E
		Private Function ParseProperty(lines() As String, ByRef lineNum As Integer) As XKProperty
		  /// Parses a #tag Property block.
		  
		  Var startLine As Integer = lineNum
		  Var tagLine As String = lines(lineNum)
		  
		  // Extract attributes from tag line.
		  Var flags As Integer = ExtractFlags(tagLine)
		  Var description As String = ExtractDescription(tagLine)
		  
		  // Create the property node.
		  Var p As New XKProperty
		  p.Flags = flags
		  p.Description = description
		  p.SourceLine = startLine + 1
		  
		  // Move to the declaration line.
		  lineNum = lineNum + 1
		  If lineNum >= lines.Count Then Return Nil
		  
		  Var declLine As String = lines(lineNum).Trim
		  
		  // Parse: PropertyName As PropertyType [= DefaultValue]
		  Var asPos As Integer = declLine.IndexOf(" As ")
		  If asPos < 0 Then
		    p.Name = declLine
		  Else
		    Var propName As String = declLine.Left(asPos).Trim
		    
		    // Check for array syntax in property name.
		    If propName.IndexOf("()") >= 0 Then
		      p.IsArray = True
		      propName = propName.ReplaceAll("()", "")
		    End If
		    
		    p.Name = propName
		    
		    Var afterAs As String = declLine.Middle(asPos + 4).Trim
		    
		    // Check for default value.
		    Var eqPos As Integer = afterAs.IndexOf(" = ")
		    If eqPos >= 0 Then
		      p.DataType = afterAs.Left(eqPos).Trim
		      p.DefaultValue = afterAs.Middle(eqPos + 3).Trim
		    Else
		      p.DataType = afterAs
		    End If
		  End If
		  
		  // Skip to #tag EndProperty.
		  While lineNum < lines.Count
		    If lines(lineNum).Trim.BeginsWith("#tag EndProperty") Then
		      Exit
		    End If
		    lineNum = lineNum + 1
		  Wend
		  
		  Return p
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573206120426567696E20546F6F6C626172427574746F6E20626C6F636B2E
		Private Function ParseToolbarButton(lines() As String, ByRef lineNum As Integer) As XKToolbarButton
		  /// Parses a Begin ToolbarButton block.
		  
		  Var beginLine As String = lines(lineNum).Trim
		  
		  // Extract button type and name from "Begin ButtonType ButtonName".
		  Var parts() As String = beginLine.Split(" ")
		  If parts.Count < 3 Then Return Nil
		  
		  Var btn As New XKToolbarButton
		  btn.ButtonType = parts(1)
		  btn.Name = parts(2)
		  btn.SourceLine = lineNum + 1
		  
		  lineNum = lineNum + 1
		  
		  // Parse until matching End.
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum)
		    Var trimmed As String = line.Trim
		    
		    If trimmed = "End" Then
		      Exit
		    ElseIf trimmed.IndexOf("=") >= 0 Then
		      // Button attribute.
		      Var eqPos As Integer = trimmed.IndexOf("=")
		      Var attrName As String = trimmed.Left(eqPos).Trim
		      Var attrValue As String = trimmed.Middle(eqPos + 1).Trim
		      
		      btn.SetAttribute(attrName, attrValue)
		      
		      If attrName = "Caption" Then
		        btn.Caption = attrValue
		      ElseIf attrName = "Tooltip" Then
		        btn.Tooltip = attrValue
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		  
		  Return btn
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061202E786F6A6F5F746F6F6C6261722066696C652E
		Private Sub ParseToolbarFile(toolbar As XKToolbar, content As String, filePath As String)
		  /// Parses a .xojo_toolbar file.
		  
		  toolbar.SourceFile = filePath
		  
		  Var lines() As String = content.ReplaceLineEndings(EndOfLine).Split(EndOfLine)
		  
		  Var lineNum As Integer = 0
		  Var totalLines As Integer = lines.Count
		  
		  // Skip to the Begin DesktopToolbar line.
		  While lineNum < totalLines
		    Var line As String = lines(lineNum).Trim
		    If line.BeginsWith("Begin DesktopToolbar ") Then
		      // Extract toolbar name.
		      toolbar.Name = line.Middle(21).Trim
		      lineNum = lineNum + 1
		      Exit
		    End If
		    lineNum = lineNum + 1
		  Wend
		  
		  // Parse toolbar contents.
		  While lineNum < totalLines
		    Var line As String = lines(lineNum)
		    Var trimmed As String = line.Trim
		    
		    If trimmed = "End" Then
		      Exit
		    ElseIf trimmed.BeginsWith("Inherits ") Then
		      toolbar.SuperClassName = trimmed.Middle(9).Trim
		    ElseIf trimmed.BeginsWith("Begin ") Then
		      Var btn As XKToolbarButton = ParseToolbarButton(lines, lineNum)
		      If btn <> Nil Then
		        toolbar.AddButton(btn)
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061202374616720566965774265686176696F7220626C6F636B2E
		Private Sub ParseViewBehavior(container As XKCodeContainer, lines() As String, ByRef lineNum As Integer)
		  /// Parses a #tag ViewBehavior block.
		  
		  lineNum = lineNum + 1
		  
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("#tag EndViewBehavior") Then
		      Exit
		    ElseIf line.BeginsWith("#tag ViewProperty") Then
		      Var vp As XKViewProperty = ParseViewProperty(lines, lineNum)
		      If vp <> Nil Then
		        container.AddViewProperty(vp)
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320612023746167205669657750726F706572747920626C6F636B2E
		Private Function ParseViewProperty(lines() As String, ByRef lineNum As Integer) As XKViewProperty
		  /// Parses a #tag ViewProperty block.
		  
		  Var vp As New XKViewProperty
		  vp.SourceLine = lineNum + 1
		  
		  lineNum = lineNum + 1
		  
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("#tag EndViewProperty") Then
		      Exit
		    ElseIf line.BeginsWith("#tag EnumValues") Then
		      // Parse enum values.
		      lineNum = lineNum + 1
		      While lineNum < lines.Count
		        Var enumLine As String = lines(lineNum).Trim
		        If enumLine.BeginsWith("#tag EndEnumValues") Then
		          Exit
		        ElseIf enumLine.BeginsWith("""") Then
		          // Remove quotes.
		          vp.EnumValues.Add(enumLine.Middle(1, enumLine.Length - 2))
		        End If
		        lineNum = lineNum + 1
		      Wend
		    Else
		      // Parse attribute=value.
		      Var eqPos As Integer = line.IndexOf("=")
		      If eqPos >= 0 Then
		        Var attrName As String = line.Left(eqPos).Trim
		        Var attrValue As String = line.Middle(eqPos + 1).Trim
		        
		        Select Case attrName
		        Case "Name"
		          vp.Name = attrValue
		        Case "Visible"
		          vp.Visible = (attrValue.Lowercase = "true")
		        Case "Group"
		          vp.Group = attrValue
		        Case "InitialValue"
		          vp.InitialValue = attrValue
		        Case "Type"
		          vp.DataType = attrValue
		        Case "EditorType"
		          vp.EditorType = attrValue
		        End Select
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		  
		  Return vp
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573206120776562207061676520282E786F6A6F5F636F6465292066696C652E
		Private Sub ParseWebPageFile(webPage As XKWebPage, content As String, filePath As String)
		  /// Parses a web page (.xojo_code) file.
		  /// Handles both WebPage and WebContainer types.
		  
		  webPage.SourceFile = filePath
		  
		  Var lines() As String = content.ReplaceLineEndings(EndOfLine).Split(EndOfLine)
		  
		  Var lineNum As Integer = 0
		  Var totalLines As Integer = lines.Count
		  Var inVisualLayout As Boolean = False
		  
		  // Skip to the Begin WebPage or Begin WebContainer line.
		  While lineNum < totalLines
		    Var line As String = lines(lineNum).Trim
		    If line.BeginsWith("Begin WebPage ") Then
		      // Extract web page name.
		      webPage.Name = line.Middle(14).Trim
		      webPage.IsContainer = False
		      inVisualLayout = True
		      lineNum = lineNum + 1
		      Exit
		    ElseIf line.BeginsWith("Begin WebContainer ") Then
		      // Extract container name.
		      webPage.Name = line.Middle(19).Trim
		      webPage.IsContainer = True
		      inVisualLayout = True
		      lineNum = lineNum + 1
		      Exit
		    End If
		    lineNum = lineNum + 1
		  Wend
		  
		  // Parse the entire file.
		  While lineNum < totalLines
		    Var line As String = lines(lineNum)
		    Var trimmed As String = line.Trim
		    
		    // Check for end of visual layout section.
		    If inVisualLayout And trimmed = "End" And lineNum + 1 < totalLines Then
		      If lines(lineNum + 1).Trim.BeginsWith("#tag EndWebPage") Or _
		        lines(lineNum + 1).Trim.BeginsWith("#tag EndWebContainer") Then
		        // End of visual layout block, but continue parsing for #tag sections.
		        inVisualLayout = False
		        lineNum = lineNum + 1
		        Continue
		      End If
		    End If
		    
		    // Parse web page/container attributes (only in visual layout section).
		    If inVisualLayout And trimmed.IndexOf("=") >= 0 And Not trimmed.BeginsWith("#tag") And Not trimmed.BeginsWith("Begin ") Then
		      Var eqPos As Integer = trimmed.IndexOf("=")
		      Var attrName As String = trimmed.Left(eqPos).Trim
		      Var attrValue As String = trimmed.Middle(eqPos + 1).Trim
		      webPage.SetAttribute(attrName, attrValue)
		    End If
		    
		    // Parse controls (only in visual layout section).
		    If inVisualLayout And trimmed.BeginsWith("Begin ") And Not trimmed.BeginsWith("Begin WebPage") And Not trimmed.BeginsWith("Begin WebContainer") Then
		      Var control As XKControl = ParseControl(lines, lineNum)
		      If control <> Nil Then
		        webPage.AddControl(control)
		      End If
		    End If
		    
		    // Parse #tag blocks (can appear in visual layout or in WindowCode section).
		    If trimmed.BeginsWith("#tag ") Then
		      Var tagName As String = ExtractTagName(trimmed)
		      
		      Select Case tagName
		      Case "Event"
		        Var ev As XKEvent = ParseEvent(lines, lineNum)
		        If ev <> Nil Then webPage.AddEvent(ev)
		        
		      Case "Events"
		        // Control events.
		        Var ceg As XKControlEventGroup = ParseControlEventGroup(lines, lineNum)
		        If ceg <> Nil Then webPage.AddControlEventGroup(ceg)
		        
		      Case "Method"
		        Var m As XKMethod = ParseMethod(lines, lineNum)
		        If m <> Nil Then webPage.AddMethod(m)
		        
		      Case "Property"
		        Var p As XKProperty = ParseProperty(lines, lineNum)
		        If p <> Nil Then webPage.AddProperty(p)
		        
		      Case "ViewBehavior"
		        ParseWebPageViewBehavior(webPage, lines, lineNum)
		        
		      End Select
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573207765622070616765207669657720626568617669F722070726F706572746965732
		Private Sub ParseWebPageViewBehavior(webPage As XKWebPage, lines() As String, ByRef lineNum As Integer)
		  /// Parses web page view behavior properties.
		  
		  lineNum = lineNum + 1
		  
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("#tag EndViewBehavior") Then
		      Exit
		    ElseIf line.BeginsWith("#tag ViewProperty") Then
		      Var vp As XKViewProperty = ParseViewProperty(lines, lineNum)
		      If vp <> Nil Then
		        webPage.AddViewProperty(vp)
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061202E786F6A6F5F77696E646F772066696C652E
		Private Sub ParseWindowFile(window As XKWindow, content As String, filePath As String)
		  /// Parses a .xojo_window file.
		  /// Handles both DesktopWindow and DesktopContainer types.
		  
		  window.SourceFile = filePath
		  
		  Var lines() As String = content.ReplaceLineEndings(EndOfLine).Split(EndOfLine)
		  
		  Var lineNum As Integer = 0
		  Var totalLines As Integer = lines.Count
		  Var inVisualLayout As Boolean = False
		  
		  // Skip to the Begin DesktopWindow or Begin DesktopContainer line.
		  While lineNum < totalLines
		    Var line As String = lines(lineNum).Trim
		    If line.BeginsWith("Begin DesktopWindow ") Then
		      // Extract window name.
		      window.Name = line.Middle(20).Trim
		      window.IsContainer = False
		      inVisualLayout = True
		      lineNum = lineNum + 1
		      Exit
		    ElseIf line.BeginsWith("Begin DesktopContainer ") Then
		      // Extract container name.
		      window.Name = line.Middle(23).Trim
		      window.IsContainer = True
		      inVisualLayout = True
		      lineNum = lineNum + 1
		      Exit
		    End If
		    lineNum = lineNum + 1
		  Wend
		  
		  // Parse the entire file.
		  While lineNum < totalLines
		    Var line As String = lines(lineNum)
		    Var trimmed As String = line.Trim
		    
		    // Check for end of visual layout section.
		    If inVisualLayout And trimmed = "End" And lineNum + 1 < totalLines Then
		      If lines(lineNum + 1).Trim.BeginsWith("#tag EndDesktopWindow") Then
		        // End of visual layout block, but continue parsing for #tag sections.
		        inVisualLayout = False
		        lineNum = lineNum + 1
		        Continue
		      End If
		    End If
		    
		    // Parse window/container attributes (only in visual layout section).
		    If inVisualLayout And trimmed.IndexOf("=") >= 0 And Not trimmed.BeginsWith("#tag") And Not trimmed.BeginsWith("Begin ") Then
		      Var eqPos As Integer = trimmed.IndexOf("=")
		      Var attrName As String = trimmed.Left(eqPos).Trim
		      Var attrValue As String = trimmed.Middle(eqPos + 1).Trim
		      window.SetAttribute(attrName, attrValue)
		    End If
		    
		    // Parse controls (only in visual layout section).
		    If inVisualLayout And trimmed.BeginsWith("Begin ") And Not trimmed.BeginsWith("Begin DesktopWindow") And Not trimmed.BeginsWith("Begin DesktopContainer") Then
		      Var control As XKControl = ParseControl(lines, lineNum)
		      If control <> Nil Then
		        window.AddControl(control)
		      End If
		    End If
		    
		    // Parse #tag blocks (can appear in visual layout or in WindowCode section).
		    If trimmed.BeginsWith("#tag ") Then
		      Var tagName As String = ExtractTagName(trimmed)
		      
		      Select Case tagName
		      Case "Event"
		        Var ev As XKEvent = ParseEvent(lines, lineNum)
		        If ev <> Nil Then window.AddEvent(ev)
		        
		      Case "Events"
		        // Control events.
		        Var ceg As XKControlEventGroup = ParseControlEventGroup(lines, lineNum)
		        If ceg <> Nil Then window.AddControlEventGroup(ceg)
		        
		      Case "Method"
		        Var m As XKMethod = ParseMethod(lines, lineNum)
		        If m <> Nil Then window.AddMethod(m)
		        
		      Case "Property"
		        Var p As XKProperty = ParseProperty(lines, lineNum)
		        If p <> Nil Then window.AddProperty(p)
		        
		      Case "ViewBehavior"
		        ParseWindowViewBehavior(window, lines, lineNum)
		        
		      End Select
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732077696E646F772076696577206265686176696F722070726F706572746965732E
		Private Sub ParseWindowViewBehavior(window As XKWindow, lines() As String, ByRef lineNum As Integer)
		  /// Parses window view behavior properties.
		  
		  lineNum = lineNum + 1
		  
		  While lineNum < lines.Count
		    Var line As String = lines(lineNum).Trim
		    
		    If line.BeginsWith("#tag EndViewBehavior") Then
		      Exit
		    ElseIf line.BeginsWith("#tag ViewProperty") Then
		      Var vp As XKViewProperty = ParseViewProperty(lines, lineNum)
		      If vp <> Nil Then
		        window.AddViewProperty(vp)
		      End If
		    End If
		    
		    lineNum = lineNum + 1
		  Wend
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mLastError As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mProjectDirectory As FolderItem
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
