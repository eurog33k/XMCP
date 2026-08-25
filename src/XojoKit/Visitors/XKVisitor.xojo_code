#tag Interface
Protected Interface XKVisitor
	#tag Method, Flags = &h0
		Sub VisitBuildStep(node As XKBuildStep)
		  /// Called when visiting an XKBuildStep node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitBuildStepList(node As XKBuildStepList)
		  /// Called when visiting an XKBuildStepList node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitClass(node As XKClass)
		  /// Called when visiting an XKClass node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitComputedProperty(node As XKComputedProperty)
		  /// Called when visiting an XKComputedProperty node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitConstant(node As XKConstant)
		  /// Called when visiting an XKConstant node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitConstantInstance(node As XKConstantInstance)
		  /// Called when visiting an XKConstantInstance node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitControl(node As XKControl)
		  /// Called when visiting an XKControl node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitControlEventGroup(node As XKControlEventGroup)
		  /// Called when visiting an XKControlEventGroup node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitEnum(node As XKEnum)
		  /// Called when visiting an XKEnum node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitEnumValue(node As XKEnumValue)
		  /// Called when visiting an XKEnumValue node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitEvent(node As XKEvent)
		  /// Called when visiting an XKEvent node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitFileType(node As XKFileType)
		  /// Called when visiting an XKFileType node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitFileTypeSet(node As XKFileTypeSet)
		  /// Called when visiting an XKFileTypeSet node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitFolder(node As XKFolder)
		  /// Called when visiting an XKFolder node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitImageRepresentation(node As XKImageRepresentation)
		  /// Called when visiting an XKImageRepresentation node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitInterface(node As XKInterface)
		  /// Called when visiting an XKInterface node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitMenuBar(node As XKMenuBar)
		  /// Called when visiting an XKMenuBar node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitMenuItem(node As XKMenuItem)
		  /// Called when visiting an XKMenuItem node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitMethod(node As XKMethod)
		  /// Called when visiting an XKMethod node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitModule(node As XKModule)
		  /// Called when visiting an XKModule node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitMultiImage(node As XKMultiImage)
		  /// Called when visiting an XKMultiImage node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitNote(node As XKNote)
		  /// Called when visiting an XKNote node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitParameter(node As XKParameter)
		  /// Called when visiting an XKParameter node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitProject(node As XKProject)
		  /// Called when visiting an XKProject node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitProperty(node As XKProperty)
		  /// Called when visiting an XKProperty node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitToolbar(node As XKToolbar)
		  /// Called when visiting an XKToolbar node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitToolbarButton(node As XKToolbarButton)
		  /// Called when visiting an XKToolbarButton node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitViewProperty(node As XKViewProperty)
		  /// Called when visiting an XKViewProperty node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitWebPage(node As XKWebPage)
		  /// Called when visiting an XKWebPage node.
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VisitWindow(node As XKWindow)
		  /// Called when visiting an XKWindow node.
		End Sub
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
	#tag EndViewBehavior
End Interface
#tag EndInterface
