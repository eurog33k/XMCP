#tag Module
Protected Module ProjectSource
	#tag Method, Flags = &h0
		Function DescribeMembers(item As XKProjectItem) As String
		  /// A readable listing of everything the parsed file says an item contains, or "" if
		  /// the item holds no code.
		  ///
		  /// This is the answer to the questions IDE scripting cannot answer: SubLocations only
		  /// enumerates contained project items, so a class or a methods-only module reports
		  /// nothing at all through the IDE.

		  // A window is not an XKCodeContainer - it carries its own members plus a control
		  // tree, and its control event handlers are the ones IDE scripting cannot see at all.
		  If item IsA XKWindow Then Return DescribeWindow(XKWindow(item))

		  Var container As XKCodeContainer = ContainerFrom(item)
		  If container = Nil Then Return ""

		  Var out() As String

		  Var methods() As XKMethod = container.Methods
		  If methods.Count > 0 Then
		    out.Add("Methods (" + methods.Count.ToString + "):")
		    For Each m As XKMethod In methods
		      out.Add("  " + MethodSignature(m))
		    Next m
		  End If

		  Var props() As XKProperty = container.Properties
		  If props.Count > 0 Then
		    out.Add("Properties (" + props.Count.ToString + "):")
		    For Each p As XKProperty In props
		      out.Add("  " + p.Name + If(p.DataType = "", "", " As " + p.DataType))
		    Next p
		  End If

		  Var computed() As XKComputedProperty = container.ComputedProperties
		  If computed.Count > 0 Then
		    out.Add("Computed properties (" + computed.Count.ToString + "):")
		    For Each c As XKComputedProperty In computed
		      out.Add("  " + c.Name + If(c.DataType = "", "", " As " + c.DataType))
		    Next c
		  End If

		  Var constants() As XKConstant = container.Constants
		  If constants.Count > 0 Then
		    out.Add("Constants (" + constants.Count.ToString + "):")
		    For Each k As XKConstant In constants
		      out.Add("  " + k.Name + If(k.DefaultValue = "", "", " = " + Unquote(k.DefaultValue)))
		    Next k
		  End If

		  Var enums() As XKEnum = container.Enums
		  If enums.Count > 0 Then
		    out.Add("Enums (" + enums.Count.ToString + "):")
		    For Each e As XKEnum In enums
		      out.Add("  " + e.Name)
		    Next e
		  End If

		  Var events() As XKEvent = container.Events
		  If events.Count > 0 Then
		    out.Add("Event implementations (" + events.Count.ToString + "):")
		    For Each ev As XKEvent In events
		      Var label As String = ev.Name
		      If ev.ControlName <> "" Then label = ev.ControlName + "." + ev.Name
		      out.Add("  " + label)
		    Next ev
		  End If

		  Var notes() As XKNote = container.Notes
		  If notes.Count > 0 Then
		    out.Add("Notes (" + notes.Count.ToString + "):")
		    For Each n As XKNote In notes
		      out.Add("  " + n.Name)
		    Next n
		  End If

		  If out.Count = 0 Then Return ""
		  Return String.FromArray(out, EndOfLine)

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ContainerFrom(item As XKProjectItem) As XKCodeContainer
		  If item = Nil Then Return Nil

		  If item IsA XKCodeContainer Then Return XKCodeContainer(item)
		  Return Nil

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function DescribeWindow(win As XKWindow) As String
		  /// A window or container: its own members, then every control event handler. These
		  /// handlers live in the .xojo_window file, which IDE scripting does not expose, so
		  /// this is the only route to them.

		  Var out() As String

		  Var methods() As XKMethod = win.Methods
		  If methods.Count > 0 Then
		    out.Add("Methods (" + methods.Count.ToString + "):")
		    For Each m As XKMethod In methods
		      out.Add("  " + MethodSignature(m))
		    Next m
		  End If

		  Var props() As XKProperty = win.Properties
		  If props.Count > 0 Then
		    out.Add("Properties (" + props.Count.ToString + "):")
		    For Each p As XKProperty In props
		      out.Add("  " + p.Name + If(p.DataType = "", "", " As " + p.DataType))
		    Next p
		  End If

		  Var events() As XKEvent = win.Events
		  If events.Count > 0 Then
		    out.Add("Window event handlers (" + events.Count.ToString + "):")
		    For Each ev As XKEvent In events
		      out.Add("  " + ev.Name + If(ev.ReturnType = "", "", " As " + ev.ReturnType))
		    Next ev
		  End If

		  Var groups() As XKControlEventGroup = win.ControlEventGroups
		  If groups.Count > 0 Then
		    out.Add("Control event handlers:")
		    For Each g As XKControlEventGroup In groups
		      For Each ev As XKEvent In g.Events
		        out.Add("  " + g.ControlName + "." + ev.Name + _
		        If(ev.ReturnType = "", "", " As " + ev.ReturnType))
		      Next ev
		    Next g
		  End If

		  Var controls() As XKControl = win.Controls
		  If controls.Count > 0 Then
		    Var names() As String
		    For Each c As XKControl In controls
		      names.Add(c.Name + " (" + c.ControlType + ")")
		    Next c
		    out.Add("Controls (" + win.ControlCount.ToString + "): " + String.FromArray(names, ", "))
		  End If

		  If out.Count = 0 Then Return ""
		  Return String.FromArray(out, EndOfLine)

		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function FindItem(project As XKProject, path As String) As XKProjectItem
		  /// The project item at this dot-separated path, or Nil.
		  ///
		  /// Folder names are not part of a path: the IDE omits them, so they are skipped here
		  /// too. Matching is case insensitive, as Xojo identifiers are.

		  If project = Nil Or path.Trim = "" Then Return Nil

		  Var wanted As String = path.Trim.Lowercase

		  For Each item As XKProjectItem In project.AllItems
		    If item = Nil Then Continue
		    If QualifiedName(project, item).Lowercase = wanted Then Return item
		  Next item

		  Return Nil

		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function FindMembers(project As XKProject, path As String, ByRef ownerPath As String) As Variant()
		  /// Every member matching this path, which is more than one when a method is
		  /// overloaded - the whole point of reading the file rather than asking the IDE, which
		  /// silently answers with whichever overload is declared first.
		  ///
		  /// The owner is the longest prefix of the path that is itself a project item, so both
		  /// "Module1.Foo" and "Window1.Button1.Pressed" resolve: the remainder is the member.

		  Var found() As Variant
		  ownerPath = ""

		  Var parts() As String = path.Split(".")
		  If parts.Count < 2 Then Return found

		  Var owner As XKProjectItem
		  Var ownerEnd As Integer = -1

		  For i As Integer = parts.LastIndex - 1 DownTo 0
		    Var prefix() As String
		    For j As Integer = 0 To i
		      prefix.Add(parts(j))
		    Next j

		    owner = FindItem(project, String.FromArray(prefix, "."))
		    If owner <> Nil Then
		      ownerEnd = i
		      Exit
		    End If
		  Next i

		  If owner = Nil Then Return found
		  ownerPath = QualifiedName(project, owner)

		  // Whatever follows the owner names the member: "Foo", or "Button1.Pressed".
		  Var tailParts() As String
		  For i As Integer = ownerEnd + 1 To parts.LastIndex
		    tailParts.Add(parts(i))
		  Next i
		  Var tail As String = String.FromArray(tailParts, ".").Lowercase
		  Var leaf As String = parts(parts.LastIndex).Lowercase

		  // A window carries its own handlers plus one group per control. Control handlers live
		  // in the .xojo_window file, which IDE scripting cannot see at all.
		  If owner IsA XKWindow Then
		    Var win As XKWindow = XKWindow(owner)

		    For Each ev As XKEvent In win.Events
		      If ev.Name.Lowercase = tail Then found.Add(ev)
		    Next ev

		    For Each g As XKControlEventGroup In win.ControlEventGroups
		      For Each ev As XKEvent In g.Events
		        Var qualified As String = g.ControlName + "." + ev.Name
		        If qualified.Lowercase = tail Then found.Add(ev)
		      Next ev
		    Next g

		    For Each m As XKMethod In win.Methods
		      If m.Name.Lowercase = leaf Then found.Add(m)
		    Next m

		    Return found
		  End If

		  Var container As XKCodeContainer = ContainerFrom(owner)
		  If container = Nil Then Return found

		  For Each m As XKMethod In container.Methods
		    If m.Name.Lowercase = leaf Then found.Add(m)
		  Next m

		  For Each ev As XKEvent In container.Events
		    If ev.Name.Lowercase = leaf Then found.Add(ev)
		  Next ev

		  Return found

		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Load(ByRef errorMessage As String, ByRef note As String) As XKProject
		  /// Saves the open project and parses the files on disk, or returns Nil with a reason.
		  ///
		  /// The save is deliberate and unconditional. Everything here reads the FILES, while
		  /// the rest of XMCP reads the IDE's memory, and the IDE cannot be asked whether it
		  /// has unsaved changes - there is no such command - so the only way to guarantee the
		  /// two agree is to write memory out first. Saving an unchanged project does nothing.
		  ///
		  /// The consequence is documented and deliberate: if the caller has edited a file on
		  /// disk without reloading, this save overwrites that edit with the IDE's older copy.
		  /// Callers surface the `note` so the user can see a save happened.

		  errorMessage = ""
		  note = ""

		  If App.IDE = Nil Then
		    errorMessage = "Xojo IDE is not connected. Start the IDE and restart XMCP."
		    Return Nil
		  End If

		  // 1. Where is the project, and is it a format we can read?
		  Var shellPath As String = ProjectPath
		  If shellPath = "" Then
		    errorMessage = "No project is open in the Xojo IDE, or it has never been saved to disk."
		    Return Nil
		  End If

		  Var manifest As FolderItem = FileFromShellPath(shellPath)
		  If manifest = Nil Then
		    errorMessage = "Could not resolve the project path: " + shellPath
		    Return Nil
		  End If

		  Var native As String = manifest.NativePath

		  If native.Lowercase.EndsWith(".xojo_binary_project") Then
		    errorMessage = "This project is saved in Xojo's binary format, which cannot be read as " + _
		    "text. Anything that inspects the files on disk needs the project saved as Text " + _
		    "(.xojo_project) or XML (.xojo_xml_project) - use File > Save As in the IDE. Both of " + _
		    "those are the version control formats, so this is worth doing anyway."
		    Return Nil
		  End If

		  // 2. Write the IDE's copy out so the files match what it holds - unless doing so
		  //    would downgrade the project. A project saved by a newer Xojo than the running
		  //    IDE opens with an "IDE Version Conflict" but opens anyway, and saving it would
		  //    write it back in the older IDE's format. Reading is safe; writing is not.
		  Var projectVersion As Double = ManifestVersion(manifest)
		  Var ideVersion As Double = IDEVersion

		  If projectVersion > 0.0 And ideVersion > 0.0 And projectVersion > ideVersion Then
		    note = "NOT saved first: this project was written by Xojo " + Format(projectVersion, "0000.000") + _
		    " and this IDE is " + Format(ideVersion, "0000.000") + ", so saving would rewrite it in the " + _
		    "older format. The files below are whatever was last written to disk, which may be behind " + _
		    "the IDE."
		  Else
		    Call App.IDE.SendAndReceive("DoCommand(""SaveFile"")" + EndOfLine + "Print ""saved""", 30000)
		    note = "The project was saved to disk first, so these files match the IDE."
		  End If

		  // 3. Parse whichever format this is.
		  Var project As XKProject
		  If native.Lowercase.EndsWith(".xojo_xml_project") Then
		    Var xml As New XKXMLParser
		    project = xml.ParseProject(native)
		    If project = Nil Then errorMessage = "Could not parse the XML project: " + xml.LastError
		  Else
		    Var text As New XKParser
		    project = text.ParseProject(native)
		    If project = Nil Then errorMessage = "Could not parse the project: " + text.LastError
		  End If

		  Return project

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function IDEVersion() As Double
		  /// The running IDE's version as a Double, e.g. 2025.031, or 0 if it cannot be read.

		  Var response As JSONItem = App.IDE.SendAndReceive("Print Str(XojoVersion)")
		  If response = Nil Or Not response.HasKey("response") Then Return 0.0

		  Var resp As Variant = response.Value("response")
		  If resp.Type <> Variant.TypeString Then Return 0.0

		  Return resp.StringValue.Trim.ToDouble

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ManifestVersion(manifest As FolderItem) As Double
		  /// The version of Xojo that last wrote this project, from RBProjectVersion in the
		  /// manifest, or 0 if it cannot be read. Both the text and XML formats are text files
		  /// carrying that value, so this needs no parser and can run before anything is saved.

		  If manifest = Nil Or Not manifest.Exists Then Return 0.0

		  Try
		    Var stream As TextInputStream = TextInputStream.Open(manifest)
		    stream.Encoding = Encodings.UTF8

		    // The value is near the top of both formats; do not read a large project in full.
		    Var head As String = stream.Read(4096)
		    stream.Close

		    Var rx As New RegEx
		    rx.SearchPattern = "RBProjectVersion=""?([0-9]+\.[0-9]+)"
		    Var match As RegExMatch = rx.Search(head)
		    If match = Nil Then Return 0.0

		    Return match.SubExpressionString(1).ToDouble
		  Catch e As RuntimeException
		    Return 0.0
		  End Try

		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ItemFile(project As XKProject, item As XKProjectItem) As FolderItem
		  /// The file on disk holding this project item, or Nil.

		  If project = Nil Or item = Nil Or item.RelativePath = "" Then Return Nil

		  Var manifest As FolderItem = FileFromShellPath(ProjectPath)
		  If manifest = Nil Or manifest.Parent = Nil Then Return Nil

		  Var file As FolderItem = manifest.Parent
		  For Each part As String In item.RelativePath.ReplaceAll("\\", "/").Split("/")
		    If part = "" Or part = "." Then Continue
		    Try
		      file = file.Child(part)
		    Catch e As RuntimeException
		      Return Nil
		    End Try
		    If file = Nil Then Return Nil
		  Next part

		  If Not file.Exists Then Return Nil
		  Return file

		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function RemoveMemberFromFile(project As XKProject, path As String, ByRef errorMessage As String) As Boolean
		  /// Deletes a member by cutting its #tag block out of the .xojo_code file that holds it.
		  ///
		  /// This is the only way to remove a method or property on a platform where the IDE's
		  /// DeleteSelection does nothing. The caller must reload the project afterwards, or the
		  /// IDE will still hold the member and write it back on its next save.
		  ///
		  /// Refuses when the name is ambiguous. Cutting the wrong overload out of a source file
		  /// is not a mistake worth risking to save a round trip.

		  errorMessage = ""

		  Var parts() As String = path.Split(".")
		  If parts.Count < 2 Then
		    errorMessage = "Not a member path: " + path
		    Return False
		  End If

		  Var name As String = parts(parts.LastIndex)
		  parts.RemoveAt(parts.LastIndex)
		  Var ownerPath As String = String.FromArray(parts, ".")

		  Var owner As XKProjectItem = FindItem(project, ownerPath)
		  If owner = Nil Then
		    errorMessage = "Could not find " + ownerPath + " in the project files."
		    Return False
		  End If

		  Var file As FolderItem = ItemFile(project, owner)
		  If file = Nil Then
		    errorMessage = "Could not locate the file for " + ownerPath + _
		    ". External items and binary projects cannot be edited this way."
		    Return False
		  End If

		  Var contents As String
		  Try
		    Var stream As TextInputStream = TextInputStream.Open(file)
		    stream.Encoding = Encodings.UTF8
		    contents = stream.ReadAll
		    stream.Close
		  Catch e As RuntimeException
		    errorMessage = "Could not read " + file.NativePath + ": " + e.Message
		    Return False
		  End Try

		  Var lines() As String = contents.ReplaceLineEndings(Chr(10)).Split(Chr(10))
		  Var keep() As String

		  Var blockStart As Integer = -1
		  Var blockKind As String = ""
		  Var blockMatches As Boolean = False
		  Var removed As Integer = 0
		  Var swallowBlank As Boolean = False
		  Var pending() As String

		  For i As Integer = 0 To lines.LastIndex
		    Var line As String = lines(i)
		    Var trimmed As String = line.Trim

		    If blockStart < 0 Then
		      // Swallow one blank line left behind by a removed block, so repeated deletes do
		      // not accumulate empty lines in the file.
		      If swallowBlank Then
		        swallowBlank = False
		        If trimmed = "" Then Continue
		      End If

		      Var kind As String = BlockKind(trimmed)
		      If kind <> "" Then
		        blockStart = i
		        blockKind = kind
		        blockMatches = TagLineNames(trimmed, name)
		        pending.RemoveAll
		        pending.Add(line)
		        Continue
		      End If

		      keep.Add(line)
		      Continue
		    End If

		    // Inside a block: collect it, and watch for the declaration that names the member.
		    pending.Add(line)
		    If Not blockMatches And DeclaresName(blockKind, trimmed, name) Then blockMatches = True

		    If trimmed = "#tag End" + blockKind Then
		      If blockMatches Then
		        removed = removed + 1
		        swallowBlank = True
		      Else
		        For Each held As String In pending
		          keep.Add(held)
		        Next held
		      End If
		      blockStart = -1
		      blockKind = ""
		      blockMatches = False
		      pending.RemoveAll
		    End If
		  Next i

		  If blockStart >= 0 Then
		    errorMessage = "The file ends inside an unterminated #tag block; refusing to edit it."
		    Return False
		  End If

		  If removed = 0 Then
		    errorMessage = "Found no declaration of """ + name + """ in " + file.NativePath + "."
		    Return False
		  End If

		  If removed > 1 Then
		    errorMessage = """" + name + """ has " + removed.ToString + " declarations in " + _
		    file.NativePath + ". Refusing to guess which to delete - remove the right #tag block " + _
		    "by hand, then call revert_project. describe_item lists them with their signatures."
		    Return False
		  End If

		  Try
		    Var out As TextOutputStream = TextOutputStream.Create(file)
		    out.Write(String.FromArray(keep, EndOfLine))
		    out.Close
		  Catch e As RuntimeException
		    errorMessage = "Could not write " + file.NativePath + ": " + e.Message
		    Return False
		  End Try

		  Return True

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function BlockKind(trimmedLine As String) As String
		  /// The kind of #tag block this line opens, or "".

		  If Not trimmedLine.BeginsWith("#tag ") Then Return ""

		  Var kinds() As String = Array("Method", "ComputedProperty", "Property", "Constant", "Note", "Event")
		  For Each kind As String In kinds
		    If trimmedLine.BeginsWith("#tag " + kind) Then Return kind
		  Next kind

		  Return ""

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function DeclaresName(blockKind As String, trimmedLine As String, name As String) As Boolean
		  /// Whether this line inside a block declares the named member.

		  Select Case blockKind
		  Case "Method", "Event"
		    Var lower As String = trimmedLine.Lowercase
		    Var target As String = name.Lowercase
		    Return lower.IndexOf("sub " + target + "(") >= 0 Or _
		    lower.IndexOf("function " + target + "(") >= 0

		  Case "Property", "ComputedProperty"
		    // "Name As Type", possibly preceded by a scope keyword.
		    Var words() As String = trimmedLine.Split(" ")
		    For i As Integer = 0 To words.LastIndex
		      Var word As String = words(i).Trim
		      If word = "" Then Continue
		      Var bare As String = word
		      Var bracket As Integer = bare.IndexOf("(")
		      If bracket > 0 Then bare = bare.Left(bracket)
		      If bare.Lowercase = name.Lowercase Then Return True
		      If word.Lowercase <> "protected" And word.Lowercase <> "private" And _
		        word.Lowercase <> "shared" Then Return False
		    Next i
		    Return False
		  End Select

		  Return False

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function TagLineNames(trimmedLine As String, name As String) As Boolean
		  /// Constants and notes carry their name on the tag line itself:
		  /// #tag Constant, Name = kFoo, Type = ...

		  Var marker As String = "name = "
		  Var lower As String = trimmedLine.Lowercase
		  Var at As Integer = lower.IndexOf(marker)
		  If at < 0 Then Return False

		  Var rest As String = trimmedLine.Middle(at + marker.Length)
		  Var comma As Integer = rest.IndexOf(",")
		  If comma >= 0 Then rest = rest.Left(comma)

		  Return rest.Trim.Lowercase = name.Lowercase

		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MemberSignature(member As Variant) As String
		  /// A one-line signature for a parsed member.

		  If member IsA XKMethod Then Return MethodSignature(XKMethod(member))

		  If member IsA XKEvent Then
		    Var ev As XKEvent = XKEvent(member)
		    Var label As String = ev.Name
		    If ev.ControlName <> "" Then label = ev.ControlName + "." + ev.Name
		    If ev.ReturnType <> "" Then label = label + " As " + ev.ReturnType
		    Return label + "  (event implementation)"
		  End If

		  Return ""

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function MethodSignature(m As XKMethod) As String
		  Var params() As String
		  For Each p As XKParameter In m.Parameters
		    Var text As String = ""
		    If p.IsByRef Then text = "ByRef "
		    If p.IsParamArray Then text = "ParamArray "
		    If p.IsOptional Then text = "Optional " + text
		    text = text + p.Name
		    If p.IsArray Then text = text + "()"
		    If p.DataType <> "" Then text = text + " As " + p.DataType
		    If p.DefaultValue <> "" Then text = text + " = " + p.DefaultValue
		    params.Add(text)
		  Next p

		  Var out As String = m.AccessModifierName + " "
		  If m.IsShared Then out = out + "Shared "
		  out = out + If(m.IsFunction, "Function ", "Sub ") + m.Name + _
		  "(" + String.FromArray(params, ", ") + ")"
		  If m.ReturnType <> "" Then out = out + " As " + m.ReturnType

		  Return out.Trim

		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MemberCode(member As Variant) As String
		  /// The body of a parsed member, as it stands in the file.

		  If member IsA XKMethod Then Return String.FromArray(XKMethod(member).CodeLines, EndOfLine)
		  If member IsA XKEvent Then Return String.FromArray(XKEvent(member).CodeLines, EndOfLine)
		  Return ""

		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function QualifiedName(project As XKProject, item As XKProjectItem) As String
		  /// The item's dot-separated path with folders left out, matching the paths the IDE
		  /// itself uses - the folder a class sits in is not part of how you address it.

		  If item = Nil Then Return ""

		  Var parts() As String
		  parts.Add(item.Name)

		  Var guard As Integer = 0
		  Var current As XKProjectItem = item

		  While current <> Nil And current.ParentGUID <> "" And guard < 32
		    guard = guard + 1
		    current = project.ItemByGUID(current.ParentGUID)
		    If current = Nil Then Exit
		    If current.ItemType = "Folder" Then Continue
		    parts.AddAt(0, current.Name)
		  Wend

		  Return String.FromArray(parts, ".")

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FileFromShellPath(shellPath As String) As FolderItem
		  If shellPath.Trim = "" Then Return Nil

		  Try
		    Return New FolderItem(shellPath, FolderItem.PathModes.Shell)
		  Catch e As RuntimeException
		    Return Nil
		  End Try

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ProjectPath() As String
		  Var response As JSONItem = App.IDE.SendAndReceive("Print ProjectShellPath")
		  If response = Nil Or Not response.HasKey("response") Then Return ""

		  Var resp As Variant = response.Value("response")
		  If resp.Type <> Variant.TypeString Then Return ""

		  Return resp.StringValue.Trim

		End Function
	#tag EndMethod


	#tag Method, Flags = &h21
		Private Function Unquote(value As String) As String
		  /// Strips the escaping the project file stores literals with: Default = \"1500" .

		  Var out As String = value.Trim
		  If out.BeginsWith("\" + """") Then out = out.Middle(2)
		  If out.EndsWith("""") Then out = out.Left(out.Length - 1)
		  Return out

		End Function
	#tag EndMethod

	#tag ViewBehavior
	#tag EndViewBehavior
End Module
#tag EndModule
