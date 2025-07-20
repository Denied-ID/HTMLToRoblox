local JSTranspiler = {}

-- Helper function to yield during long operations
local function yieldIfNeeded(JSEngine)
	if JSEngine and JSEngine.yieldIfNeeded then
		JSEngine.yieldIfNeeded()
	end
end

function JSTranspiler.transpile(js, JSEngine)
	-- Handle comments
	js = js:gsub("//[^\n]*", "") -- Remove single line comments
	
	if JSEngine then yieldIfNeeded(JSEngine) end
	
	-- Replace common JS functions with their Lua equivalents
	js = js:gsub("console%.log", "print")
		:gsub("console%.warn", "warn")
		:gsub("console%.error", "error")
		:gsub("alert%s*%(", "print(")
		:gsub("window%.alert%s*%(", "print(")
	
	if JSEngine then yieldIfNeeded(JSEngine) end
	
	-- Variable declarations
	js = js:gsub("let%s+", "local ")
		:gsub("const%s+", "local ")
		:gsub("var%s+", "local ")
	
	if JSEngine then yieldIfNeeded(JSEngine) end
	
	-- Browser navigation
	js = js:gsub("history%.back%(%s*%)", "JSEngine.historyBack()")
	js = js:gsub("window%.location%.href%s*=%s*([^;]+)", "JSEngine.navigateTo(%1)")
	js = js:gsub("location%.href%s*=%s*([^;]+)", "JSEngine.navigateTo(%1)")
	
	if JSEngine then yieldIfNeeded(JSEngine) end
	
	-- Arrow functions and regular functions
	js = js:gsub("%(([^)]-)%)%s*=>%s*{", "function(%1)")
		:gsub("};", "end")
		:gsub("}", "end")
		:gsub("function%s+([%w_]+)%s*%(([^)]-)%)", "function %1(%2)")
	
	if JSEngine then yieldIfNeeded(JSEngine) end
	
	-- Common DOM manipulations
	js = js:gsub(
		"document%.getElementById%(%s*[\"'](.-)[\"']%s*%)%.onclick%s*=%s*function%(",
		"JSEngine.getGui('%1').MouseButton1Click:Connect(function("
	)
	js = js:gsub(
		"document%.getElementById%(%s*[\"'](.-)[\"']%)%.innerText%s*=%s*([^;]+)",
		"JSEngine.setInnerText('%1', %2)"
	)
	js = js:gsub(
		"document%.getElementById%(%s*[\"'](.-)[\"']%)%.innerHTML%s*=%s*([^;]+)",
		"JSEngine.setInnerHTML('%1', %2)"
	)
	js = js:gsub(
		"document%.getElementById%(%s*[\"'](.-)[\"']%)%.value%s*=%s*([^;]+)",
		"JSEngine.setValue('%1', %2)"
	)
	js = js:gsub(
		"document%.getElementById%(%s*[\"'](.-)[\"']%s*%)",
		"JSEngine.getGui('%1')"
	)
	
	if JSEngine then yieldIfNeeded(JSEngine) end
	
	-- querySelector and querySelectorAll
	js = js:gsub(
		"document%.querySelector%(%s*[\"'](.-)[\"']%s*%)",
		"JSEngine.querySelector('%1')"
	)
	js = js:gsub(
		"document%.querySelectorAll%(%s*[\"'](.-)[\"']%s*%)",
		"JSEngine.querySelectorAll('%1')"
	)
	
	if JSEngine then yieldIfNeeded(JSEngine) end
	
	-- addEventListener
	js = js:gsub(
		"([%w%._]+)%.addEventListener%(%s*[\"'](.-)[\"']%s*,%s*function%s*%(([^)]*)%)",
		"JSEngine.addEventListener(%1, '%2', function(%3)"
	)
	
	if JSEngine then yieldIfNeeded(JSEngine) end
	
	-- Form validation functions
	js = js:gsub(
		"Roblox%.AnimatedSignupFormValidator%.validateForm%(%s*%)",
		"JSEngine.validateForm()"
	)
	js = js:gsub(
		"validateForm%(%s*%)",
		"JSEngine.validateForm()"
	)
	
	if JSEngine then yieldIfNeeded(JSEngine) end
	
	-- Handle common control structures
	js = js:gsub("if%s*%((.-)%)", "if %1 then")
		:gsub("else%s*{", "else")
		:gsub("else%s+if", "elseif")
	
	if JSEngine then yieldIfNeeded(JSEngine) end
	
	-- Loops
	js = js:gsub("for%s*%((.-)%s*;%s*(.-)%s*;%s*(.-)%)", 
		function(init, cond, incr)
			-- Convert for loop to Lua style
			local luaInit = init:gsub("var%s+", "local "):gsub("let%s+", "local ")
			return luaInit .. " while " .. cond .. " do task.spawn(function() " .. incr
		end
	)
	
	if JSEngine then yieldIfNeeded(JSEngine) end
	
	-- Clean up semicolons
	js = js:gsub(";", "")
	
	if JSEngine then yieldIfNeeded(JSEngine) end
	
	-- Standard library functions
	js = js:gsub("setTimeout%(", "JSEngine.StdLib.setTimeout(")
		:gsub("clearTimeout%(", "JSEngine.StdLib.clearTimeout(")
		:gsub("setInterval%(", "JSEngine.StdLib.setInterval(")
		:gsub("clearInterval%(", "JSEngine.StdLib.clearInterval(")
		:gsub("parseInt%(", "JSEngine.StdLib.parseInt(")
		:gsub("parseFloat%(", "JSEngine.StdLib.parseFloat(")
		:gsub("JSON%.stringify%(", "JSEngine.StdLib.JSON.stringify(")
		:gsub("JSON%.parse%(", "JSEngine.StdLib.JSON.parse(")
	
	if JSEngine then yieldIfNeeded(JSEngine) end
	
	-- jQuery-like functions
	js = js:gsub("%$%(%s*[\"'](.-)[\"']%s*%)", "JSEngine.querySelector('%1')")
	js = js:gsub("%$%(%s*[\"'](.-)[\"']%s*%)%.click%(%s*function%s*%(([^)]*)%)", 
		"JSEngine.addEventListener(JSEngine.querySelector('%1'), 'click', function(%2)")
	js = js:gsub("%$%(%s*[\"'](.-)[\"']%s*%)%.on%(%s*[\"'](.-)[\"']%s*,%s*function%s*%(([^)]*)%)",
		"JSEngine.addEventListener(JSEngine.querySelector('%1'), '%2', function(%3)")
	js = js:gsub("%$%(%s*[\"'](.-)[\"']%s*%)%.tipsy%(%s*{%s*gravity:%s*[\"'](.-)[\"']%s*}%s*%)",
		"-- Tooltip functionality not implemented: $('%1').tipsy({gravity: '%2'})")
	js = js:gsub("%$%(%s*[\"'](.-)[\"']%s*%)%.each%(%s*function%s*%(([^)]*)%)",
		"for _, element in ipairs(JSEngine.querySelectorAll('%1')) do function(%2)")
	js = js:gsub("%$%.ajax%(%s*{", "-- AJAX not implemented: $.ajax({")
	js = js:gsub("%$%.post%(%s*[\"'](.-)[\"']", "-- AJAX POST not implemented: $.post('%1'")
	js = js:gsub("%$%.get%(%s*[\"'](.-)[\"']", "-- AJAX GET not implemented: $.get('%1'")
	
	return js
end

function JSTranspiler.executeDirectly(jsCode, JSEngine)
	local luaCode = JSTranspiler.transpile(jsCode, JSEngine)
	local result = nil
	
	-- Extract and execute print statements
	for statement in luaCode:gmatch("print%s*%(([^)]+)%)") do
		if JSEngine then yieldIfNeeded(JSEngine) end
		local content = statement:gsub("[\"']", "")
		print(content)
	end
	
	-- Extract and execute warn statements
	for statement in luaCode:gmatch("warn%s*%(([^)]+)%)") do
		if JSEngine then yieldIfNeeded(JSEngine) end
		local content = statement:gsub("[\"']", "")
		warn(content)
	end
	
	-- Extract and execute error statements
	for statement in luaCode:gmatch("error%s*%(([^)]+)%)") do
		if JSEngine then yieldIfNeeded(JSEngine) end
		local content = statement:gsub("[\"']", "")
		error(content)
	end
	
	-- Extract variable assignments
	for varName, value in luaCode:gmatch("local%s+([%w_]+)%s*=%s*([^%s]+)") do
		if JSEngine then yieldIfNeeded(JSEngine) end
		JSEngine.variables[varName] = tonumber(value) or value:gsub("[\"']", "")
	end
	
	-- Try to execute the full code if it's simple enough
	pcall(function()
		local fn, err = loadstring(luaCode)
		if fn then
			result = fn()
		end
	end)
	
	-- Check for return false pattern
	if luaCode:match("return%s+false") then
		result = false
	end
	
	return result
end

return JSTranspiler
