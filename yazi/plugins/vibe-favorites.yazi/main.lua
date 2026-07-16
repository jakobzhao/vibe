local function favorites_dir()
	return os.getenv("VIBE_FAVORITES_DIR") or (os.getenv("HOME") .. "/.local/share/vibe/favorites")
end

local function helper()
	return os.getenv("VIBE_FAVORITE_HELPER") or "vibe-favorite"
end

local get_context = ya.sync(function(state)
	local current = cx.active.current
	return {
		cwd = tostring(current.cwd),
		hovered = current.hovered and tostring(current.hovered.url) or nil,
		previous = state.previous,
	}
end)

local set_previous = ya.sync(function(state, path)
	state.previous = path
end)

local function run_helper(action, path)
	local child, err = Command(helper())
		:arg({ action, path })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if not child then
		return false, tostring(err)
	end

	local output, wait_err = child:wait_with_output()
	if not output then
		return false, tostring(wait_err)
	end

	local message = output.status.success and output.stdout or output.stderr
	message = tostring(message):gsub("%s+$", "")
	return output.status.success, message
end

local function notify(ok, message)
	ya.notify({
		title = "Favorites",
		content = message ~= "" and message or (ok and "Done" or "Unable to update favorites"),
		level = ok and "info" or "error",
		timeout = 2,
	})
end

return {
	entry = function(_, job)
		local action = job.args[1]
		local context = get_context()
		local root = favorites_dir()

		if action == "toggle" then
			if context.cwd == root then
				run_helper("title", "directory")
				ya.emit("cd", { context.previous or os.getenv("VIBE_PROJECT_DIR") or os.getenv("HOME") })
			else
				set_previous(context.cwd)
				run_helper("title", "favorites")
				ya.emit("cd", { root })
			end
			return
		end

		if not context.hovered then
			return notify(false, "No file selected")
		end

		if action == "add" then
			local ok, message = run_helper("add", context.hovered)
			run_helper("title", context.cwd == root and "favorites" or "directory")
			return notify(ok, message)
		end

		if action == "remove" then
			local ok, message = run_helper("remove", context.hovered)
			run_helper("title", context.cwd == root and "favorites" or "directory")
			notify(ok, message)
			if ok then
				ya.emit("refresh", {})
			end
		end
	end,
}
