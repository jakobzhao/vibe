vim.opt.mouse = "a"
vim.opt.number = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.swapfile = false
vim.opt.updatetime = 300
local compact_ui = vim.env.VIBE_COMPACT_UI ~= "0"
vim.opt.laststatus = compact_ui and 0 or 2
if compact_ui then
  vim.opt.ruler = false
  vim.opt.showmode = false
  if vim.fn.exists("+cmdheight") == 1 then
    vim.opt.cmdheight = 0
  end
end

local palette = {
  background = "#141729",
  surface = "#343851",
  muted = "#8d91a5",
  foreground = "#e2e3e8",
  green = "#21b568",
  cyan = "#3ed7be",
  blue = "#2091f6",
  selection = "#1b6649",
}

local function apply_vibe_theme()
  local highlights = {
    Normal = { fg = palette.foreground, bg = palette.background },
    NormalNC = { fg = palette.muted, bg = palette.background },
    EndOfBuffer = { fg = palette.background, bg = palette.background },
    LineNr = { fg = palette.muted, bg = palette.background },
    CursorLineNr = { fg = palette.green, bg = palette.background, bold = true },
    SignColumn = { fg = palette.muted, bg = palette.background },
    StatusLine = { fg = palette.background, bg = palette.green, bold = true },
    StatusLineNC = { fg = palette.muted, bg = palette.surface },
    WinSeparator = { fg = palette.surface, bg = palette.background },
    Visual = { fg = palette.foreground, bg = palette.selection },
    Search = { fg = palette.background, bg = palette.cyan, bold = true },
    IncSearch = { fg = palette.background, bg = palette.blue, bold = true },
    VibeTitle = { fg = palette.green, bg = palette.background, bold = true },
    VibeHint = { fg = palette.muted, bg = palette.background },
  }

  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

apply_vibe_theme()

local function set_pane_title(title)
  local pane = vim.env.VIBE_MAIN_PANE
  if pane and pane ~= "" then
    vim.fn.jobstart(
      { "tmux", "set-option", "-p", "-t", pane, "@vibe_role", title },
      { detach = true }
    )
  end
end

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(args)
    local name = vim.api.nvim_buf_get_name(args.buf)
    if name ~= "" and vim.bo[args.buf].buftype == "" then
      set_pane_title("Main · " .. vim.fn.fnamemodify(name, ":t"))
    end
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    if vim.fn.argc() ~= 0 then
      return
    end

    local content = {
      { "V I B E", "VibeTitle" },
      { "", nil },
      { "Choose a file in the Directory panel", "VibeHint" },
      { "", nil },
      { "Enter open  ·  Mouse enabled  ·  Ctrl-a h/j/k/l move", "VibeHint" },
      { "", nil },
      { "i edit  ·  Esc normal  ·  :w save  ·  :q close", "VibeHint" },
      { "", nil },
      { "Mouse: click panels  ·  Drag borders to resize", "VibeHint" },
      { "", nil },
      { "Ctrl-a d detach  ·  Ctrl-a Q quit vibe", "VibeHint" },
    }
    local footer = {
      { "Author       Bo Zhao", "VibeHint" },
      { "Affiliation  University of Washington", "VibeHint" },
      { "Version      0.1.0", "VibeHint" },
    }

    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.filetype = "vibe-welcome"
    vim.opt_local.number = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.wrap = false

    local welcome_buf = vim.api.nvim_get_current_buf()
    local function render_welcome()
      if not vim.api.nvim_buf_is_valid(welcome_buf) then
        return
      end

      local win = vim.fn.bufwinid(welcome_buf)
      if win == -1 then
        return
      end

      local width = vim.api.nvim_win_get_width(win)
      local height = vim.api.nvim_win_get_height(win)
      local footer_gap = 2
      local bottom_margin = 1
      local content_height = math.max(1, height - #footer - footer_gap - bottom_margin)
      local top = math.max(0, math.floor((content_height - #content) / 2))
      local lines = {}
      for _ = 1, top do
        table.insert(lines, "")
      end
      for _, item in ipairs(content) do
        local text = item[1]
        local padding = math.max(0, math.floor((width - vim.fn.strdisplaywidth(text)) / 2))
        table.insert(lines, string.rep(" ", padding) .. text)
      end

      local footer_start = math.max(#lines + footer_gap, height - #footer - bottom_margin)
      while #lines < footer_start do
        table.insert(lines, "")
      end

      local footer_width = 0
      for _, item in ipairs(footer) do
        footer_width = math.max(footer_width, vim.fn.strdisplaywidth(item[1]))
      end
      local footer_padding = math.max(0, math.floor((width - footer_width) / 2))
      for _, item in ipairs(footer) do
        table.insert(lines, string.rep(" ", footer_padding) .. item[1])
      end

      vim.bo[welcome_buf].readonly = false
      vim.bo[welcome_buf].modifiable = true
      vim.api.nvim_buf_set_lines(welcome_buf, 0, -1, false, lines)
      vim.api.nvim_buf_clear_namespace(welcome_buf, -1, 0, -1)
      for index, item in ipairs(content) do
        if item[2] then
          vim.api.nvim_buf_add_highlight(
            welcome_buf,
            -1,
            item[2],
            top + index - 1,
            0,
            -1
          )
        end
      end
      for index, item in ipairs(footer) do
        if item[2] then
          vim.api.nvim_buf_add_highlight(
            welcome_buf,
            -1,
            item[2],
            footer_start + index - 1,
            0,
            -1
          )
        end
      end
      vim.bo[welcome_buf].modified = false
      vim.bo[welcome_buf].modifiable = false
      vim.bo[welcome_buf].readonly = true
    end

    render_welcome()
    vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
      callback = render_welcome,
    })

    set_pane_title("Main")
  end,
})
