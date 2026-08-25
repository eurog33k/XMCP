#tag Class
Protected Class XKImageRepresentation
Inherits XKNode
	#tag Method, Flags = &h0
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new image representation with the specified parent.
		  
		  Super.Constructor(parent)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return "ImageRepresentation"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToDebugString(indent As Integer = 0) As String
		  /// Returns a debug representation of this node.
		  
		  Var prefix As String = ""
		  For i As Integer = 1 To indent
		    prefix = prefix + "  "
		  Next i
		  
		  Var result As String = prefix
		  
		  If HSize > 0 And VSize > 0 Then
		    result = result + HSize.ToString(Locale.Raw, "0") + "x" + VSize.ToString(Locale.Raw, "0")
		  Else
		    result = result + "(not set)"
		  End If
		  
		  result = result + " @" + PPI.ToString + "ppi"
		  
		  If HasImageData Then
		    result = result + " [has data]"
		  Else
		    result = result + " [no data]"
		  End If
		  
		  Return result
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		Comment As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Device As Integer = 31
	#tag EndProperty

	#tag Property, Flags = &h0
		FullPath As String
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  /// Returns True if this representation has actual image data.
			  
			  Return SaveInfo <> ""
			End Get
		#tag EndGetter
		HasImageData As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		HSize As Double = -1
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  /// Returns a name for this image representation based on its path or dimensions.
			  
			  If PartialPath <> "" Then
			    Return PartialPath
			  ElseIf HSize > 0 And VSize > 0 Then
			    Return HSize.ToString(Locale.Raw, "0") + "x" + VSize.ToString(Locale.Raw, "0") + "@" + PPI.ToString + "ppi"
			  Else
			    Return NodeTypeName
			  End If
			End Get
		#tag EndGetter
		Name As String
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		Orientation As String = "Any"
	#tag EndProperty

	#tag Property, Flags = &h0
		PartialPath As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Platform As Integer = 15
	#tag EndProperty

	#tag Property, Flags = &h0
		PPI As Integer = 72
	#tag EndProperty

	#tag Property, Flags = &h0
		SaveInfo As String
	#tag EndProperty

	#tag Property, Flags = &h0
		VSize As Double = -1
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
			Name="SaveInfo"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="FullPath"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="PartialPath"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="HSize"
			Visible=false
			Group="Behavior"
			InitialValue="-1"
			Type="Double"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="VSize"
			Visible=false
			Group="Behavior"
			InitialValue="-1"
			Type="Double"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="PPI"
			Visible=false
			Group="Behavior"
			InitialValue="72"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Device"
			Visible=false
			Group="Behavior"
			InitialValue="31"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Platform"
			Visible=false
			Group="Behavior"
			InitialValue="15"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Orientation"
			Visible=false
			Group="Behavior"
			InitialValue="Any"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Comment"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="HasImageData"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
