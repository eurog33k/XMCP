#tag Class
Protected Class XKMenuBar
Inherits XKProjectItem
	#tag Method, Flags = &h0
		Sub AddMenuItem(item As XKMenuItem)
		  /// Adds a top-level menu item to this menu bar.
		  
		  If item <> Nil Then
		    mMenuItems.Add(item)
		    AddChild(item)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new menu bar with the specified parent.
		  
		  Super.Constructor(parent)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MenuItems() As XKMenuItem()
		  /// Returns all top-level menu items.
		  
		  Return mMenuItems
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return "MenuBar"
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
		  lines.Add(prefix + "MenuBar: " + Name)
		  
		  For Each item As XKMenuItem In mMenuItems
		    lines.Add(item.ToDebugString(indent + 1))
		  Next item
		  
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected mMenuItems() As XKMenuItem
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
