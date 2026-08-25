#tag Class
Protected Class XKToolbar
Inherits XKProjectItem
	#tag Method, Flags = &h0
		Sub AddButton(btn As XKToolbarButton)
		  /// Adds a button to this toolbar.
		  
		  If btn <> Nil Then
		    mButtons.Add(btn)
		    AddChild(btn)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Buttons() As XKToolbarButton()
		  /// Returns all buttons in this toolbar.
		  
		  Return mButtons
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new toolbar with the specified parent.
		  
		  Super.Constructor(parent)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return "DesktopToolbar"
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
		  lines.Add(prefix + "Toolbar: " + Name)
		  
		  If SuperClassName <> "" Then
		    lines.Add(prefix + "  Inherits: " + SuperClassName)
		  End If
		  
		  For Each btn As XKToolbarButton In mButtons
		    lines.Add(btn.ToDebugString(indent + 1))
		  Next btn
		  
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected mButtons() As XKToolbarButton
	#tag EndProperty

	#tag Property, Flags = &h0
		SuperClassName As String
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
			Name="SuperClassName"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
