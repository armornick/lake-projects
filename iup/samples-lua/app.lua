
local txtScript = iup.multiline{expand="YES", border="YES"}

function open_file()
	local f, err = iup.GetFile("*.lua")
	if err == 0 then
		local inputf = io.open(f, "r")
		local code = inputf:read("*a")
	end
end

function run_script()
	local script = txtScript.value
	local chunk, err = loadstring(script)
	if chunk then
		local r, err = pcall(chunk)
		if not r then
			iup.Alarm("Error executing script", err, "Ok")
		end
	else
		iup.Alarm("Error loading script", err, "Ok")
	end
end

local btnOpen = iup.button{title="Open File", action=open_file}
local btnRun = iup.button{title="Run Script", action=run_script}

local dlg = iup.dialog {
	iup.vbox
	{
		iup.hbox
		{
			iup.fill{},
			btnOpen,
			btnRun,
			iup.fill{};
			alignment = "ATOP"
		},
		txtScript;
	};
	title = "Lua Executor"
}

dlg:showxy (iup.CENTER, iup.CENTER)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end