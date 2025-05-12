# General Rules

## Directory Structure

```
.
├── src/
│   ├── main.c                # C entrypoint for running mruby bytecode
│   └── main.rb               # mruby script embedding logic for the tool
└── test
    └── mai_test.rb           # test
```

## src/main.rb

### Important Notes

- You can write `mruby`, not MRI `ruby`. Be aware that there are many classes and methods that exist in MRI but not in mruby.
  - For example, `require` cannot be used.
- Only the following libraries and classes are available because they are imported from external libraries.
  - ENV
  - JSON
  - MTest
  - Tempfile

### Implementation Policy

- Implement as a unit as much as possible as a singleton method within `module Mai`.
  - For testability, do not call exit within singleton methods.
  - For testability, do not call ARGV within singleton methods.

## Testing (test/mai_test.rb)

- Tests are performed using MTest by loading (evaluating) src/main.rb
- Tests the singleton methods of the `Mai` module.
