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
local animations_enabled = vim.env.VIBE_ANIMATIONS ~= "0"
if vim.g.vibe_title_timer then
  pcall(vim.fn.timer_stop, vim.g.vibe_title_timer)
  vim.g.vibe_title_timer = nil
end
local vibe_group = vim.api.nvim_create_augroup("Vibe", { clear = true })
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
    VibeMetaLabel = { fg = palette.muted, bg = palette.background },
    VibeMetaValue = { fg = palette.foreground, bg = palette.background },
    VibeLink = { fg = palette.blue, bg = palette.background, underline = true },
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
  group = vibe_group,
  callback = function(args)
    local name = vim.api.nvim_buf_get_name(args.buf)
    if name ~= "" and vim.bo[args.buf].buftype == "" then
      set_pane_title("Editor · " .. vim.fn.fnamemodify(name, ":t"))
    end
  end,
})

local welcome_content = {
  { "V I B E", "VibeTitle" },
  { "A minimalist terminal environment for vibe coding", "VibeHint" },
  { "", nil },
  { "Choose a file in Directory to open in Editor", "VibeHint" },
  { "", nil },
  { "Enter open  ·  Mouse enabled  ·  Ctrl-a h/j/k/l move", "VibeHint" },
  { "", nil },
  { "i edit  ·  Esc normal  ·  :w save  ·  :q close", "VibeHint" },
  { "", nil },
  { "Mouse: click panels  ·  Drag borders to resize", "VibeHint" },
  { "", nil },
  { "Ctrl-a d detach  ·  Ctrl-a Q quit vibe", "VibeHint" },
}

local welcome_footer = {
  { label = "Author", value = "Bo Zhao" },
  { label = "Affiliation", value = "UW Humanistic GIS Lab" },
  { label = "Website", value = "https://hgis.uw.edu", url = "https://hgis.uw.edu" },
  { label = "Version", value = "0.1.0" },
}

local welcome_buf
local welcome_namespace = vim.api.nvim_create_namespace("vibe-welcome")

local function ensure_welcome_buffer()
  if welcome_buf and vim.api.nvim_buf_is_valid(welcome_buf) then
    return welcome_buf
  end

  local current = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_name(current) == ""
      and vim.bo[current].buftype == ""
      and not vim.bo[current].modified then
    welcome_buf = current
  else
    welcome_buf = vim.api.nvim_create_buf(false, true)
  end

  vim.bo[welcome_buf].buflisted = false
  vim.bo[welcome_buf].buftype = "nofile"
  vim.bo[welcome_buf].bufhidden = "hide"
  vim.bo[welcome_buf].filetype = "vibe-welcome"
  return welcome_buf
end

local function render_welcome()
  local buf = ensure_welcome_buffer()
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    return
  end

  local width = vim.api.nvim_win_get_width(win)
  local height = vim.api.nvim_win_get_height(win)
  local footer_gap = 2
  local bottom_margin = 1
  local content_height = math.max(1, height - #welcome_footer - footer_gap - bottom_margin)
  local top = math.max(0, math.floor((content_height - #welcome_content) / 2))
  local lines = {}
  for _ = 1, top do
    table.insert(lines, "")
  end
  for _, item in ipairs(welcome_content) do
    local text = item[1]
    local padding = math.max(0, math.floor((width - vim.fn.strdisplaywidth(text)) / 2))
    table.insert(lines, string.rep(" ", padding) .. text)
  end

  local footer_start = math.max(#lines + footer_gap, height - #welcome_footer - bottom_margin)
  while #lines < footer_start do
    table.insert(lines, "")
  end

  local footer_label_width = 0
  local footer_value_width = 0
  for _, item in ipairs(welcome_footer) do
    footer_label_width = math.max(footer_label_width, vim.fn.strdisplaywidth(item.label))
    footer_value_width = math.max(footer_value_width, vim.fn.strdisplaywidth(item.value))
  end
  local footer_gap_width = 2
  local footer_width = footer_label_width + footer_gap_width + footer_value_width
  local footer_padding = math.max(0, math.floor((width - footer_width) / 2))
  for _, item in ipairs(welcome_footer) do
    local label_padding = footer_label_width - vim.fn.strdisplaywidth(item.label)
    table.insert(
      lines,
      string.rep(" ", footer_padding + label_padding)
        .. item.label
        .. string.rep(" ", footer_gap_width)
        .. item.value
    )
  end

  vim.bo[buf].readonly = false
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, welcome_namespace, 0, -1)
  for index, item in ipairs(welcome_content) do
    if item[2] then
      vim.api.nvim_buf_add_highlight(buf, welcome_namespace, item[2], top + index - 1, 0, -1)
    end
  end
  for index, item in ipairs(welcome_footer) do
    local row = footer_start + index - 1
    local label_padding = footer_label_width - vim.fn.strdisplaywidth(item.label)
    local label_start = footer_padding + label_padding
    local value_start = footer_padding + footer_label_width + footer_gap_width
    vim.api.nvim_buf_add_highlight(
      buf,
      welcome_namespace,
      "VibeMetaLabel",
      row,
      label_start,
      label_start + #item.label
    )
    vim.api.nvim_buf_add_highlight(
      buf,
      welcome_namespace,
      item.url and "VibeLink" or "VibeMetaValue",
      row,
      value_start,
      value_start + #item.value
    )
    if item.url then
      vim.api.nvim_buf_set_extmark(buf, welcome_namespace, row, value_start, {
        end_col = value_start + #item.value,
        url = item.url,
      })
    end
  end
  vim.bo[buf].modified = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
end

local animation_colors = { palette.green, palette.cyan, palette.blue }
local animation_timer
local animation_step = 0

local function interpolate_color(first, second, amount)
  local function channel(color, offset)
    return tonumber(color:sub(offset, offset + 1), 16)
  end

  local channels = {}
  for offset = 2, 6, 2 do
    local start_value = channel(first, offset)
    local end_value = channel(second, offset)
    table.insert(channels, math.floor(start_value + (end_value - start_value) * amount + 0.5))
  end
  return string.format("#%02x%02x%02x", channels[1], channels[2], channels[3])
end

local function start_title_animation()
  if not animations_enabled or animation_timer then
    return
  end

  local steps_per_color = 16
  animation_timer = vim.fn.timer_start(250, function()
    if not welcome_buf or vim.fn.bufwinid(welcome_buf) == -1 then
      return
    end

    local segment = math.floor(animation_step / steps_per_color) % #animation_colors
    local next_segment = (segment + 1) % #animation_colors
    local progress = (animation_step % steps_per_color) / steps_per_color
    local eased = (1 - math.cos(math.pi * progress)) / 2
    local color = interpolate_color(
      animation_colors[segment + 1],
      animation_colors[next_segment + 1],
      eased
    )
    vim.api.nvim_set_hl(0, "VibeTitle", {
      fg = color,
      bg = palette.background,
      bold = true,
    })
    animation_step = animation_step + 1
  end, { ["repeat"] = -1 })
  vim.g.vibe_title_timer = animation_timer
end

local function show_welcome()
  local buf = ensure_welcome_buffer()
  vim.api.nvim_win_set_buf(0, buf)
  vim.opt_local.number = false
  vim.opt_local.signcolumn = "no"
  vim.opt_local.wrap = false
  render_welcome()
  start_title_animation()
  set_pane_title("Editor")
end

vim.api.nvim_create_user_command("VibeClose", function(opts)
  local current = vim.api.nvim_get_current_buf()
  if current == welcome_buf or vim.bo[current].filetype == "vibe-welcome" then
    vim.cmd(opts.bang and "quit!" or "quit")
    return
  end
  if vim.bo[current].buftype ~= "" then
    vim.cmd(opts.bang and "quit!" or "quit")
    return
  end
  if vim.bo[current].modified and not opts.bang then
    vim.api.nvim_err_writeln("No write since last change (add ! to override)")
    return
  end

  show_welcome()
  if vim.api.nvim_buf_is_valid(current) then
    vim.api.nvim_buf_delete(current, { force = opts.bang })
  end
end, { bang = true, force = true })

vim.cmd([[
  cnoreabbrev <expr> q getcmdtype() ==# ':' && getcmdline() ==# 'q' ? 'VibeClose' : 'q'
  cnoreabbrev <expr> quit getcmdtype() ==# ':' && getcmdline() ==# 'quit' ? 'VibeClose' : 'quit'
]])

vim.api.nvim_create_autocmd("VimEnter", {
  group = vibe_group,
  once = true,
  callback = function()
    if vim.fn.argc() == 0 then
      show_welcome()
    end
  end,
})

vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
  group = vibe_group,
  callback = render_welcome,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vibe_group,
  callback = function()
    if animation_timer then
      vim.fn.timer_stop(animation_timer)
      animation_timer = nil
      vim.g.vibe_title_timer = nil
    end
  end,
})
