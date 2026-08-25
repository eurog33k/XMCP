#tag Class
Protected Class XKParameter
Inherits XKNode
	#tag Method, Flags = &h0
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new parameter with the specified parent.
		  
		  Super.Constructor(parent)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return "Parameter"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToSignatureString() As String
		  /// Returns the parameter in signature notation (e.g. ByRef name As Type).
		  
		  Var result As String = ""
		  
		  // Modifiers.
		  If IsByRef Then
		    result = result + "ByRef "
		  ElseIf IsOptional Then
		    result = result + "Optional "
		  ElseIf IsParamArray Then
		    result = result + "ParamArray "
		  End If
		  
		  // Name.
		  result = result + Name
		  
		  // Array indicator.
		  If IsArray Then
		    result = result + "()"
		  End If
		  
		  // Type.
		  result = result + " As " + DataType
		  
		  // Default value.
		  If IsOptional And DefaultValue <> "" Then
		    result = result + " = " + DefaultValue
		  End If
		  
		  Return result
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		DataType As String
	#tag EndProperty

	#tag Property, Flags = &h0
		DefaultValue As String
	#tag EndProperty

	#tag Property, Flags = &h0
		IsArray As Boolean = False
	#tag EndProperty

	#tag Property, Flags = &h0
		IsByRef As Boolean = False
	#tag EndProperty

	#tag Property, Flags = &h0
		IsOptional As Boolean = False
	#tag EndProperty

	#tag Property, Flags = &h0
		IsParamArray As Boolean = False
	#tag EndProperty

	#tag Property, Flags = &h0
		Name As String
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
			Name="DataType"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsByRef"
			Visible=false
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsOptional"
			Visible=false
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="DefaultValue"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsParamArray"
			Visible=false
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsArray"
			Visible=false
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
