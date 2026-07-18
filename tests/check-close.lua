local scenario = arg[1]

if scenario == "clean" then
  vim.cmd("VibeClose")
  assert(vim.bo.filetype == "vibe-welcome", "clean close did not return to welcome")
elseif scenario == "modified" then
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
  vim.cmd("silent! VibeClose")
  assert(vim.bo.filetype ~= "vibe-welcome", "modified buffer closed without force")
  vim.bo.modified = false
elseif scenario == "force" then
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
  vim.cmd("VibeClose!")
  assert(vim.bo.filetype == "vibe-welcome", "forced close did not return to welcome")
else
  error("unknown close scenario: " .. tostring(scenario))
end

vim.cmd("qa!")
