#tag Module
Protected Module Platform
	#tag Method, Flags = &h21
		Private Sub AddFolderIfWritable(folders() As FolderItem, folder As FolderItem)
		  If folder = Nil Then Return
		  
		  Try
		    If Not folder.Exists Then Return
		    If Not folder.IsWriteable Then Return
		  Catch e As RuntimeException
		    Return
		  End Try
		  
		  For Each existing As FolderItem In folders
		    If existing.NativePath = folder.NativePath Then Return
		  Next existing
		  
		  folders.Add(folder)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub AddUnique(paths() As String, path As String)
		  If path.Trim = "" Then Return
		  
		  For Each existing As String In paths
		    If existing = path Then Return
		  Next existing
		  
		  paths.Add(path)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function CandidateFolders() As FolderItem()
		  /// The folders the Xojo IDE may have placed its IPC listener in, in the same
		  /// order the IDE itself considers them. The first writable folder is the one
		  /// the IDE picked, so callers should try it first.
		  ///
		  /// This mirrors FindIPCPath in Xojo's shipped IDECommunicator v2 example
		  /// (Example Projects/.../IDE Scripting/IDECommunicator/v2), which is the
		  /// reference implementation of the IDE's own path resolution.
		  
		  Var folders() As FolderItem
		  
		  // Boot volume /tmp and /var/tmp. On macOS and Linux these are the usual
		  // answer; on Windows C:\tmp rarely exists, so the chain falls through.
		  Var boot As FolderItem
		  Try
		    boot = FolderItem.DriveAt(0)
		  Catch e As RuntimeException
		    boot = Nil
		  End Try
		  
		  If boot <> Nil Then
		    AddFolderIfWritable(folders, SafeChild(boot, "tmp"))
		    Var varDir As FolderItem = SafeChild(boot, "var")
		    If varDir <> Nil Then AddFolderIfWritable(folders, SafeChild(varDir, "tmp"))
		  End If
		  
		  // %LOCALAPPDATA%\Temp on Windows, /var/folders/.../T on macOS, /tmp on Linux.
		  AddFolderIfWritable(folders, SpecialFolder.Temporary)
		  
		  // Last resort, matching the example. Note that on Windows SpecialFolder.Home
		  // follows OneDrive when it is active, so this rung is the least reliable.
		  AddFolderIfWritable(folders, SpecialFolder.Home)
		  
		  Return folders
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DebugLogFile() As FolderItem
		  /// The file that App.UnhandledException handlers are expected to write to and
		  /// that the get_debug_log tool reads.
		  ///
		  /// macOS and Linux keep the historic /tmp/xmcp_debug.log so existing handlers
		  /// keep working. SpecialFolder.Temporary is deliberately not used there: on
		  /// macOS it resolves to a per-process /var/folders/.../T path, so XMCP and the
		  /// app being debugged would not agree on a single file.
		  
		  #If TargetWindows Then
		    Var tmp As FolderItem = SpecialFolder.Temporary
		    If tmp = Nil Then Return Nil
		    Return tmp.Child("xmcp_debug.log")
		  #Else
		    Return New FolderItem("/tmp/xmcp_debug.log", FolderItem.PathModes.Native)
		  #EndIf
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DebugLogPath() As String
		  /// The debug log location as text, for tool descriptions and error messages.
		  
		  Var f As FolderItem = DebugLogFile
		  If f = Nil Then Return "xmcp_debug.log"
		  Return f.NativePath
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DocsRootPath() As String
		  /// Where the Xojo IDE keeps installed documentation, resolved rather than described:
		  /// ~/Library/Application Support/Xojo/Xojo on macOS, %APPDATA%\Xojo\Xojo on Windows.
		  
		  Var root As FolderItem = SpecialFolder.ApplicationData
		  If root = Nil Then Return "(application data folder not found)"
		  
		  Var vendor As FolderItem = SafeChild(root, "Xojo")
		  If vendor = Nil Then Return root.NativePath
		  
		  Var inner As FolderItem = SafeChild(vendor, "Xojo")
		  If inner = Nil Then Return vendor.NativePath
		  
		  Return inner.NativePath
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IPCSocketPaths() As String()
		  /// Ordered list of paths where the Xojo IDE may be listening for IDE scripts.
		  ///
		  /// Only candidate FOLDERS are probed for writability - never the socket path
		  /// itself. On Windows an IPCSocket endpoint has no filesystem entry, so
		  /// FolderItem.Exists on the socket path is always False even while the IDE is
		  /// listening. Verified 2026-08-21 on Windows 11 with Xojo 2026r1.1, confirmed by the
		  /// person who ran it: "C:\Program Files\Xojo\Xojo 2026r1.1\Xojo.exe". Two earlier
		  /// answers here were wrong - 2021r3.1, which is installed on that box but dormant since
		  /// 2022, and then 2025r3.1, inferred from which version's files had been touched last
		  /// before the runs. Several versions are installed and a touched preferences folder is
		  /// not evidence that the IDE ran anything, which is what that inference assumed. The
		  /// shipped IDECommunicator example resolves and connects to
		  /// C:\Users\<user>\AppData\Local\Temp\XojoIDE, while `dir` on that exact path
		  /// reports "File Not Found".
		  
		  Var name As String = SocketName
		  Var paths() As String
		  
		  #If TargetMacOS Then
		    // First, ahead of the computed chain: this is where the IDE actually listens,
		    // and NativePath below resolves the /tmp symlink to /private/tmp, which would
		    // otherwise push the historic /tmp form to the back of the list.
		    AddUnique(paths, "/tmp/" + name)
		    AddUnique(paths, "/private/tmp/" + name)
		  #EndIf
		  
		  For Each parent As FolderItem In CandidateFolders
		    Var child As FolderItem = SafeChild(parent, name)
		    If child <> Nil Then AddUnique(paths, child.NativePath)
		  Next parent
		  
		  Return paths
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SafeChild(parent As FolderItem, name As String) As FolderItem
		  If parent = Nil Then Return Nil
		  
		  Try
		    Return parent.Child(name)
		  Catch e As RuntimeException
		    Return Nil
		  End Try
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SocketName() As String
		  /// The IPC socket file name the IDE listens on.
		  ///
		  /// Xojo honours the XOJO_IPCPATH environment variable so that several IDEs can
		  /// run side by side, each with its own listener. It holds a bare file NAME, not
		  /// a path, and the IDE only accepts a-z, A-Z, 0-9 and underscore - anything
		  /// else is ignored here rather than passed through.
		  
		  Var name As String = ""
		  Try
		    name = System.EnvironmentVariable("XOJO_IPCPATH").Trim
		  Catch e As RuntimeException
		    name = ""
		  End Try
		  
		  If name <> "" Then
		    Var rx As New RegEx
		    rx.SearchPattern = "^[A-Za-z0-9_]+$"
		    If rx.Search(name) <> Nil Then Return name
		  End If
		  
		  Return "XojoIDE"
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SocketPathSummary() As String
		  /// A human readable summary of where XMCP looked, for connection errors.
		  
		  Var paths() As String = IPCSocketPaths
		  If paths.Count = 0 Then Return "(no writable IPC folder found)"
		  Return String.FromArray(paths, ", ")
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SupportsSystemLog() As Boolean
		  /// Whether System.DebugLog output can be read back after the fact. Only macOS keeps
		  /// it: there it goes to the unified log, on Windows to OutputDebugString - which only
		  /// an attached debugger sees - and on Linux to stderr.
		  ///
		  /// This is the single place that knows it, so callers stay free of #If.
		  
		  #If TargetMacOS Then
		    Return True
		  #Else
		    Return False
		  #EndIf
		  
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
	#tag EndViewBehavior
End Module
#tag EndModule
