#tag Class
Protected Class XKMethod
Inherits XKNode
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

	#tag Method, Flags = &h0
		Sub AddCodeLine(line As String)
		  /// Adds a code line to this method.
		  
		  mCodeLines.Add(line)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddParameter(p As XKParameter)
		  /// Adds a parameter to this method.
		  
		  If p <> Nil Then
		    mParameters.Add(p)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CodeLines() As String()
		  /// Returns the code lines of this method.
		  
		  Return mCodeLines
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new method with the specified parent.
		  
		  Super.Constructor(parent)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return "Method"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Parameters() As XKParameter()
		  /// Returns the parameters of this method.
		  
		  Return mParameters
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetCodeLines(lines() As String)
		  /// Sets the list of code lines for this method.
		  
		  mCodeLines = lines
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToDebugString(indent As Integer = 0) As String
		  /// Returns a debug representation of this node.
		  
		  Var prefix As String = ""
		  For i As Integer = 1 To indent
		    prefix = prefix + "  "
		  Next i
		  
		  // Build the signature.
		  Var sig As String = prefix + AccessModifierName
		  
		  If IsShared Then
		    sig = sig + " Shared"
		  End If
		  
		  If IsFunction Then
		    sig = sig + " Function "
		  Else
		    sig = sig + " Sub "
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
		  
		  If Description <> "" Then
		    sig = sig + "  // " + Description
		  End If
		  
		  // Add line count info.
		  sig = sig + "  [" + mCodeLines.Count.ToString + " lines]"
		  
		  Return sig
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		Description As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Flags As Integer = 0
	#tag EndProperty

	#tag Property, Flags = &h0
		IsFunction As Boolean = False
	#tag EndProperty

	#tag Property, Flags = &h0
		IsShared As Boolean = False
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
			Name="Flags"
			Visible=false
			Group="Behavior"
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
			Name="IsShared"
			Visible=false
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Description"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
