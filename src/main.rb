def load(path)
  eval(File.read(path), binding, path)
end

def config_home
  XDG_CONFIG_HOME || (HOME + "/.config")
end

if ARGV[0] == "run" && ARGV[1]
  task_name = ARGV[1]
  script_path = "#{config_home}/mycli/tasks/#{task_name}/main.rb"

  if File.exist?(script_path)
    load(script_path)
  else
    puts "Task '#{task_name}' not found at #{script_path}"
    exit 1
  end

elsif ARGV[0] == "run"
  puts "Usage: mycli run <task_name>"
  exit 1
end
