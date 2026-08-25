#tag Class
Protected Class XKEvent
Inherits XKNode
	#tag Method, Flags = &h0, Description = 41646473206120636F6465206C696E6520746F2074686973206576656E742E
		Sub AddCodeLine(line As String)
		  /// Adds a code line to this event.
		  
		  mCodeLines.Add(line)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 41646473206120706172616D6574657220746F2074686973206576656E742E
		Sub AddParameter(p As XKParameter)
		  /// Adds a parameter to this event.
		  
		  If p <> Nil Then
		    mParameters.Add(p)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E732074686520636F6465206C696E6573206F662074686973206576656E742E
		Function CodeLines() As String()
		  /// Returns the code lines of this event.
		  
		  Return mCodeLines
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 437265617465732061206E6577206576656E742077697468207468652073706563696669656420706172656E742E
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new event with the specified parent.
		  
		  Super.Constructor(parent)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return "Event"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E732074686520706172616D6574657273206F662074686973206576656E742E
		Function Parameters() As XKParameter()
		  /// Returns the parameters of this event.
		  
		  Return mParameters
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 5365747320746865206C697374206F6620636F6465206C696E657320666F722074686973206576656E742E
		Sub SetCodeLines(lines() As String)
		  /// Sets the list of code lines for this event.
		  
		  mCodeLines = lines
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, Description = 52657475726E73206120646562756720726570726573656E746174696F6E206F662074686973206E6F64652E
		Function ToDebugString(indent As Integer = 0) As String
		  /// Returns a debug representation of this node.
		  
		  Var prefix As String = ""
		  For i As Integer = 1 To indent
		    prefix = prefix + "  "
		  Next i
		  
		  // Build the signature.
		  Var sig As String = prefix + "Event "
		  
		  If IsFunction Then
		    sig = sig + "Function "
		  Else
		    sig = sig + "Sub "
		  End If
		  
		  sig = sig + Name + "("
		  
		  // Parameters.
		  Var paramStrs() As String
		  For Each p As XKParameter In mParameters
		    paramStrs.Add(p.ToSignatureString)
		  Next p
		  sig = sig + String.FromArray(paramStrs, ", ") + ")"
		  
		  If IsFunction And ReturnType <> "" Then
		    sig = sig + " As " + ReturnType
		  End If
		  
		  // Add line count info.
		  sig = sig + "  [" + mCodeLines.Count.ToString + " lines]"
		  
		  Return sig
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		ControlName As String
	#tag EndProperty

	#tag Property, Flags = &h0
		IsFunction As Boolean = False
	#tag EndProperty

	#tag Property, Flags = &h0
		IsMenuHandler As Boolean = False
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mCodeLines() As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mParameters() As XKParameter
	#tag EndProperty

	#tag Property, Flags = &h0
		Name As String
	#tag EndProperty

	#tag Property, Flags = &h0
		ReturnType As String
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
			Name="IsFunction"
			Visible=false
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="ReturnType"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ControlName"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsMenuHandler"
			Visible=false
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
