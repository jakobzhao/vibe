local current_directory = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

local function at_boundary(path, root)
	if not root or root == "" then
		return false
	end
	return path:gsub("/+$", "") == root:gsub("/+$", "")
end

return {
	entry = function()
		local cwd = current_directory()
		if at_boundary(cwd, os.getenv("VIBE_PROJECT_DIR")) then
			return
		end
		ya.emit("leave", {})
	end,
}
