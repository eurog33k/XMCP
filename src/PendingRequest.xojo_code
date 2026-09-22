#tag Class
Protected Class PendingRequest
	#tag Method, Flags = &h0
		Sub Constructor(replySocket As IPCSocket, requestTag As String, requestScript As String)
		  Sock = replySocket
		  Tag = requestTag
		  Script = requestScript
		  SinceUS = System.Microseconds
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReplyComplete() As Boolean
		  /// Takes whatever the IDE has written so far and reports whether a whole reply
		  /// frame has arrived. The caller polls the socket first.
		  ///
		  /// The IDE frames its messages as NUL-terminated JSON, and on Windows the transport
		  /// is TCP, which splits a large reply across segments as a matter of course. Treating
		  /// the first byte as "the IDE has finished" would close the socket while the IDE may
		  /// still be writing the rest - and a write into a closed peer is the SIGPIPE that
		  /// parking exists to avoid, so releasing early reintroduces the crash by the back
		  /// door. Only a NUL means the reply is whole.
		  ///
		  /// The bytes are kept only to find that terminator. Nobody reads them: the caller
		  /// gave up on this request long ago and the reply is discarded on release.
		  
		  Buffer = Buffer + Sock.ReadAll
		  Return Buffer.IndexOf(Chr(0)) >= 0
		End Function
	#tag EndMethod


	#tag Note, Name = Why a parked socket is held open
		One request the IDE accepted but has not answered yet, and the socket it arrived on.
		
		The socket is held open rather than closed: the IDE runs scripts one at a time on its
		main thread, so a build or a modal dialog can leave a request unanswered for minutes,
		and a write into a closed peer raises SIGPIPE, which the Xojo IDE does not ignore.
		IDECommunicator.DrainPending polls these and releases the ones the IDE has finished
		with.
		
		This replaces four parallel arrays. The buffer is why: a reply is whole only once its
		NUL terminator arrives, and tracking a fifth array alongside the other four to know
		that would be worse than carrying the state together.
	#tag EndNote


	#tag Property, Flags = &h0
		Buffer As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Script As String
	#tag EndProperty

	#tag Property, Flags = &h0
		SinceUS As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Sock As IPCSocket
	#tag EndProperty

	#tag Property, Flags = &h0
		Tag As String
	#tag EndProperty


End Class
#tag EndClass
