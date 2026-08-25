#tag Class
Protected Class XKCodeContainer
Inherits XKProjectItem
	#tag Method, Flags = &h0
		Function AccessModifierName() As String
		  /// Returns the access modifier flags as a human-readable string (Public, Protected, Private, etc.).
		  
		  Select Case Flags
		  Case &h0
		    Return "Public"
		    
		  Case &h1
		    Return "Protected"
		    
		  Case &h21
		    Return "Private"
		    
		  Else
		    Return "Unknown (" + Flags.ToString + ")"
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 41646473206120636F6D70757465642070726F706572747920746F2074686973206974656D2E
		Sub AddComputedProperty(prop As XKComputedProperty)
		  /// Adds a computed property to this item.
		  
		  If prop <> Nil Then
		    mComputedProperties.Add(prop)
		    AddChild(prop)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 41646473206120636F6E7374616E7420746F2074686973206974656D2E
		Sub AddConstant(c As XKConstant)
		  /// Adds a constant to this item.
		  
		  If c <> Nil Then
		    mConstants.Add(c)
		    AddChild(c)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 4164647320616E20656E756D20746F2074686973206974656D2E
		Sub AddEnum(e As XKEnum)
		  /// Adds an enum to this item.
		  
		  If e <> Nil Then
		    mEnums.Add(e)
		    AddChild(e)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 4164647320616E206576656E7420746F2074686973206974656D2E
		Sub AddEvent(e As XKEvent)
		  /// Adds an event to this item.
		  
		  If e <> Nil Then
		    mEvents.Add(e)
		    AddChild(e)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 416464732061206D6574686F6420746F2074686973206974656D2E
		Sub AddMethod(m As XKMethod)
		  /// Adds a method to this item.
		  
		  If m <> Nil Then
		    mMethods.Add(m)
		    AddChild(m)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 416464732061206E6F746520746F2074686973206974656D2E
		Sub AddNote(n As XKNote)
		  /// Adds a note to this item.
		  
		  If n <> Nil Then
		    mNotes.Add(n)
		    AddChild(n)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 4164647320612070726F706572747920746F2074686973206974656D2E
		Sub AddProperty(prop As XKProperty)
		  /// Adds a property to this item.
		  
		  If prop <> Nil Then
		    mProperties.Add(prop)
		    AddChild(prop)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 41646473206120766965772070726F706572747920746F2074686973206974656D2E
		Sub AddViewProperty(vp As XKViewProperty)
		  /// Adds a view property to this item.
		  
		  If vp <> Nil Then
		    mViewProperties.Add(vp)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E7320616C6C20636F6D70757465642070726F70657274696573206F662074686973206974656D2E
		Function ComputedProperties() As XKComputedProperty()
		  /// Returns all computed properties of this item.
		  
		  Return mComputedProperties
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E7320616C6C20636F6E7374616E7473206F662074686973206974656D2E
		Function Constants() As XKConstant()
		  /// Returns all constants of this item.
		  
		  Return mConstants
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 437265617465732061206E657720636F646520636F6E7461696E65722077697468207468652073706563696669656420706172656E742E
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new code container with the specified parent.
		  
		  Super.Constructor(parent)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E7320616C6C20656E756D73206F662074686973206974656D2E
		Function Enums() As XKEnum()
		  /// Returns all enums of this item.
		  
		  Return mEnums
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E7320616C6C206576656E7473206F662074686973206974656D2E
		Function Events() As XKEvent()
		  /// Returns all events of this item.
		  
		  Return mEvents
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E7320616C6C206D6574686F6473206F662074686973206974656D2E
		Function Methods() As XKMethod()
		  /// Returns all methods of this item.
		  
		  Return mMethods
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E73207468652074797065206E616D65206F662074686973206E6F64652E
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return "XKCodeContainer"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E7320616C6C206E6F746573206F662074686973206974656D2E
		Function Notes() As XKNote()
		  /// Returns all notes of this item.
		  
		  Return mNotes
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E7320616C6C2070726F70657274696573206F662074686973206974656D2E
		Function Properties() As XKProperty()
		  /// Returns all properties of this item.
		  
		  Return mProperties
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E73206120646562756720726570726573656E746174696F6E206F662074686973206E6F64652E
		Function ToDebugString(indent As Integer = 0) As String
		  /// Returns a debug representation of this node.
		  
		  Var prefix As String = ""
		  For i As Integer = 1 To indent
		    prefix = prefix + "  "
		  Next i
		  
		  Var lines() As String
		  
		  // Header line.
		  Var header As String = prefix + NodeTypeName + ": " + Name
		  If SuperClassName <> "" Then
		    header = header + " Inherits " + SuperClassName
		  End If
		  If Interfaces.Count > 0 Then
		    header = header + " Implements " + String.FromArray(Interfaces, ", ")
		  End If
		  lines.Add(header)
		  
		  // Access modifier.
		  lines.Add(prefix + "  Access: " + AccessModifierName)
		  
		  // Properties.
		  If mProperties.Count > 0 Then
		    lines.Add(prefix + "  Properties (" + mProperties.Count.ToString + "):")
		    For Each p As XKProperty In mProperties
		      lines.Add(p.ToDebugString(indent + 2))
		    Next p
		  End If
		  
		  // Computed properties.
		  If mComputedProperties.Count > 0 Then
		    lines.Add(prefix + "  ComputedProperties (" + mComputedProperties.Count.ToString + "):")
		    For Each cp As XKComputedProperty In mComputedProperties
		      lines.Add(cp.ToDebugString(indent + 2))
		    Next cp
		  End If
		  
		  // Methods.
		  If mMethods.Count > 0 Then
		    lines.Add(prefix + "  Methods (" + mMethods.Count.ToString + "):")
		    For Each m As XKMethod In mMethods
		      lines.Add(m.ToDebugString(indent + 2))
		    Next m
		  End If
		  
		  // Events.
		  If mEvents.Count > 0 Then
		    lines.Add(prefix + "  Events (" + mEvents.Count.ToString + "):")
		    For Each ev As XKEvent In mEvents
		      lines.Add(ev.ToDebugString(indent + 2))
		    Next ev
		  End If
		  
		  // Notes.
		  If mNotes.Count > 0 Then
		    lines.Add(prefix + "  Notes (" + mNotes.Count.ToString + "):")
		    For Each n As XKNote In mNotes
		      lines.Add(n.ToDebugString(indent + 2))
		    Next n
		  End If
		  
		  // Constants.
		  If mConstants.Count > 0 Then
		    lines.Add(prefix + "  Constants (" + mConstants.Count.ToString + "):")
		    For Each c As XKConstant In mConstants
		      lines.Add(c.ToDebugString(indent + 2))
		    Next c
		  End If
		  
		  // Enums.
		  If mEnums.Count > 0 Then
		    lines.Add(prefix + "  Enums (" + mEnums.Count.ToString + "):")
		    For Each e As XKEnum In mEnums
		      lines.Add(e.ToDebugString(indent + 2))
		    Next e
		  End If
		  
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E7320616C6C2076696577206265686176696F722070726F70657274696573206F662074686973206974656D2E
		Function ViewProperties() As XKViewProperty()
		  /// Returns all view behavior properties of this item.
		  
		  Return mViewProperties
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		Flags As Integer = 0
	#tag EndProperty

	#tag Property, Flags = &h0
		Interfaces() As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mComputedProperties() As XKComputedProperty
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mConstants() As XKConstant
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mEnums() As XKEnum
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mEvents() As XKEvent
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mMethods() As XKMethod
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mNotes() As XKNote
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
