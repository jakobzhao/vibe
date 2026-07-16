-- Vibe Favorites is intentionally configured through environment variables in
-- bin/vibe, so the same Yazi config remains usable outside a Vibe session.

-- Keep Vibe's compact Directory pane visually minimal.
require("no-status"):setup()

-- Clicking only moves the cursor.  Cloud-backed files are hydrated exclusively
-- after an explicit Enter handled by the vibe-open plugin.
function Entity:click(event, up)
	if up or event.is_middle then
		return
	end

	ya.emit("reveal", { self._file.url })
end
