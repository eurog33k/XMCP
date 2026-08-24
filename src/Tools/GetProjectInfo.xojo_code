#tag Class
Protected Class GetProjectInfo
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("get_project_info", "Returns information about the currently open Xojo project including the project path, Xojo IDE version, and selected item.")

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  #Pragma Unused args

		  Var script As String = _
		  "Dim info As String = ""Project: "" + ProjectShellPath + Chr(10)" + EndOfLine + _
		  "info = info + ""Xojo Version: "" + Str(XojoVersion) + Chr(10)" + EndOfLine + _
		  "info = info + ""Current Location: "" + Location + Chr(10)" + EndOfLine + _
		  "info = info + ""Location Type: "" + TypeOfCurrentLocation + Chr(10)" + EndOfLine + _
		  "info = info + ""Selected Item: "" + ProjectItem" + EndOfLine + _
		  "Print info"

		  If App.IDE = Nil Then
		    Return MCPKit.ToolResult.Failure("Xojo IDE is not connected. Start the IDE and restart XMCP.")
		  End If

		  Var response As JSONItem = App.IDE.SendAndReceive(script)
		  If response = Nil Then
		    If App.IDE.LastErrorMessage <> "" Then
		      Return MCPKit.ToolResult.Failure(App.IDE.LastErrorMessage)
		    End If
		    Return MCPKit.ToolResult.Failure("Timeout waiting for IDE response.")
		  End If

		  If response.HasKey("response") Then
		    Var resp As Variant = response.Value("response")
		    Var text As String
		    If resp.Type = Variant.TypeString Then
		      text = resp.StringValue
		    Else
		      Var respJSON As JSONItem = response.Value("response")
		      text = respJSON.ToString
		    End If

		    // Derive project directory from the project file path (in Xojo code, not IDE script).
		    Var projectPath As String = ""
		    For Each line As String In text.Split(Chr(10))
		      If line.BeginsWith("Project: ") Then
		        projectPath = line.Middle(9).Trim
		        Exit
		      End If
		    Next
		    If projectPath <> "" Then
		      Var projectFile As New FolderItem(projectPath, FolderItem.PathModes.Shell)
		      If projectFile <> Nil And projectFile.Parent <> Nil Then
		        // NativePath, not ShellPath: on Windows ShellPath is the 8.3 short path for
		        // items that exist, which is unreadable and not what callers want to see.
		        // ProjectShellPath gave us that short form, so restate it as a long path too.
		        text = text.Replace("Project: " + projectPath, "Project: " + projectFile.NativePath)
		        text = text + Chr(10) + "Project Directory: " + projectFile.Parent.NativePath
		      End If
		    End If

		    Return MCPKit.ToolResult.Success(text)
		  End If

		  Return MCPKit.ToolResult.Failure("Unexpected response from IDE: " + response.ToString)

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
