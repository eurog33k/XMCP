#tag Class
Protected Class XKXMLParser
	#tag Method, Flags = &h21, Description = 4275696C647320746865206275696C6420617574616D6174696F6E206869657261726368792E
		Private Sub BuildBuildAutomationHierarchy()
		  /// Builds the build automation hierarchy by connecting step lists and steps.
		  
		  // First pass: create XKBuildStepList objects for BuildStepsList blocks.
		  Var stepListsById As New Dictionary
		  
		  For Each p As Pair In mBuildStepBlocks
		    Var info As Dictionary = Dictionary(p.Right)
		    Var blockType As String = info.Value("blockType")
		    
		    If blockType = "BuildStepsList" Then
		      Var stepList As New XKBuildStepList
		      stepList.PlatformName = info.Value("name")
		      stepListsById.Value(info.Value("blockId")) = stepList
		      
		      // Find parent BuildAutomation and add to it.
		      Var parentId As Integer = info.Value("parentId")
		      Var parent As XKProjectItem = XKProjectItem(mBlocksById.Lookup(parentId, Nil))
		      If parent IsA XKBuildAutomation Then
		        XKBuildAutomation(parent).AddStepList(stepList)
		      End If
		    End If
		  Next p
		  
		  // Second pass: create XKBuildStep objects and add to their parent step lists.
		  For Each p2 As Pair In mBuildStepBlocks
		    Var info2 As Dictionary = Dictionary(p2.Right)
		    Var blockType2 As String = info2.Value("blockType")
		    
		    If blockType2 <> "BuildStepsList" Then
		      Var buildStep As New XKBuildStep
		      buildStep.Name = info2.Value("name")
		      buildStep.StepType = blockType2
		      
		      // Parse additional attributes from the node.
		      Var stepNode As XmlNode = XmlNode(info2.Value("node"))
		      For i As Integer = 0 To stepNode.ChildCount - 1
		        Var child As XmlNode = stepNode.Child(i)
		        If Not (child IsA XmlElement) Then Continue
		        Var elem As XmlElement = XmlElement(child)
		        
		        // Check for <Hex> child element (e.g., FileAlias).
		        Var attrValue As String = ""
		        Var hexNode As XmlNode = Nil
		        For j As Integer = 0 To child.ChildCount - 1
		          Var subNode As XmlNode = child.Child(j)
		          If subNode IsA XmlElement And XmlElement(subNode).Name = "Hex" Then
		            hexNode = subNode
		            Exit
		          End If
		        Next j
		        
		        If hexNode <> Nil And hexNode.FirstChild <> Nil Then
		          attrValue = XKParserUtils.DecodeHexString(hexNode.FirstChild.Value)
		          // Replace null bytes with "/" (path separators in file aliases).
		          attrValue = attrValue.ReplaceAll(Chr(0), "/")
		        ElseIf child.FirstChild <> Nil Then
		          attrValue = child.FirstChild.Value
		        End If
		        
		        If attrValue <> "" Then
		          buildStep.SetAttribute(elem.Name, attrValue)
		        End If
		      Next i
		      
		      // Find parent step list and add to it.
		      Var stepParentId As Integer = info2.Value("parentId")
		      Var parentList As XKBuildStepList = XKBuildStepList(stepListsById.Lookup(stepParentId, Nil))
		      If parentList <> Nil Then
		        parentList.AddStep(buildStep)
		      End If
		    End If
		  Next p2
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 4275696C6473207468652068696572617263687920666F7220636F6E74726F6C7320696E20612077696E646F772E
		Private Sub BuildControlHierarchy(window As XKWindow)
		  /// Builds the hierarchy for controls in a window.
		  /// Controls use InitialParent property to define nesting.
		  
		  // First pass: create a lookup by control name.
		  Var controlsByName As New Dictionary
		  
		  For i As Integer = 0 To window.ControlCount - 1
		    Var ctrl As XKControl = window.ControlAt(i)
		    controlsByName.Value(ctrl.Name) = ctrl
		  Next i
		  
		  // Second pass: build hierarchy using InitialParent.
		  Var topLevelControls() As XKControl
		  Var childControls() As XKControl
		  
		  For i As Integer = 0 To window.ControlCount - 1
		    Var ctrl As XKControl = window.ControlAt(i)
		    Var parentName As String = ctrl.GetAttribute("InitialParent")
		    
		    If parentName = "" Then
		      topLevelControls.Add(ctrl)
		    Else
		      Var parentCtrl As XKControl = XKControl(controlsByName.Lookup(parentName, Nil))
		      If parentCtrl <> Nil Then
		        parentCtrl.AddNestedControl(ctrl)
		        childControls.Add(ctrl)
		      Else
		        topLevelControls.Add(ctrl)
		      End If
		    End If
		  Next i
		  
		  // Rebuild the window's control list with only top-level controls.
		  window.ClearControls
		  For Each ctrl As XKControl In topLevelControls
		    window.AddControl(ctrl)
		  Next ctrl
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 4275696C6473207468652068696572617263687920627920636F6E6E656374696E67206974656D7320746F207468656972207061072656E74732
		Private Sub BuildHierarchy(project As XKProject)
		  /// Builds the hierarchy by connecting items to their parents.
		  
		  For Each entry As DictionaryEntry In mBlocksById
		    Var item As XKProjectItem = XKProjectItem(entry.Value)
		    If item = Nil Then Continue
		    
		    Var parentId As Integer = item.ParentContainerId
		    
		    If parentId = 0 Then
		      // Top-level item.
		      project.AddChild(item)
		    Else
		      // Find parent and add as child.
		      Var parentItem As XKProjectItem = XKProjectItem(mBlocksById.Lookup(parentId, Nil))
		      If parentItem <> Nil Then
		        parentItem.AddChild(item)
		      Else
		        // Parent not found, add to root.
		        project.AddChild(item)
		      End If
		    End If
		  Next entry
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 4275696C6473207468652068696572617263687920666F7220636F6E74726F6C7320696E206120776562207061676520636F6E7461696E65722E
		Private Sub BuildWebPageControlHierarchy(webPage As XKWebPage)
		  /// Builds the hierarchy for controls in a web page.
		  /// Controls use InitialParent property to define nesting.
		  
		  // First pass: create a lookup by control name.
		  Var controlsByName As New Dictionary
		  
		  For i As Integer = 0 To webPage.ControlCount - 1
		    Var ctrl As XKControl = webPage.ControlAt(i)
		    controlsByName.Value(ctrl.Name) = ctrl
		  Next i
		  
		  // Second pass: build hierarchy using InitialParent.
		  Var topLevelControls() As XKControl
		  Var childControls() As XKControl
		  
		  For i As Integer = 0 To webPage.ControlCount - 1
		    Var ctrl As XKControl = webPage.ControlAt(i)
		    Var parentName As String = ctrl.GetAttribute("InitialParent")
		    
		    If parentName = "" Then
		      topLevelControls.Add(ctrl)
		    Else
		      Var parentCtrl As XKControl = XKControl(controlsByName.Lookup(parentName, Nil))
		      If parentCtrl <> Nil Then
		        parentCtrl.AddNestedControl(ctrl)
		        childControls.Add(ctrl)
		      Else
		        topLevelControls.Add(ctrl)
		      End If
		    End If
		  Next i
		  
		  // Rebuild the web page's control list with only top-level controls.
		  webPage.ClearControls
		  For Each ctrl As XKControl In topLevelControls
		    webPage.AddControl(ctrl)
		  Next ctrl
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 4465636F646573206120436F64654465736372697074696F6E206E6F64652077686963682063616E20636F6E7461696E20706C61696E2074657874206F722061206865782D656E636F646564203C4865783E20656C656D656E742E
		Private Function DecodeDescription(node As XmlNode) As String
		  /// Decodes a CodeDescription node which can contain plain text or a hex-encoded <Hex> element.
		  
		  If node = Nil Then Return ""
		  
		  // Check for <Hex> child element.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    If XmlElement(child).Name = "Hex" Then
		      // Hex-encoded content.
		      If child.FirstChild <> Nil Then
		        Return XKParserUtils.DecodeHexString(child.FirstChild.Value)
		      End If
		      Return ""
		    End If
		  Next i
		  
		  // Plain text content.
		  If node.FirstChild <> Nil Then
		    Return node.FirstChild.Value
		  End If
		  
		  Return ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 457874726163747320616C6C203C536F757263654C696E653E20656C656D656E74732066726F6D20616E203C4974656D536F757263653E206E6F64652E
		Private Function ExtractSourceLines(sourceNode As XmlNode) As String()
		  /// Extracts all <SourceLine> elements from an <ItemSource> node.
		  
		  Var lines() As String
		  
		  If sourceNode = Nil Then Return lines
		  
		  For i As Integer = 0 To sourceNode.ChildCount - 1
		    Var child As XmlNode = sourceNode.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    If XmlElement(child).Name = "SourceLine" Then
		      If child.FirstChild <> Nil Then
		        lines.Add(child.FirstChild.Value)
		      Else
		        lines.Add("")
		      End If
		    End If
		  Next i
		  
		  Return lines
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 46696E6473207468652066696E697368696E6720706172656E2061742074686520676976656E206465707468206F662074686520737472696E672E
		Private Function FindMatchingParen(s As String, startPos As Integer) As Integer
		  /// Finds the matching closing parenthesis.
		  
		  Var depth As Integer = 0
		  For i As Integer = startPos To s.Length - 1
		    Var c As String = s.Middle(i, 1)
		    If c = "(" Then
		      depth = depth + 1
		    ElseIf c = ")" Then
		      depth = depth - 1
		      If depth = 0 Then
		        Return i
		      End If
		    End If
		  Next i
		  Return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 47657473207468652076616C7565206F6620616E204D584C20617474726962757465206279206E616D652E
		Private Function GetAttributeValue(node As XmlNode, attrName As String) As String
		  /// Gets the value of an XML attribute by name.
		  
		  If node = Nil Then Return ""
		  
		  If node IsA XmlElement Then
		    Return XmlElement(node).GetAttribute(attrName)
		  End If
		  
		  Return ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 476574732074686520626F6F6C65616E2076616C7565206F66206120636869646C20656C656D656E742E
		Private Function GetChildBoolean(parent As XmlNode, name As String) As Boolean
		  /// Gets the boolean value of a child element.
		  
		  Var value As String = GetChildText(parent, name)
		  Return value = "1" Or value.Lowercase = "true"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 476574732074686520696E74656765722076616C7565206F66206120636869646C20656C656D656E742E
		Private Function GetChildInteger(parent As XmlNode, name As String) As Integer
		  /// Gets the integer value of a child element.
		  
		  Var value As String = GetChildText(parent, name)
		  If value = "" Then Return 0
		  Return Val(value)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 476574732074686520746578742076616C7565206F66206120636869646C20656C656D656E74206279206E616D652E
		Private Function GetChildText(parent As XmlNode, name As String) As String
		  /// Gets the text value of a child element by name.
		  
		  If parent = Nil Then Return ""
		  
		  For i As Integer = 0 To parent.ChildCount - 1
		    Var child As XmlNode = parent.Child(i)
		    
		    // Only check element nodes.
		    If Not (child IsA XmlElement) Then Continue
		    
		    If XmlElement(child).Name = name Then
		      If child.FirstChild <> Nil Then
		        Return child.FirstChild.Value
		      End If
		      Return ""
		    End If
		  Next i
		  
		  Return ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 476574732074686520496E69746961506172656E74206F662061206D656E75206974656D2C2077686963682069732073746F72656420696E2074686520466C616773206669656C642E
		Private Function GetItemFlags(node As XmlNode) As Integer
		  /// Gets the ItemFlags value from a node.
		  
		  Return GetChildInteger(node, "ItemFlags")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E7320746865206C617374206572726F72206D6573736167652069662070617273696E67206661696C65642E
		Function LastError() As String
		  /// Returns the last error message if parsing failed.
		  
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ParseExternalItem(content As String) As XKProjectItem
		  /// Parses one external item file in Xojo's XML form (.xojo_xml_code, .xojo_xml_window)
		  /// and returns the item it describes, or Nil.
		  ///
		  /// An XML external item is a whole RBProject document holding a single block, so it can
		  /// be read with the same block parsers as a full XML project - it just has to be handed
		  /// to them. The text parser used to give these files to its own #tag reader, which finds
		  /// nothing in XML and reported the item as having no members.
		  
		  mLastError = ""
		  
		  Var doc As XmlDocument
		  Try
		    doc = New XmlDocument(content)
		  Catch e As RuntimeException
		    mLastError = "Could not parse the external item as XML: " + e.Message
		    Return Nil
		  End Try
		  
		  Var root As XmlNode = doc.DocumentElement
		  If root = Nil Or root.Name <> "RBProject" Then
		    mLastError = "External item is not an RBProject document."
		    Return Nil
		  End If
		  
		  For i As Integer = 0 To root.ChildCount - 1
		    Var child As XmlNode = root.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    
		    Var elem As XmlElement = XmlElement(child)
		    If elem.Name <> "block" Then Continue
		    
		    // The block type is the shape of the file, not what the manifest calls the item -
		    // every code container is written as type="Module", with IsClass and IsInterface
		    // inside it deciding which one it actually is.
		    Var blockType As String = elem.GetAttribute("type")
		    Var item As XKProjectItem = ParseBlock(elem, blockType, 0)
		    If item <> Nil Then Return item
		  Next i
		  
		  mLastError = "External item contains no block element."
		  Return Nil
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ParseExternalCodeBlock(node As XmlNode) As XKProjectItem
		  /// An ExternalCode block: a reference to an item stored outside the project, carrying no
		  /// code of its own. Nothing here handled that type, so it fell to the unknown-block
		  /// branch and was dropped - which is why an XML project reported every external item as
		  /// not found while list_project_items, which asks the IDE, listed it perfectly well.
		  ///
		  /// A binary external uses the identical element names and differs only in what it points
		  /// at, so one resolver covers both and the file itself decides which reader applies.
		  
		  Var name As String = GetChildText(node, "ObjName")
		  Var partialPath As String = GetChildText(node, "PartialPath")
		  Var fullPath As String = GetChildText(node, "FullPath")
		  
		  Var file As FolderItem = ResolveExternalFile(partialPath, fullPath)
		  
		  If file = Nil Then
		    // Return the item anyway. It exists, and calling it missing is precisely the answer
		    // that sent readers after the wrong problem; what it lacks is a readable file.
		    Var missing As New XKProjectItem
		    missing.Name = name
		    missing.RelativePath = If(partialPath <> "", partialPath, fullPath)
		    Return missing
		  End If
		  
		  Var content As String = XKParserUtils.ReadFileContents(file)
		  
		  Var parsed As XKProjectItem
		  If content <> "" Then parsed = ParseExternalItem(content)
		  
		  If parsed = Nil Then
		    // Reachable but unreadable - a binary external is the ordinary case.
		    Var opaque As New XKProjectItem
		    opaque.Name = name
		    opaque.RelativePath = file.NativePath
		    Return opaque
		  End If
		  
		  // The reference supplies the name the project knows it by; the file supplies its shape.
		  parsed.Name = name
		  parsed.RelativePath = file.NativePath
		  parsed.SourceFile = file.NativePath
		  
		  Return parsed
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ResolveExternalFile(partialPath As String, fullPath As String) As FolderItem
		  /// Finds the file an external reference points at.
		  ///
		  /// PartialPath first, deliberately. It is relative to the project and so travels with a
		  /// checkout, while FullPath is absolute and belongs to whichever machine last saved -
		  /// resolving through it would work there and break everywhere else, which is the exact
		  /// shape of bug this port has already produced twice. FullPath is only a fallback for a
		  /// reference that has no relative form.
		  
		  If partialPath <> "" Then
		    Var base As FolderItem = ExternalBaseFolder
		    If base <> Nil Then
		      Var f As FolderItem = base
		      Var normalised As String = partialPath.ReplaceAll("\", "/")
		      
		      For Each part As String In normalised.Split("/")
		        If part = "" Then Continue
		        If f = Nil Then Exit
		        
		        Try
		          If part = ".." Then
		            f = f.Parent
		          Else
		            f = f.Child(part)
		          End If
		        Catch e As RuntimeException
		          f = Nil
		        End Try
		      Next part
		      
		      If f <> Nil And f.Exists Then Return f
		    End If
		  End If
		  
		  If fullPath <> "" Then
		    Try
		      Var f As New FolderItem(fullPath, FolderItem.PathModes.Native)
		      If f <> Nil And f.Exists Then Return f
		    Catch e As RuntimeException
		      // Fall through.
		    End Try
		  End If
		  
		  Return Nil
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ExternalBaseFolder() As FolderItem
		  /// The folder a relative external reference is measured from: the one holding the project.
		  
		  If mProjectFilePath = "" Then Return Nil
		  
		  Try
		    Var f As New FolderItem(mProjectFilePath, FolderItem.PathModes.Native)
		    If f = Nil Then Return Nil
		    Return f.Parent
		  Catch e As RuntimeException
		    Return Nil
		  End Try
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061207369676E676C6520626C6F636B20656C656D656E742E
		Private Function ParseBlock(node As XmlNode, blockType As String, blockId As Integer) As XKProjectItem
		  /// Parses a single block element.
		  
		  Var item As XKProjectItem
		  
		  Select Case blockType
		  Case "Folder"
		    item = ParseFolderBlock(node)
		    
		  Case "Module"
		    item = ParseModuleBlock(node)
		    
		  Case "ExternalCode"
		    item = ParseExternalCodeBlock(node)
		    
		  Case "DesktopWindow", "Window", "DesktopContainer", "ContainerControl"
		    // The classic spellings as well as the API 2 ones. An unmigrated desktop project
		    // saved as XML says Window and ContainerControl, and matching only DesktopWindow
		    // left those projects with no windows at all - the same gap the text parser had.
		    item = ParseWindowBlock(node)
		    
		  Case "Menu"
		    item = ParseMenuBlock(node)
		    
		  Case "DesktopToolbar", "Toolbar"
		    item = ParseToolbarBlock(node)
		    
		  Case "FileTypes"
		    item = ParseFileTypesBlock(node)
		    
		  Case "MultiImage"
		    item = ParseMultiImageBlock(node)
		    
		  Case "BuildAutomation"
		    item = ParseBuildAutomationBlock(node)
		    
		  Case "WebSession"
		    // WebSession is just a class with WebSession superclass.
		    item = ParseModuleBlock(node)
		    
		  Case "WebView"
		    item = ParseWebPageBlock(node)
		    
		  Case "BuildStepsList", "BuildProjectStep", "CopyFilesStep", "SignProjectScriptStep", "ExternalScriptStep"
		    // Build steps are handled as children of BuildAutomation.
		    // Store them for later processing.
		    StoreBuildStepBlock(node, blockType, blockId)
		    Return Nil
		    
		  Else
		    // Unknown block type, skip.
		    Return Nil
		  End Select
		  
		  If item <> Nil Then
		    // Store the parent ID for hierarchy building.
		    item.ParentContainerId = GetChildInteger(node, "ObjContainerID")
		    item.GUID = "&h" + Hex(blockId)
		    item.ItemType = blockType
		    
		    // "Module" is the wrapper every code container is written in - IsClass and
		    // IsInterface inside it decide what the item really is - and "ExternalCode" names a
		    // reference rather than a thing. Reporting the wrapper meant a console App with
		    // IsClass=1 and Superclass=ConsoleApplication was labelled (Module).
		    If item IsA XKInterface Then
		      item.ItemType = "Interface"
		    ElseIf item IsA XKClass Then
		      item.ItemType = "Class"
		    ElseIf item IsA XKModule Then
		      item.ItemType = "Module"
		    End If
		    
		    // A reference whose file could not be read keeps the block name, and "ExternalCode" is
		    // Xojo's internal label rather than anything a reader would recognise.
		    If item.ItemType = "ExternalCode" Then item.ItemType = "External item"
		  End If
		  
		  Return item
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573206120426F696C64206175746F6D6174696F6E20626C6F636B2E
		Private Function ParseBuildAutomationBlock(node As XmlNode) As XKBuildAutomation
		  /// Parses a BuildAutomation block.
		  
		  Var ba As New XKBuildAutomation
		  ba.Name = GetChildText(node, "ObjName")
		  
		  Return ba
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573206120636F6E7374616E7420656C656D656E742E
		Private Function ParseConstant(node As XmlNode) As XKConstant
		  /// Parses a Constant element.
		  
		  Var c As New XKConstant
		  c.Name = GetChildText(node, "ItemName")
		  c.Flags = GetItemFlags(node)
		  
		  // The value lives in ItemDef. Only a declaration-based fallback further down was being
		  // read, which XML constants do not have - so every constant in an XML item came back
		  // without its value while the text format showed it.
		  c.DefaultValue = GetChildText(node, "ItemDef")
		  
		  // Set Scope based on Flags.
		  Select Case c.Flags
		  Case &h0
		    c.Scope = "Public"
		  Case &h1
		    c.Scope = "Protected"
		  Case &h21
		    c.Scope = "Private"
		  Else
		    c.Scope = "Public"
		  End Select
		  
		  // Get description.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    If XmlElement(child).Name = "CodeDescription" Then
		      c.Description = DecodeDescription(child)
		      Exit
		    End If
		  Next i
		  
		  // Parse the declaration from ItemSource.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    If XmlElement(child).Name = "ItemSource" Then
		      Var lines() As String = ExtractSourceLines(child)
		      If lines.Count > 0 Then
		        // Parse constant declaration: ConstName As Type = Value
		        Var decl As String = lines(0).Trim
		        
		        Var asPos As Integer = decl.IndexOf(" As ")
		        If asPos >= 0 Then
		          c.Name = decl.Left(asPos).Trim
		          
		          Var afterAs As String = decl.Middle(asPos + 4).Trim
		          Var eqPos As Integer = afterAs.IndexOf(" = ")
		          If eqPos >= 0 Then
		            c.DataType = afterAs.Left(eqPos).Trim
		            c.DefaultValue = afterAs.Middle(eqPos + 3).Trim
		          Else
		            c.DataType = afterAs
		          End If
		        End If
		      End If
		      Exit
		    End If
		  Next i
		  
		  Return c
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320612073696E676C6520636F6E74726F6C20656C656D656E742E
		Private Function ParseControl(node As XmlNode) As XKControl
		  /// Parses a single control element.
		  
		  Var ctrl As New XKControl
		  
		  ctrl.ControlType = GetChildText(node, "ControlClass")
		  ctrl.Name = GetChildText(node, "ItemName")
		  
		  // Parse PropertyVal elements.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    Var elem As XmlElement = XmlElement(child)
		    If elem.Name = "PropertyVal" Then
		      Var attrName As String = elem.GetAttribute("Name")
		      
		      Var attrValue As String = ""
		      If child.FirstChild <> Nil Then
		        attrValue = child.FirstChild.Value
		      End If
		      
		      ctrl.SetAttribute(attrName, attrValue)
		      
		      // Check for Name property which overrides ItemName.
		      If attrName = "Name" And attrValue <> "" Then
		        ctrl.Name = attrValue
		      End If
		    End If
		  Next i
		  
		  Return ctrl
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320616E206576656E7420656C656D656E742028486F6F6B496E7374616E636520666F722077696E646F77732C204576656E7420666F7220636F6E74726F6C73292E
		Private Function ParseEvent(node As XmlNode) As XKEvent
		  /// Parses an event element (HookInstance for windows, Event for controls).
		  
		  Var ev As New XKEvent
		  ev.Name = GetChildText(node, "ItemName")
		  
		  // Parse the code from ItemSource.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    If XmlElement(child).Name = "ItemSource" Then
		      Var lines() As String = ExtractSourceLines(child)
		      If lines.Count > 0 Then
		        // First line is the signature.
		        ParseEventSignature(ev, lines(0))
		        
		        // Remaining lines are code (excluding first and last).
		        Var codeLines() As String
		        For j As Integer = 1 To lines.LastIndex - 1
		          codeLines.Add(lines(j))
		        Next j
		        ev.SetCodeLines(codeLines)
		      End If
		      Exit
		    End If
		  Next i
		  
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

	#tag Method, Flags = &h21, Description = 506172736573207468652073696E676E617475726520666F7220616E206576656E742E
		Private Sub ParseEventSignature(ev As XKEvent, sigLine As String)
		  /// Parses the signature for an event.
		  
		  sigLine = sigLine.Trim
		  
		  // Determine if Function or Sub.
		  If sigLine.BeginsWith("Function ") Then
		    ev.IsFunction = True
		    sigLine = sigLine.Middle(9)
		  ElseIf sigLine.BeginsWith("Sub ") Then
		    ev.IsFunction = False
		    sigLine = sigLine.Middle(4)
		  End If
		  
		  // Extract event name.
		  Var parenPos As Integer = sigLine.IndexOf("(")
		  If parenPos < 0 Then
		    ev.Name = sigLine.Trim
		    Return
		  End If
		  
		  ev.Name = sigLine.Left(parenPos).Trim
		  
		  // Extract parameters.
		  Var closeParenPos As Integer = FindMatchingParen(sigLine, parenPos)
		  If closeParenPos > parenPos Then
		    Var paramStr As String = sigLine.Middle(parenPos + 1, closeParenPos - parenPos - 1)
		    ParseEventParameters(ev, paramStr)
		  End If
		  
		  // Extract return type.
		  If ev.IsFunction Then
		    Var asPos As Integer = sigLine.IndexOf(closeParenPos, " As ")
		    If asPos >= 0 Then
		      Var returnType As String = sigLine.Middle(asPos + 4).Trim
		      // Remove "Handles X.Y" if present.
		      Var handlesPos As Integer = returnType.IndexOf(" Handles ")
		      If handlesPos >= 0 Then
		        returnType = returnType.Left(handlesPos).Trim
		      End If
		      ev.ReturnType = returnType
		    End If
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061206669616C6520747970657320626C6F636B2E
		Private Function ParseFileTypesBlock(node As XmlNode) As XKFileTypeSet
		  /// Parses a FileTypes block.
		  
		  Var fts As New XKFileTypeSet
		  fts.Name = GetChildText(node, "ObjName")
		  
		  // Parse FileType children.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    If XmlElement(child).Name = "FileType" Then
		      Var ft As New XKFileType
		      ft.CodeName = GetChildText(child, "CodeName")
		      // Parse other attributes as needed.
		      For j As Integer = 0 To child.ChildCount - 1
		        Var attrNode As XmlNode = child.Child(j)
		        If Not (attrNode IsA XmlElement) Then Continue
		        If attrNode.FirstChild <> Nil Then
		          ft.SetAttribute(XmlElement(attrNode).Name, attrNode.FirstChild.Value)
		        End If
		      Next j
		      fts.AddFileType(ft)
		    End If
		  Next i
		  
		  Return fts
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573206120466F6C64657220626C6F636B2E
		Private Function ParseFolderBlock(node As XmlNode) As XKFolder
		  /// Parses a Folder block.
		  
		  Var folder As New XKFolder
		  folder.Name = GetChildText(node, "ObjName")
		  
		  Return folder
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061204D656E75206F7220446573746F6F6C626172206D656E7520626C6F636B2E
		Private Function ParseMenuBlock(node As XmlNode) As XKMenuBar
		  /// Parses a Menu block.
		  
		  Var menu As New XKMenuBar
		  menu.Name = GetChildText(node, "ObjName")
		  
		  // Parse MenuItem children.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    If XmlElement(child).Name = "MenuItem" Then
		      Var item As XKMenuItem = ParseMenuItem(child)
		      If item <> Nil Then
		        menu.AddMenuItem(item)
		      End If
		    End If
		  Next i
		  
		  Return menu
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061206D656E7520686E646C657220656C656D656E742E
		Private Function ParseMenuHandler(node As XmlNode) As XKEvent
		  /// Parses a MenuHandler element (treated as an event).
		  
		  Var ev As XKEvent = ParseEvent(node)
		  If ev <> Nil Then
		    ev.IsMenuHandler = True
		  End If
		  Return ev
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320612073696E676C65206D656E75206974656D20616E642069747320730602D6974656D732
		Private Function ParseMenuItem(node As XmlNode) As XKMenuItem
		  /// Parses a single menu item and its sub-items.
		  
		  Var item As New XKMenuItem
		  item.Name = GetChildText(node, "ItemName")
		  item.Text = GetChildText(node, "ItemText")
		  item.MenuItemType = GetChildText(node, "Superclass")
		  
		  // Parse nested MenuItems.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    If XmlElement(child).Name = "MenuItem" Then
		      Var subItem As XKMenuItem = ParseMenuItem(child)
		      If subItem <> Nil Then
		        item.AddSubItem(subItem)
		      End If
		    End If
		  Next i
		  
		  Return item
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061206D6574686F6420656C656D656E742E
		Private Function ParseMethod(node As XmlNode) As XKMethod
		  /// Parses a method element.
		  
		  Var m As New XKMethod
		  m.Name = GetChildText(node, "ItemName")
		  m.Flags = GetItemFlags(node)
		  m.IsShared = GetChildBoolean(node, "IsShared")
		  
		  // Get description.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    If XmlElement(child).Name = "CodeDescription" Then
		      m.Description = DecodeDescription(child)
		      Exit
		    End If
		  Next i
		  
		  // Parse the code from ItemSource.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    If XmlElement(child).Name = "ItemSource" Then
		      Var lines() As String = ExtractSourceLines(child)
		      If lines.Count > 0 Then
		        // First line is the signature.
		        ParseMethodSignature(m, lines(0))
		        
		        // Remaining lines are code (excluding first and last which are signature and End).
		        Var codeLines() As String
		        For j As Integer = 1 To lines.LastIndex - 1
		          codeLines.Add(lines(j))
		        Next j
		        m.SetCodeLines(codeLines)
		      End If
		      Exit
		    End If
		  Next i
		  
		  Return m
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320706172616D65746572732066726F6D206120706172616D6574657220737472696E672E
		Private Sub ParseMethodParameters(m As XKMethod, paramStr As String)
		  /// Parses parameters from a parameter string.
		  
		  If paramStr.Trim = "" Then Return
		  
		  Var params() As String = XKParserUtils.SplitParameters(paramStr)
		  
		  For Each param As String In params
		    Var p As XKParameter = XKParserUtils.ParseSingleParameter(param.Trim)
		    If p <> Nil Then
		      m.AddParameter(p)
		    End If
		  Next param
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061206D6574686F64207369676E6174757265206C696E652E
		Private Sub ParseMethodSignature(m As XKMethod, sigLine As String)
		  /// Parses a method signature line.
		  
		  sigLine = sigLine.Trim
		  
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
		  If sigLine.BeginsWith("Function ") Then
		    m.IsFunction = True
		    sigLine = sigLine.Middle(9)
		  ElseIf sigLine.BeginsWith("Sub ") Then
		    m.IsFunction = False
		    sigLine = sigLine.Middle(4)
		  End If
		  
		  // Extract method name.
		  Var parenPos As Integer = sigLine.IndexOf("(")
		  If parenPos < 0 Then
		    m.Name = sigLine.Trim
		    Return
		  End If
		  
		  m.Name = sigLine.Left(parenPos).Trim
		  
		  // Extract parameters.
		  Var closeParenPos As Integer = FindMatchingParen(sigLine, parenPos)
		  If closeParenPos > parenPos Then
		    Var paramStr As String = sigLine.Middle(parenPos + 1, closeParenPos - parenPos - 1)
		    ParseMethodParameters(m, paramStr)
		  End If
		  
		  // Extract return type.
		  If m.IsFunction Then
		    Var asPos As Integer = sigLine.IndexOf(closeParenPos, " As ")
		    If asPos >= 0 Then
		      m.ReturnType = sigLine.Middle(asPos + 4).Trim
		    End If
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061204D6F64756C6520626C6F636B2C2077686963682063616E20626520612043616C73732C204D6F64756C652C206F7220496E746572666163652E
		Private Function ParseModuleBlock(node As XmlNode) As XKCodeContainer
		  /// Parses a Module block, which can be a Class, Module, or Interface.
		  
		  Var isClass As Boolean = GetChildBoolean(node, "IsClass")
		  Var isInterface As Boolean = GetChildBoolean(node, "IsInterface")
		  
		  Var container As XKCodeContainer
		  
		  If isInterface Then
		    container = New XKInterface
		  ElseIf isClass Then
		    container = New XKClass
		  Else
		    container = New XKModule
		  End If
		  
		  container.Name = GetChildText(node, "ObjName")
		  container.Flags = GetItemFlags(node)
		  container.SuperClassName = GetChildText(node, "Superclass")
		  
		  // Parse interfaces.
		  Var interfacesStr As String = GetChildText(node, "Interfaces")
		  If interfacesStr <> "" Then
		    Var interfaces() As String = interfacesStr.Split(",")
		    For Each iface As String In interfaces
		      container.Interfaces.Add(iface.Trim)
		    Next iface
		  End If
		  
		  // Parse members.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    
		    Select Case XmlElement(child).Name
		    Case "Method"
		      Var m As XKMethod = ParseMethod(child)
		      If m <> Nil Then container.AddMethod(m)
		      
		    Case "Property"
		      Var p As XKProperty = ParseProperty(child)
		      If p <> Nil Then
		        If p.IsComputed Then
		          Var cp As New XKComputedProperty
		          cp.Name = p.Name
		          cp.DataType = p.DataType
		          cp.Flags = p.Flags
		          cp.Description = p.Description
		          cp.HasGetter = (p.GetAccessor <> "")
		          cp.HasSetter = (p.SetAccessor <> "")
		          container.AddComputedProperty(cp)
		        Else
		          container.AddProperty(p)
		        End If
		      End If
		      
		    Case "Constant"
		      Var c As XKConstant = ParseConstant(child)
		      If c <> Nil Then container.AddConstant(c)
		      
		    Case "Note"
		      Var n As XKNote = ParseNote(child)
		      If n <> Nil Then container.AddNote(n)
		      
		    Case "HookInstance"
		      Var ev As XKEvent = ParseEvent(child)
		      If ev <> Nil Then container.AddEvent(ev)
		      
		    Case "ViewProperty"
		      Var vp As XKViewProperty = ParseViewProperty(child)
		      If vp <> Nil Then container.AddViewProperty(vp)
		      
		    End Select
		  Next i
		  
		  Return container
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320616E206D756C74694D696D616765206F7220496D61676520626C6F636B2E
		Private Function ParseMultiImageBlock(node As XmlNode) As XKMultiImage
		  /// Parses a MultiImage block.
		  
		  Var img As New XKMultiImage
		  img.Name = GetChildText(node, "ObjName")
		  
		  // TODO: Parse image representations if needed.
		  
		  Return img
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061206E6F746520656C656D656E742E
		Private Function ParseNote(node As XmlNode) As XKNote
		  /// Parses a note element.
		  
		  Var n As New XKNote
		  n.Name = GetChildText(node, "ItemName")
		  
		  // Parse the content from ItemSource.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    If XmlElement(child).Name = "ItemSource" Then
		      Var lines() As String = ExtractSourceLines(child)
		      n.Content = String.FromArray(lines, EndOfLine)
		      Exit
		    End If
		  Next i
		  
		  Return n
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 506172736573206120586F6A6F2070726F6A6563742066726F6D2074686520737065636966696564202E786F6A6F5F786D6C5F70726F6A6563742066696C6520706174682E
		Function ParseProject(projectFilePath As String) As XKProject
		  /// Parses a Xojo project from the specified .xojo_xml_project file path.
		  ///
		  /// Returns the parsed XKProject node representing the entire project tree,
		  /// or Nil if parsing fails.
		  
		  // Validate the file exists.
		  Var f As FolderItem = New FolderItem(projectFilePath, FolderItem.PathModes.Native)
		  If f = Nil Or Not f.Exists Then
		    mLastError = "Project file not found: " + projectFilePath
		    Return Nil
		  End If
		  
		  // Store the project file path.
		  mProjectFilePath = projectFilePath
		  
		  // Read the file contents.
		  Var content As String = XKParserUtils.ReadFileContents(f)
		  If content = "" Then
		    mLastError = "Could not read project file: " + projectFilePath
		    Return Nil
		  End If
		  
		  // Parse as XML.
		  Var doc As XmlDocument
		  Try
		    doc = New XmlDocument(content)
		  Catch e As XmlException
		    mLastError = "XML parsing error: " + e.Message
		    Return Nil
		  End Try
		  
		  // Initialize blocks dictionary and build step storage.
		  mBlocksById = New Dictionary
		  Redim mBuildStepBlocks(-1)
		  
		  // Find the root RBProject element.
		  Var root As XmlNode = doc.DocumentElement
		  If root = Nil Or root.Name <> "RBProject" Then
		    mLastError = "Invalid XML project format: missing RBProject element"
		    Return Nil
		  End If
		  
		  // Find and parse the Project block.
		  Var project As XKProject
		  
		  For i As Integer = 0 To root.ChildCount - 1
		    Var child As XmlNode = root.Child(i)
		    
		    // Only process element nodes.
		    If Not (child IsA XmlElement) Then Continue
		    
		    Var elem As XmlElement = XmlElement(child)
		    If elem.Name = "block" Then
		      Var blockType As String = elem.GetAttribute("type")
		      
		      If blockType = "Project" Then
		        project = ParseProjectBlock(elem)
		        Exit
		      End If
		    End If
		  Next i
		  
		  If project = Nil Then
		    mLastError = "Project block not found"
		    Return Nil
		  End If
		  
		  project.ProjectFilePath = projectFilePath
		  project.SourceFile = projectFilePath
		  
		  // Extract project name from filename.
		  Var filename As String = f.Name
		  If filename.EndsWith(".xojo_xml_project") Then
		    project.Name = filename.Left(filename.Length - 17)
		  Else
		    project.Name = filename
		  End If
		  
		  // Parse all other blocks.
		  For i As Integer = 0 To root.ChildCount - 1
		    Var child As XmlNode = root.Child(i)
		    
		    // Only process element nodes.
		    If Not (child IsA XmlElement) Then Continue
		    
		    Var elem As XmlElement = XmlElement(child)
		    If elem.Name = "block" Then
		      Var blockType As String = elem.GetAttribute("type")
		      Var idStr As String = elem.GetAttribute("ID")
		      Var blockId As Integer = Val(idStr)
		      
		      If blockType = "Project" Then Continue // Already parsed.
		      
		      Var item As XKProjectItem = ParseBlock(elem, blockType, blockId)
		      If item <> Nil Then
		        item.SourceFile = projectFilePath
		        mBlocksById.Value(blockId) = item
		        project.RegisterItem(item)
		      End If
		    End If
		  Next i
		  
		  // Build the hierarchy.
		  BuildHierarchy(project)
		  
		  // Build the build automation hierarchy.
		  BuildBuildAutomationHierarchy()
		  
		  Return project
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573207468652050726F6A65637420626C6F636B2E
		Private Function ParseProjectBlock(node As XmlNode) As XKProject
		  /// Parses the Project block.
		  
		  Var project As New XKProject
		  
		  // Parse project settings - only process element nodes.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    
		    // Skip non-element nodes.
		    If Not (child IsA XmlElement) Then Continue
		    
		    Var elem As XmlElement = XmlElement(child)
		    Var name As String = elem.Name
		    Var value As String = ""
		    If elem.FirstChild <> Nil Then
		      value = elem.FirstChild.Value
		    End If
		    
		    project.SetSetting(name, value)
		    
		    Select Case name
		    Case "ProjectType"
		      project.ProjectType = value
		    Case "ProjectSavedInVers"
		      project.RBProjectVersion = value
		    Case "IDEVersion"
		      project.OrigIDEVersion = value
		    End Select
		  Next i
		  
		  Return project
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 5061727365732061207072706F70657274656C657320656C656D656E742E
		Private Function ParseProperty(node As XmlNode) As XKProperty
		  /// Parses a property element.
		  
		  Var p As New XKProperty
		  p.Name = GetChildText(node, "ItemName")
		  p.Flags = GetItemFlags(node)
		  p.IsShared = GetChildBoolean(node, "IsShared")
		  
		  // ItemName carries the array marker - "profileStack()" - and so does the declaration.
		  // Neither was reaching the output, so an array property read as a scalar: a caller was
		  // told profileStack holds one TUProfileData rather than a list of them.
		  If p.Name.IndexOf("()") >= 0 Then
		    p.IsArray = True
		    p.Name = p.Name.ReplaceAll("()", "")
		  End If
		  
		  // Get description.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    If XmlElement(child).Name = "CodeDescription" Then
		      p.Description = DecodeDescription(child)
		      Exit
		    End If
		  Next i
		  
		  // Check for computed property (GetAccessor/SetAccessor).
		  Var getAccessor As String = GetChildText(node, "GetAccessor")
		  Var setAccessor As String = GetChildText(node, "SetAccessor")
		  If getAccessor <> "" Or setAccessor <> "" Then
		    p.IsComputed = True
		    p.GetAccessor = getAccessor
		    p.SetAccessor = setAccessor
		  End If
		  
		  // Parse the declaration from ItemDeclaration or ItemSource.
		  Var declaration As String = GetChildText(node, "ItemDeclaration")
		  If declaration = "" Then
		    For i As Integer = 0 To node.ChildCount - 1
		      Var child As XmlNode = node.Child(i)
		      If Not (child IsA XmlElement) Then Continue
		      If XmlElement(child).Name = "ItemSource" Then
		        Var lines() As String = ExtractSourceLines(child)
		        If lines.Count > 0 Then
		          declaration = lines(0)
		        End If
		        Exit
		      End If
		    Next i
		  End If
		  
		  If declaration <> "" Then
		    ParsePropertyDeclaration(p, declaration)
		  End If
		  
		  Return p
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320612070726F7065727479206465636C61726174696F6E20737472696E672E
		Private Sub ParsePropertyDeclaration(p As XKProperty, declaration As String)
		  /// Parses a property declaration string.
		  
		  declaration = declaration.Trim
		  
		  // Check for array syntax.
		  If declaration.IndexOf("()") >= 0 Then
		    p.IsArray = True
		    declaration = declaration.ReplaceAll("()", "")
		  End If
		  
		  // Parse: PropertyName As PropertyType [= DefaultValue]
		  Var asPos As Integer = declaration.IndexOf(" As ")
		  If asPos < 0 Then
		    p.Name = declaration
		    Return
		  End If
		  
		  p.Name = declaration.Left(asPos).Trim
		  
		  Var afterAs As String = declaration.Middle(asPos + 4).Trim
		  
		  // Check for default value.
		  Var eqPos As Integer = afterAs.IndexOf(" = ")
		  If eqPos >= 0 Then
		    p.DataType = afterAs.Left(eqPos).Trim
		    p.DefaultValue = afterAs.Middle(eqPos + 3).Trim
		  Else
		    p.DataType = afterAs
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573206120546F6F6C62617220626C6F636B2E
		Private Function ParseToolbarBlock(node As XmlNode) As XKToolbar
		  /// Parses a Toolbar block.
		  
		  Var toolbar As New XKToolbar
		  toolbar.Name = GetChildText(node, "ObjName")
		  toolbar.SuperClassName = GetChildText(node, "Superclass")
		  
		  // Parse ToolbarButton children.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    If XmlElement(child).Name = "ToolbarItem" Then
		      Var btn As New XKToolbarButton
		      btn.Name = GetChildText(child, "ItemName")
		      btn.Caption = GetChildText(child, "Caption")
		      btn.Tooltip = GetChildText(child, "Tooltip")
		      btn.ButtonType = GetChildText(child, "Superclass")
		      toolbar.AddButton(btn)
		    End If
		  Next i
		  
		  Return toolbar
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320612056696557506F70657274792065656D656E742E
		Private Function ParseViewProperty(node As XmlNode) As XKViewProperty
		  /// Parses a ViewProperty element.
		  
		  Var vp As New XKViewProperty
		  vp.Name = GetChildText(node, "Name")
		  vp.Visible = GetChildBoolean(node, "Visible")
		  vp.Group = GetChildText(node, "Group")
		  vp.InitialValue = GetChildText(node, "InitialValue")
		  vp.DataType = GetChildText(node, "Type")
		  vp.EditorType = GetChildText(node, "EditorType")
		  
		  Return vp
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 506172736573206120576562506167652028576562566965772920626C6F636B2E
		Private Function ParseWebPageBlock(node As XmlNode) As XKWebPage
		  /// Parses a WebPage block.
		  
		  Var webPage As New XKWebPage
		  webPage.Name = GetChildText(node, "ObjName")
		  webPage.SuperClassName = GetChildText(node, "Superclass")
		  webPage.Flags = GetItemFlags(node)
		  
		  // Check if it's a container.
		  Var superClass As String = webPage.SuperClassName
		  webPage.IsContainer = (superClass.IndexOf("Container") >= 0)
		  
		  // Parse interfaces.
		  Var interfacesStr As String = GetChildText(node, "Interfaces")
		  If interfacesStr <> "" Then
		    Var interfaces() As String = interfacesStr.Split(",")
		    For Each iface As String In interfaces
		      webPage.Interfaces.Add(iface.Trim)
		    Next iface
		  End If
		  
		  // Parse members and controls.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    
		    Select Case XmlElement(child).Name
		    Case "Method"
		      Var m As XKMethod = ParseMethod(child)
		      If m <> Nil Then webPage.AddMethod(m)
		      
		    Case "Property"
		      Var p As XKProperty = ParseProperty(child)
		      If p <> Nil Then webPage.AddProperty(p)
		      
		    Case "HookInstance"
		      Var ev As XKEvent = ParseEvent(child)
		      If ev <> Nil Then webPage.AddEvent(ev)
		      
		    Case "MenuHandler"
		      Var ev As XKEvent = ParseMenuHandler(child)
		      If ev <> Nil Then webPage.AddEvent(ev)
		      
		    Case "Control"
		      Var ctrl As XKControl = ParseControl(child)
		      If ctrl <> Nil Then webPage.AddControl(ctrl)
		      
		    Case "ViewProperty"
		      Var vp As XKViewProperty = ParseViewProperty(child)
		      If vp <> Nil Then webPage.AddViewProperty(vp)
		      
		    End Select
		  Next i
		  
		  // Build control hierarchy.
		  BuildWebPageControlHierarchy(webPage)
		  
		  Return webPage
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 50617273657320612057696E646F7720626C6F636B2E
		Private Function ParseWindowBlock(node As XmlNode) As XKWindow
		  /// Parses a DesktopWindow block.
		  
		  Var window As New XKWindow
		  window.Name = GetChildText(node, "ObjName")
		  window.SuperClassName = GetChildText(node, "Superclass")
		  window.Flags = GetItemFlags(node)
		  
		  // Check if it's a container.
		  Var superClass As String = window.SuperClassName
		  window.IsContainer = (superClass.IndexOf("Container") >= 0)
		  
		  // Parse interfaces.
		  Var interfacesStr As String = GetChildText(node, "Interfaces")
		  If interfacesStr <> "" Then
		    Var interfaces() As String = interfacesStr.Split(",")
		    For Each iface As String In interfaces
		      window.Interfaces.Add(iface.Trim)
		    Next iface
		  End If
		  
		  // Parse members and controls.
		  For i As Integer = 0 To node.ChildCount - 1
		    Var child As XmlNode = node.Child(i)
		    If Not (child IsA XmlElement) Then Continue
		    
		    Select Case XmlElement(child).Name
		    Case "Method"
		      Var m As XKMethod = ParseMethod(child)
		      If m <> Nil Then window.AddMethod(m)
		      
		    Case "Property"
		      Var p As XKProperty = ParseProperty(child)
		      If p <> Nil Then window.AddProperty(p)
		      
		    Case "HookInstance"
		      Var ev As XKEvent = ParseEvent(child)
		      If ev <> Nil Then window.AddEvent(ev)
		      
		    Case "MenuHandler"
		      Var ev As XKEvent = ParseMenuHandler(child)
		      If ev <> Nil Then window.AddEvent(ev)
		      
		    Case "Control"
		      Var ctrl As XKControl = ParseControl(child)
		      If ctrl <> Nil Then window.AddControl(ctrl)
		      
		    Case "ViewProperty"
		      Var vp As XKViewProperty = ParseViewProperty(child)
		      If vp <> Nil Then window.AddViewProperty(vp)
		      
		    Case "Constant"
		      Var c As XKConstant = ParseConstant(child)
		      If c <> Nil Then window.AddConstant(c)
		      
		    End Select
		  Next i
		  
		  // Build control hierarchy.
		  BuildControlHierarchy(window)
		  
		  Return window
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21, Description = 53746F7265732061206275696C6420737465702073746E642072656C6174656420626C6F636B20666F72206C617465722070726F63657373696E672E
		Private Sub StoreBuildStepBlock(node As XmlNode, blockType As String, blockId As Integer)
		  /// Stores a build step block for later processing.
		  
		  Var info As New Dictionary
		  info.Value("node") = node
		  info.Value("blockType") = blockType
		  info.Value("blockId") = blockId
		  info.Value("parentId") = GetChildInteger(node, "ObjContainerID")
		  info.Value("name") = GetChildText(node, "ObjName")
		  
		  mBuildStepBlocks.Add(New Pair(blockId, info))
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mBlocksById As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mBuildStepBlocks() As Pair
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastError As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mProjectFilePath As String
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
