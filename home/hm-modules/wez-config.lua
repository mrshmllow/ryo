local wezterm = require("wezterm")

local function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Catppuccin Mocha"
	else
		return "Catppuccin Latte"
	end
end

return {
	font = wezterm.font("JetBrainsMono Nerd Font Mono"),
	hide_tab_bar_if_only_one_tab = true,
	color_scheme = scheme_for_appearance(wezterm.gui.get_appearance()),
	window_background_opacity = 0.9,
	automatically_reload_config = true,
	-- https://github.com/wezterm/wezterm/issues/6731
	warn_about_missing_glyphs = false,
}
