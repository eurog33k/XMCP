#tag Module
Protected Module XKParserUtils
	#tag Method, Flags = &h1, Description = 4465636F6465732061206865782D656E636F64656420737472696E6720746F20706C61696E20746578742E
		Protected Function DecodeHexString(hexStr As String) As String
		  /// Decodes a hex-encoded string to plain text.
		  ///
		  /// Each pair of hex digits represents one byte of UTF-8 text.
		  
		  If hexStr = "" Then Return ""
		  
		  // Calculate the number of complete byte pairs.
		  // If the string has an odd length, ignore the trailing character.
		  Var byteCount As Integer = hexStr.Length \ 2
		  If byteCount = 0 Then Return ""
		  
		  Var mb As New MemoryBlock(byteCount)
		  
		  For i As Integer = 0 To byteCount - 1
		    Var hexByte As String = hexStr.Middle(i * 2, 2)
		    Var byteValue As Integer = Val("&h" + hexByte)
		    mb.Byte(i) = byteValue
		  Next i
		  
		  Return mb.StringValue(0, mb.Size, Encodings.UTF8)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1, Description = 50617273657320612073696E676C6520706172616D6574657220737472696E672E
		Protected Function ParseSingleParameter(param As String) As XKParameter
		  /// Parses a single parameter string.
		  
		  If param = "" Then Return Nil
		  
		  Var p As New XKParameter
		  
		  // Check for modifiers.
		  If param.IndexOf("ByRef ") >= 0 Then
		    p.IsByRef = True
		    param = param.ReplaceAll("ByRef ", "")
		  End If
		  
		  If param.IndexOf("Optional ") >= 0 Then
		    p.IsOptional = True
		    param = param.ReplaceAll("Optional ", "")
		  End If
		  
		  If param.IndexOf("ParamArray ") >= 0 Then
		    p.IsParamArray = True
		    param = param.ReplaceAll("ParamArray ", "")
		  End If
		  
		  // Check for array syntax.
		  If param.IndexOf("()") >= 0 Then
		    p.IsArray = True
		    param = param.ReplaceAll("()", "")
		  End If
		  
		  // Split by "As".
		  Var asPos As Integer = param.IndexOf(" As ")
		  If asPos < 0 Then
		    p.Name = param.Trim
		    Return p
		  End If
		  
		  p.Name = param.Left(asPos).Trim
		  
		  Var afterAs As String = param.Middle(asPos + 4).Trim
		  
		  // Check for default value.
		  Var eqPos As Integer = afterAs.IndexOf(" = ")
		  If eqPos >= 0 Then
		    p.DataType = afterAs.Left(eqPos).Trim
		    p.DefaultValue = afterAs.Middle(eqPos + 3).Trim
		  Else
		    p.DataType = afterAs
		  End If
		  
		  Return p
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1, Description = 5265616473207468652074657874696E6720636F6E74656E7473206F6620612066696C652E
		Protected Function ReadFileContents(f As FolderItem) As String
		  /// Reads the contents of a file.
		  
		  If f = Nil Or Not f.Exists Then Return ""
		  
		  Try
		    Var stream As TextInputStream = TextInputStream.Open(f)
		    stream.Encoding = Encodings.UTF8
		    Var content As String = stream.ReadAll
		    stream.Close
		    Return content
		  Catch e As IOException
		    Return ""
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1, Description = 5265736F6C76657320612072656C6174697665207061746820746F20616E206162736F6C7574652070617468206261736564206F6E207468652070726F6A656374206469726563746F72792E
		Protected Function ResolveRelativePath(baseDirectory As FolderItem, relativePath As String) As String
		  /// Resolves a relative path to an absolute path based on the project directory.
		  
		  If baseDirectory = Nil Then Return ""
		  
		  // Split the path and navigate through each component.
		  Var parts() As String = relativePath.Split("/")
		  Var f As FolderItem = baseDirectory
		  
		  For Each part As String In parts
		    If part <> "" Then
		      f = f.Child(part)
		      If f = Nil Then Return ""
		    End If
		  Next part
		  
		  If f <> Nil And f.Exists Then
		    Return f.NativePath
		  End If
		  
		  Return ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1, Description = 53706C697473206120706172616D6574657220737472696E6720627920636F6D6D61732C2068616E646C696E67206E657374656420747970657320636F72726563746C792E
		Protected Function SplitParameters(paramStr As String) As String()
		  /// Splits a parameter string by commas, handling nested types correctly.
		  
		  Var result() As String
		  Var current As String = ""
		  Var depth As Integer = 0
		  
		  For i As Integer = 0 To paramStr.Length - 1
		    Var c As String = paramStr.Middle(i, 1)
		    
		    If c = "(" Then
		      depth = depth + 1
		      current = current + c
		    ElseIf c = ")" Then
		      depth = depth - 1
		      current = current + c
		    ElseIf c = "," And depth = 0 Then
		      result.Add(current)
		      current = ""
		    Else
		      current = current + c
		    End If
		  Next i
		  
		  If current.Trim <> "" Then
		    result.Add(current)
		  End If
		  
		  Return result
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
