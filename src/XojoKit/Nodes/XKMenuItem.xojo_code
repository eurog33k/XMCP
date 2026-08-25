#tag Class
Protected Class XKMenuItem
Inherits XKNode
	#tag Method, Flags = &h0, Description = 41646473206120737562206D656E75206974656D2E
		Sub AddSubItem(item As XKMenuItem)
		  /// Adds a sub menu item.
		  
		  If item <> Nil Then
		    mSubItems.Add(item)
		    AddChild(item)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E732074686520617474726962757465732064696374696F6E6172792E
		Function AllAttributes() As Dictionary
		  /// Returns the attributes dictionary.
		  
		  Return mAttributes
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 437265617465732061206E6577206D656E75206974656D2077697468207468652073706563696669656420706172656E742E
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new menu item with the specified parent.
		  
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
		  
		  Return MenuItemType
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 5365747320616E206174747269627574652E
		Sub SetAttribute(key As String, value As String)
		  /// Sets an attribute.
		  
		  mAttributes.Value(key) = value
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E7320616C6C20737562206D656E75206974656D732E
		Function SubItems() As XKMenuItem()
		  /// Returns all sub menu items.
		  
		  Return mSubItems
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E73206120646562756720726570726573656E746174696F6E206F662074686973206E6F64652E
		Function ToDebugString(indent As Integer = 0) As String
		  /// Returns a debug representation of this node.
		  
		  Var prefix As String = ""
		  For i As Integer = 1 To indent
		    prefix = prefix + "  "
		  Next i
		  
		  Var result As String = prefix
		  
		  // Check for separator.
		  If Text = "-" Then
		    result = result + "---separator---"
		  Else
		    result = result + MenuItemType + " " + Name
		    
		    If Text <> "" And Text <> Name Then
		      result = result + " """ + Text + """"
		    End If
		    
		    Var shortcut As String = GetAttribute("Shortcut", "")
		    If shortcut <> "" Then
		      result = result + " [" + shortcut + "]"
		    End If
		  End If
		  
		  // Nested items.
		  If mSubItems.Count > 0 Then
		    For Each sub_ As XKMenuItem In mSubItems
		      result = result + EndOfLine + sub_.ToDebugString(indent + 1)
		    Next sub_
		  End If
		  
		  Return result
		End Function
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected mAttributes As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h0
		MenuItemType As String = "DesktopMenuItem"
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mSubItems() As XKMenuItem
	#tag EndProperty

	#tag Property, Flags = &h0
		Name As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Text As String
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
			Name="MenuItemType"
			Visible=false
			Group="Behavior"
			InitialValue="DesktopMenuItem"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Text"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
