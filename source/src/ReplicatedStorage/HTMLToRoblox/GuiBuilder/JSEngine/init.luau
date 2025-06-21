local JSTranspiler = require(script.JSTranspiler)
local JSEngine = {}
JSEngine.GuiRegistry = {}
JSEngine.variables = {}
function JSEngine.register(id, gui)
	if id then
		JSEngine.GuiRegistry[id] = gui
	end
end
function JSEngine.getGui(id)
	return JSEngine.GuiRegistry[id]
end
function JSEngine.execute(jsCode)
	return JSTranspiler.executeDirectly(jsCode, JSEngine)
end
function JSEngine.evaluateExpression(expr)
	if expr:match('^[\"].*\"$') or expr:match("^'.*'$") then
		return expr:gsub("[\"']", "")
	end
	local n = tonumber(expr)
	if n then return n end
	if JSEngine.variables[expr] then return JSEngine.variables[expr] end
	return expr
end
function JSEngine.setInnerText(id, content)
	local gui = JSEngine.getGui(id)
	if gui and (gui:IsA("TextLabel") or gui:IsA("TextButton")) then
		gui.Text = JSEngine.evaluateExpression(content)
	end
end
function JSEngine.setInnerHTML(id, content)
	return JSEngine.setInnerText(id, content)
end
function JSEngine.setValue(id, content)
	local gui = JSEngine.getGui(id)
	if gui and gui:IsA("TextBox") then
		gui.Text = JSEngine.evaluateExpression(content)
	end
end
function JSEngine.navigateTo(href)
	warn("[JS] *navigating* to: " .. tostring(href))
end
function JSEngine.historyBack()
	warn("[JS] history.back()  closing GUI")
	local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		local htmlGui = playerGui:FindFirstChild("HTMLRender")
		if htmlGui then htmlGui:Destroy() end
	end
end
return JSEngine
