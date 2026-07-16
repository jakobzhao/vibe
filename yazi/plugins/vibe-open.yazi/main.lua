local get_hovered = ya.sync(function()
	local hovered = cx.active.current.hovered
	if not hovered then
		return nil
	end

	return {
		path = tostring(hovered.url),
		is_dir = hovered.cha.is_dir,
	}
end)

local function notify_error(message)
	ya.notify({
		title = "Open in Main",
		content = message,
		level = "error",
		timeout = 3,
	})
end

return {
	entry = function()
		local hovered = get_hovered()
		if not hovered then
			return notify_error("No file selected")
		end

		if hovered.is_dir then
			ya.emit("enter", {})
			return
		end

		-- This is the only path that reads a file: the user explicitly pressed
		-- Enter, and Neovim may now hydrate the cloud-backed placeholder.
		local child, err = Command(os.getenv("EDITOR") or "vibe-open")
			:arg(hovered.path)
			:stdout(Command.NULL)
			:stderr(Command.PIPED)
			:spawn()
		if not child then
			return notify_error(tostring(err))
		end

		local output, wait_err = child:wait_with_output()
		if not output then
			return notify_error(tostring(wait_err))
		end
		if not output.status.success then
			local message = tostring(output.stderr):gsub("%s+$", "")
			return notify_error(message ~= "" and message or "Unable to open file")
		end
	end,
}
