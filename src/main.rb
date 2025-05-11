def load(path)
  eval(File.read(path), binding, path) # rubocop:disable Security/Eval
end

# emulate Dir.each_child
class Dir
  class << self
    def each_child(path)
      entries(path).each do |entry|
        next if entry == '.' || entry == '..'
        yield entry
      end
    end
  end
end

module Mi
  EVALUATION_PROMPT_TEMPLATE = <<~EOF
    Return **only** a single JSON object that exactly matches the schema:
      {
        "main": string,          // copy-paste of the provided draft answer
        "confidence": number,    // 0–1 (two decimals), self-assessed factual correctness
        "fit_score": number      // 0–1 (two decimals), relevance & completeness w.r.t. the question
      }
    Do **not** add keys, comments, or extra text.

    # USER
    Below is the original question and the draft answer produced in the previous step.

    QUESTION:
    <<<QUESTION_TEXT>>>

    DRAFT_ANSWER (to be copied verbatim into "main"):
    <<<MAIN_TEXT>>>

    Tasks:
    1. Evaluate the *factual correctness* of the draft answer and assign **confidence**
       • 1 = certainly correct 0 = no confidence
    2. Evaluate the *alignment / completeness* of the draft answer to the question and assign **fit_score**#{'  '}
       • 1 = fully addresses all aspects 0 = unrelated
    3. Output the final JSON object.
       • Use exactly two decimal places for the numeric fields.
       • Escape any internal newlines in "main" with \n so the JSON stays valid.
       • Do **not** explain your reasoning.
  EOF

  #: tasks_dir: String
  #: return: [String, void] | [void, String]
  def self.list_tasks(tasks_dir)
    tasks = []
    if Dir.exist?(tasks_dir)
      Dir.each_child(tasks_dir) do |entry|
        path = File.join(tasks_dir, entry)
        next unless File.directory?(path)
        Dir.each_child(path) do |sub_entry|
          sub_path = File.join(path, sub_entry)
          if File.file?(sub_path) && sub_entry == 'main.rb'
            tasks << File.basename(path)
          end
          next unless File.directory?(sub_path)
          Dir.each_child(sub_path) do |sub_sub_entry|
            if File.file?(File.join(sub_path, sub_sub_entry)) && sub_sub_entry == 'main.rb'
              tasks << (File.basename(path) + '/' + File.basename(sub_path))
            end
          end
        end
      end
      if tasks.empty?
        ["No tasks found in #{tasks_dir}", nil]
      else
        retval = "Available tasks:\n"
        tasks.each do |task_name|
          retval += "  - #{task_name}\n"
        end
        [retval, nil]
      end
    else
      [nil, "Tasks directory not found at #{tasks_dir}"]
    end
  end

  #: input: String
  #: return: [String, void] | [void, String]
  def self.parse_input(input)
    content = JSON.parse(input)
    if content.fetch("confidence") < 0.8
      [nil, "confidence is less than 0.8"]
    elsif content.fetch("fit_score") < 0.8
      [nil, "fit_score is less than 0.8"]
    else
      [content.fetch("main"), nil]
    end
  rescue JSON::ParserError
    [input, nil]
  end

  def self.build_second_response_schema(first_response_schema:)
    {
      "type": "OBJECT",
      "properties": {
        "main": first_response_schema,
        "confidence": {
          "type": "NUMBER"
        },
        "fit_score": {
          "type": "NUMBER"
        },
      },
      "propertyOrdering": [
        "main",
        "confidence",
        "fit_score",
      ]
    }
  end

  def self.mi_schema(text:, response_schema:)
    {
      "contents": [
        {
          "parts": [
            {
              "text": text,
            }
          ]
        }
      ],
      "generationConfig": {
        "responseMimeType": "application/json",
        "responseSchema": response_schema,
      },
    }.to_json
  end

  def self.extract_text(response_json)
    hash = JSON.parse(response_json)
    hash.fetch("candidates")[0].fetch("content").fetch("parts")[0].fetch("text")
  end

  def self.run(text:, response_schema:, gemini_api_key:)
    @debug ||= true if ARGV.include?("--debug")
    data = mi_schema(text:, response_schema:)
    io = nil

    Tempfile.open("temp") do |file|
      file.puts data
      file.flush

      cmd = [
        "curl",
        "-H",
        "'Content-Type: application/json'",
        "-sSL",
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=#{gemini_api_key}",
        "-d",
        "@#{file.path}"
      ].join(' ')
      $stderr.puts cmd if @debug
      unless gemini_api_key
        $stderr.puts "GEMINI_API_KEY is blank."
        exit 1
      end
      io = IO.popen(cmd, "r")
    end

    output = io.read
    $stderr.puts output if @debug
    io.close
    status = $?
    exit $? if status != 0
    output
  end
end # module Mi

CONFIG_HOME = ENV['XDG_CONFIG_HOME'] || (ENV['HOME'] + "/.config")
GEMINI_API_KEY = ENV['GEMINI_API_KEY']

# $ mi list
if ARGV[0] == "list"
  tasks_dir = "#{CONFIG_HOME}/mi/tasks"
  stdout_string, stderr_string = Mi.list_tasks(tasks_dir)
  stderr_string && $stderr.puts(stderr_string) && exit(1)
  stdout_string && puts(stdout_string) && exit
end

# $ mi run
if ARGV[0] == "run" && ARGV[1]
  task_name = ARGV[1]
  script_path = "#{CONFIG_HOME}/mi/tasks/#{task_name}/main.rb"

  if ARGV.include?("--no-stdin")
    input = ["", nil]
  else
    input = ""
    input += $stdin.gets until $stdin.eof?
    input = Mi.parse_input(input)
  end
  input[1] && $stderr.puts(input[1]) && exit(1)
  input = input[0]

  if File.exist?(script_path)
    # === Phase 1: Generate draft answer using the task-defined prompt ===
    # Sends the user input through the task's prompt (from ~/.config/mi/tasks/<task>/main.rb)
    # and gets a candidate answer from the Gemini API.
    klass = load(script_path)
    task = klass.new
    question = task.text(input)
    answer = Mi.run(
      text: question,
      response_schema: task.response_schema,
      gemini_api_key: GEMINI_API_KEY,
    )
    answer = Mi.extract_text(answer)

    # === Phase 2: Evaluate the draft answer with confidence and fit_score ===
    # Sends the draft answer back into Gemini with a strict evaluation prompt.
    # Gemini returns a JSON object containing:
    #   - main: the original answer
    #   - confidence: self-assessed factual correctness (0–1)
    #   - fit_score: alignment and completeness to the original question (0–1)
    second_response_schema = Mi.build_second_response_schema(first_response_schema: task.response_schema)
    evaluate_answer = Mi.run(
      text: Mi::EVALUATION_PROMPT_TEMPLATE.gsub("<<<QUESTION_TEXT>>>", question).gsub("<<<MAIN_TEXT>>>", answer),
      response_schema: second_response_schema,
      gemini_api_key: GEMINI_API_KEY,
    )
    puts JSON.parse(Mi.extract_text(evaluate_answer)).to_json
    exit 0
  else
    $stderr.puts "Task '#{task_name}' not found at #{script_path}"
    exit 1
  end
end
