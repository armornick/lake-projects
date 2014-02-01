local function split(s, sep)
	local start, stop = 1, 0
	local results = {}
	
	while stop do
		stop = s:find(sep, start)
		if stop then
			table.insert(results, s:sub(start, stop-1))
			start = stop + 1
		else
			table.insert(results, s:sub(start, #s))
		end
	end
	
	return results
end

-----------------------------------------------
-- http://lua-users.org/wiki/IteratorsTutorial
local function square(state,n) 
	if n<state then 
		n=n+1 
		return n,n*n 
	end 
end
local function squares(nbvals) 
	return square,nbvals,0 
end
-- for i,n in squares(5) do print(i,n) end
-----------------------------------------------

local function iterate_string(str)
	local f = function (s, i)
		if i <= #s then
			i = i + 1
			return i, s:sub(i, i)
		end
	end
	
	return f, str, 0
end

playground = {
	striter = iterate_string,
	squares = squares,
	split = split
}