local CssParser = {}

local function trim(s)
	return (s and s:match("^%s*(.-)%s*$")) or ""
end

local function stripComments(text)
	return text:gsub("/%%*.-%%*/", "")
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
		-- Normalize property keys by removing hyphens/underscores so that
		-- "background-color" -> "backgroundcolor" to match inline-style handling
		local key = prop:lower():gsub("[-_]", "")
		if key == "transition" then
			styles[key] = parseTransitionValue(val)
		else
			styles[key] = trim(val)
		end
	end
	return styles
end

function CssParser.parse(cssText)
	cssText = stripComments(cssText or "")
	local stylesBySelector = {}

	for selectorGroup, declarations in cssText:gmatch("([^{}]+)%s*{([^}]*)}") do
		local styles = parseDeclarations(declarations)

		for selector in selectorGroup:gmatch("[^,]+") do
			selector = trim(selector)
			if selector ~= "" then
				stylesBySelector[selector] = styles
			end
		end
	end

	return stylesBySelector
end

return CssParser
