-- Initialize CssParser module
local CssParser = {}

-- Function to check if a selector matches a GUI element
function CssParser.selectorMatches(selector, gui)
	if not selector or not gui then return false end
	
	-- Simple selector cases
	if selector == "*" then
		return true -- Universal selector matches everything
	end
	
	-- Get element attributes
	local tag = gui:GetAttribute("HtmlTag")
	local id = gui:GetAttribute("ID")
	local classAttr = gui:GetAttribute("Class")
	local parentId = gui:GetAttribute("ParentID")
	local parentClass = gui:GetAttribute("ParentClass")
	
	-- Debug selector matching
	local isServer = game:GetService("RunService"):IsServer()
	local debug = false
	
	if debug and isServer then
		print("Matching selector:", selector)
		print("  - Tag:", tag)
		print("  - ID:", id)
		print("  - Class:", classAttr)
		print("  - ParentID:", parentId)
		print("  - ParentClass:", parentClass)
	end
	
	-- For text nodes, also check parent attributes
	if tag == "text" then
		if parentId and selector:match("#" .. parentId) then
			if debug and isServer then print("  - Matched by ParentID") end
			return true
		end
		if parentClass then
			for className in parentClass:gmatch("%S+") do
				if selector:match("%." .. className) then
					if debug and isServer then print("  - Matched by ParentClass") end
					return true
				end
			end
		end
	end
	
	-- Handle tag selectors (e.g., "div")
	if tag and selector:lower() == tag:lower() then
		if debug and isServer then print("  - Matched by tag name") end
		return true
	end
	
	-- Handle ID selectors (e.g., "#myId")
	if id and selector:match("^#" .. id .. "$") then
		if debug and isServer then print("  - Matched by ID exact") end
		return true
	end
	
	-- Handle class selectors (e.g., ".myClass")
	if classAttr then
		for className in classAttr:gmatch("%S+") do
			if selector:match("^%." .. className .. "$") then
				if debug and isServer then print("  - Matched by class exact") end
				return true
			end
		end
	end
	
	-- Handle tag with ID (e.g., "div#myId")
	if tag and id and selector:match("^" .. tag:lower() .. "#" .. id .. "$") then
		if debug and isServer then print("  - Matched by tag+ID") end
		return true
	end
	
	-- Handle tag with class (e.g., "div.myClass")
	if tag and classAttr then
		for className in classAttr:gmatch("%S+") do
			if selector:match("^" .. tag:lower() .. "%." .. className .. "$") then
				if debug and isServer then print("  - Matched by tag+class") end
				return true
			end
		end
	end
	
	-- Handle more complex selectors
	
	-- ID selector within a more complex selector (e.g., "div #myId")
	if id and selector:match("#" .. id) then
		if debug and isServer then print("  - Matched by ID within complex selector") end
		return true
	end
	
	-- Class selector within a more complex selector (e.g., "div .myClass")
	if classAttr then
		for className in classAttr:gmatch("%S+") do
			if selector:match("%." .. className) then
				if debug and isServer then print("  - Matched by class within complex selector") end
				return true
			end
		end
	end
	
	-- Body tag special case - match both "body" and "html body"
	if tag == "body" and (selector:lower() == "body" or selector:lower() == "html body") then
		if debug and isServer then print("  - Matched body tag special case") end
		return true
	end
	
	-- Handle attribute selectors (e.g., "[type=checkbox]")
	local attrPattern = "%[([^%]=]+)=?['\"]?([^%]'\"]*)['\"]?%]"
	for attrName, attrValue in selector:gmatch(attrPattern) do
		local guiAttrValue = gui:GetAttribute(attrName)
		if guiAttrValue and (attrValue == "" or tostring(guiAttrValue) == attrValue) then
			if debug and isServer then print("  - Matched by attribute", attrName, "=", attrValue) end
			return true
		end
	end
	
	-- Not matched
	return false
end

-- Function to parse CSS text into a structured format
function CssParser.parse(cssText)
	if not cssText or cssText == "" then
		return { rules = {}, hoverRules = {}, activeRules = {}, imports = {} }
	end
	
	local result = {
		rules = {},
		hoverRules = {},
		activeRules = {},
		imports = {}
	}
	
	-- Remove comments
	cssText = cssText:gsub("/%*.-%*/", "")
	
	-- Extract @import rules
	for importRule in cssText:gmatch("@import%s+url%(([^%)]+)%)[^;]*;") do
		-- Clean up the URL
		local url = importRule:gsub("^['\"]", ""):gsub("['\"]$", "")
		table.insert(result.imports, url)
	end
	
	-- Also match @import with quotes
	for importRule in cssText:gmatch("@import%s+['\"]([^'\"]+)['\"][^;]*;") do
		table.insert(result.imports, importRule)
	end
	
	-- Extract CSS rules
	for selectorText, declarationText in cssText:gmatch("([^{]-)%s*{%s*([^}]-)%s*}") do
		-- Skip @media and other at-rules
		if not selectorText:match("^%s*@") then
			-- Handle multiple selectors (comma-separated)
			for selector in selectorText:gmatch("([^,]+)") do
				selector = selector:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
				
				-- Skip empty selectors
				if selector ~= "" then
					local properties = {}
					
					-- Extract property-value pairs
					for property, value in declarationText:gmatch("([^:;]+)%s*:%s*([^;]+)") do
						property = property:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
						value = value:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
						
						if property ~= "" and value ~= "" then
							properties[property:lower()] = value
						end
					end
					
					-- Store the rule
					if next(properties) ~= nil then
						if selector:match(":hover$") then
							local baseSelector = selector:gsub(":hover$", "")
							table.insert(result.hoverRules, {
								selector = baseSelector,
								properties = properties
							})
						elseif selector:match(":active$") then
							local baseSelector = selector:gsub(":active$", "")
							table.insert(result.activeRules, {
								selector = baseSelector,
								properties = properties
							})
						else
							table.insert(result.rules, {
								selector = selector,
								properties = properties
							})
						end
					end
				end
			end
		end
	end
	
	return result
end

-- Return the module
return CssParser 