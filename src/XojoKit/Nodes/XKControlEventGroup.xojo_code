#tag Class
Protected Class XKControlEventGroup
Inherits XKNode
	#tag Method, Flags = &h0
		Sub AddEvent(e As XKEvent)
		  /// Adds an event to this control group.
		  
		  If e <> Nil Then
		    mEvents.Add(e)
		    AddChild(e)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new control event group with the specified parent.
		  
		  Super.Constructor(parent)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Events() As XKEvent()
		  /// Returns all events for this control.
		  
		  Return mEvents
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return "ControlEventGroup"
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
		  lines.Add(prefix + "Events for " + ControlName + ":")
		  
		  For Each ev As XKEvent In mEvents
		    lines.Add(ev.ToDebugString(indent + 1))
		  Next ev
		  
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		ControlName As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mEvents() As XKEvent
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  /// Returns the control name as the name for this event group.
			  
			  Return ControlName
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
			Name="ControlName"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
