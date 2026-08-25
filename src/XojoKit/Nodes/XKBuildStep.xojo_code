#tag Class
Protected Class XKBuildStep
Inherits XKNode
	#tag Method, Flags = &h0
		Function AllAttributes() As Dictionary
		  /// Returns the attributes dictionary.
		  
		  Return mAttributes
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new build step with the specified parent.
		  
		  Super.Constructor(parent)
		  
		  mAttributes = New Dictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetAttribute(key As String, defaultValue As String = "") As String
		  /// Gets an attribute by key.
		  
		  If mAttributes.HasKey(key) Then
		    Return mAttributes.Value(key).StringValue
		  Else
		    Return defaultValue
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return StepType
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetAttribute(key As String, value As String)
		  /// Sets an attribute.
		  
		  mAttributes.Value(key) = value
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToDebugString(indent As Integer = 0) As String
		  /// Returns a debug representation of this node.
		  
		  Var prefix As String = ""
		  For i As Integer = 1 To indent
		    prefix = prefix + "  "
		  Next i
		  
		  Var result As String = prefix + StepType + " " + Name
		  
		  Return result
		End Function
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected mAttributes As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h0
		Name As String
	#tag EndProperty

	#tag Property, Flags = &h0
		StepType As String
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
			Name="StepType"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
