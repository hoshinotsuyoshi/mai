cmd = ['curl', '-sS', 'https://jsonplaceholder.typicode.com/todos/1'].join(' ')
io = IO.popen(cmd, "r")
output = io.read
io.close
status = $?
if status == 0
  output = JSON.parse(output).fetch('title')
end

puts "Output: #{output}"
puts "Exit status: #{status}"
