#tag Class
Protected Class XKNode
	#tag Method, Flags = &h0
		Sub Accept(visitor As XKVisitor)
		  /// Accepts a visitor and calls the appropriate Visit method.
		  /// This uses introspection to determine the concrete type and dispatch accordingly.
		  /// Subclasses may override this for more efficient dispatch.
		  
		  Var typeName As String = Introspection.GetType(Self).Name
		  
		  Select Case typeName
		  Case "XKProject"
		    visitor.VisitProject(XKProject(Self))
		    
		  Case "XKFolder"
		    visitor.VisitFolder(XKFolder(Self))
		    
		  Case "XKClass"
		    visitor.VisitClass(XKClass(Self))
		    
		  Case "XKModule"
		    visitor.VisitModule(XKModule(Self))
		    
		  Case "XKInterface"
		    visitor.VisitInterface(XKInterface(Self))
		    
		  Case "XKWindow"
		    visitor.VisitWindow(XKWindow(Self))
		    
		  Case "XKMenuBar"
		    visitor.VisitMenuBar(XKMenuBar(Self))
		    
		  Case "XKMenuItem"
		    visitor.VisitMenuItem(XKMenuItem(Self))
		    
		  Case "XKToolbar"
		    visitor.VisitToolbar(XKToolbar(Self))
		    
		  Case "XKToolbarButton"
		    visitor.VisitToolbarButton(XKToolbarButton(Self))
		    
		  Case "XKMultiImage"
		    visitor.VisitMultiImage(XKMultiImage(Self))
		    
		  Case "XKImageRepresentation"
		    visitor.VisitImageRepresentation(XKImageRepresentation(Self))
		    
		  Case "XKFileTypeSet"
		    visitor.VisitFileTypeSet(XKFileTypeSet(Self))
		    
		  Case "XKFileType"
		    visitor.VisitFileType(XKFileType(Self))
		    
		  Case "XKMethod"
		    visitor.VisitMethod(XKMethod(Self))
		    
		  Case "XKEvent"
		    visitor.VisitEvent(XKEvent(Self))
		    
		  Case "XKProperty"
		    visitor.VisitProperty(XKProperty(Self))
		    
		  Case "XKComputedProperty"
		    visitor.VisitComputedProperty(XKComputedProperty(Self))
		    
		  Case "XKConstant"
		    visitor.VisitConstant(XKConstant(Self))
		    
		  Case "XKConstantInstance"
		    visitor.VisitConstantInstance(XKConstantInstance(Self))
		    
		  Case "XKEnum"
		    visitor.VisitEnum(XKEnum(Self))
		    
		  Case "XKEnumValue"
		    visitor.VisitEnumValue(XKEnumValue(Self))
		    
		  Case "XKParameter"
		    visitor.VisitParameter(XKParameter(Self))
		    
		  Case "XKNote"
		    visitor.VisitNote(XKNote(Self))
		    
		  Case "XKControl"
		    visitor.VisitControl(XKControl(Self))
		    
		  Case "XKViewProperty"
		    visitor.VisitViewProperty(XKViewProperty(Self))
		    
		  Case "XKControlEventGroup"
		    visitor.VisitControlEventGroup(XKControlEventGroup(Self))
		    
		  Case "XKBuildStepList"
		    visitor.VisitBuildStepList(XKBuildStepList(Self))
		    
		  Case "XKBuildStep"
		    visitor.VisitBuildStep(XKBuildStep(Self))
		    
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddChild(child As XKNode)
		  /// Adds a child node to this node's children.
		  
		  If child <> Nil Then
		    mChildren.Add(child)
		    child.mParent = Self
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Children() As XKNode()
		  /// Returns the children of this node.
		  
		  Return mChildren
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new node with the specified parent.
		  
		  mParent = parent
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 46696E64732061206E6F646520627920697473204E6F64654964207265637572736976656C792E204D61792072657475726E204E696C2E
		Function FindNode(nodeId As String) As XKNode
		  /// Finds a node by its NodeId recursively.
		  /// May return Nil.
		  
		  If Self.NodeId = nodeId Then Return Self
		  
		  // Optimization: Only search children that match the path prefix.
		  // Parse the current node's path.
		  Var myPath As String = Self.NodeId
		  Var colonIndex As Integer = myPath.IndexOf(":")
		  If colonIndex > -1 Then
		    myPath = myPath.Left(colonIndex)
		  End If
		  
		  // Parse the target path.
		  Var targetPath As String = nodeId
		  colonIndex = targetPath.IndexOf(":")
		  If colonIndex > -1 Then
		    targetPath = targetPath.Left(colonIndex)
		  End If
		  
		  // Optimization check: target path must start with my path + "."
		  // Or be exactly my path (but that case is handled at the start).
		  
		  // If target path is shorter than my path, it can't be a child.
		  If targetPath.Length <= myPath.Length Then Return Nil
		  
		  // If target path doesn't start with my path followed by dot, it's not in this branch.
		  If targetPath.IndexOf(myPath + ".") <> 0 Then Return Nil
		  
		  For Each child As XKNode In mChildren
		    Var result As XKNode = child.FindNode(nodeId)
		    If result <> Nil Then Return result
		  Next child
		  
		  Return Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsLastChild() As Boolean
		  /// Returns True if this is the last child of its parent.
		  
		  If mParent = Nil Then Return True
		  
		  Var siblings() As XKNode = mParent.Children
		  If siblings.Count = 0 Then Return True
		  
		  Var lastChild As XKNode = siblings(siblings.LastIndex)
		  Return lastChild Is Self
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  // Subclasses should override this.
		  Return "XKNode"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToDebugString(indent As Integer = 0) As String
		  /// Returns a debug representation of this node.
		  
		  // Subclasses should override to provide more detail.
		  
		  Var prefix As String = ""
		  For i As Integer = 1 To indent
		    prefix = prefix + "  "
		  Next i
		  
		  Return prefix + NodeTypeName
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  /// Returns a display name for this node by finding the Name property via introspection.
			  /// This avoids shadowing issues that crash the Xojo debugger.
			  
			  Var ti As Introspection.TypeInfo = Introspection.GetType(Self)
			  For Each prop As Introspection.PropertyInfo In ti.GetProperties
			    If prop.Name = "Name" And prop.IsPublic Then
			      Var value As Variant = prop.Value(Self)
			      If value <> Nil Then
			        Return value.StringValue
			      End If
			    End If
			  Next prop
			  Return NodeTypeName
			End Get
		#tag EndGetter
		DisplayName As String
	#tag EndComputedProperty

	#tag Property, Flags = &h1
		Protected mChildren() As XKNode
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mNodeId As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mParent As XKNode
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  /// Returns a unique hierarchical identifier for this node.
			  /// Format: ProjectName.Folder.ClassName:Type
			  /// Generates one on first access if not already set.
			  
			  If mNodeId = "" Then
			    // Build path components by walking up the parent chain.
			    Var pathComponents() As String
			    Var current As XKNode = Self
			    
			    While current <> Nil
			      pathComponents.Add(current.DisplayName)
			      current = current.Parent
			    Wend
			    
			    // Reverse to get root-to-leaf order.
			    Var reversedPath() As String
			    For i As Integer = pathComponents.LastIndex DownTo 0
			      reversedPath.Add(pathComponents(i))
			    Next i
			    
			    // Build the ID.
			    Var basePath As String = String.FromArray(reversedPath, ".")
			    
			    // Project nodes don't get a type suffix.
			    If Self IsA XKProject Then
			      mNodeId = basePath
			    Else
			      mNodeId = basePath + ":" + NodeTypeName
			    End If
			  End If
			  Return mNodeId
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  /// Sets the unique node identifier.
			  
			  mNodeId = value
			End Set
		#tag EndSetter
		NodeId As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  /// The optional parent node.
			  
			  Return mParent
			End Get
		#tag EndGetter
		Parent As XKNode
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		SourceFile As String
	#tag EndProperty

	#tag Property, Flags = &h0
		SourceLine As Integer = 0
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
		#tag ViewProperty
			Name="SourceFile"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="SourceLine"
			Visible=false
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="DisplayName"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="NodeId"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
