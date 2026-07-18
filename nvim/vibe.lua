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
  subtle = "#686d82",
  foreground = "#e2e3e8",
  green = "#21b568",
  cyan = "#3ed7be",
  blue = "#2091f6",
  violet = "#9167f5",
  pink = "#ff7dc5",
  amber = "#eca855",
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
    VibeTitle1 = { fg = palette.green, bg = palette.background, bold = true },
    VibeTitle2 = { fg = palette.cyan, bg = palette.background, bold = true },
    VibeTitle3 = { fg = palette.blue, bg = palette.background, bold = true },
    VibeTitle4 = { fg = palette.violet, bg = palette.background, bold = true },
    VibeSubtitle = { fg = palette.muted, bg = palette.background },
    VibeSection = { fg = palette.muted, bg = palette.background, bold = true },
    VibeInstruction = { fg = palette.subtle, bg = palette.background },
    VibeMeta = { fg = palette.subtle, bg = palette.background },
    VibeVersion = { fg = palette.subtle, bg = palette.background },
    VibeLink = { fg = palette.muted, bg = palette.background, underline = true },
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

-- Every glyph occupies the same seven-row grid.  Their padded widths place the
-- visible strokes at fixed columns (V 1-8, I 15-19, B 25-30, E 37-43), so the
-- top, middle, and baseline stay aligned without row-by-row optical drift.
local title_glyphs = {
  {
    "\\      /      ",
    "\\      /      ",
    " \\    /       ",
    " \\    /       ",
    "  \\  /        ",
    "  \\  /        ",
    "   \\/         ",
  },
  {
    "-----     ",
    "  |       ",
    "  |       ",
    "  |       ",
    "  |       ",
    "  |       ",
    "-----     ",
  },
  {
    "|----\\      ",
    "|    |      ",
    "|    |      ",
    "|----/      ",
    "|    \\      ",
    "|    |      ",
    "|----/      ",
  },
  {
    "|------",
    "|      ",
    "|      ",
    "|----  ",
    "|      ",
    "|      ",
    "|------",
  },
}

local title_art = {}
local title_spans = {}
for row = 1, #title_glyphs[1] do
  local parts = {}
  local column = 0
  title_spans[row] = {}
  for index, glyph in ipairs(title_glyphs) do
    local line = glyph[row]
    table.insert(parts, line)
    title_spans[row][index] = { column, column + #line }
    column = column + #line
  end
  title_art[row] = table.concat(parts)
end

local welcome_content = {
  { title_art[1], "VibeTitle" },
  { title_art[2], "VibeTitle" },
  { title_art[3], "VibeTitle" },
  { title_art[4], "VibeTitle" },
  { title_art[5], "VibeTitle" },
  { title_art[6], "VibeTitle" },
  { title_art[7], "VibeTitle" },
  { "", nil },
  { "A focused terminal workspace for vibe coding", "VibeSubtitle" },
  { "", nil },
  { "", nil },
  { "", nil },
  { "OPEN & CONTEXT", "VibeSection" },
  { "Enter opens  ·  c a adds context  ·  c s stages it in Agent", "VibeInstruction" },
  { "", nil },
  { "EDIT", "VibeSection" },
  { "i insert  ·  Esc normal  ·  :w save  ·  :q close", "VibeInstruction" },
  { "", nil },
  { "REVIEW & TEST", "VibeSection" },
  { "Ctrl-a g reviews changes  ·  Ctrl-a t runs tests", "VibeInstruction" },
  { "", nil },
  { "SESSION", "VibeSection" },
  { "Ctrl-a e Directory  ·  Ctrl-a s Shell  ·  Ctrl-a d detach", "VibeInstruction" },
}

local compact_welcome_content = {
  { title_art[1], "VibeTitle" },
  { title_art[2], "VibeTitle" },
  { title_art[3], "VibeTitle" },
  { title_art[4], "VibeTitle" },
  { title_art[5], "VibeTitle" },
  { title_art[6], "VibeTitle" },
  { title_art[7], "VibeTitle" },
  { "", nil },
  { "A focused terminal workspace", "VibeSubtitle" },
  { "", nil },
  { "Enter open  ·  c a context  ·  c s Agent", "VibeInstruction" },
  { "i insert  ·  Esc normal  ·  :w save  ·  :q close", "VibeInstruction" },
  { "Ctrl-a g review  ·  Ctrl-a t test", "VibeInstruction" },
  { "Ctrl-a e Directory  ·  Ctrl-a s Shell", "VibeInstruction" },
  { "Ctrl-a d detach  ·  Ctrl-a Q quit", "VibeInstruction" },
}

local welcome_footer = {
  { value = "Bo Zhao  ·  UW Humanistic GIS Lab", highlight = "VibeMeta" },
  { value = "https://hgis.uw.edu", url = "https://hgis.uw.edu", highlight = "VibeLink" },
  { value = "v0.3.0", highlight = "VibeVersion" },
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
  local content = (width < 65 or height < 32) and compact_welcome_content or welcome_content
  local footer_gap = 2
  local bottom_margin = 1
  local content_height = math.max(1, height - #welcome_footer - footer_gap - bottom_margin)
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

  local footer_start = math.max(#lines + footer_gap, height - #welcome_footer - bottom_margin)
  while #lines < footer_start do
    table.insert(lines, "")
  end

  for _, item in ipairs(welcome_footer) do
    local padding = math.max(0, math.floor((width - vim.fn.strdisplaywidth(item.value)) / 2))
    table.insert(lines, string.rep(" ", padding) .. item.value)
  end

  vim.bo[buf].readonly = false
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, welcome_namespace, 0, -1)
  for index, item in ipairs(content) do
    if item[2] then
      vim.api.nvim_buf_add_highlight(buf, welcome_namespace, item[2], top + index - 1, 0, -1)
    end
  end
  for row_offset, title_line in ipairs(title_art) do
    local title_padding = math.max(0, math.floor((width - vim.fn.strdisplaywidth(title_line)) / 2))
    for index, span in ipairs(title_spans[row_offset]) do
      vim.api.nvim_buf_add_highlight(
        buf,
        welcome_namespace,
        "VibeTitle" .. index,
        top + row_offset - 1,
        title_padding + span[1],
        title_padding + span[2]
      )
    end
  end
  for index, item in ipairs(welcome_footer) do
    local row = footer_start + index - 1
    local value_start = math.max(0, math.floor((width - vim.fn.strdisplaywidth(item.value)) / 2))
    vim.api.nvim_buf_add_highlight(
      buf,
      welcome_namespace,
      item.highlight,
      row,
      value_start,
      value_start + #item.value
    )
    if item.url then
      local link_mark = {
        end_col = value_start + #item.value,
      }
      -- Hyperlink extmarks were added in Neovim 0.10. Keep the visual link
      -- styling on older supported versions without passing an unknown key.
      if vim.fn.has("nvim-0.10") == 1 then
        link_mark.url = item.url
      end
      vim.api.nvim_buf_set_extmark(buf, welcome_namespace, row, value_start, link_mark)
    end
  end
  vim.bo[buf].modified = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
end

local animation_colors = {
  palette.green,
  palette.cyan,
  palette.blue,
  palette.violet,
  palette.pink,
  palette.amber,
}
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

  -- Six transitions at 1.6 seconds each make a calm 9.6-second rainbow loop.
  local steps_per_color = 8
  animation_timer = vim.fn.timer_start(200, function()
    if not welcome_buf or vim.fn.bufwinid(welcome_buf) == -1 then
      return
    end

    local progress = (animation_step % steps_per_color) / steps_per_color
    local eased = (1 - math.cos(math.pi * progress)) / 2
    local segment = math.floor(animation_step / steps_per_color) % #animation_colors
    for index = 1, 4 do
      local color_index = (segment + index - 1) % #animation_colors + 1
      local next_color_index = color_index % #animation_colors + 1
      local color = interpolate_color(
        animation_colors[color_index],
        animation_colors[next_color_index],
        eased
      )
      vim.api.nvim_set_hl(0, "VibeTitle" .. index, {
        fg = color,
        bg = palette.background,
        bold = true,
      })
    end
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
    if vim.fn.has("nvim-0.10") == 1 then
      vim.api.nvim_echo(
        { { "No write since last change (add ! to override)", "ErrorMsg" } },
        true,
        {}
      )
    end
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

local function project_dir()
  return vim.env.VIBE_PROJECT_DIR or vim.fn.getcwd()
end

local function git_output(arguments)
  local command = { "git", "-c", "core.quotePath=false", "-C", project_dir() }
  vim.list_extend(command, arguments)
  local output = vim.fn.systemlist(command)
  return output, vim.v.shell_error
end


local function review_items()
  local lines, status = git_output({ "status", "--short", "--untracked-files=all" })
  if status ~= 0 then
    return nil, table.concat(lines, "\n")
  end

  local items = {}
  for _, line in ipairs(lines) do
    local state = line:sub(1, 2)
    local path = line:sub(4)
    local arrow = path:find(" -> ", 1, true)
    if arrow then
      path = path:sub(arrow + 4)
    end
    if path:sub(1, 1) == '"' and path:sub(-1) == '"' then
      path = path:sub(2, -2)
    end
    table.insert(items, {
      filename = project_dir() .. "/" .. path,
      lnum = 1,
      col = 1,
      text = state .. "  " .. path,
    })
  end
  return items, nil
end

local function selected_review_file()
  if vim.bo.buftype == "quickfix" then
    local list = vim.fn.getqflist({ idx = 0, items = 1 })
    local item = list.items[list.idx]
    if item and item.bufnr and item.bufnr > 0 then
      return vim.api.nvim_buf_get_name(item.bufnr)
    end
  end

  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" and vim.bo.buftype == "" then
    return name
  end
  return nil
end

local function show_review_diff()
  local path = selected_review_file()
  if not path then
    vim.notify("Choose a changed file first", vim.log.levels.WARN)
    return
  end

  local relative = vim.fn.fnamemodify(path, ":.")
  if path:sub(1, #project_dir() + 1) == project_dir() .. "/" then
    relative = path:sub(#project_dir() + 2)
  end
  local lines, status = git_output({ "diff", "--no-ext-diff", "HEAD", "--", relative })
  if status ~= 0 or #lines == 0 then
    lines = vim.fn.systemlist({ "git", "-c", "core.quotePath=false", "-C", project_dir(),
      "diff", "--no-index", "--", "/dev/null", path })
  end
  if #lines == 0 then
    lines = { "No diff for " .. relative }
  end

  vim.cmd("tabnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "diff"
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.keymap.set("n", "q", "<Cmd>tabclose<CR>", { buffer = buf, silent = true })
  set_pane_title("Review · " .. vim.fn.fnamemodify(relative, ":t"))
end

vim.api.nvim_create_user_command("VibeReviewDiff", show_review_diff, { force = true })

vim.api.nvim_create_user_command("VibeReview", function()
  local items, err = review_items()
  if not items then
    vim.notify(err ~= "" and err or "Not a Git repository", vim.log.levels.ERROR)
    return
  end
  if #items == 0 then
    vim.notify("Working tree is clean", vim.log.levels.INFO)
    return
  end

  vim.fn.setqflist({}, " ", { title = "Vibe Review", items = items })
  vim.cmd("botright copen")
  local buf = vim.api.nvim_get_current_buf()
  vim.keymap.set("n", "d", "<Cmd>VibeReviewDiff<CR>", { buffer = buf, silent = true })
  vim.keymap.set("n", "r", "<Cmd>VibeReview<CR>", { buffer = buf, silent = true })
  set_pane_title("Review · " .. #items .. " changed")
end, { force = true })

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
