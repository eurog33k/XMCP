#tag Class
Protected Class XKMultiImage
Inherits XKProjectItem
	#tag Method, Flags = &h0
		Sub AddRepresentation(rep As XKImageRepresentation)
		  /// Adds an image representation to this multi-image.
		  
		  If rep <> Nil Then
		    mRepresentations.Add(rep)
		    AddChild(rep)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new multi-image with the specified parent.
		  
		  Super.Constructor(parent)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return "MultiImage"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Representations() As XKImageRepresentation()
		  /// Returns all image representations.
		  
		  Return mRepresentations
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToDebugString(indent As Integer = 0) As String
		  /// Returns a debug representation of this node.
		  
		  Var prefix As String = ""
		  For i As Integer = 1 To indent
		    prefix = prefix + "  "
		  Next i
		  
		  Var lines() As String
		  lines.Add(prefix + "MultiImage: " + Name + " (" + mRepresentations.Count.ToString + " representations)")
		  
		  For Each rep As XKImageRepresentation In mRepresentations
		    lines.Add(rep.ToDebugString(indent + 1))
		  Next rep
		  
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected mRepresentations() As XKImageRepresentation
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
