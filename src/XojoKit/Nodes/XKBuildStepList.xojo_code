#tag Class
Protected Class XKBuildStepList
Inherits XKNode
	#tag Method, Flags = &h0
		Sub AddStep(buildStep As XKBuildStep)
		  /// Adds a build step.
		  
		  If buildStep <> Nil Then
		    mSteps.Add(buildStep)
		    AddChild(buildStep)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(parent As XKNode = Nil)
		  /// Creates a new build step list with the specified parent.
		  
		  Super.Constructor(parent)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeTypeName() As String
		  /// Returns the type name of this node.
		  
		  Return "BuildStepList"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Steps() As XKBuildStep()
		  /// Returns all build steps for this platform.
		  
		  Return mSteps
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
		  lines.Add(prefix + "Platform: " + PlatformName + " (" + mSteps.Count.ToString + " steps)")
		  
		  For Each buildStep As XKBuildStep In mSteps
		    lines.Add(buildStep.ToDebugString(indent + 1))
		  Next buildStep
		  
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod


	#tag Property, Flags = &h1
		Protected mSteps() As XKBuildStep
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  /// Returns the platform name as the name for this build step list.
			  
			  Return PlatformName
			End Get
		#tag EndGetter
		Name As String
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		PlatformName As String
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
			Name="PlatformName"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
