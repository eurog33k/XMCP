#tag Class
Protected Class XKProject
Inherits XKNode
	#tag Method, Flags = &h0
		Function AllItems() As XKProjectItem()
		  /// Returns all items in the project (not just direct children of the project).
		  
		  Var result() As XKProjectItem
		  
		  For Each entry As DictionaryEntry In mItemsByGUID
		    result.Add(XKProjectItem(entry.Value))
		  Next entry
		  
		  Return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  /// Creates a new project.
		  
		  Super.Constructor(Nil)
		  
		  // Initialize the dictionaries.
		  mSettings = New Dictionary
		  mItemsByGUID = New Dictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetSetting(key As String, defaultValue As String = "") As String
		  /// Gets a setting by key. Returns the setting value or defaultValue if not found.
		  
		  If mSettings.HasKey(key) Then
		    Return mSettings.Value(key).StringValue
		  Else
		    Return defaultValue
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ItemByGUID(guid As String) As XKProjectItem
		  /// Looks up an item by its GUID. Returns Nil if not found.
		  
		  If mItemsByGUID.HasKey(guid) Then
		    Return XKProjectItem(mItemsByGUID.Value(guid))
		  Else
		    Return Nil
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return "XKProject"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RegisterItem(item As XKProjectItem)
		  /// Registers an item by its GUID.
		  
		  If item <> Nil And item.GUID <> "" Then
		    mItemsByGUID.Value(item.GUID) = item
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetSetting(key As String, value As String)
		  /// Sets a key-value pair as a setting of this project.
		  
		  mSettings.Value(key) = value
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Settings() As Dictionary
		  /// Returns the settings dictionary.
		  
		  Return mSettings
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToDebugString(indent As Integer = 0) As String
		  /// Returns a debug representation of the whole project tree.
		  
		  Var prefix As String = ""
		  For i As Integer = 1 To indent
		    prefix = prefix + "  "
		  Next i
		  
		  Var lines() As String
		  
		  lines.Add(prefix + "Project: " + Name)
		  lines.Add(prefix + "  Type: " + ProjectType)
		  lines.Add(prefix + "  Version: " + RBProjectVersion)
		  lines.Add("")
		  lines.Add(prefix + "Items:")
		  
		  // Add all top-level items.
		  For Each child As XKNode In Children
		    lines.Add(child.ToDebugString(indent + 1))
		  Next child
		  
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		MinIDEVersion As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mItemsByGUID As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mSettings As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h0
		Name As String
	#tag EndProperty

	#tag Property, Flags = &h0
		OrigIDEVersion As String
	#tag EndProperty

	#tag Property, Flags = &h0
		ProjectFilePath As String
	#tag EndProperty

	#tag Property, Flags = &h0
		ProjectType As String
	#tag EndProperty

	#tag Property, Flags = &h0
		RBProjectVersion As String
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
			Name="ProjectType"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RBProjectVersion"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="MinIDEVersion"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="OrigIDEVersion"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ProjectFilePath"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
