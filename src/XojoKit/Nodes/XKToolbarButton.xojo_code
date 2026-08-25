#tag Class
Protected Class XKToolbarButton
Inherits XKNode
	#tag Method, Flags = &h0, Description = 52657475726E732074686520617474726962757465732064696374696F6E6172792E
		Function AllAttributes() As Dictionary
		  /// Returns the attributes dictionary.
		  
		  Return mAttributes
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 437265617465732061206E657720746F6F6C62617220627574746F6E2077697468207468652073706563696669656420706172656E742E
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new toolbar button with the specified parent.
		  
		  Super.Constructor(parent)
		  
		  mAttributes = New Dictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 4765747320616E20617474726962757465206279206B65792E
		Function GetAttribute(key As String, defaultValue As String = "") As String
		  /// Gets an attribute by key.
		  
		  If mAttributes.HasKey(key) Then
		    Return mAttributes.Value(key).StringValue
		  Else
		    Return defaultValue
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E73207468652074797065206E616D65206F662074686973206E6F64652E
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return ButtonType
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 5365747320616E206174747269627574652E
		Sub SetAttribute(key As String, value As String)
		  /// Sets an attribute.
		  
		  mAttributes.Value(key) = value
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E73206120646562756720726570726573656E746174696F6E206F662074686973206E6F64652E
		Function ToDebugString(indent As Integer = 0) As String
		  /// Returns a debug representation of this node.
		  
		  Var prefix As String = ""
		  For i As Integer = 1 To indent
		    prefix = prefix + "  "
		  Next i
		  
		  Var result As String = prefix + ButtonType + " " + Name
		  
		  If Caption <> "" Then
		    result = result + " """ + Caption + """"
		  End If
		  
		  If Tooltip <> "" Then
		    result = result + " (" + Tooltip + ")"
		  End If
		  
		  Return result
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		ButtonType As String = "DesktopToolbarButton"
	#tag EndProperty

	#tag Property, Flags = &h0
		Caption As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mAttributes As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h0
		Name As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Tooltip As String
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
			Name="ButtonType"
			Visible=false
			Group="Behavior"
			InitialValue="DesktopToolbarButton"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Caption"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Tooltip"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
