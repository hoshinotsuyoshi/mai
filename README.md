# mi CLI Tool

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

### 1. Clone the Repository

```sh
git clone https://github.com/hoshinotsuyoshi/mi.git
cd mi
```

### 2. Build the Tool

```sh
make
```

This will compile:

*   `mruby` with the default configuration.
*   The Ruby code into bytecode.
*   A C binary (`mi`) that includes the Ruby bytecode.

### 3. Set the Gemini API Key

Set the `GEMINI_API_KEY` environment variable with your Gemini API key. This is essential for the tool to interact with the Gemini API.

```sh
export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
```

### 4. Run the Tool

```sh
./mi run <task_name>
```

*   The `<task_name>` should correspond to a directory under `$XDG_CONFIG_HOME/mi/tasks/` (e.g., `$XDG_CONFIG_HOME/mi/tasks/my_task/main.rb`).
*   Input can be provided via standard input (stdin) unless the task is run with the `--no-stdin` flag.

### 5. Task Input (via stdin, optional):

Tasks can optionally receive input via standard input. The input should be a valid JSON object. This input is then passed to the task's `text` method.

### 6. Expected Output

The tool outputs a JSON object, which includes the final generated content (`main`), a confidence score, and a fit score. These scores reflect the tool's assessment of the generated content's accuracy and relevance.

```json
{"main": "Generated content", "confidence": 0.95, "fit_score": 0.90}
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

## License

MIT
