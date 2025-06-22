local JSTranspiler = {}
function JSTranspiler.transpile(js)
	js = js:gsub("console%.log", "print")
		:gsub("console%.warn", "warn")
		:gsub("console%.error", "error")
		:gsub("alert%s*%(", "print(")
		:gsub("window%.alert%s*%(", "print(")
	js = js:gsub("let%s+", "local ")
		:gsub("const%s+", "local ")
		:gsub("var%s+", "local ")
		:gsub("history%.back%(%s*%)", "JSEngine.historyBack()")
	js = js:gsub("%(([^)]-)%)%s*=>%s*{", "function(%1)")
		:gsub("};", "end")
		:gsub("}", "end")
		:gsub("function%s+([%w_]+)%s*%(([^)]-)%)", "function %1(%2)")
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
	js = js:gsub(";", "")
	js = js:gsub("setTimeout%(", "JSEngine.StdLib.setTimeout(")
		:gsub("clearTimeout%(", "JSEngine.StdLib.clearTimeout(")
		:gsub("setInterval%(", "JSEngine.StdLib.setInterval(")
		:gsub("clearInterval%(", "JSEngine.StdLib.clearInterval(")
		:gsub("parseInt%(", "JSEngine.StdLib.parseInt(")
		:gsub("parseFloat%(", "JSEngine.StdLib.parseFloat(")
		:gsub("JSON%.stringify%(", "JSEngine.StdLib.JSON.stringify(")
		:gsub("JSON%.parse%(", "JSEngine.StdLib.JSON.parse(")
	return js
end
function JSTranspiler.executeDirectly(jsCode, JSEngine)
	local luaCode = JSTranspiler.transpile(jsCode)
	local result = nil
	for statement in luaCode:gmatch("print%s*%(([^)]+)%)") do
		local content = statement:gsub("[\"']", "")
		print(content)
	end
	for statement in luaCode:gmatch("warn%s*%(([^)]+)%)") do
		local content = statement:gsub("[\"']", "")
		warn(content)
	end
	for statement in luaCode:gmatch("error%s*%(([^)]+)%)") do
		local content = statement:gsub("[\"']", "")
		error(content)
	end
	for varName, value in luaCode:gmatch("local%s+([%w_]+)%s*=%s*([^%s]+)") do
		JSEngine.variables[varName] = tonumber(value) or value:gsub("[\"']", "")
	end
	if luaCode:match("return%s+false") then
		result = false
	end
	return result
end
return JSTranspiler
