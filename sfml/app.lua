local window = RenderWindow.new(800, 600, "Black Screen")
print("size", window:size())
print("position", window:position())

local navy = {r=0, g=0, b=128}
local MOVE_SPEED = 20
local circle = CircleShape.new(80, 3)
circle:color("cyan")

local keymap = {
	Left = function ()
		circle:move(-MOVE_SPEED, 0)
	end;
	
	Right = function ()
		circle:move(MOVE_SPEED, 0)
	end;
	
	Up = function ()
		circle:move(0, -MOVE_SPEED)
	end;
	
	Down = function ()
		circle:move(0, MOVE_SPEED)
	end;
}

while window:is_open() do
	local event = window:poll()
	if type(event) == "table" then
		local eventtype = event.type
		-- print(eventtype)
		
		if eventtype == "Closed" then
			break
		elseif eventtype == "KeyReleased" and event.key == "Escape" then
			break
		elseif eventtype == "KeyReleased" then
			local handler = keymap[event.key]
			if handler then
				handler()
			end
		end
	end
	
	window:clear(navy)
	window:draw(circle)
	window:display()
end

print("Closing window")
window:close()