local scenario = arg[1]

if scenario == "clean" then
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(":q<CR>", true, false, true),
    "xt",
    false
  )
  assert(vim.bo.filetype == "vibe-welcome", "clean :q did not return to welcome")
elseif scenario == "modified" then
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
  vim.cmd("silent! VibeClose")
  assert(vim.bo.filetype ~= "vibe-welcome", "modified buffer closed without force")
elseif scenario == "force" then
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
  vim.cmd("VibeClose!")
  assert(vim.bo.filetype == "vibe-welcome", "forced close did not return to welcome")
else
  error("unknown close scenario: " .. tostring(scenario))
end
