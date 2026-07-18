local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local text = table.concat(lines, "\n")

assert(text:find("A focused terminal workspace for vibe coding", 1, true))
assert(text:find("\\      /", 1, true))
assert(text:find("|------", 1, true))
assert(text:find("OPEN & NAVIGATE", 1, true))
assert(text:find("EDIT", 1, true))
assert(text:find("SESSION", 1, true))
assert(text:find("UW Humanistic GIS Lab", 1, true))
assert(not text:find("Choose a file in Explorer", 1, true))
assert(not text:find("Author", 1, true))
assert(not text:find("Affiliation", 1, true))
assert(not text:find("Website", 1, true))
assert(not text:find("Version", 1, true))

local title_rows = {}
for _, line in ipairs(lines) do
  if line:find("\\      /", 1, true)
      or line:find(" \\    /", 1, true)
      or line:find("  \\  /", 1, true)
      or line:find("   \\/", 1, true) then
    table.insert(title_rows, line)
  end
end
assert(#title_rows == 7, "welcome wordmark does not have seven rows")
local title_left
for _, line in ipairs(title_rows) do
  local row_left = line:find("%S")
  if line:find("\\      /", 1, true) then
    title_left = row_left - 1
  end
end
assert(title_left, "welcome V anchor is missing")
assert(title_rows[1]:find("-----", title_left + 15, true) == title_left + 15,
  "I is not at its fixed offset from V")
assert(title_rows[1]:find("|----\\", title_left + 25, true) == title_left + 25,
  "B is not at its fixed offset from V")
assert(title_rows[1]:find("|------", title_left + 37, true) == title_left + 37,
  "E is not at its fixed offset from V")

local subtitle_row
local navigation_row
for row, line in ipairs(lines) do
  if line:find("A focused terminal workspace for vibe coding", 1, true) then
    subtitle_row = row
  elseif line:find("OPEN & NAVIGATE", 1, true) then
    navigation_row = row
  end
end
assert(subtitle_row and navigation_row, "welcome sections are missing")
assert(navigation_row - subtitle_row == 4, "subtitle and instructions do not have three blank lines")

local normal_color = vim.api.nvim_get_hl(0, { name = "Normal" }).fg
local instruction_color = vim.api.nvim_get_hl(0, { name = "VibeInstruction" }).fg
local meta_color = vim.api.nvim_get_hl(0, { name = "VibeMeta" }).fg
local version_color = vim.api.nvim_get_hl(0, { name = "VibeVersion" }).fg
assert(instruction_color == meta_color, "instructions and metadata do not share the secondary tone")
assert(instruction_color ~= normal_color, "instructions use the primary text color")
assert(version_color ~= normal_color, "version uses the primary text color")
local section_color = vim.api.nvim_get_hl(0, { name = "VibeSection" }).fg
local subtitle_color = vim.api.nvim_get_hl(0, { name = "VibeSubtitle" }).fg
assert(section_color == subtitle_color, "welcome headings do not share the pale gray tone")

local values = {
  "Bo Zhao  ·  UW Humanistic GIS Lab",
  "https://hgis.uw.edu",
  "v0.2.3",
}
for _, value in ipairs(values) do
  local found_column
  for _, line in ipairs(lines) do
    found_column = line:find(value, 1, true)
    if found_column then
      break
    end
  end
  assert(found_column, "missing welcome metadata value: " .. value)
  local expected_column = math.floor(
    (vim.api.nvim_win_get_width(0) - vim.fn.strdisplaywidth(value)) / 2
  ) + 1
  assert(found_column == math.max(1, expected_column), "welcome metadata value is not centered: " .. value)
end

local has_website_link = false
for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) do
  if mark[4].url == "https://hgis.uw.edu" then
    has_website_link = true
    break
  end
end
if vim.fn.has("nvim-0.10") == 1 then
  assert(has_website_link, "welcome Website is not linked")
else
  assert(not has_website_link, "pre-0.10 Neovim unexpectedly created a URL extmark")
end

local initial_title_colors = {}
for index = 1, 4 do
  initial_title_colors[index] = vim.api.nvim_get_hl(0, { name = "VibeTitle" .. index }).fg
end
local unique_colors = {}
for _, color in ipairs(initial_title_colors) do
  unique_colors[color] = true
end
assert(vim.tbl_count(unique_colors) == 4, "VIBE letters do not start with distinct colors")
vim.wait(700)
for index = 1, 4 do
  local animated_color = vim.api.nvim_get_hl(0, { name = "VibeTitle" .. index }).fg
  assert(animated_color ~= initial_title_colors[index], "VIBE letter color did not animate")
end

vim.cmd("qa!")
