#tag Class
Protected Class SaveProject
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("save_project", "Saves the current Xojo project to disk (File > Save). Use this after set_code, create_project_item, constant_value or get_item_description so the changes are written to disk - the IDE holds them in memory until saved, and build_project builds the in-memory project. The IDE writes only modified items, so saving an unchanged project does nothing.")

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  #Pragma Unused args

		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If

		  // SaveFile is a documented DoCommand, so an unrecognised-command failure is not a
		  // concern here the way it was for BuildApp's numeric build targets. A DoCommand
		  // answers {} when it is accepted and a scriptError object when the script fails, so
		  // check for the latter rather than treating any response as success.
		  Var script As String = "DoCommand ""SaveFile""" + EndOfLine + _
		  "Print ProjectShellPath"

		  Var response As JSONItem = App.IDE.SendAndReceive(script, 30000)
		  If response = Nil Then
		    If App.IDE.LastErrorMessage <> "" Then
		      Return MCPKit.ToolResult.Failure(App.IDE.LastErrorMessage)
		    End If
		    Return MCPKit.ToolResult.Failure("Timeout waiting for the IDE to save the project.")
		  End If

		  If Not response.HasKey("response") Then
		    Return MCPKit.ToolResult.Failure("Unexpected response from IDE: " + response.ToString)
		  End If

		  Var resp As Variant = response.Value("response")
		  If resp.Type <> Variant.TypeString Then
		    // An object here is a scriptError, openErrors or similar - not a successful save.
		    Var respJSON As JSONItem = response.Value("response")
		    Return MCPKit.ToolResult.Failure("Save failed: " + respJSON.ToString)
		  End If

		  Var shellPath As String = resp.StringValue.Trim
		  If shellPath = "" Then
		    Return MCPKit.ToolResult.Failure("No project is open in the Xojo IDE, or it has never " + _
		    "been saved to disk. A project that has never been saved needs File > Save As first, " + _
		    "which cannot be scripted without a file dialog.")
		  End If

		  // Report the long path: on Windows ProjectShellPath is the 8.3 short form.
		  Var nativePath As String = shellPath
		  Try
		    Var projectFile As New FolderItem(shellPath, FolderItem.PathModes.Shell)
		    If projectFile <> Nil And projectFile.Exists Then nativePath = projectFile.NativePath
		  Catch e As RuntimeException
		    // Keep the shell path for display.
		  End Try

		  // Not "Project saved": the IDE has no command that reports whether there was anything
		  // to save, so a second call in a row looks exactly like the first. Claim what is
		  // actually known - that the files now match the IDE - rather than implying a write.
		  Return MCPKit.ToolResult.Success("The files on disk now match the IDE: " + nativePath + _
		  ". The IDE cannot be asked whether it had unsaved changes, so this does not tell you " + _
		  "whether anything was actually written.")

		End Function
	#tag EndMethod


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
