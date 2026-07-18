local function helper()
	return os.getenv("VIBE_CONTEXT_HELPER") or "vibe-context"
end

local get_paths = ya.sync(function()
	local paths = {}
	for _, url in pairs(cx.active.selected) do
		table.insert(paths, tostring(url))
	end
	if #paths == 0 and cx.active.current.hovered then
		table.insert(paths, tostring(cx.active.current.hovered.url))
	end
	return paths
end)

local function run_helper(action, paths)
	local command = Command(helper()):arg(action)
	if paths then
		command = command:arg(paths)
	end
	local child, err = command:stdout(Command.PIPED):stderr(Command.PIPED):spawn()
	if not child then
		return false, tostring(err)
	end

	local output, wait_err = child:wait_with_output()
	if not output then
		return false, tostring(wait_err)
	end
	local message = output.status.success and output.stdout or output.stderr
	return output.status.success, tostring(message):gsub("%s+$", "")
end

local function notify(ok, message)
	ya.notify({
		title = "Agent Context",
		content = message ~= "" and message or (ok and "Done" or "Unable to update context"),
		level = ok and "info" or "error",
		timeout = 3,
	})
end

return {
	entry = function(_, job)
		local action = job.args[1]
		if action == "add" then
			local paths = get_paths()
			if #paths == 0 then
				return notify(false, "No file selected")
			end
			local ok, message = run_helper("add", paths)
			return notify(ok, message)
		end

		if action == "send" or action == "clear" then
			local ok, message = run_helper(action)
			return notify(ok, message)
		end

		notify(false, "Unknown context action")
	end,
}
