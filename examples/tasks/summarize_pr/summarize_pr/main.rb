# Summarize a Git diff into an English PR description

Class.new(Mi) do
  def text(input)
    <<~PROMPT
      You are a senior software engineer.
      Summarize the following Git diff as a Pull-Request description
      with three short sections (Overview / Motivation / Risk),
      each within 1200 characters, bullet-point style, in Markdown style, as a single or multiple sentence(s) (no array nor JSON).

      --- BEGIN DIFF ---
      #{input}
      --- END DIFF ---
    PROMPT
  end

  # def response_schema
  #   { type: "STRING" }
  # end

  # def model
  #   "gemini-2.0-flash-lite"
  # end
end
