local config_dir = os.getenv("HOME") .. "/dev/dotfiles/rex/"

dofile(config_dir .. "actions.lua")
local plugins = dofile(config_dir .. "plugins.lua")
dofile(config_dir .. "keybindings.lua")(plugins)
