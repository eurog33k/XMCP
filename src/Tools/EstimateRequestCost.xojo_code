#tag Class
Protected Class EstimateRequestCost
Inherits MCPKit.Tool
	#tag Method, Flags = &h0
		Sub Constructor()
		  Super.Constructor("estimate_request_cost", "Estimates likely token cost for a proposed request and suggests cheaper alternative approaches.")

		  Parameters.Add(New MCPKit.ToolParameter("request", MCPKit.ToolParameterTypes.String_, _
		  "Natural-language request to estimate (for example: 'Add a ListBox to Window1').", _
		  False, "", True))

		  Parameters.Add(New MCPKit.ToolParameter("planned_tools", MCPKit.ToolParameterTypes.String_, _
		  "Optional comma-separated list of tools you expect to call (for example: 'select_project_item,create_project_item').", _
		  True, "", False))

		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Run(args() As MCPKit.ToolArgument) As MCPKit.ToolResult
		  Var request As String = ""
		  Var plannedTools As String = ""
		  For Each arg As MCPKit.ToolArgument In args
		    If arg.Name = "request" Then
		      request = arg.Value.StringValue
		    ElseIf arg.Name = "planned_tools" Then
		      plannedTools = arg.Value.StringValue
		    End If
		  Next arg

		  If request.Trim = "" Then
		    Return MCPKit.ToolResult.Failure("The request parameter is required.")
		  End If

		  Var score As Integer = 0
		  Var reasons() As String
		  Var alternatives() As String

		  Var requestLower As String = request.Lowercase

		  If request.Length > 250 Then
		    score = score + 2
		    reasons.Add("Long request likely needs larger context exchange.")
		  ElseIf request.Length > 100 Then
		    score = score + 1
		    reasons.Add("Moderate request size may require extra context.")
		  End If

		  If HasAnyKeyword(requestLower, Array("entire", "whole", "full", "everything", "all files", "codebase", "architecture", "refactor", "analyze", "analyse", "review", "audit")) Then
		    score = score + 3
		    reasons.Add("Broad scope wording indicates potentially large reads/writes.")
		  End If

		  If HasAnyKeyword(requestLower, Array("documentation", "docs", "api reference", "lookup")) Then
		    score = score + 2
		    reasons.Add("Documentation-heavy tasks can produce large responses.")
		  End If

		  If HasAnyKeyword(requestLower, Array("add", "rename", "single", "window1", "listbox", "button", "one control")) Then
		    score = score - 1
		    reasons.Add("Request appears focused on a specific UI/code change.")
		  End If

		  Var planned As String = plannedTools.Lowercase.ReplaceAll(" ", "")
		  If planned <> "" Then
		    If planned.IndexOf("list_doc_topics") >= 0 Then
		      score = score + 3
		      reasons.Add("`list_doc_topics` can return very large indexes.")
		      alternatives.Add("Use `list_doc_topics` with a narrow `filter` value.")
		    End If
		    If planned.IndexOf("lookup_class") >= 0 Then
		      score = score + 1
		      reasons.Add("`lookup_class` defaults to a scoped summary; full=true returns the complete reference page.")
		      alternatives.Add("Avoid full=true unless the complete page is needed - the default summary or a single member is usually enough.")
		    End If
		    If planned.IndexOf("search_docs") >= 0 Then
		      score = score + 2
		      reasons.Add("`search_docs` can return large context blocks.")
		      alternatives.Add("Keep `max_results` and `context_lines` low.")
		    End If
		    If planned.IndexOf("get_code") >= 0 Or planned.IndexOf("set_code") >= 0 Then
		      score = score + 1
		      reasons.Add("Code read/write tools may move large text blocks.")
		      alternatives.Add("Operate on one location at a time.")
		    End If
		  End If

		  If score < 0 Then score = 0

		  Var level As String
		  Var tokenBand As String
		  If score <= 2 Then
		    level = "LOW"
		    tokenBand = "Typically under ~1,000 tokens."
		  ElseIf score <= 5 Then
		    level = "MEDIUM"
		    tokenBand = "Typically ~1,000 to ~5,000 tokens."
		  Else
		    level = "HIGH"
		    tokenBand = "Often above ~5,000 tokens."
		  End If

		  If level <> "LOW" Then
		    alternatives.Add("Limit scope to a single file/class/window first.")
		    alternatives.Add("Ask for a quick/minimal pass before a full pass.")
		  End If

		  // De-duplicate alternatives while preserving order.
		  Var dedupedAlternatives() As String
		  Var seen As New Dictionary
		  For Each alt As String In alternatives
		    If alt.Trim = "" Then Continue
		    If Not seen.HasKey(alt) Then
		      seen.Value(alt) = True
		      dedupedAlternatives.Add(alt)
		    End If
		  Next alt

		  If reasons.Count = 0 Then
		    reasons.Add("No high-cost indicators detected in the provided request.")
		  End If

		  Var output As String = "Cost estimate: " + level + EndOfLine + _
		  "Token impact: " + tokenBand + EndOfLine

		  output = output + EndOfLine + "Why:"
		  For Each reason As String In reasons
		    output = output + EndOfLine + "- " + reason
		  Next reason

		  If dedupedAlternatives.Count > 0 Then
		    output = output + EndOfLine + EndOfLine + "Cheaper alternatives:"
		    For i As Integer = 0 To dedupedAlternatives.LastIndex
		      output = output + EndOfLine + Str(i + 1).Trim + ". " + dedupedAlternatives(i)
		    Next i
		  End If

		  output = output + EndOfLine + EndOfLine + "Note: This is a heuristic estimate, not an exact token count."
		  Return MCPKit.ToolResult.Success(output)

		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HasAnyKeyword(haystack As String, needles() As String) As Boolean
		  For Each needle As String In needles
		    If haystack.IndexOf(needle) >= 0 Then Return True
		  Next needle
		  
		  Return False

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
