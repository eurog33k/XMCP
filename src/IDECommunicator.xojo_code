#tag Class
Protected Class IDECommunicator
	#tag Method, Flags = &h0
		Sub Constructor()
		  mTagCounter = 0
		  mSocketPath = FindIPCPath
		  LastErrorMessage = ""
		  mConnected = False
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function CandidateSocketPaths() As String()
		  /// The path that last worked first, then the platform's candidates in the
		  /// order the IDE itself considers them. See Platform.IPCSocketPaths.
		  
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

	#tag Method, Flags = &h21
		Private Function FindIPCPath() As String
		  /// The path the IDE is most likely listening on. Platform.IPCSocketPaths
		  /// probes candidate FOLDERS for writability rather than testing the socket
		  /// path itself, which is the only form that works on Windows.
		  
		  Var paths() As String = Platform.IPCSocketPaths
		  If paths.Count > 0 Then Return paths(0)
		  
		  Return ""
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

		  mSocketPath = FindIPCPath
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
		  /// Retries up to kMaxRetries times with a short pause if the socket is
		  /// temporarily unavailable (e.g. after the Xojo IDE navigates to a new
		  /// item) and the failure happened before the script was written to the
		  /// socket. Once the script has actually been sent, a subsequent failure
		  /// (e.g. timeout waiting for the response) is NOT retried, since the IDE
		  /// may have already executed it — resending could run it twice.

		  LastErrorMessage = ""
		  mParkedThisRequest = False
		  
		  // A request the IDE has accepted but not answered is still being executed: the
		  // IDE runs scripts one at a time on its main thread, and a build (or a modal
		  // dialog) holds it for minutes. Sending another request now would only queue it
		  // behind that one and give up on it too. Say so instead; DrainPending notices
		  // when the IDE has caught up and the next call goes through normally.
		  If DrainPending > 0 Then
		    // "Has not finished answering", not "has not answered": for 250ms after the IDE's answer
		    // starts arriving, XMCP is still collecting it (see PendingRequest.ReplyComplete) and the
		    // request is still held, so a new one is still turned down - correctly, but saying the IDE
		    // "has not answered" would then be untrue.
		    LastErrorMessage = "The Xojo IDE is still busy with an earlier request and has not finished answering it:" + _
		    EndOfLine + PendingSummary + EndOfLine + _
		    "No new request was sent. A build blocks the IDE until it finishes; wait for it, then try again. " + _
		    "Do not quit or restart Claude Code (or whichever MCP client you use) meanwhile: on macOS " + _
		    "and Linux the Xojo IDE crashes if it answers over a connection that has been closed."
		    LogVerbose("IDE request refused: " + LastErrorMessage)
		    Return Nil
		  End If
		  
		  Var tag As String = NextTag

		  // Build protocol upgrade + script request.
		  Var proto As New JSONItem
		  proto.Value("protocol") = 2

		  // Every request must be answerable. The IDE answers once per Print and not at all
		  // without one, so a script that prints nothing is never replied to: the request
		  // times out, its socket is parked, and because the IDE serves one IPC connection at
		  // a time that blocks every other client until the give-up timer expires. Appending
		  // the sentinel here rather than in each tool means a tool cannot forget, and a
		  // caller-supplied script - run_ide_script, or anything through RunScript - cannot
		  // reintroduce it. MergeReply ranks real output above an empty reply, so a script
		  // that does print still reports its own output.
		  //
		  // Skipped only when the script really ends in a line continuation, where the sentinel
		  // would be absorbed into that line and change its meaning. Such a script does not
		  // compile, and a compile error is itself a reply, so it cannot park either way. What
		  // counts as a continuation is decided by EndsWithLineContinuation, not by the last
		  // character: a comment or a name can end in an underscore too.
		  //
		  // An empty or whitespace-only script gets the sentinel as well. Without it such a
		  // script reaches the IDE with no Print, is never answered, and parks. Tools guard
		  // against sending one, but the guarantee belongs here, where no caller can skip it.
		  Var sent As String = script
		  If Not EndsWithLineContinuation(script) Then
		    sent = script + EndOfLine + "Print """""
		  End If
		  
		  Var req As New JSONItem
		  req.Value("tag") = tag
		  req.Value("script") = sent

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
		      Var responseViaSocket As JSONItem = SendAndReceiveViaIPCSocket(candidatePath, payload, tag, timeoutMS, script)
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
		      
		      // The request was delivered and is now parked: the IDE has it and will execute
		      // it. Trying the remaining candidate paths - on macOS the same socket under
		      // other names - would only knock on a busy IDE again and clutter the message
		      // with "no listener" noise that is not the problem.
		      If mParkedThisRequest Then Exit
		    Next candidatePath
		    
		    If mParkedThisRequest Then
		      mParkedThisRequest = False
		      LastErrorMessage = String.FromArray(socketErrors, " | ")
		      Exit While
		    End If
		    
		    // All paths failed. If the socket was simply not found (IDE temporarily
		    // closed it after a navigation), wait briefly and retry.
		    Var allNotFound As Boolean = True
		    For Each err As String In socketErrors
		      If Not err.BeginsWith(kNoListenerPrefix) Then
		        allNotFound = False
		        Exit
		      End If
		    Next err

		    If attempt < kMaxRetries And (socketErrors.Count = 0 Or allNotFound) Then
		      LogVerbose("IDE request " + tag + ": socket temporarily unavailable, retrying in " + kRetryPauseMS.ToString + "ms...")
		      Var pauseDeadline As Double = System.Microseconds + (kRetryPauseMS * 1000.0)
		      While System.Microseconds < pauseDeadline
		        App.SleepCurrentThread(10)
		      Wend
		    Else
		      If socketErrors.Count > 0 Then
		        LastErrorMessage = String.FromArray(socketErrors, " | ")
		      Else
		        LastErrorMessage = "No IPCSocket response from Xojo IDE within " + timeoutMS.ToString + _
		        "ms. Searched: " + Platform.SocketPathSummary
		      End If
		      Exit While
		    End If
		  Wend

		  LogVerbose("IDE request " + tag + ": failed. " + LastErrorMessage)

		  mConnected = False
		  Return Nil

		End Function
	#tag EndMethod
	
	#tag Method, Flags = &h0
		Function RunScript(script As String, timeoutMS As Integer = 10000) As MCPKit.ToolResult
		  /// Sends an IDE script and converts the reply into a ToolResult. Thirteen tools go
		  /// through here - set_code, constant_value, get_code, select_project_item and the rest -
		  /// so this is the path most of XMCP reports through.
		  ///
		  /// It now reports through the same classifier as run_ide_script, build_project,
		  /// run_project and analyze_project. It used to have its own rules, and they were wrong
		  /// in both directions: any reply carrying a scriptError key became a Failure with the
		  /// envelope dumped as raw JSON, so a script that merely raised a compiler warning was
		  /// reported as an outright failure; and a warning arriving alongside real output was
		  /// dropped entirely, because the merged parts under xmcp_parts were never read.
		  ///
		  /// That was not hypothetical. get_selected_text builds a script using Str() on an
		  /// Integer, which the IDE answers with a precision warning on every call - visible
		  /// through run_ide_script, silently discarded here.
		  ///
		  /// Three behaviours callers depend on are kept. A response that is a string is never
		  /// re-parsed as JSON: a constant or description whose text happens to contain
		  /// {"buildError":...} is content, not a failure, and re-parsing it used to say
		  /// otherwise. A script that deliberately prints "ERROR: ..." is still a Failure - that
		  /// is how several tools report their own guard clauses. And an empty object, which is
		  /// how the IDE answers a script that printed an empty string, still normalises to ""
		  /// rather than the literal text "{}".
		  
		  Var response As JSONItem = SendAndReceive(script, timeoutMS)
		  If response = Nil Then
		    If LastErrorMessage <> "" Then
		      Return MCPKit.ToolResult.Failure(LastErrorMessage)
		    End If
		    Var timeoutS As Integer = timeoutMS / 1000
		    Return MCPKit.ToolResult.Failure("No answer from the IDE within " + timeoutS.ToString + "s.")
		  End If
		  
		  If Not response.HasKey("response") Then
		    Return MCPKit.ToolResult.Failure("Unexpected response from IDE: " + response.ToString)
		  End If
		  
		  // Blocking errors first, in every shape the IDE sends, formatted, with the line numbers
		  // corrected for the boilerplate line it wraps each script in. ReplyDiagnostics returns
		  // "" for output, an empty reply, or warnings only, so a warning never lands here.
		  Var diagnostics As String = ReplyDiagnostics(response)
		  If diagnostics <> "" Then Return MCPKit.ToolResult.Failure(diagnostics)
		  
		  // Warnings are handled differently here than in run_ide_script, on purpose.
		  //
		  // The scripts reaching RunScript are generated by XMCP, not written by the caller, so a
		  // compiler warning about one is our own flaw rather than anything the caller can act on:
		  // get_selected_text uses Str() on an Integer and the IDE warns about the precision on
		  // every call. Appending that to the result would corrupt it, because for most of these
		  // tools the result IS data - the selected text, a constant's value, a list of items -
		  // and there would be no way to tell where the data ended and the diagnostic began.
		  //
		  // So a warning is attached only when the script printed nothing, where there is nothing
		  // to corrupt and it explains the silence. Otherwise it is logged and kept out of the
		  // payload. run_ide_script still reports warnings inline, because there the script is the
		  // caller's own and the warning is about their code.
		  Var warnings As String = ReplyWarnings(response)
		  
		  Var resp As String
		  Var kind As String = ReplyKind(response)
		  
		  If kind = "warning" Or kind = "empty" Then
		    // Nothing was printed. The warnings, if any, are the whole of what there is to say.
		    resp = ""
		  Else
		    Var respVar As Variant = response.Value("response")
		    If respVar.Type <> Variant.TypeObject Then
		      resp = respVar.StringValue
		    Else
		      Var respJSON As JSONItem
		      Try
		        respJSON = response.Value("response")
		      Catch e As RuntimeException
		        respJSON = Nil
		      End Try
		      If respJSON = Nil Then
		        resp = respVar.StringValue
		      ElseIf respJSON.Count = 0 Then
		        resp = ""
		      Else
		        resp = respJSON.ToString
		      End If
		    End If
		  End If
		  
		  If warnings <> "" Then
		    // Exact, for the same reason as MergeReply: resp is data. (A whitespace-only result
		    // cannot actually reach here - the IDE collapses one to an empty reply - but the test
		    // should not depend on that.)
		    If resp = "" Then
		      resp = "The script ran but printed nothing. The IDE reported warnings about it:" + _
		      EndOfLine + warnings
		    Else
		      LogVerbose("Script warnings (not surfaced, the reply carries data): " + warnings)
		    End If
		  End If
		  
		  // Case-sensitive, and deliberately not trimmed. BeginsWith is case-insensitive by
		  // default in this Xojo version, so "Error: ..." or "error: ..." in a result - a
		  // constant's value, a line of selected code - was misreported as a failure. Every tool
		  // that reports its own guard clause prints exactly "ERROR:" at the very start, so the
		  // exact, case-sensitive prefix is the whole contract; trimming would let data that
		  // merely contains "ERROR:" after some whitespace be mistaken for one.
		  If resp.BeginsWith("ERROR:", ComparisonOptions.CaseSensitive) Then
		    Return MCPKit.ToolResult.Failure(resp)
		  End If
		  
		  Return MCPKit.ToolResult.Success(resp)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function EndsWithLineContinuation(script As String) As Boolean
		  /// True when the script's last line of code ends in a line continuation, so that an
		  /// appended line would be absorbed into it.
		  ///
		  /// This used to be "the trimmed script's last character is an underscore", and that is
		  /// wrong in two ways that were each measured on 2026r2.1:
		  ///   - a comment can end in one. "Var x As Integer = 1 // rename to foo_" followed by
		  ///     more code runs the next line, so the underscore is not a continuation;
		  ///   - a name can end in one. "Var foo_ As Integer = 7" is legal.
		  /// Either as the last line of a script with no Print of its own meant no sentinel, no
		  /// reply, and the socket parked for the full give-up time.
		  ///
		  /// So the trailing comment is removed first - a ' or // outside a string literal - and an
		  /// underscore then counts only when it is not the end of a name. It cannot be told apart
		  /// by the space before it: "+_" continues exactly as "+ _" does.
		  ///
		  /// When unsure this returns False, which appends the sentinel. That is the safe way to be
		  /// wrong: a sentinel appended to a real continuation only changes the compile error of a
		  /// script that could not compile anyway, whereas a skipped one leaves a valid script
		  /// unanswered.
		  
		  Var lines() As String = script.ReplaceLineEndings(Chr(10)).Split(Chr(10))
		  Var last As String = ""
		  For i As Integer = lines.LastIndex DownTo 0
		    If lines(i).Trim <> "" Then
		      last = lines(i)
		      Exit
		    End If
		  Next i
		  If last = "" Then Return False
		  
		  // Keep the code part of the line. A comment marker inside a string literal is text, so
		  // track whether we are inside one; a doubled quote toggles twice and stays balanced.
		  Var code As String = ""
		  Var inString As Boolean = False
		  Var n As Integer = last.Length
		  For i As Integer = 0 To n - 1
		    Var c As String = last.Middle(i, 1)
		    If c = Chr(34) Then
		      inString = Not inString
		    ElseIf Not inString Then
		      If c = "'" Then Exit
		      If c = "/" And i + 1 < n And last.Middle(i + 1, 1) = "/" Then Exit
		    End If
		    code = code + c
		  Next i
		  code = code.Trim
		  
		  // A line that is only a Rem comment has no code at all. (= is case-insensitive here,
		  // which matches Rem, REM and rem alike.)
		  If code.Length >= 3 And code.Left(3) = "Rem" Then
		    If code.Length = 3 Or code.Middle(3, 1) = " " Or code.Middle(3, 1) = Chr(9) Then Return False
		  End If
		  
		  If code.Length = 0 Or code.Right(1) <> "_" Then Return False
		  If code.Length = 1 Then Return True
		  
		  // An underscore that ends a name - foo_ - belongs to the name.
		  Return Not IsNameCharacter(code.Middle(code.Length - 2, 1))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function IsNameCharacter(c As String) As Boolean
		  /// Letters, digits and the underscore. Anything outside ASCII is counted as a letter too:
		  /// that makes EndsWithLineContinuation return False and append the sentinel, which is
		  /// the safe way to be wrong.
		  
		  If c = "" Then Return False
		  If c = "_" Then Return True
		  Var codePoint As Integer = c.Asc
		  If codePoint >= 48 And codePoint <= 57 Then Return True
		  If codePoint >= 65 And codePoint <= 90 Then Return True
		  If codePoint >= 97 And codePoint <= 122 Then Return True
		  Return codePoint > 127
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
		Private Function SendAndReceiveViaIPCSocket(candidatePath As String, payload As String, tag As String, timeoutMS As Integer, script As String) As JSONItem
		  LastErrorMessage = ""

		  #If Not TargetWindows Then
		    // A Unix domain socket is a real filesystem entry, so a missing file means the
		    // IDE is definitely not listening here and the connect can be skipped entirely.
		    // Never do this on Windows: an IPCSocket endpoint there is not a file but a TCP
		    // socket on localhost whose port is derived from the path string, so Exists is
		    // always False even while the IDE is listening.
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
		    // Whether this counts as 'nobody is listening' - and so as retryable - differs
		    // by platform. Off Windows the Exists check above already ruled out a missing
		    // socket, so a failed connect means something more specific (a stale socket from
		    // a crashed IDE, a permission problem) and is reported as fatal, unchanged from
		    // before. On Windows there is no such check to lean on, so a failed connect is
		    // the only evidence that nothing is listening on this candidate.
		    #If TargetWindows Then
		      LastErrorMessage = kNoListenerPrefix + " at " + candidatePath + ": " + e.Message
		    #Else
		      LastErrorMessage = "IPCSocket connect failed for " + candidatePath + ": " + e.Message
		    #EndIf
		    Return Nil
		  End Try
		  
		  // Bound the connect wait separately from the response wait. Without a socket file
		  // to pre-check, a wrong candidate can only be ruled out by a failed connect, and a
		  // build request would otherwise sit here for its full 120s timeout on every
		  // candidate before reaching the one the IDE is listening on.
		  Var connectTimeoutMS As Integer = timeoutMS
		  If connectTimeoutMS > kConnectTimeoutMS Then connectTimeoutMS = kConnectTimeoutMS
		  Var connectDeadlineUS As Double = System.Microseconds + (connectTimeoutMS * 1000.0)
		  
		  While Not sock.IsConnected And System.Microseconds < connectDeadlineUS
		    sock.Poll
		    App.SleepCurrentThread(5)
		  Wend
		  
		  If Not sock.IsConnected Then
		    sock.Close
		    #If TargetWindows Then
		      LastErrorMessage = kNoListenerPrefix + " at " + candidatePath + _
		      " (connect timed out after " + connectTimeoutMS.ToString + "ms)."
		    #Else
		      LastErrorMessage = "IPCSocket connect timed out for " + candidatePath + _
		      " after " + connectTimeoutMS.ToString + "ms."
		    #EndIf
		    Return Nil
		  End If

		  // Once Write succeeds, the IDE may have already received (and be
		  // executing) the script even if we never see a response — e.g. a
		  // timeout below. From this point on, a failure must NOT be treated
		  // as safe to blindly retry with the same script.
		  Try
		    sock.Write(payload)
		    sock.Flush
		  Catch e As RuntimeException
		    // The comment above is the rule, and this branch used to break it: it closed the
		    // socket and returned without setting mParkedThisRequest, so the candidate loop went
		    // on to the next path and resent the script. On macOS the next path is usually the
		    // same socket under another name - /tmp is /private/tmp - so a write that had in fact
		    // reached the IDE before Flush failed would run twice. And closing a connection the
		    // IDE may answer on is the SIGPIPE this class exists to prevent.
		    //
		    // So it parks, like every other case where the request may have been delivered.
		    // If the connection is really broken, DrainPending finds that on its next poll - the
		    // poll throws or the socket reports itself closed - and releases it within one idle
		    // pass, so a dead socket does not hold the IDE's connection slot.
		    AddPending(sock, tag, script)
		    mParkedThisRequest = True
		    LastErrorMessage = "Writing the request to the Xojo IDE failed partway (" + e.Message + "). " + _
		    "It may or may not have arrived, so it is not being resent, and the connection is kept " + _
		    "open in case the IDE answers. Further requests are refused until it does or the " + _
		    "connection is found closed. Do not quit or restart Claude Code (or whichever MCP client " + _
		    "you use) meanwhile: on macOS and Linux the Xojo IDE crashes if it answers over a " + _
		    "connection that has been closed."
		    Return Nil
		  End Try

		  Var buffer As String = ""
		  Var hadData As Boolean = False
		  
		  // One reply can arrive as several messages under the same tag: a script's Print
		  // output and a compiler warning about it arrive together, and an analysis returns
		  // its buildError and the Print sentinel together. Returning on the first frame made
		  // the answer whichever part won the race. After the first matching frame the loop
		  // keeps reading for a short window and MergeReply folds the parts.
		  //
		  // A warning gets no special window. An earlier version waited far longer when the
		  // first frame was a warning, on the assumption that the output was still to come -
		  // an assumption we could not reproduce: measured against the IDE socket on 2025r3.1
		  // and 2026r2.1, the warning always arrived with the output, never ahead of it. If a
		  // reply ever does turn out to be warnings-only, the socket is parked rather than
		  // answered (see below), so the late output still lands safely.
		  Var frames() As JSONItem
		  Var collectUntilUS As Double = deadlineUS
		  
		  While System.Microseconds < deadlineUS And System.Microseconds < collectUntilUS
		    // Guarded like Connect and Write above, and like DrainPending's own Poll. The write
		    // has already succeeded here, so the IDE may be executing the script; an exception
		    // escaping would skip both the merge below and the parking below it, leaking an
		    // open socket and losing the guarantee that a delivered script is never resent.
		    // Stop reading and let it park - DrainPending will fail the same way and release it.
		    Var chunk As String
		    Try
		      sock.Poll
		      chunk = sock.ReadAll
		    Catch e As RuntimeException
		      LogVerbose("IDE request " + tag + ": polling failed (" + e.Message + "); parking it.")
		      Exit
		    End Try

		    If chunk = "" Then
		      App.SleepCurrentThread(5)
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
		          frames.Add(response)
		          If frames.Count = 1 Then
		            collectUntilUS = System.Microseconds + (kSplitReplyWindowMS * 1000.0)
		          End If
		        Else
		          LogVerbose("IDE request " + tag + ": ignoring a frame for another tag (stale or unsolicited).")
		        End If
		      Catch e As RuntimeException
		        // Any exception, not only JSONException. The write has already succeeded here, so
		        // one escaping - a tag that is not a string, say - would skip both the merge and
		        // the parking below, leaving an open socket that is neither answered nor parked.
		        // A frame that cannot be read is skipped, like a malformed one always was.
		        LogVerbose("IDE request " + tag + ": skipped an unreadable frame (" + e.Message + ").")
		      End Try
		    Wend
		  Wend
		  
		  // Warnings and nothing else means the script is still running: every caller sends
		  // a script that ends in a Print, so an output frame is always coming eventually.
		  // Answering with the warning here would pick the wrong part AND close the socket
		  // on a reply still in flight - the two failures this class exists to avoid. Fall
		  // through to parking instead.
		  Var onlyWarnings As Boolean = frames.Count > 0
		  For Each f As JSONItem In frames
		    If ReplyKind(f) <> "warning" Then
		      onlyWarnings = False
		      Exit
		    End If
		  Next f
		  
		  If frames.Count > 0 And Not onlyWarnings Then
		    // Closed here, once our reply is in hand, and that leaves one residual risk worth
		    // stating rather than hiding: a further frame for this tag arriving after the
		    // kSplitReplyWindowMS window would be written into a closed peer. None has been
		    // observed - every measured multi-part reply arrived within milliseconds - and the
		    // alternative, parking every answered socket, would hold the IDE's single connection
		    // slot after each request. The window is the trade.
		    sock.Close
		    LastErrorMessage = ""
		    Return MergeReply(frames)
		  End If
		  
		  // Data arrived for some other tag and nothing for ours. This used to close the socket
		  // and return without setting mParkedThisRequest, which was wrong twice over: the
		  // caller's candidate loop then resent a script the IDE had already accepted, and
		  // closing a connection the IDE still owes a reply on is the SIGPIPE this class exists
		  // to avoid. A foreign frame says nothing about our request except that the IDE is
		  // busy - which is what parking is for - so it is logged and falls through.
		  If hadData And frames.Count = 0 Then
		    LogVerbose("IDE request " + tag + ": data from " + candidatePath + " carried another tag; ours is still outstanding.")
		  End If
		  
		  // The IDE accepted the request - connect and write both succeeded - and has not
		  // answered within the timeout. Do NOT close the socket. The IDE will answer when
		  // it is done, and a write into a closed peer raises SIGPIPE, which the Xojo IDE
		  // does not ignore: it dies mid-build, with no crash report. Park the socket open
		  // instead; DrainPending releases it once the IDE has replied or has gone away.
		  AddPending(sock, tag, script)
		  mParkedThisRequest = True
		  LastErrorMessage = "The Xojo IDE accepted the request but has not answered within " + timeoutMS.ToString + _
		  "ms. It is most likely busy - a build, or a modal dialog waiting for a click - and it will finish " + _
		  "the request regardless. The connection is kept open so the IDE can reply safely; that reply will " + _
		  "be discarded. Further requests are refused until the IDE has answered." + _
		  " Do not quit or restart Claude Code (or whichever MCP client you use) until then: " + _
		  "quitting closes this connection, and on macOS and Linux the Xojo IDE crashes if it " + _
		  "answers over a connection that has been closed."
		  
		  Return Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReplyKind(envelope As JSONItem) As String
		  /// Classifies one reply envelope by what its "response" carries:
		  ///   "output"  - a string (what the script printed), or an object that is none of the below
		  ///   "empty"   - an empty object: the IDE's answer to a script that printed nothing
		  ///   "warning" - diagnostics that are warnings only; the script or build still ran
		  ///   "error"   - scriptError with errors, buildError with errors, missingFiles, openErrors, loadError
		  ///   "unknown" - no "response" key at all
		  ///
		  /// scriptError is a heterogeneous array: each entry has a "type" that is
		  /// scriptCompilerError, scriptRuntimeError or scriptCompilerWarning, and a reply that
		  /// carries only warnings means the script compiled and ran. Treating the whole array as
		  /// fatal reported failures for scripts that had worked.
		  
		  If envelope = Nil Or Not envelope.HasKey("response") Then Return "unknown"
		  
		  // Anything that is not an object is what the script produced. A string is the usual
		  // case, but a reply part can also be a number or a boolean, and those used to be
		  // classified by attempting a JSONItem cast and catching the failure - control flow
		  // hidden in an exception handler, which is both slower and easy to misread as an
		  // error path. Ask what the value is instead.
		  Var resp As Variant = envelope.Value("response")
		  If resp.Type <> Variant.TypeObject Then Return "output"
		  
		  // It is an object, but not every object is a JSONItem; one that is not is still
		  // something the script produced, so the cast keeps its guard.
		  Var obj As JSONItem
		  Try
		    obj = envelope.Value("response")
		  Catch e As RuntimeException
		    Return "output"
		  End Try
		  If obj = Nil Then Return "output"
		  If obj.Count = 0 Then Return "empty"
		  
		  If obj.HasKey("scriptError") Then
		    Var items As JSONItem = obj.Value("scriptError")
		    If items <> Nil And items.IsArray Then
		      For i As Integer = 0 To items.Count - 1
		        Var entry As JSONItem = items.ChildAt(i)
		        Var kind As String = If(entry <> Nil And entry.HasKey("type"), entry.Value("type").StringValue, "")
		        If Not kind.Lowercase.EndsWith("warning") Then Return "error"
		      Next i
		      Return "warning"
		    End If
		    Return "error"
		  End If
		  
		  If obj.HasKey("buildError") Then
		    Var be As JSONItem = obj.Value("buildError")
		    If be <> Nil And be.HasKey("errors") Then
		      Var errs As JSONItem = be.Value("errors")
		      If errs <> Nil And errs.Count > 0 Then Return "error"
		    End If
		    If be <> Nil And be.HasKey("warnings") Then
		      Var warns As JSONItem = be.Value("warnings")
		      If warns <> Nil And warns.Count > 0 Then Return "warning"
		    End If
		    Return "empty"
		  End If
		  
		  If obj.HasKey("missingFiles") Or obj.HasKey("openErrors") Or obj.HasKey("loadError") Then Return "error"
		  
		  Return "output"
		End Function
	#tag EndMethod
	#tag Method, Flags = &h0
		Function ReplyDiagnostics(envelope As JSONItem) As String
		  /// The reply's blocking diagnostics as readable text, or "" when there are none -
		  /// that is, when the reply is output, empty, or warnings only. Covers every error
		  /// shape the IDE is known to send: scriptError (errors only; warnings are for
		  /// ReplyWarnings), buildError.errors, missingFiles, openErrors and loadError.
		  ///
		  /// missingFiles is undocumented but real: an Android build with no key store answers
		  /// {"missingFiles": "Unable to build. Please specify a Key Store properties file..."},
		  /// a precise message that used to be dropped as an unrecognised object.
		  
		  // Guarded independently of ReplyKind. Reading the response out of the envelope is
		  // only safe because ReplyKind returned "error", which implies a non-Nil envelope
		  // carrying a JSONItem response - a contract held in another method's head. If that
		  // classification ever widens, this would raise a NilObjectException rather than
		  // report the error it was asked about, so it checks for itself.
		  If envelope = Nil Or Not envelope.HasKey("response") Then Return ""
		  If ReplyKind(envelope) <> "error" Then Return ""
		  
		  Var obj As JSONItem
		  Try
		    obj = envelope.Value("response")
		  Catch e As RuntimeException
		    Return ""
		  End Try
		  If obj = Nil Then Return ""
		  
		  Var lines() As String
		  
		  If obj.HasKey("scriptError") Then
		    Var text As String = FormatScriptErrors(obj.Value("scriptError"), False)
		    If text <> "" Then lines.Add("Script errors:" + EndOfLine + text)
		  End If
		  If obj.HasKey("buildError") Then
		    Var be As JSONItem = obj.Value("buildError")
		    If be <> Nil And be.HasKey("errors") Then
		      Var errs As JSONItem = be.Value("errors")
		      If errs <> Nil And errs.Count > 0 Then
		        lines.Add("Build errors (" + errs.Count.ToString + "):" + EndOfLine + FormatDiagnosticList(errs, "Error"))
		      End If
		    End If
		  End If
		  If obj.HasKey("missingFiles") Then
		    lines.Add("The IDE needs something configured before it can build: " + obj.Value("missingFiles").StringValue)
		  End If
		  If obj.HasKey("openErrors") Then
		    lines.Add("The project reported errors while opening: " + JSONItem(obj.Value("openErrors")).ToString)
		  End If
		  If obj.HasKey("loadError") Then
		    lines.Add("The project could not be loaded: " + JSONItem(obj.Value("loadError")).ToString)
		  End If
		  
		  If lines.Count = 0 Then Return "The IDE returned an error: " + obj.ToString
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod
	#tag Method, Flags = &h0
		Function ReplyWarnings(envelope As JSONItem) As String
		  /// Warnings carried by the reply - in its primary part or in any part MergeReply
		  /// attached - as readable text, or "" when there are none. For a successful script
		  /// this is typically a scriptCompilerWarning about the script XMCP itself sent.
		  
		  If envelope = Nil Then Return ""
		  Var lines() As String
		  
		  Var candidates() As JSONItem
		  If envelope.HasKey("response") And envelope.Value("response").Type = Variant.TypeObject Then
		    Try
		      candidates.Add(JSONItem(envelope.Value("response")))
		    Catch e As RuntimeException
		    End Try
		  End If
		  If envelope.HasKey("xmcp_parts") Then
		    Var parts As JSONItem = envelope.Value("xmcp_parts")
		    For i As Integer = 0 To parts.Count - 1
		      Try
		        // Only objects. MergeReply attaches the other parts' response VALUES, and
		        // for a multi-Print script those are plain strings - asking one of those
		        // HasKey raises, and the exception escaped as a JSON-RPC parse error.
		        Var child As JSONItem = parts.ChildAt(i)
		        If child <> Nil And Not child.IsArray Then candidates.Add(child)
		      Catch e As RuntimeException
		      End Try
		    Next i
		  End If
		  
		  For Each obj As JSONItem In candidates
		    If obj = Nil Or obj.IsArray Then Continue
		    
		    // A reply part can be any JSON the IDE chose to send. Reading warnings out of
		    // one must never fail the whole request: there is nothing to report from a part
		    // that is not an object, and that is not an error.
		    Try
		      If obj.HasKey("scriptError") Then
		        Var text As String = FormatScriptErrors(obj.Value("scriptError"), True)
		        If text <> "" Then lines.Add(text)
		      End If
		      If obj.HasKey("buildError") Then
		        Var be As JSONItem = obj.Value("buildError")
		        If be <> Nil And be.HasKey("warnings") Then
		          Var warns As JSONItem = be.Value("warnings")
		          If warns <> Nil And warns.Count > 0 Then lines.Add(FormatDiagnosticList(warns, "Warning"))
		        End If
		      End If
		    Catch e As RuntimeException
		    End Try
		  Next obj
		  
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod
	#tag Method, Flags = &h21
		Private Function FormatScriptErrors(items As JSONItem, warningsOnly As Boolean) As String
		  /// One line per scriptError entry of the requested severity. The IDE wraps the
		  /// script in a line of boilerplate before compiling it, so every line number it
		  /// reports is one greater than the line that was sent; that offset is removed here.
		  /// A line too small to carry the offset passes through unchanged. Column -1 means
		  /// unknown and is omitted.
		  
		  If items = Nil Then Return ""
		  Var lines() As String
		  If Not items.IsArray Then Return items.ToString
		  
		  For i As Integer = 0 To items.Count - 1
		    Var entry As JSONItem = items.ChildAt(i)
		    If entry = Nil Then Continue
		    Var kind As String = If(entry.HasKey("type"), entry.Value("type").StringValue, "")
		    Var isWarning As Boolean = kind.Lowercase.EndsWith("warning")
		    If isWarning <> warningsOnly Then Continue
		    
		    Var text As String = If(kind = "", If(warningsOnly, "Warning", "Error"), kind)
		    If entry.HasKey("message") Then text = text + ": " + entry.Value("message").StringValue
		    If entry.HasKey("line") Then
		      Var line As Integer = entry.Value("line").IntegerValue
		      If line >= 2 Then line = line - 1
		      If line > 0 Then text = text + " (line " + line.ToString + ")"
		    End If
		    If entry.HasKey("column") Then
		      Var column As Integer = entry.Value("column").IntegerValue
		      If column >= 0 Then text = text + " (column " + column.ToString + ")"
		    End If
		    lines.Add(text)
		  Next i
		  
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod
	#tag Method, Flags = &h0
		Function FormatDiagnosticList(list As JSONItem, defaultType As String, preferDefaultType As Boolean = False) As String
		  /// One line per buildError entry: type, message, location and position.
		  ///
		  /// Public because a tool can need these lines under its own heading: analyze_project
		  /// reports "Analysis results", not "Build errors", so it formats the lists itself
		  /// rather than taking ReplyDiagnostics' wording wholesale. Sharing the line format is
		  /// the point - it was hand-rolled a second time there, twice over.
		  
		  If list = Nil Then Return ""
		  Var lines() As String
		  For i As Integer = 0 To list.Count - 1
		    Var err As JSONItem = list.ChildAt(i)
		    If err = Nil Then Continue
		    // Xojo's "type" is the issue category - "Code" - not its severity, so it reads the
		    // same on an error and on a warning. A caller whose heading does not already say
		    // which it is asks for defaultType instead, so a warning line still says Warning.
		    Var errType As String = defaultType
		    If Not preferDefaultType And err.HasKey("type") Then errType = err.Value("type").StringValue
		    Var msg As String = If(err.HasKey("message"), err.Value("message").StringValue, "")
		    Var location As String = If(err.HasKey("location"), err.Value("location").StringValue, "")
		    Var position As String = If(err.HasKey("position"), err.Value("position").StringValue, "")
		    Var line As String = errType + ": " + msg
		    If location <> "" Then line = line + " [" + location + "]"
		    If position <> "" And position <> location Then line = line + " (" + position + ")"
		    lines.Add(line)
		  Next i
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod
	#tag Method, Flags = &h21
		Private Function MergeReply(frames() As JSONItem) As JSONItem
		  /// Folds the parts of one reply into a single envelope so callers keep reading
		  /// response.Value("response") as before. The primary part is chosen by weight: an
		  /// error beats output, output beats a warning, and a warning beats an empty answer -
		  /// an empty reply carries nothing, so it must never displace a warning. Every other part is attached under "xmcp_parts" (their
		  /// "response" values) so a tool can still report, say, the compiler warning that
		  /// accompanied a successful script - see ReplyWarnings.
		  
		  If frames.Count = 0 Then Return Nil
		  If frames.Count = 1 Then Return frames(0)
		  
		  Var primary As Integer = -1
		  Var rank() As String = Array("error", "output", "warning", "empty", "unknown")
		  For r As Integer = 0 To rank.LastIndex
		    For i As Integer = 0 To frames.LastIndex
		      Var kind As String = ReplyKind(frames(i))
		      If kind = rank(r) Then
		        // Among outputs, prefer one that actually says something.
		        // Exact, not trimmed. This ranking picks the answer for every tool, and for most the
		        // answer is data, so the test is for an empty string and nothing looser. In practice
		        // the difference is moot for whitespace: measured on 2026r2.1, the IDE collapses a
		        // Print of only whitespace into an empty reply itself, while "[   ]" keeps its spaces.
		        If kind = "output" And frames(i).Value("response").Type = Variant.TypeString And _
		          frames(i).Value("response").StringValue = "" Then Continue
		        primary = i
		        Exit For i
		      End If
		    Next i
		    If primary >= 0 Then Exit For r
		  Next r
		  
		  // Nothing matched any rank. That happens in exactly one case: every frame was an
		  // output whose string was empty, so the preference above skipped all of them and no
		  // later rank could match either, since they are all "output". An empty output is
		  // still the script's answer - a script that printed empty strings - so take the
		  // first one deliberately. Arriving here by falling out of the rank table read like
		  // an oversight; it is a real case with a real answer.
		  If primary < 0 Then primary = 0
		  
		  Var merged As JSONItem = frames(primary)
		  Var parts As New JSONItem("[]")
		  For i As Integer = 0 To frames.LastIndex
		    If i = primary Then Continue
		    If frames(i).HasKey("response") Then parts.Add(frames(i).Value("response"))
		  Next i
		  If parts.Count > 0 Then merged.Value("xmcp_parts") = parts
		  
		  LogVerbose("Merged " + frames.Count.ToString + " reply parts; primary kind " + ReplyKind(merged) + ".")
		  Return merged
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub AddPending(sock As IPCSocket, tag As String, script As String)
		  /// Parks a socket whose request the IDE accepted but has not answered yet.
		  ///
		  /// The IDE runs scripts on its main thread, so during a build - or behind a modal
		  /// dialog - it answers nothing until it is done, and then answers everything that
		  /// queued up, on the connections the requests arrived on. Closing such a
		  /// connection is what killed the IDE: its later write hits a closed peer, the
		  /// kernel raises SIGPIPE, and the Xojo IDE does not ignore that signal. The system
		  /// log showed "exited due to SIGPIPE | sent by Xojo" five seconds after the build
		  /// finished, with no crash report. So a timed-out socket stays open here until the
		  /// IDE has replied or has gone away; DrainPending does the housekeeping.
		  ///
		  /// The crash is a macOS/Linux one: there the IPCSocket is a Unix domain socket. On
		  /// Windows it is a TCP socket on localhost, where a write into a closed peer merely
		  /// fails. Parking is still right there - a busy IDE accepts the connect into its
		  /// backlog on both platforms, so the request is delivered either way, and refusing
		  /// to stack more behind it is what keeps the message honest.
		  
		  mPending.Add(New PendingRequest(sock, tag, script))
		End Sub
	#tag EndMethod
	#tag Method, Flags = &h0
		Function DrainPending() As Integer
		  /// Polls every parked socket and releases the ones the IDE is finished with: it
		  /// wrote a reply (discarded - the caller gave up long ago), or it closed the
		  /// connection (the IDE quit or crashed), or the socket has been parked longer
		  /// than kPendingGiveUpMS. Returns how many are still waiting for the IDE.
		  
		  Var i As Integer = mPending.LastIndex
		  While i >= 0
		    Var req As PendingRequest = mPending(i)
		    Var done As Boolean = False
		    Var reason As String = ""
		    
		    Try
		      req.Sock.Poll
		      // A reply is whole only once its NUL terminator arrives. Releasing on the first
		      // byte would close the socket on a reply still being written, which is the
		      // SIGPIPE this whole mechanism exists to avoid - and on Windows the transport is
		      // TCP, where a large reply is split across segments as a matter of course.
		      If req.ReplyComplete Then
		        done = True
		        reason = "the IDE answered it (reply discarded)"
		      ElseIf Not req.Sock.IsConnected Then
		        // Nothing more is coming, whether or not what arrived was whole.
		        done = True
		        reason = "the IDE closed the connection"
		      ElseIf System.Microseconds - req.SinceUS > kPendingGiveUpMS * 1000.0 Then
		        // The one release that closes a socket the IDE may still answer. If it does answer
		        // after this - a build longer than the limit, a dialog left open for hours - that
		        // write hits a closed peer, which on macOS and Linux is the SIGPIPE parking exists
		        // to prevent. It is a deliberate bound: without one, a request the IDE never
		        // answers would hold its only IPC connection for as long as this process lives.
		        Var giveUpMinutes As Integer = kPendingGiveUpMS / 60000
		        done = True
		        reason = "it was parked for over " + giveUpMinutes.ToString + " minutes"
		      End If
		    Catch e As RuntimeException
		      done = True
		      reason = "polling it failed: " + e.Message
		    End Try
		    
		    If done Then
		      LogVerbose("IDE request " + req.Tag + ": released, " + reason + ".")
		      Try
		        req.Sock.Close
		      Catch e As RuntimeException
		        // Nothing left to do with it.
		      End Try
		      mPending.RemoveAt(i)
		    End If
		    
		    i = i - 1
		  Wend
		  
		  Return mPending.Count
		End Function
	#tag EndMethod
	#tag Method, Flags = &h21
		Private Function PendingSummary() As String
		  /// One line per parked request: its tag, how long ago it was sent, and the start
		  /// of its script - enough to recognise "that was the build I started".
		  
		  Var lines() As String
		  For Each req As PendingRequest In mPending
		    Var ageS As Integer = Floor((System.Microseconds - req.SinceUS) / 1000000.0)
		    Var preview As String = req.Script.ReplaceLineEndings(" ").Trim
		    If preview.Length > 80 Then preview = preview.Left(77) + "..."
		    lines.Add("  " + req.Tag + " (sent " + ageS.ToString + "s ago): " + preview)
		  Next req
		  
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod

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


	#tag Property, Flags = &h21
		Private mParkedThisRequest As Boolean
	#tag EndProperty
	#tag Property, Flags = &h21
		Private mPending() As PendingRequest
	#tag EndProperty
	#tag Constant, Name = kPendingGiveUpMS, Type = Double, Dynamic = False, Default = \"7200000", Scope = Private, Description = 486F77206C6F6E672061207061726B656420736F636B65742069732068656C64206F70656E2077616974696E6720666F72207468652049444520746F20616E737765722C20696E206D696C6C697365636F6E647320283220686F757273292E
	#tag EndConstant
	
	#tag Constant, Name = kConnectTimeoutMS, Type = Double, Dynamic = False, Default = \"1500", Scope = Private
	#tag EndConstant
	
	#tag Constant, Name = kNoListenerPrefix, Type = String, Dynamic = False, Default = \"IPC socket not found", Scope = Private
	#tag EndConstant
	
	#tag Constant, Name = kSplitReplyWindowMS, Type = Double, Dynamic = False, Default = \"250", Scope = Private, Description = 486F77206C6F6E6720746F206B6565702072656164696E6720666F72206D6F726520706172747320616674657220746865206669727374206D61746368696E67207265706C79206672616D652C20696E206D696C6C697365636F6E64732E
	#tag EndConstant
	
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
