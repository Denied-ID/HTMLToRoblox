local JSTranspiler = require(script.JSTranspiler)
local StdLib = require(script:WaitForChild("StdLib"))
local JSEngine = {}

JSEngine.StdLib = StdLib
JSEngine.GuiRegistry = {}
JSEngine.variables = {}
JSEngine.forms = {}
JSEngine.timeouts = {}
JSEngine.intervals = {}
JSEngine.eventListeners = {}
JSEngine.elements = {}

-- Configuration for timeout protection
JSEngine.Config = {
	MaxExecutionTime = 0.5, -- Maximum execution time in seconds
	YieldInterval = 100,    -- Yield after processing this many operations
	DebugMode = false       -- Enable debug logging
}

-- Execution state tracking
local operationCount = 0
local lastYieldTime = os.clock()

-- Function to yield if needed to prevent timeouts
local function yieldIfNeeded()
	operationCount = operationCount + 1
	
	if operationCount >= JSEngine.Config.YieldInterval then
		operationCount = 0
		
		local currentTime = os.clock()
		local elapsed = currentTime - lastYieldTime
		
		if elapsed > JSEngine.Config.MaxExecutionTime then
			if JSEngine.Config.DebugMode then
				print("JS Engine yielding after " .. elapsed .. " seconds")
			end
			task.wait()
			lastYieldTime = os.clock()
		end
	end
end

-- Expose the yieldIfNeeded function to be used by JSTranspiler
JSEngine.yieldIfNeeded = yieldIfNeeded

-- Store a reference to the current document (main GUI container)
local currentDocument = nil

-- Create a document object for DOM operations
JSEngine.document = {}

function JSEngine.document.getElementById(id)
	return JSEngine.getGui(id)
end

function JSEngine.document.querySelector(selector)
	return JSEngine.querySelector(selector)
end

function JSEngine.document.querySelectorAll(selector)
	return JSEngine.querySelectorAll(selector)
end

function JSEngine.document.createElement(tagName)
	return StdLib.DOM.createElement(tagName)
end

JSEngine.document.body = {
	appendChild = function(element)
		-- This is just a stub since we can't actually append to the body in Roblox
		print("Attempted to append to document.body:", element)
	end
}

function JSEngine.setDocument(document)
	currentDocument = document
	
	-- Set up document.body reference
	if currentDocument then
		JSEngine.document.body = currentDocument
	end
end

function JSEngine.register(id, gui)
	if id then
		JSEngine.GuiRegistry[id] = gui
		
		-- If this is a form element, register it with the form system
		if gui:GetAttribute("HtmlTag") == "form" then
			JSEngine.forms[id] = {
				elements = {},
				validated = false
			}
		elseif gui:IsA("TextBox") and gui:GetAttribute("FormId") then
			local formId = gui:GetAttribute("FormId")
			if not JSEngine.forms[formId] then
				JSEngine.forms[formId] = {
					elements = {},
					validated = false
				}
			end
			JSEngine.forms[formId].elements[id] = gui
		end
	end
end

function JSEngine.getGui(id)
	if not currentDocument then
		warn("No document set for JSEngine")
		return nil
	end
	
	-- First look for elements with ID attribute
	local elements = currentDocument:GetDescendants()
	for _, element in ipairs(elements) do
		yieldIfNeeded() -- Prevent timeout during long searches
		if element:GetAttribute("ID") == id then
			return element
		end
	end
	
	-- Then look for elements with Name matching the ID
	return currentDocument:FindFirstChild(id, true)
end

function JSEngine.execute(jsCode)
	-- Reset operation counters before execution
	operationCount = 0
	lastYieldTime = os.clock()
	
	if JSEngine.Config.DebugMode then
		print("Executing JavaScript: " .. string.sub(jsCode, 1, 50) .. (string.len(jsCode) > 50 and "..." or ""))
	end
	
	return JSTranspiler.executeDirectly(jsCode, JSEngine)
end

function JSEngine.evaluateExpression(expr)
	yieldIfNeeded() -- Prevent timeout during complex expressions
	
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
	warn("[JS] history.back()  closing GUI")
	local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		local htmlGui = playerGui:FindFirstChild("HTMLRender")
		if htmlGui then htmlGui:Destroy() end
	end
end

-- Form validation functions
function JSEngine.validateForm()
	-- Basic form validation
	local isValid = true
	
	if currentDocument then
		local formElements = currentDocument:GetDescendants()
		for _, element in ipairs(formElements) do
			if element:GetAttribute("required") and element:IsA("TextBox") and element.Text == "" then
				isValid = false
				
				-- Highlight the invalid field
				local originalColor = element.BackgroundColor3
				element.BackgroundColor3 = Color3.fromRGB(255, 200, 200)
				
				task.delay(1, function()
					element.BackgroundColor3 = originalColor
				end)
			end
		end
	end
	
	return isValid
end

-- DOM API functions
local selectorCache = {}

function JSEngine.querySelector(selector)
	if not currentDocument then
		warn("No document set for JSEngine")
		return nil
	end
	
	-- Check cache first
	local cacheKey = "qs_" .. selector
	if selectorCache[cacheKey] then
		-- Verify the element still exists in the document
		local cached = selectorCache[cacheKey]
		if cached and cached:IsDescendantOf(currentDocument) then
			return cached
		else
			-- Remove invalid cache entry
			selectorCache[cacheKey] = nil
		end
	end
	
	-- Handle ID selectors (#id)
	if selector:sub(1, 1) == "#" then
		local id = selector:sub(2)
		local result = JSEngine.getGui(id)
		if result then
			selectorCache[cacheKey] = result
		end
		return result
	end
	
	-- Handle class selectors (.class)
	if selector:sub(1, 1) == "." then
		local className = selector:sub(2)
		local elements = currentDocument:GetDescendants()
		for _, element in ipairs(elements) do
			yieldIfNeeded() -- Prevent timeout during long searches
			local elementClass = element:GetAttribute("Class")
			if elementClass and string.find(elementClass, className) then
				selectorCache[cacheKey] = element
				return element
			end
		end
	end
	
	-- Handle tag selectors (e.g., "div")
	local elements = currentDocument:GetDescendants()
	for _, element in ipairs(elements) do
		yieldIfNeeded() -- Prevent timeout during long searches
		local tag = element:GetAttribute("HtmlTag")
		if tag and tag:lower() == selector:lower() then
			selectorCache[cacheKey] = element
			return element
		end
	end
	
	return nil
end

function JSEngine.querySelectorAll(selector)
	if not currentDocument then
		warn("No document set for JSEngine")
		return {}
	end
	
	-- Check cache first
	local cacheKey = "qsa_" .. selector
	if selectorCache[cacheKey] then
		-- Verify the elements still exist in the document
		local cached = selectorCache[cacheKey]
		local allValid = true
		
		for i, element in ipairs(cached) do
			if not element:IsDescendantOf(currentDocument) then
				allValid = false
				break
			end
		end
		
		if allValid then
			return cached
		else
			-- Remove invalid cache entry
			selectorCache[cacheKey] = nil
		end
	end
	
	local results = {}
	
	-- Handle ID selectors (#id)
	if selector:sub(1, 1) == "#" then
		local id = selector:sub(2)
		local element = JSEngine.getGui(id)
		if element then
			table.insert(results, element)
		end
		selectorCache[cacheKey] = results
		return results
	end
	
	-- Handle class selectors (.class)
	if selector:sub(1, 1) == "." then
		local className = selector:sub(2)
		local elements = currentDocument:GetDescendants()
		for _, element in ipairs(elements) do
			yieldIfNeeded() -- Prevent timeout during long searches
			local elementClass = element:GetAttribute("Class")
			if elementClass and string.find(elementClass, className) then
				table.insert(results, element)
			end
		end
		selectorCache[cacheKey] = results
		return results
	end
	
	-- Handle tag selectors (e.g., "div")
	local elements = currentDocument:GetDescendants()
	for _, element in ipairs(elements) do
		yieldIfNeeded() -- Prevent timeout during long searches
		local tag = element:GetAttribute("HtmlTag")
		if tag and tag:lower() == selector:lower() then
			table.insert(results, element)
		end
	end
	
	selectorCache[cacheKey] = results
	return results
end

-- Add a function to clear the selector cache when needed
function JSEngine.clearSelectorCache()
	selectorCache = {}
end

-- Define the cleanup function
function JSEngine.cleanup()
	-- Clean up all event listeners
	for element, events in pairs(JSEngine.eventListeners) do
		for eventType, connections in pairs(events) do
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
		end
	end
	
	-- Clean up all timeouts and intervals
	for _, timeout in pairs(JSEngine.timeouts) do
		if timeout.connection then
			timeout.connection:Disconnect()
		end
	end
	
	for _, interval in pairs(JSEngine.intervals) do
		if interval.connection then
			interval.connection:Disconnect()
		end
	end
	
	-- Reset all variables
	JSEngine.variables = {}
	JSEngine.timeouts = {}
	JSEngine.intervals = {}
	JSEngine.eventListeners = {}
	JSEngine.elements = {}
	currentDocument = nil
	
	-- Clear the selector cache
	JSEngine.clearSelectorCache()
end

-- Add event listener support
function JSEngine.addEventListener(element, eventType, handler)
	if not element then
		warn("Cannot add event listener to nil element")
		return
	end
	
	local connection = nil
	
	if eventType == "click" then
		-- Find the clickable part of the element
		local button = nil
		if element:IsA("TextButton") or element:IsA("ImageButton") then
			button = element
		else
			button = element:FindFirstChildWhichIsA("TextButton") or element:FindFirstChildWhichIsA("ImageButton")
		end
		
		if button then
			connection = button.MouseButton1Click:Connect(function()
				pcall(handler, {target = element})
			end)
		end
	elseif eventType == "change" then
		-- For input elements
		if element:GetAttribute("Type") == "checkbox" or element:GetAttribute("Type") == "radio" then
			local button = element:FindFirstChildWhichIsA("TextButton")
			if button then
				connection = button.MouseButton1Click:Connect(function()
					pcall(handler, {target = element})
				end)
			end
		elseif element:IsA("TextBox") then
			connection = element.FocusLost:Connect(function()
				pcall(handler, {target = element})
			end)
		end
	end
	
	if connection then
		if not JSEngine.eventListeners[element] then
			JSEngine.eventListeners[element] = {}
		end
		
		if not JSEngine.eventListeners[element][eventType] then
			JSEngine.eventListeners[element][eventType] = {}
		end
		
		table.insert(JSEngine.eventListeners[element][eventType], connection)
	end
end

return JSEngine

