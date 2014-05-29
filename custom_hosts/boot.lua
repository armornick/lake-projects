function get_mainfile (moduleName)
	return "bob.lua"
end

print "hello from boot.lua!"

if arg then
	print(string.format("number of arguments: %d", #arg))
	for i = 0, #arg do
		print(string.format("argument %d: %s", i, arg[i]))
	end
end
