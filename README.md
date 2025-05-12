# mai

## NAME

mai - CLI tool for executing Gemini API tasks defined by user scripts with embedded mruby

## SYNOPSIS

```sh
mai list
mai run <task_name> [--no-stdin]
```

## DESCRIPTION

`mai` is a command-line tool designed to interact with the Gemini API for generating content based on user-defined tasks. It executes custom Ruby logic via `mruby`, which is embedded directly within a statically compiled binary. This design allows for tasks to be dynamically loaded from configuration scripts without requiring an external Ruby installation.

`mai` works by taking a task name, locating the corresponding Ruby script in `$XDG_CONFIG_HOME/mai/tasks/`, and executing it using embedded mruby. The task script defines a prompt and response schema for communicating with the Gemini API. `mai` makes an initial API call to generate a response, followed by a second call to evaluate that response for factual correctness and relevance. The final output is a structured JSON object with the main result and evaluation scores.

## INSTALLATION

### Download Prebuilt Binary

1. Visit the [Releases page](https://github.com/hoshinotsuyoshi/mai/releases).
2. Download the binary for your OS and architecture.
3. Make the binary executable:

   ```sh
   chmod +x ./mai
   ```

4. (Optional) Move it to your system PATH:

   ```sh
   mv ./mai /usr/local/bin/
   ```

### Build from Source

```sh
git clone https://github.com/hoshinotsuyoshi/mai.git
cd mai
make
```

This compiles `mruby`, the Ruby bytecode, and links everything into a single binary.

## USAGE

### Setup

Set your Gemini API key as an environment variable:

```sh
export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
```

### List Tasks

```sh
mai list
```

Lists available tasks under `$XDG_CONFIG_HOME/mai/tasks/`. Subdirectory paths are supported.

### Run a Task

```sh
mai run <task_name> [--no-stdin]
```

- `<task_name>` refers to a directory containing `main.rb`.
- Input is read from stdin unless `--no-stdin` is specified.
- If stdin includes a JSON object with `confidence` or `fit_score` below 0.8, an error is raised.

### Output

```json
{
  "main": "The generated and evaluated content.",
  "confidence": 0.95,
  "fit_score": 0.90
}
```

## TASK CUSTOMIZATION

Tasks are Ruby scripts defined at:

```
$XDG_CONFIG_HOME/mai/tasks/<task_name>/main.rb
```

### Required Methods

- `text(input)`: Returns a prompt string for the Gemini API.
- `response_schema`: Returns a JSON schema object for validating the API response.

### Optional Method

- `model`: Returns a Gemini model name (e.g. `gemini-2.0-flash-lite`).

### Example

```ruby
Class.new(Mai) do
  # Defines the prompt sent to the Gemini API.
  # 'input' contains the text read from stdin.
  def text(input)
    "Summarize the following article concisely:\n\n#{input}"
  end

  def response_schema
    { "type": "STRING" }
  end

  # def model
  #   "gemini-2.0-flash"
  # end
end
```

## FEATURES

- Task-based modular system
- Embedded Ruby execution with mruby
- Two-phase Gemini API interaction
- JSON schema-based validation
- Automatic task discovery
- Optional model selection per task

## REQUIREMENTS

- Unix-like OS (Linux, macOS)
- C compiler (e.g. clang)
- GNU `make`
- `curl`
- Google Gemini API key

## DIRECTORY STRUCTURE

```
.                          (mai source repository)
├── Makefile               # Build script
├── src/
│   ├── main.c             # C entrypoint (embeds mruby and bytecode)
│   └── main.rb            # Core Ruby logic for mai commands
└── LICENSE                # MIT License
```

User-defined tasks are located in the XDG config directory:

```
$XDG_CONFIG_HOME/
└── mai/
    └── tasks/
        ├── <task_name_1>/
        │   └── main.rb      # Task definition 1
        ├── <task_name_2>/
        │   └── main.rb      # Task definition 2
        └── <category>/
            └── <task_name_3>/
                └── main.rb  # Nested task definition 3
```

## Roadmap

TBD

This section outlines possible directions for the project. These ideas are exploratory and may or may not be implemented. Contributions and feedback are welcome.

The following features are under consideration:

* [ ] **Task Metadata Support**
  Allow each task to define optional metadata (e.g., description, tags, version) via a `metadata` method.

* [ ] **`mai list` Command**
  Add a `mai list` subcommand to display available tasks under `$XDG_CONFIG_HOME/mai/tasks/`.

* [ ] **Default Input Template Support**
  Support defining fallback JSON input when no stdin is provided.

* [ ] **Interactive Prompt Mode**
  Add an `--interactive` flag to prompt users for required fields based on schema or task-defined questions.

* [ ] **Dry-Run Mode**
  Add a `--dry-run` flag to show the prompt and schema without calling the Gemini API.

* [ ] **Response Caching**
  Cache responses based on input + prompt to avoid redundant API calls.

* [ ] **Streaming Output Option**
  Support streaming output from Gemini (where available) for long responses.

* [ ] **Inline Debug Output Toggle**
  Provide more granular debug output control (e.g., `--verbose`).

* [ ] **Built-in Task Templates**
  Add `mai new <task_name>` to scaffold a task directory with a starter `main.rb`.

* [ ] **Improved Schema Validation**
  Provide clearer errors and suggestions when the Gemini response does not match the schema.

* [ ] **Error Recovery for Gemini API Failures**
  Add retry logic with exponential backoff for temporary errors or rate limits.

* [ ] **Support for Alternative Models**
  Allow specifying alternative Gemini models via env vars (e.g., `GEMINI_MODEL`) or task settings.

* [ ] **Environment Variable Injection into Tasks**
  Safely expose whitelisted environment variables (e.g., `ENV["MY_TOKEN"]`) inside task scripts.

* [ ] **Logging and History Tracking**
  Optionally log executed tasks, prompts, and responses to a local file.

* [ ] **Task Validation Command**
  Add `mai validate <task_name>` to check for task loading errors and malformed schemas.

* [ ] **Schema Type Shorthands and Helpers**
  Provide helpers like `Mai::Schema.string_array` to simplify schema definitions.

* [ ] **GitHub-Flavored Task Sharing**
  Allow importing tasks from GitHub or Gist via commands like `mai import gh:user/repo/task_name`.

### Ideas

These are looser concepts that may inspire future functionality:

* [ ] **Web Frontend for Task Management**
  Provide a browser-based UI to view, edit, and execute tasks locally.

* [ ] **Visual Prompt Builder**
  Drag-and-drop or form-based UI to build structured prompts for common task types.

* [ ] **AI-Assisted Task Authoring**
  Use the Gemini API itself to help scaffold new task logic and schema definitions.

* [ ] **CLI Wizard Mode**
  A guided flow for creating or debugging tasks interactively via the terminal.

* [ ] **Multi-Step Task Execution**
  Support chaining multiple tasks or prompts in a declarative task pipeline.

* [ ] **Built-in Prompt Gallery**
  Provide a curated set of prebuilt tasks or prompt templates for inspiration.

* [ ] **Usage Analytics (Opt-In)**
  Collect anonymous statistics on commonly used tasks or error types to guide development.

## LICENSE

MIT
