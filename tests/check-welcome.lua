local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local text = table.concat(lines, "\n")

assert(text:find("A minimalist terminal environment for vibe coding", 1, true))
assert(text:find("UW Humanistic GIS Lab", 1, true))

local values = {
  "Bo Zhao",
  "UW Humanistic GIS Lab",
  "https://hgis.uw.edu",
  "0.1.0",
}
local value_column
for _, value in ipairs(values) do
  local found_column
  for _, line in ipairs(lines) do
    found_column = line:find(value, 1, true)
    if found_column then
      break
    end
  end
  assert(found_column, "missing welcome metadata value: " .. value)
  value_column = value_column or found_column
  assert(found_column == value_column, "welcome metadata values are not aligned")
end

local has_website_link = false
for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) do
  if mark[4].url == "https://hgis.uw.edu" then
    has_website_link = true
    break
  end
end
assert(has_website_link, "welcome Website is not linked")

local initial_title_color = vim.api.nvim_get_hl(0, { name = "VibeTitle" }).fg
vim.wait(700)
local animated_title_color = vim.api.nvim_get_hl(0, { name = "VibeTitle" }).fg
assert(animated_title_color ~= initial_title_color, "VIBE title color did not animate")
