#tag Class
Protected Class XKControl
Inherits XKNode
	#tag Method, Flags = &h0
		Sub AddNestedControl(c As XKControl)
		  /// Adds a control nested inside this one.
		  
		  If c <> Nil Then
		    mNestedControls.Add(c)
		    AddChild(c)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AllAttributes() As Dictionary
		  /// Returns the attributes dictionary.
		  
		  Return mAttributes
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new control with the specified parent.
		  
		  Super.Constructor(parent)
		  
		  mAttributes = New Dictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetAttribute(key As String, defaultValue As String = "") As String
		  /// Gets a control attribute by its key.
		  
		  If mAttributes.HasKey(key) Then
		    Return mAttributes.Value(key).StringValue
		  Else
		    Return defaultValue
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NestedControls() As XKControl()
		  /// Returns controls nested inside this one.
		  
		  Return mNestedControls
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return ControlType
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetAttribute(key As String, value As String)
		  /// Sets a control attribute.
		  
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
		  
		  Var result As String = prefix + ControlType + " " + Name
		  
		  // Position info.
		  Var left As String = GetAttribute("Left", "")
		  Var top As String = GetAttribute("Top", "")
		  Var width As String = GetAttribute("Width", "")
		  Var height As String = GetAttribute("Height", "")
		  
		  If left <> "" And top <> "" Then
		    result = result + " @(" + left + ", " + top + ")"
		  End If
		  
		  If width <> "" And height <> "" Then
		    result = result + " [" + width + "x" + height + "]"
		  End If
		  
		  // Nested controls.
		  If mNestedControls.Count > 0 Then
		    For Each nc As XKControl In mNestedControls
		      result = result + EndOfLine + nc.ToDebugString(indent + 1)
		    Next nc
		  End If
		  
		  Return result
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		ControlType As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mAttributes As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mNestedControls() As XKControl
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
			Name="ControlType"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
