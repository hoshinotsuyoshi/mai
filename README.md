# mi CLI Tool

This is a command-line tool (`mi`) that utilizes `mruby` to run Ruby code, which is embedded within a statically compiled C binary. The tool interacts with a remote API (Gemini API) to generate content based on provided input.

## 🔧 Features

* Embeds Ruby code (`main.rb`) directly into a C binary.
* Uses `mruby` for lightweight Ruby scripting.
* Interacts with the [Gemini API](https://generativelanguage.googleapis.com/) to generate content based on custom schemas.
* Supports customization through `main.rb` to modify how tasks are run.

## 📦 Project Structure

```
.
├── Makefile                  # Build script for compiling the CLI tool
├── src/
│   ├── main.c                # C entrypoint for running embedded Ruby bytecode
│   └── main.rb               # Ruby script embedding logic for the tool
└── LICENSE                   # Project license (MIT)
```

## 🚀 Usage

### 1. Clone the Repository

```sh
git clone https://github.com/hoshinotsuyoshi/mi-cli.git
cd mi-cli
```

### 2. Build the Tool

```sh
make
```

This will compile:

* `mruby` with the default configuration.
* The Ruby code in `main.rb` into bytecode.
* A C binary (`mi`) that includes the Ruby bytecode.

### 3. Run the Tool

Once built, you can run the tool:

```sh
./mi run <task_name>
```

* The `task_name` should correspond to a Ruby script (e.g., `src/mi/tasks/<task_name>/main.rb`).
* If the task is found, it will be executed using the embedded Ruby code.

### 4. Expected Output

The tool makes a request to the Gemini API, processes the response, and outputs it in JSON format:

```
Output: delectus aut autem
Exit status: pid 12345 exit 0
```

(Note: The actual output will vary depending on the API response.)

## 🧹 Clean

To remove build artifacts and temporary files, run:

```sh
make clean
```

## 🧪 Customization

You can modify the Ruby code in `src/main.rb` to customize the behavior of the tool.

* The tool uses the Gemini API to generate content. You can modify the schema or change the API's request format.
* To change the API key or add new environment variables, simply modify the `main.rb` file, where `GEMINI_API_KEY` is set from the environment.

### Example of Customization in `main.rb`

The script defines a method `Mi.run` that prepares a schema and sends a request to the Gemini API:

```ruby
def self.run(text:)
  schema = mi_schema(text)
  cmd = [
    "curl",
    "-H",
    "'Content-Type: application/json'",
    "-sSL",
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=#{GEMINI_API_KEY}",
    "-d",
    "'#{schema}'"
  ].join(' ')
 
  io = IO.popen(cmd, "r")
  output = io.read
  io.close
  status = $?
  if status == 0
    output = JSON.parse(output)
  end
  puts output.to_json
end
```

## 🛠 Dependencies

* `clang` or another C compiler
* `curl` for making HTTP requests
* GNU `make` for building
* A Unix-like environment (macOS, Linux, etc.)

## 📄 License

MIT
