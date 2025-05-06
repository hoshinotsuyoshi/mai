# mruby-cli-template

This is a minimal template for building a statically-linked CLI tool using [mruby](https://github.com/mruby/mruby). It embeds a Ruby script into a single C binary, making it portable across Unix-like systems.

## 🔧 Features

- Embeds `main.rb` into a native binary (`mycli`)
- Statically links `mruby` (optional, default on Linux)
- Includes [mruby-json](https://github.com/mattn/mruby-json) gem
- Uses `curl` and parses JSON from a remote API
- Fully customizable via `build_config.rb`

## 📦 Project Structure

```

.
├── Makefile                  # Build script for compiling CLI
├── build\_config.rb           # mruby build configuration
├── src/
│   ├── main.c                # C entrypoint embedding compiled Ruby bytecode
│   ├── main.rb               # Ruby logic to be embedded
├── mrbgems/mruby-json/       # JSON parsing gem (submodule)
├── mruby/                    # mruby source (submodule)

````

## 🚀 Usage

### 1. Clone the repository

```sh
git clone --recurse-submodules https://github.com/hoshinotsuyoshi/mruby-cli-template.git
cd mruby-cli-template
````

If you forgot `--recurse-submodules`:

```sh
git submodule update --init --recursive
```

### 2. Build

```sh
make
```

This compiles:

* `mruby` with the specified configuration
* `main.rb` to bytecode (`.mrb`)
* C binary with the embedded bytecode

### 3. Run

```sh
./mycli
```

Expected output:

```
Output: delectus aut autem
Exit status: pid 12345 exit 0
```

(Note: The actual output depends on the remote API response.)

## 🧹 Clean

```sh
make clean
```

Removes build artifacts and temporary files.

## 🛠 Dependencies

* `clang` or another C compiler
* `curl`
* GNU `make`
* Unix-like environment (macOS, Linux, etc.)

## 🧪 Customization

You can modify `src/main.rb` freely. Upon rebuilding, the updated Ruby code will be embedded into the binary.

To add other gems, edit `build_config.rb`:

```ruby
conf.gem './mrbgems/your-custom-gem'
```

## 📄 License

MIT
