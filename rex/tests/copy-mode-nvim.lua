-- Run with: nvim --headless -u NONE -i NONE -l rex/tests/copy-mode-nvim.lua
local root = assert(debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*[/\\])"))
local temporary = vim.fn.tempname()
vim.fn.mkdir(temporary .. "/nvim", "p", 448)
vim.fn.writefile(
	{ "assert(vim.g.forwarded_argument == [[spaces and 'quotes']])", "vim.g.user_config_loaded = true" },
	temporary .. "/nvim/init.lua"
)
local check = [[
vim.schedule(function()
  local ok, err = pcall(function()
    assert(vim.g.user_config_loaded, 'The user config must load despite upstream -u NONE')
    assert(vim.o.shadafile == 'NONE', 'Keep the upstream history setting')
    assert(vim.o.updatecount == 0, 'Keep the upstream swap setting')
    for _, mode in ipairs({ 'n', 'x', 't' }) do
      local mapping = vim.fn.maparg('q', mode, false, true)
      assert(mapping.buffer ~= 0 and mapping.rhs == '<Cmd>qa!<CR>')
      assert(vim.fn.maparg('<Esc>', mode, false, true).rhs ~= '<Cmd>qa!<CR>')
    end
  end)
  if ok then vim.cmd('qa!') else io.stderr:write(tostring(err)); vim.cmd('cquit') end
end)
]]
local result = vim.system({
	root .. "../copy-mode-nvim",
	"--headless",
	"-u",
	"NONE",
	"-i",
	"NONE",
	"-n",
	"--cmd",
	"lua vim.g.forwarded_argument = [[spaces and 'quotes']]",
	"-c",
	"lua " .. check,
}, { env = { XDG_CONFIG_HOME = temporary, NVIM_APPNAME = "nvim" }, text = true, timeout = 10000 }):wait()
vim.fn.delete(temporary, "rf")
assert(result.code == 0, (result.stderr or "") .. (result.stdout or ""))
print(
	"PASS: wrapper loads user config, preserves argument boundaries and history settings, and installs viewer-local quit keys"
)
