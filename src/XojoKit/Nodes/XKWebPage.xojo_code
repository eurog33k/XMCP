#tag Class
Protected Class XKWebPage
Inherits XKProjectItem
	#tag Method, Flags = &h0
		Sub AddConstant(c As XKConstant)
		  /// Adds a constant to this web page.
		  
		  If c <> Nil Then
		    mConstants.Add(c)
		    AddChild(c)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddControl(c As XKControl)
		  /// Adds a control to this web page.
		  
		  If c <> Nil Then
		    mControls.Add(c)
		    AddChild(c)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddControlEventGroup(ceg As XKControlEventGroup)
		  /// Adds a control event group to this web page.
		  
		  If ceg <> Nil Then
		    mControlEvents.Add(ceg)
		    AddChild(ceg)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddEvent(e As XKEvent)
		  /// Adds an event to this web page.
		  
		  If e <> Nil Then
		    mEvents.Add(e)
		    AddChild(e)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddMethod(m As XKMethod)
		  /// Adds a method to this web page.
		  
		  If m <> Nil Then
		    mMethods.Add(m)
		    AddChild(m)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddProperty(p As XKProperty)
		  /// Adds a property to this web page.
		  
		  If p <> Nil Then
		    mProperties.Add(p)
		    AddChild(p)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddViewProperty(vp As XKViewProperty)
		  /// Adds a view property to this web page.
		  
		  If vp <> Nil Then
		    mViewProperties.Add(vp)
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
		Sub ClearControls()
		  /// Clears all controls from this web page.
		  
		  mControls.RemoveAll
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new web page with the specified parent.
		  
		  Super.Constructor(parent)
		  
		  mAttributes = New Dictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ControlAt(index As Integer) As XKControl
		  /// Returns the control at the specified index.
		  
		  If index >= 0 And index < mControls.Count Then
		    Return mControls(index)
		  End If
		  Return Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ControlCount() As Integer
		  /// Returns the number of top-level controls.
		  
		  Return mControls.Count
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ControlEventGroups() As XKControlEventGroup()
		  /// Returns all control event groups in this web page.
		  
		  Return mControlEvents
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Controls() As XKControl()
		  /// Returns all top-level controls in this web page.
		  
		  Return mControls
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Events() As XKEvent()
		  /// Returns all events in this web page.
		  
		  Return mEvents
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetAttribute(key As String, defaultValue As String = "") As String
		  /// Gets a web page attribute by its key.
		  
		  If mAttributes.HasKey(key) Then
		    Return mAttributes.Value(key).StringValue
		  Else
		    Return defaultValue
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Methods() As XKMethod()
		  /// Returns all methods in this web page.
		  
		  Return mMethods
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  If IsContainer Then
		    Return "WebContainer"
		  Else
		    Return "WebPage"
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Properties() As XKProperty()
		  /// Returns all properties of this web page.
		  
		  Return mProperties
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetAttribute(key As String, value As String)
		  /// Sets a web page attribute.
		  
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
		  
		  Var lines() As String
		  
		  // Header.
		  lines.Add(prefix + NodeTypeName + ": " + Name)
		  
		  // Web page attributes.
		  Var title As String = GetAttribute("Title", "")
		  If title <> "" Then
		    lines.Add(prefix + "  Title: " + title)
		  End If
		  
		  Var width As String = GetAttribute("Width", "")
		  Var height As String = GetAttribute("Height", "")
		  If width <> "" And height <> "" Then
		    lines.Add(prefix + "  Size: " + width + " x " + height)
		  End If
		  
		  // Controls.
		  If mControls.Count > 0 Then
		    lines.Add(prefix + "  Controls (" + mControls.Count.ToString + "):")
		    For Each c As XKControl In mControls
		      lines.Add(c.ToDebugString(indent + 2))
		    Next c
		  End If
		  
		  // Events.
		  If mEvents.Count > 0 Then
		    lines.Add(prefix + "  Events (" + mEvents.Count.ToString + "):")
		    For Each ev As XKEvent In mEvents
		      lines.Add(ev.ToDebugString(indent + 2))
		    Next ev
		  End If
		  
		  // Control events.
		  If mControlEvents.Count > 0 Then
		    lines.Add(prefix + "  ControlEvents (" + mControlEvents.Count.ToString + "):")
		    For Each ce As XKControlEventGroup In mControlEvents
		      lines.Add(ce.ToDebugString(indent + 2))
		    Next ce
		  End If
		  
		  // Methods.
		  If mMethods.Count > 0 Then
		    lines.Add(prefix + "  Methods (" + mMethods.Count.ToString + "):")
		    For Each m As XKMethod In mMethods
		      lines.Add(m.ToDebugString(indent + 2))
		    Next m
		  End If
		  
		  // Properties.
		  If mProperties.Count > 0 Then
		    lines.Add(prefix + "  Properties (" + mProperties.Count.ToString + "):")
		    For Each p As XKProperty In mProperties
		      lines.Add(p.ToDebugString(indent + 2))
		    Next p
		  End If
		  
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ViewProperties() As XKViewProperty()
		  /// Returns all view behavior properties in this web page.
		  
		  Return mViewProperties
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		Flags As Integer = 0
	#tag EndProperty

	#tag Property, Flags = &h0
		Interfaces() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		IsContainer As Boolean
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mAttributes As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mConstants() As XKConstant
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mControlEvents() As XKControlEventGroup
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mControls() As XKControl
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mEvents() As XKEvent
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mMethods() As XKMethod
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mProperties() As XKProperty
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mViewProperties() As XKViewProperty
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
			Name="IsContainer"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Flags"
			Visible=false
			Group="Behavior"
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
