-- args.lua: command-line arguments live in the global table `arg`
print("script name:", arg[0])
print("argument count:", #arg)
for i = 1, #arg do
  print(i, arg[i])
end
