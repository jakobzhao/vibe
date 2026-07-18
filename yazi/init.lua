-- Vibe Favorites is intentionally configured through environment variables in
-- bin/vibe, so the same Yazi config remains usable outside a Vibe session.

-- Keep Vibe's compact Explorer pane visually minimal.
require("no-status"):setup()

-- Present the directory passed to Vibe as the visible root instead of exposing
-- its absolute parent path in Yazi's header. Descendants remain recognizable
-- as "root-name/path/within/root".
local function visible_path(path, root, label)
	if not root or root == "" then
		return nil
	end

	root = root:gsub("/+$", "")
	if path ~= root and path:sub(1, #root + 1) ~= root .. "/" then
		return nil
	end

	local name = label or root:match("([^/]+)$") or root
	return name .. path:sub(#root + 1)
end

function Header:cwd()
	local max = self._area.w - self._right_width
	if max <= 0 then
		return ""
	end

	local path = tostring(self._current.cwd)
	local shown = visible_path(path, os.getenv("VIBE_PROJECT_DIR"))
		or visible_path(path, os.getenv("VIBE_FAVORITES_DIR"), "Favorites")
		or ya.readable_path(path)
	local text = shown .. self:flags()
	return ui.Span(ui.truncate(text, { max = max, rtl = true })):style(th.mgr.cwd)
end

-- Clicking only moves the cursor.  Cloud-backed files are hydrated exclusively
-- after an explicit Enter handled by the vibe-open plugin.
function Entity:click(event, up)
	if up or event.is_middle then
		return
	end

	ya.emit("reveal", { self._file.url })
end
