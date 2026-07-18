local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
local text = table.concat(lines, "\n")

assert(text:find("A minimalist terminal environment for vibe coding", 1, true))
assert(text:find("UW Humanistic GIS Lab", 1, true))
assert(not text:find("Choose a file in Directory", 1, true))
assert(not text:find("Author", 1, true))
assert(not text:find("Affiliation", 1, true))
assert(not text:find("Website", 1, true))
assert(not text:find("Version", 1, true))

local values = {
  "Bo Zhao",
  "UW Humanistic GIS Lab",
  "https://hgis.uw.edu",
  "0.1.0",
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
