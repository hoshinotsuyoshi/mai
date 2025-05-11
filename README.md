# mi

`mi` is a command-line interface tool designed to interact with the Gemini API for generating content based on user-defined tasks. It executes custom Ruby logic via mruby, which is embedded directly within a statically compiled binary. This approach allows tasks to be dynamically loaded from user configuration scripts, providing flexibility without requiring an external Ruby installation.

## Overview

The `mi` tool functions by taking a specified task name, locating and loading the corresponding Ruby script from the user's configuration directory. This script defines the prompt and schema for the initial interaction with the Gemini API. `mi` sends the user input (or lack thereof) through the task's defined prompt, retrieves a draft answer from the API, and then performs a second API call to evaluate the draft answer for factual correctness and relevance. The final output is a structured JSON object containing the evaluated answer and scores.

## Key Features

*   **Task-Based Generation:** Generates content based on modular, user-defined tasks.
*   **Dynamic Task Loading:** Automatically discovers and loads task definitions from Ruby scripts located in `$XDG_CONFIG_HOME/mi/tasks/`.
*   **Embedded mruby Execution:** Runs task logic written in Ruby using an embedded mruby interpreter, resulting in a self-contained, statically compiled binary.
*   **Gemini API Integration:** Interacts with the Google Gemini API using task-defined prompts and schemas.
*   **Two-Phase Evaluation:** Implements a built-in second API call to evaluate the initial generated content for confidence and fit score.
*   **Customizable Prompts & Schemas:** Tasks define the specific text prompt and expected response schema for the first API call.
*   **Task Listing:** Includes a command to list all available tasks discovered in the configuration directory.

## Installation / Usage

### ✅ Recommended: Download Prebuilt Binary

1.  Visit the [Releases page](https://github.com/hoshinotsuyoshi/mi/releases).
2.  Download the appropriate binary for your operating system and architecture.
3.  Make the binary executable:

    ```sh
    chmod +x ./mi
    ```

4.  (Optional) Move the binary to a directory included in your system's `PATH`, such as `/usr/local/bin/`:

    ```sh
    mv ./mi /usr/local/bin/
    ```

### 🛠️ Alternative: Build from Source

1.  Ensure you have a C compiler (like `clang`) and GNU `make` installed.
2.  Clone the repository:

    ```sh
    git clone https://github.com/hoshinotsuyoshi/mi.git
    cd mi
    ```

3.  Build the binary:

    ```sh
    make
    ```

    This process compiles mruby, the core Ruby logic into bytecode, and links everything into a single `mi` executable.

### 🔧 Setup & Run

1.  Obtain a Gemini API key and set it as the `GEMINI_API_KEY` environment variable:

    ```sh
    export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
    ```

2.  List available tasks:

    ```sh
    mi list
    ```

    This command searches `$XDG_CONFIG_HOME/mi/tasks/` for task definitions (directories containing `main.rb`). Tasks in subdirectories (e.g., `category/task_name`) are listed with their full path.

3.  Run a task:

    ```sh
    mi run <task_name>
    ```

    *   `<task_name>` corresponds to the name of a directory (or path within subdirectories) under `$XDG_CONFIG_HOME/mi/tasks/` that contains a `main.rb` script.
    *   By default, the tool reads input from stdin. Use the `--no-stdin` flag if the task does not require external input.
    *   If stdin is provided as a JSON object containing `confidence` and `fit_score` keys, the tool will exit with an error if either value is less than 0.8. Otherwise, the raw input is passed to the task's `text` method.

4.  Output:

    The tool outputs a JSON object to stdout representing the evaluated result from the Gemini API:

    ```json
    {
      "main": "The generated and evaluated content.",
      "confidence": 0.95,  // Self-assessed factual correctness (0-1)
      "fit_score": 0.90     // Relevance and completeness w.r.t. question (0-1)
    }
    ```

## Task Customization

Tasks are defined by Ruby scripts located in `$XDG_CONFIG_HOME/mi/tasks/<task_name>/main.rb`. Each `main.rb` file must define a class that provides the core logic for interacting with the Gemini API.

The class within the script must implement the following methods:

*   `text(input)`: This method receives the input read from stdin (if any) as a string. It should return the final text prompt string that will be sent to the Gemini API in the first call.
*   `response_schema`: This method must return a JSON schema object defining the expected structure of the response from the *first* Gemini API call.
*   `(Optional) model`: This method can return a string specifying the desired Gemini model to use for this task, overriding the default (`gemini-2.0-flash-lite`). The model must be one of the internally supported options.

### Example Task Definition (`$XDG_CONFIG_HOME/mi/tasks/summarize_article/main.rb`)

```ruby
Class.new(Mi) do
  # Defines the prompt sent to the Gemini API.
  # 'input' contains the text read from stdin.
  def text(input)
    "Summarize the following article concisely:

#{input}"
  end

  # Defines the expected structure of the API response.
  # Used for schema validation in the first call and building the evaluation prompt.
  def response_schema
    {
      "type": "STRING"
    }
  end

  # (Optional) Specify a different model for this task.
  # def model
  #   "gemini-2.0-flash"
  # end
end
```

## Requirements / Dependencies

*   A Unix-like operating system (macOS, Linux, etc.)
*   A C compiler (like `clang`)
*   GNU `make`
*   `curl` command-line tool
*   A valid Gemini API key (set as the `GEMINI_API_KEY` environment variable)

## Directory Structure

```
.                          (mi source repository)
├── Makefile               # Build script
├── src/
│   ├── main.c             # C entrypoint (embeds mruby and bytecode)
│   └── main.rb            # Core Ruby logic for mi commands
└── LICENSE                # MIT License
```

User-defined tasks are located in the XDG config directory:

```
$XDG_CONFIG_HOME/
└── mi/
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

* [ ] **`mi list` Command**
  Add a `mi list` subcommand to display available tasks under `$XDG_CONFIG_HOME/mi/tasks/`.

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
  Add `mi new <task_name>` to scaffold a task directory with a starter `main.rb`.

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
  Add `mi validate <task_name>` to check for task loading errors and malformed schemas.

* [ ] **Schema Type Shorthands and Helpers**
  Provide helpers like `Mi::Schema.string_array` to simplify schema definitions.

* [ ] **GitHub-Flavored Task Sharing**
  Allow importing tasks from GitHub or Gist via commands like `mi import gh:user/repo/task_name`.

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

## License

MIT
