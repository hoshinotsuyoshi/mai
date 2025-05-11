# Translate an English PR description into natural Japanese

Class.new(Mi) do
  def text(input)
    $stderr.puts input # debug

    source = input

    <<~PROMPT
      Translate the following Pull-Request description into
      concise, natural Japanese. **keep bullet points**, **in Markdown style, as a single or multiple sentence(s)**.
      **Return value as a String(not JSON).**

      --- BEGIN TEXT ---
      #{source}
      --- END TEXT ---
    PROMPT
  end

  # def response_schema
  #   { type: "STRING" }
  # end

  # def model
  #   "gemini-2.0-flash-lite"
  # end
end
