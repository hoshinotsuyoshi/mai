# update readme

Class.new do
  def text(_input)
    # NOTE: This works only on my local machine :)
    main   = File.read('/Users/hoshino/ghq/github.com/hoshinotsuyoshi/mi/src/main.rb')
    readme = File.read('/Users/hoshino/ghq/github.com/hoshinotsuyoshi/mi/README.md')

    string = <<~'PROMPT'
      Based on the following information, rewrite the README for this tool in clear, concise, and technically accurate English.
      The structure of the new README should include:

      * Overview (What the tool does)
      * Key Features
      * Installation / Usage
      * Task Customization
      * Requirements / Dependencies
      * Directory Structure
      * License
      * (Optional) Tips or Examples if appropriate

      Make sure to reflect how tasks are dynamically loaded from user-defined scripts using `XDG_CONFIG_HOME`, and note that the embedded Ruby logic is executed via mruby inside a statically compiled binary.

      **Return value as a String(not JSON).**

      ### Context 1: Key parts of the implementation (`src/main.rb`)

      ```ruby
      <<<src/main.rb>>>
      ```

      ### Context 2: The current README

      ```markdown
      <<<README.md>>>
      ```
    PROMPT
    string.sub('<<<src/main.rb>>>', main).sub('<<<README.md>>>', readme)
  end

  def response_schema
    { type: "STRING" }
  end
end
