#tag Class
Protected Class XKFileType
Inherits XKNode
	#tag Method, Flags = &h0, Description = 52657475726E732074686520617474726962757465732064696374696F6E6172792E
		Function AllAttributes() As Dictionary
		  /// Returns the attributes dictionary.
		  
		  Return mAttributes
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 437265617465732061206E65772066696C6520747970652077697468207468652073706563696669656420706172656E742E
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new file type with the specified parent.
		  
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
		  
		  Return "FileType"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 5365747320616E206174747269627574652E
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
		  
		  Var result As String = prefix + CodeName
		  
		  Var ext As String = GetAttribute("Extension", "")
		  If ext <> "" Then
		    result = result + " (" + ext + ")"
		  End If
		  
		  Var mimeType As String = GetAttribute("MimeType", "")
		  If mimeType <> "" Then
		    result = result + " [" + mimeType + "]"
		  End If
		  
		  Return result
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		CodeName As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mAttributes As Dictionary
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  /// Returns the code name as the name for this file type.
			  
			  Return CodeName
			End Get
		#tag EndGetter
		Name As String
	#tag EndComputedProperty


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
			Name="CodeName"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
