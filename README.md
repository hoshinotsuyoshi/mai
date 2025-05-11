# mi

This is a command-line tool (`mi`) that leverages the Gemini API to generate content based on user-defined tasks. It executes Ruby logic via mruby, embedded within a statically compiled binary. Tasks are dynamically loaded from user-defined scripts. These scripts are located in the user's configuration directory, allowing for highly customizable behavior without requiring external Ruby dependencies.

## Overview

The `mi` tool takes a task name as input, loads the corresponding task definition from a Ruby script, interacts with the Gemini API based on the task's specifications, and outputs the results. The core logic is written in Ruby and executed using mruby, ensuring a small footprint and fast execution.

## Key Features

*   **Task-Based Content Generation:** Generates content based on user-defined tasks.
*   **Dynamic Task Loading:** Tasks are loaded dynamically from Ruby scripts located in the user's configuration directory (`$XDG_CONFIG_HOME/mi/tasks/<task_name>/main.rb`).
*   **mruby Execution:** Executes Ruby code via mruby, embedded in a statically compiled binary.
*   **Gemini API Interaction:** Interacts with the Gemini API to generate content based on custom schemas and prompts defined in the tasks.
*   **Two-Phase Evaluation:** Evaluates initial Gemini API responses for factual correctness and relevance before final output.
*   **Customizable Schemas:** Supports customization through Ruby scripts to define schemas and tailor the API interaction.

## Installation / Usage

### ✅ Recommended: Download Prebuilt Binary

1. Go to the [Releases page](https://github.com/hoshinotsuyoshi/mi/releases)
2. Download the binary for your OS (e.g., `mi-macos`, `mi-linux`)
3. Make it executable:

   ```sh
   chmod +x ./mi
   ```

4. (Optional) Move it to your `PATH`:

   ```sh
   mv ./mi /usr/local/bin/
   ```

### 🛠️ Alternative: Build from Source

1. Clone the repository:

   ```sh
   git clone https://github.com/hoshinotsuyoshi/mi.git
   cd mi
   ```

2. Build the binary:

   ```sh
   make
   ```

   This compiles:

   * `mruby` with the default configuration
   * The task execution logic into `mruby` bytecode
   * A statically linked mi binary that embeds the `mruby` bytecode

### 🔧 Setup & Run

1. Set your Gemini API key:

   ```sh
   export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
   ```

2. Run a task:

   ```sh
   mi run <task_name>
   ```

   * `<task_name>` must match a directory under `$XDG_CONFIG_HOME/mi/tasks/`, such as `my_task/main.rb`
   * Input can be piped in via stdin unless using `--no-stdin`

3. (Optional) Provide task input via stdin:

   Input should be a valid JSON object. It will be passed to the task's `text` method.

4. Output:

   Output is a JSON object containing the result, confidence score, and fit score:

   ```json
   {
     "main": "Generated content",
     "confidence": 0.95,
     "fit_score": 0.90
   }
   ```

## Task Customization

Tasks are defined by Ruby scripts located in `$XDG_CONFIG_HOME/mi/tasks/<task_name>/main.rb`. Each task script should define a class that includes:

*   A `text` method: This method takes the input (if any) and returns a prompt string for the Gemini API. This prompt is used in the first API call to generate the draft answer.
*   A `response_schema` method: This method returns a JSON schema that describes the expected format of the Gemini API's response. This schema is used to validate the Gemini API's first response, and to construct the evaluation prompt in the second API call.

### Example Task Definition

```ruby
# $XDG_CONFIG_HOME/mi/tasks/cookie_recipe/main.rb

Class.new do
  def text(_input)
    "List a few popular cookie recipes, and include the amounts of ingredients."
  end

  def response_schema
    {
      "type": "ARRAY",
      "items": {
        "type": "OBJECT",
        "properties": {
          "recipeName": {
            "type": "STRING"
          },
          "ingredients": {
            "type": "ARRAY",
            "items": {
              "type": "STRING"
            }
          }
        },
        "propertyOrdering": [
          "recipeName",
          "ingredients"
        ]
      }
    }
  end
end
```

## Requirements / Dependencies

*   `clang` or another C compiler
*   `curl` for making HTTP requests
*   GNU `make` for building
*   A Unix-like environment (macOS, Linux, etc.)
*   A Gemini API key (set as the `GEMINI_API_KEY` environment variable)

## Directory Structure

```
.
├── Makefile                  # Build script for compiling the CLI tool
├── src/
│   ├── main.c                # C entrypoint for running embedded Ruby bytecode
│   └── main.rb               # Ruby script embedding logic for the tool
└── LICENSE                   # Project license (MIT)
```

Task definitions are stored in:

```
$XDG_CONFIG_HOME/mi/tasks/<task_name>/main.rb
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
