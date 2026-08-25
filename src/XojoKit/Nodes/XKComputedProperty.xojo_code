#tag Class
Protected Class XKComputedProperty
Inherits XKNode
	#tag Method, Flags = &h0
		Function AccessModifierName() As String
		  /// Returns the access modifier flags as a human-readable string (Public, Protected, Private, etc.).
		  
		  Select Case Flags
		  Case &h0
		    Return "Public"
		    
		  Case &h1
		    Return "Protected"
		    
		  Case &h21
		    Return "Private"
		    
		  Else
		    Return "Unknown (" + Flags.ToString + ")"
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new computed property with the specified parent.
		  
		  Super.Constructor(parent)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return "ComputedProperty"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToDebugString(indent As Integer = 0) As String
		  /// Returns a debug representation of this node.
		  
		  Var prefix As String = ""
		  For i As Integer = 1 To indent
		    prefix = prefix + "  "
		  Next i
		  
		  Var result As String = prefix + AccessModifierName + " " + Name + " As " + DataType + " (computed)"
		  
		  Var parts() As String
		  If HasGetter Then parts.Add("get")
		  If HasSetter Then parts.Add("set")
		  If parts.Count > 0 Then
		    result = result + " [" + String.FromArray(parts, ", ") + "]"
		  End If
		  
		  If Description <> "" Then
		    result = result + "  // " + Description
		  End If
		  
		  Return result
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		DataType As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Description As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Flags As Integer = 0
	#tag EndProperty

	#tag Property, Flags = &h0
		GetterCode() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		HasGetter As Boolean = False
	#tag EndProperty

	#tag Property, Flags = &h0
		HasSetter As Boolean = False
	#tag EndProperty

	#tag Property, Flags = &h0
		Name As String
	#tag EndProperty

	#tag Property, Flags = &h0
		SetterCode() As String
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
			Name="Flags"
			Visible=false
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataType"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="HasGetter"
			Visible=false
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="HasSetter"
			Visible=false
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
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
