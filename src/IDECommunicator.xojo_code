#tag Class
Protected Class IDECommunicator
	#tag Method, Flags = &h0
		Sub Constructor()
		  mTagCounter = 0
		  mSocketPath = ""  // No last-known-good path yet; discovered on first request.
		  LastErrorMessage = ""
		  mConnected = False
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function CandidateSocketPaths() As String()
		  /// The last known good path first, then every path the IDE may be listening on
		  /// for this platform. See Platform.IPCSocketPaths.

		  Var paths() As String
		  paths.Add(mSocketPath)
		  For Each p As String In Platform.IPCSocketPaths
		    paths.Add(p)
		  Next p

		  Var unique() As String
		  For Each p As String In paths
		    If p.Trim = "" Then Continue
		    If Not ContainsString(unique, p) Then unique.Add(p)
		  Next p
		  
		  Return unique
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ContainsString(values() As String, target As String) As Boolean
		  For Each value As String In values
		    If value = target Then Return True
		  Next value
		  
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NextTag() As String
		  /// Returns a unique tag string for each request to correlate requests with responses.

		  mTagCounter = mTagCounter + 1
		  Return "xmcp_" + mTagCounter.ToString

		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Reconnect()
		  /// Reconnect to the Xojo IDE.

		  mSocketPath = ""  // Forget the last known good path and rediscover.
		  LastErrorMessage = ""
		  mConnected = False

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SendAndReceive(script As String, timeoutMS As Integer = 10000) As JSONItem
		  /// Sends an IDE script and waits synchronously for the tagged response.
		  /// Uses IPCSocket transport only.
		  /// Returns the response JSON or Nil on timeout.
		  ///
		  /// Retries up to 3 times with a short pause if the socket is temporarily
		  /// unavailable (e.g. after the Xojo IDE navigates to a new item).

		  LastErrorMessage = ""

		  Var tag As String = NextTag

		  // Build protocol upgrade + script request.
		  Var proto As New JSONItem
		  proto.Value("protocol") = 2

		  Var req As New JSONItem
		  req.Value("tag") = tag
		  req.Value("script") = script

		  Var payload As String = proto.ToString + Chr(0) + req.ToString + Chr(0)
		  LogVerbose("IDE request " + tag + ": trying IPCSocket transport.")

		  Const kMaxRetries = 5
		  Const kRetryPauseMS = 1000

		  Var attempt As Integer = 0
		  While attempt < kMaxRetries
		    attempt = attempt + 1

		    Var socketErrors() As String
		    For Each candidatePath As String In CandidateSocketPaths
		      LogVerbose("IDE request " + tag + ": IPCSocket path " + candidatePath + " (attempt " + attempt.ToString + ")")
		      Var responseViaSocket As JSONItem = SendAndReceiveViaIPCSocket(candidatePath, payload, tag, timeoutMS)
		      If responseViaSocket <> Nil Then
		        mConnected = True
		        mSocketPath = candidatePath
		        LastErrorMessage = ""
		        LogVerbose("IDE request " + tag + ": success via IPCSocket (" + candidatePath + ").")
		        Return responseViaSocket
		      End If

		      If LastErrorMessage <> "" Then
		        LogVerbose("IDE request " + tag + ": IPCSocket failed (" + candidatePath + "): " + LastErrorMessage)
		        socketErrors.Add(LastErrorMessage)
		      End If
		    Next candidatePath

		    // All paths failed. If nothing was listening anywhere (the IDE temporarily
		    // closes its socket after a navigation), wait briefly and retry. On macOS
		    // that shows up as a missing socket file; on Windows, where there is no file
		    // to miss, it shows up as a failed connect - kNoListenerPrefix covers both.
		    Var allNoListener As Boolean = True
		    For Each err As String In socketErrors
		      If Not err.BeginsWith(kNoListenerPrefix) Then
		        allNoListener = False
		        Exit
		      End If
		    Next err

		    If attempt < kMaxRetries And (socketErrors.Count = 0 Or allNoListener) Then
		      LogVerbose("IDE request " + tag + ": socket temporarily unavailable, retrying in " + kRetryPauseMS.ToString + "ms...")
		      // Sleeping is safe here: this app has no Timers or socket event handlers,
		      // and the IPCSocket below is driven by explicit Poll calls.
		      Thread.SleepCurrent(kRetryPauseMS)
		    Else
		      If socketErrors.Count > 0 Then
		        LastErrorMessage = String.FromArray(socketErrors, " | ")
		      Else
		        LastErrorMessage = "No IPCSocket response from Xojo IDE within " + timeoutMS.ToString + _
		        "ms. Searched: " + Platform.SocketPathSummary
		      End If

		      If allNoListener Then
		        // Nothing was listening on any candidate path. By far the most common cause
		        // is simply that the IDE is not running, and the raw timeout text does not
		        // suggest that - so say it.
		        LastErrorMessage = LastErrorMessage + " Is the Xojo IDE running with a project open?"
		      End If
		      Exit While
		    End If
		  Wend

		  LogVerbose("IDE request " + tag + ": failed. " + LastErrorMessage)

		  mConnected = False
		  Return Nil

		End Function
	#tag EndMethod
	
	#tag Method, Flags = &h21
		Private Sub LogVerbose(message As String)
		  If App <> Nil And App.Verbose Then
		    System.DebugLog(message)
		  End If
		End Sub
	#tag EndMethod
	
	#tag Method, Flags = &h21
		Private Function SendAndReceiveViaIPCSocket(candidatePath As String, payload As String, tag As String, timeoutMS As Integer) As JSONItem
		  LastErrorMessage = ""
		  
		  #If Not TargetWindows Then
		    // A Unix domain socket is a real filesystem entry, so a missing file means the
		    // IDE is definitely not listening here and we can skip the connect entirely.
		    // Never do this on Windows: an IPCSocket endpoint there has no filesystem
		    // entry at all, so Exists is always False even while the IDE is listening.
		    Var socketFile As New FolderItem(candidatePath, FolderItem.PathModes.Native)
		    If socketFile = Nil Or Not socketFile.Exists Then
		      LastErrorMessage = kNoListenerPrefix + " at " + candidatePath + " (no socket file)."
		      Return Nil
		    End If
		  #EndIf

		  Var deadlineUS As Double = System.Microseconds + (timeoutMS * 1000.0)
		  Var sock As New IPCSocket
		  sock.Path = candidatePath

		  Try
		    sock.Connect
		  Catch e As RuntimeException
		    LastErrorMessage = kNoListenerPrefix + " at " + candidatePath + ": " + e.Message
		    Return Nil
		  End Try

		  // Bound the connect wait separately from the response wait. Without a real
		  // socket file to pre-check, a wrong candidate can only be ruled out by a failed
		  // connect, and a build request would otherwise sit here for its full 120s
		  // timeout on every candidate before reaching the one the IDE is listening on.
		  Var connectTimeoutMS As Integer = timeoutMS
		  If connectTimeoutMS > kConnectTimeoutMS Then connectTimeoutMS = kConnectTimeoutMS
		  Var connectDeadlineUS As Double = System.Microseconds + (connectTimeoutMS * 1000.0)

		  While Not sock.IsConnected And System.Microseconds < connectDeadlineUS
		    sock.Poll
		    Thread.SleepCurrent(1)  // 1ms between polls; without this we spin a core until connected.
		  Wend

		  If Not sock.IsConnected Then
		    sock.Close
		    LastErrorMessage = kNoListenerPrefix + " at " + candidatePath + _
		    " (connect timed out after " + connectTimeoutMS.ToString + "ms)."
		    Return Nil
		  End If

		  Try
		    sock.Write(payload)
		    sock.Flush
		  Catch e As RuntimeException
		    sock.Close
		    LastErrorMessage = "IPCSocket write failed for " + candidatePath + ": " + e.Message
		    Return Nil
		  End Try
		  
		  Var buffer As String = ""
		  Var hadData As Boolean = False
		  
		  While System.Microseconds < deadlineUS
		    sock.Poll
		    
		    Var chunk As String = sock.ReadAll
		    If chunk = "" Then
		      // Same trap as the stdin loop in ServerApplication: an empty read plus a bare
		      // Continue spins a core for the whole time we wait for the IDE to answer.
		      Thread.SleepCurrent(1)
		      Continue
		    End If
		    
		    hadData = True
		    buffer = buffer + chunk
		    
		    Var nulPos As Integer = buffer.IndexOf(Chr(0))
		    While nulPos >= 0
		      Var frame As String = buffer.Left(nulPos).Trim
		      buffer = buffer.Middle(nulPos + 1)
		      nulPos = buffer.IndexOf(Chr(0))
		      
		      If frame = "" Then Continue
		      
		      Try
		        Var response As New JSONItem(frame)
		        If response.HasKey("tag") And response.Value("tag").StringValue = tag Then
		          sock.Close
		          LastErrorMessage = ""
		          Return response
		        End If
		      Catch e As JSONException
		        // Ignore malformed chunks and continue.
		      End Try
		    Wend
		  Wend
		  
		  sock.Close
		  
		  If hadData Then
		    LastErrorMessage = "Received IPC data from " + candidatePath + ", but no matching tag was found for " + tag + "."
		  Else
		    LastErrorMessage = "No IPCSocket response from " + candidatePath + " within " + timeoutMS.ToString + "ms."
		  End If
		  
		  Return Nil
		End Function
	#tag EndMethod

	#tag Constant, Name = kConnectTimeoutMS, Type = Double, Dynamic = False, Default = \"1500", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kNoListenerPrefix, Type = String, Dynamic = False, Default = \"No IDE listener", Scope = Private
	#tag EndConstant

	#tag Property, Flags = &h0
		LastErrorMessage As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mConnected As Boolean
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mSocketPath As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected mTagCounter As Integer
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
			InitialValue=""
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
	#tag EndViewBehavior
End Class
#tag EndClass
