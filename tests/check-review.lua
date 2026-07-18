vim.cmd("VibeReview")

local review = vim.fn.getqflist({ title = 1, items = 1 })
assert(review.title == "Vibe Review", "review quickfix title is missing")
assert(#review.items == 2, "review did not list modified and untracked files")

local names = {}
for _, item in ipairs(review.items) do
	names[vim.fn.fnamemodify(vim.api.nvim_buf_get_name(item.bufnr), ":t")] = true
end
assert(names["tracked.txt"], "modified file is missing from review")
assert(names["untracked.txt"], "untracked file is missing from review")

vim.cmd("VibeReviewDiff")
assert(vim.bo.filetype == "diff", "review diff did not open a diff buffer")
local diff = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
assert(diff:find("changed", 1, true), "review diff does not contain the tracked change")

vim.cmd("qa!")
