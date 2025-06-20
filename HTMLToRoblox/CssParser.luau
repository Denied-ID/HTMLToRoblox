-- CssParser.lua
local CssParser = {}

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function parseTransitionValue(value)
	local parts = {}
	for part in value:gmatch("[^,]+") do
		local prop, duration, easing, delay = part:match("(%S+)%s+(%d+%.?%d*)s%s*(%S*)%s*(%d*%.?%d*)s*")
		if prop and duration then
			table.insert(parts, {
				property = prop,
				duration = tonumber(duration),
				easing = easing ~= "" and easing or "ease",
				delay = tonumber(delay) or 0
			})
		end
	end
	return parts
end

local function parseDeclarations(declarations)
	local styles = {}
	for prop, val in declarations:gmatch("([%w%-]+)%s*:%s*([^;]+);?") do
		local key = prop:lower()
		if key == "transition" then
			styles[key] = parseTransitionValue(val)
		else
			styles[key] = trim(val)
		end
	end
	return styles
end

function CssParser.parse(cssText)
	local stylesBySelector = {}

	for selector, declarations in cssText:gmatch("([^{}]+){([^}]+)}") do
		selector = trim(selector)
		local styles = parseDeclarations(declarations)
		stylesBySelector[selector] = styles
	end

	return stylesBySelector
end

return CssParser
