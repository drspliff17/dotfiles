-- Write current general.config.layout value to state file
function Save_Layout_State()
	local path = os.getenv("HOME") .. "/.config/hypr/layout_saved_state"
	local layout = hl.get_config("general.layout")
	local f = io.open(path, "w")

	if f and type(layout) == "string" then
		f:write(layout, "\n")
		f:close()
	end
end

-- Load previous general.config.layout value from state file
function Load_Layout_State()
	local function validLayout(layout)
		return type(layout) == "string" and layout:match("^[%w_-]+$") ~= nil
	end

	local home = os.getenv("HOME")
	if not home then
		return
	end

	local path = home .. "/.config/hypr/layout_saved_state"

	local f = io.open(path, "r")
	if not f then
		return
	end

	local layout = f:read("*l")
	f:close()

	if validLayout(layout) then
		hl.config({ general = { layout = layout } })
	end
end

-- Calls hl.dispatch(dsp.submap) on the respective L_(general.config.layout) value
function Set_Layout_Submap()
	local l = hl.get_config("general.layout")
	if l == "dwindle" then
		hl.dispatch(hl.dsp.submap("L_Dwindle"))
	elseif l == "scrolling" then
		hl.dispatch(hl.dsp.submap("L_Scrolling"))
	elseif l == "monocle" then
		hl.dispatch(hl.dsp.submap("L_Monocle"))
	else
		hl.dispatch(hl.dsp.submap("reset"))
	end
end
