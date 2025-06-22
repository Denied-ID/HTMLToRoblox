local ComponentRegistry = require(script:WaitForChild("ComponentRegistry"))
local CssParser = require(script.Parent:WaitForChild("CssParser"))
local TweenService = game:GetService("TweenService")

local GuiBuilder = {}

-- forward declaration
local collectCssTables

local string_format = string.format
local string_gsub = string.gsub
local table_insert = table.insert
local table_concat = table.concat

local function normalizeKey(key)
	return key and key:lower():gsub("[-_]", "") or ""
end

-- Apply hover and active states to GUI elements
local function applyHoverActiveStates(gui, tag, computedHoverStyles, computedActiveStyles, props)
	if not gui or (not computedHoverStyles and not computedActiveStyles) then return end
	
	-- Default link styling if it's an <a> tag without explicit styling
	if tag == "a" and props and props.attributes and props.attributes.href then
		-- Apply default link styling if not explicitly styled
		local hasTextColor = false
		local hasCustomStyles = false
		
		-- Check if custom color styles are specified for the link
		if props.attributes.style then
			-- Parse inline styles to check for custom color
			for rule in props.attributes.style:gmatch("[^;]+") do
				local key, value = rule:match("^%s*([^:]+):%s*(.-)%s*$")
				if key and value and normalizeKey(key) == "color" then
					hasTextColor = true
					hasCustomStyles = true
					break
				end
			end
		end
		
		-- Also check hover styles
		if computedHoverStyles then
			for k, _ in pairs(computedHoverStyles) do
				if normalizeKey(k) == "color" then
					hasTextColor = true
					break
				end
			end
		end
		
		-- If no hover color specified, add default link hover color
		if not hasTextColor and not hasCustomStyles and (gui:IsA("TextLabel") or gui:IsA("TextButton")) then
			computedHoverStyles = computedHoverStyles or {}
			computedHoverStyles.color = "#0000EE" -- Default link color
			
			-- Apply default blue color, but don't mark it as custom styling
			gui.TextColor3 = Color3.fromRGB(0, 0, 238) -- Default link color
			
			-- We no longer apply text stroke to simulate underlining - it causes visual issues
			-- Links now just use the blue color without additional styling
		end
	end
	
	-- Apply hover/active states
	if computedHoverStyles or computedActiveStyles then
		local registryStateProps = {
			hover = {},
			active = {}
		}
		
		-- Create a UIPadding if needed for hover/active state indicators
		if not gui:FindFirstChildOfClass("UIPadding") then
			local padding = Instance.new("UIPadding")
			padding.PaddingLeft = UDim.new(0, 0)
			padding.PaddingRight = UDim.new(0, 0)
			padding.PaddingTop = UDim.new(0, 0)
			padding.PaddingBottom = UDim.new(0, 0)
			padding.Parent = gui
		end
		
		-- Store original properties
		local originalProps = {}
		originalProps.BackgroundColor3 = gui.BackgroundColor3
		originalProps.BackgroundTransparency = gui.BackgroundTransparency
		if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
			originalProps.TextColor3 = gui.TextColor3
			originalProps.TextSize = gui.TextSize
		end
		
		-- Create hover/active state handlers
		gui.MouseEnter:Connect(function()
			local tweenInfo = TweenInfo.new(0.15)
			local targetProps = ComponentRegistry.getTweenTargetProperties(registryStateProps.hover, computedHoverStyles, gui)
			if next(targetProps) then
				local tween = TweenService:Create(gui, tweenInfo, targetProps)
				tween:Play()
			end
		end)
		
		gui.MouseLeave:Connect(function()
			local tweenInfo = TweenInfo.new(0.15)
			local tween = TweenService:Create(gui, tweenInfo, originalProps)
			tween:Play()
		end)
		
		if gui:IsA("GuiButton") then
			gui.MouseButton1Down:Connect(function()
				local tweenInfo = TweenInfo.new(0.05)
				local targetProps = ComponentRegistry.getTweenTargetProperties(registryStateProps.active, computedActiveStyles, gui)
				if next(targetProps) then
					local tween = TweenService:Create(gui, tweenInfo, targetProps)
					tween:Play()
				end
			end)
			
			gui.MouseButton1Up:Connect(function()
				local tweenInfo = TweenInfo.new(0.05)
				local targetProps = ComponentRegistry.getTweenTargetProperties(registryStateProps.hover, computedHoverStyles, gui)
				if next(targetProps) then
					local tween = TweenService:Create(gui, tweenInfo, targetProps)
					tween:Play()
				else
					local tween = TweenService:Create(gui, tweenInfo, originalProps)
					tween:Play()
				end
			end)
		end
	end
end

-- Helper function to apply CSS styles to a GUI object
local function applyCssToGui(gui, styles)
	if not gui or not styles then return end
	
	for k, v in pairs(styles) do
		local normalizedKey = normalizeKey(k)
		
		-- Background properties
		if normalizedKey == "backgroundcolor" then
			gui.BackgroundColor3 = ComponentRegistry.parseColor(v)
			gui.BackgroundTransparency = 0
		elseif normalizedKey == "backgroundtransparency" then
			gui.BackgroundTransparency = tonumber(v) or 0
		
		-- Text properties
		elseif normalizedKey == "color" then
			if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
				gui.TextColor3 = ComponentRegistry.parseColor(v)
			end
		elseif normalizedKey == "fontfamily" or normalizedKey == "fontname" then
			if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
				-- Map common font names to Roblox fonts
				local fontName = v:lower()
				if fontName:match("arial") or fontName:match("helvetica") or fontName:match("sans") then
					gui.Font = Enum.Font.SourceSans
				elseif fontName:match("times") or fontName:match("serif") then
					gui.Font = Enum.Font.SourceSans -- Use SourceSans as fallback
				elseif fontName:match("courier") or fontName:match("mono") then
					gui.Font = Enum.Font.Code
				end
			end
		elseif normalizedKey == "fontsize" then
			if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
				local size = v
				if type(size) == "string" then
					size = size:match("(%d+)") or "16"
				end
				gui.TextSize = tonumber(size) or 16
			end
		elseif normalizedKey == "fontweight" then
			if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
				local weight = v:lower()
				if weight == "bold" then
					gui.Font = Enum.Font.SourceSansBold
				end
			end
		elseif normalizedKey == "textalign" then
			if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
				local align = v:lower()
				if align == "center" then
					gui.TextXAlignment = Enum.TextXAlignment.Center
				elseif align == "right" then
					gui.TextXAlignment = Enum.TextXAlignment.Right
				else
					gui.TextXAlignment = Enum.TextXAlignment.Left
				end
			end
		elseif normalizedKey == "verticalalign" then
			if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
				local align = v:lower()
				if align == "middle" then
					gui.TextYAlignment = Enum.TextYAlignment.Center
				elseif align == "bottom" then
					gui.TextYAlignment = Enum.TextYAlignment.Bottom
				else
					gui.TextYAlignment = Enum.TextYAlignment.Top
				end
			end
		
		-- Border properties
		elseif normalizedKey == "borderstyle" then
			if v:lower() ~= "none" then
				gui.BorderSizePixel = 1
			else
				gui.BorderSizePixel = 0
			end
		elseif normalizedKey == "borderwidth" or normalizedKey == "borderthickness" then
			local width = tonumber(v:match("(%d+)")) or 1
			gui.BorderSizePixel = width
		elseif normalizedKey == "bordercolor" then
			gui.BorderColor3 = ComponentRegistry.parseColor(v)
		
		-- Size and position properties
		elseif normalizedKey == "width" then
			local width, unit = ComponentRegistry.parseUnit(v)
			if unit == "px" then
				gui.Size = UDim2.new(0, width, gui.Size.Y.Scale, gui.Size.Y.Offset)
			elseif unit == "%" then
				gui.Size = UDim2.new(width/100, 0, gui.Size.Y.Scale, gui.Size.Y.Offset)
			end
		elseif normalizedKey == "height" then
			local height, unit = ComponentRegistry.parseUnit(v)
			if unit == "px" then
				gui.Size = UDim2.new(gui.Size.X.Scale, gui.Size.X.Offset, 0, height)
			elseif unit == "%" then
				gui.Size = UDim2.new(gui.Size.X.Scale, gui.Size.X.Offset, height/100, 0)
			end
		end
	end
end

local function escapeText(text, isRichTextContent)
	if not text then return "" end
	text = tostring(text)

	text = string_gsub(text, "&ldquo;", "\"")
	text = string_gsub(text, "&rdquo;", "\"")
	text = string_gsub(text, "&", "&amp;")

	if not isRichTextContent then
		text = string_gsub(text, "<", "&lt;")
		text = string_gsub(text, ">", "&gt;")
	end

	text = string_gsub(text, "\"", "&quot;")
	text = string_gsub(text, "'", "&apos;")
	return text
end

-- Check if an element should create its own GUI object or be treated as rich text
local function shouldCreateOwnGui(tag)
	-- These elements should always create their own GUI objects
	local standaloneElements = {
		"a", "button", "input", "textarea", "select", "img", "iframe", "canvas",
		"video", "audio", "table", "tr", "td", "th", "form", "hr", "font", "option"
	}
	
	for _, elem in ipairs(standaloneElements) do
		if tag == elem then
			return true
		end
	end
	
	return false
end

local function parseStyleString(styleString)
	local styles = {}
	if not styleString then return styles end
	
	for rule in styleString:gmatch("[^;]+") do
		local key, value = rule:match("^%s*([^:]+):%s*(.-)%s*$")
		if key and value then
			styles[key:lower():gsub("[-_]", "")] = value:gsub("^%s*(.-)%s*$", "%1")
		end
	end
	return styles
end

local function Color3ToRichTextFormat(color)
	local r = math.floor(color.R * 255 + 0.5)
	local g = math.floor(color.G * 255 + 0.5)
	local b = math.floor(color.B * 255 + 0.5)
	return string_format("rgb(%d,%d,%d)", r, g, b)
end

local function applyRichTextStyles(content, styleString)
	if not styleString or styleString == "" or not content then
		return content or ""
	end

	local styledContent = content
	local styles = parseStyleString(styleString)

	for property, value in pairs(styles) do
		value = value:lower()
		
		if property == "fontweight" and (value == "bold" or (tonumber(value) and tonumber(value) >= 600)) then
			styledContent = string_format("<b>%s</b>", styledContent)
		elseif property == "fontstyle" and value == "italic" then
			styledContent = string_format("<i>%s</i>", styledContent)
		elseif property == "textdecoration" then
			if value:find("underline") then
				styledContent = string_format("<u>%s</u>", styledContent)
			end
			if value:find("line-through") then
				styledContent = string_format("<s>%s</s>", styledContent)
			end
		elseif property == "color" then
			local colorValue = ComponentRegistry.parseColor(value)
			if colorValue then
				local rgbColor = Color3ToRichTextFormat(colorValue) 
				styledContent = string_format('<font color="%s">%s</font>', rgbColor, styledContent)
			elseif value:match("^#") or value:match("rgb") then
				styledContent = string_format('<font color="%s">%s</font>', value, styledContent)
			end
		elseif property == "fontsize" then
			local sizeValue = ComponentRegistry.parseSize(value)
			if sizeValue then
				-- Convert HTML-style font size (1-7) to pixels if needed
				if type(sizeValue) == "number" and sizeValue <= 7 then
					sizeValue = (sizeValue * 2) + 10
				end
				styledContent = string_format('<font size="%d">%s</font>', sizeValue, styledContent)
			end
		end
	end
	
	return styledContent
end

-- Helper function to reconstruct HTML content for rich text
function GuiBuilder.reconstructHtml(node)
	if type(node) == "string" then
		return escapeText(node, true) 
	end

	if type(node) ~= "table" then
		return "" 
	end

	local result = ""

	if node.children then
	for _, child in ipairs(node.children) do
			result = result .. GuiBuilder.reconstructHtml(child)
		end
	end

	return result
end

function GuiBuilder.build(parent, node, cssTables)
	if not cssTables then
		cssTables = {}
		collectCssTables(node, cssTables)
	end

	if not node or not node.children then return end

	if node.tag == "root" then
		for _, child in ipairs(node.children) do
			if type(child) == "table" then
				if child.tag == "html" then
					GuiBuilder.build(parent, child, cssTables)
					return
				elseif child.tag == "body" then
					GuiBuilder.build(parent, child, cssTables)
					return
				end
			end
		end
		
		local order = 0
		for _, child in ipairs(node.children) do
			if type(child) == "table" then
				GuiBuilder.buildChild(parent, child, order, cssTables)
				order = order + 1
			end
		end
		return
	end

	if node.tag == "html" then
		for _, child in ipairs(node.children) do
			if type(child) == "table" and child.tag == "body" then
				GuiBuilder.build(parent, child, cssTables)
				return
			end
		end
		return
	end

	if node.tag == "body" then
		local bodyFrame = Instance.new("ScrollingFrame")
		bodyFrame.Name = "BodyFrame"
		bodyFrame.Size = UDim2.new(1, 0, 1, 0)
		bodyFrame.BackgroundTransparency = 1
		bodyFrame.BorderSizePixel = 0
		bodyFrame.ScrollBarThickness = 8
		bodyFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		bodyFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		bodyFrame.Parent = parent

		local layout = Instance.new("UIListLayout")
		layout.Parent = bodyFrame
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 4)
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left

		local padding = Instance.new("UIPadding")
		padding.Parent = bodyFrame
		padding.PaddingTop = UDim.new(0, 16)
		padding.PaddingBottom = UDim.new(0, 16)
		padding.PaddingLeft = UDim.new(0, 16)
		padding.PaddingRight = UDim.new(0, 32)

		-- Apply CSS styles to the body frame
		local computedBodyStyles = {}
		-- Apply CSS from all style sheets
		for _, cssTable in ipairs(cssTables) do
			for _, rule in ipairs(cssTable.rules or {}) do
				-- Simple selector matching - check if tag matches
				if rule.selector:lower():match(node.tag:lower()) then
					for k, v in pairs(rule.properties) do
						computedBodyStyles[k] = v
					end
				end
			end
		end
		
		applyCssToGui(bodyFrame, computedBodyStyles)

		local order = 0
		for _, child in ipairs(node.children) do
			GuiBuilder.buildChild(bodyFrame, child, order, cssTables)
			order = order + 1
		end
	end
end

function GuiBuilder.buildChild(parent, child, order, cssTables)
	if not parent or not child then return end
	
	local isRichTextElement = false
	local isRichTextContainer = parent:IsA("TextLabel") or parent:IsA("TextButton") or parent:IsA("TextBox")
	
	-- Special case for text nodes
	if type(child) == "string" then
		-- Ignore pure whitespace text nodes (except in pre tags)
		if child:match("^%s+$") then
			return
		end
			-- Skip adding raw text directly under a <select> element
	if parent:GetAttribute("HtmlTag") == "select" then
		return 
	end
	-- Trim leading and trailing whitespace before applying to GUI elements
	local trimmedText = child:gsub("^%s+", ""):gsub("%s+$", "")
	if isRichTextContainer then
		parent.Text = parent.Text .. escapeText(trimmedText, true)
	else
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
		textLabel.Text = escapeText(trimmedText)
		textLabel.RichText = true
		textLabel.TextWrapped = true
		textLabel.AutomaticSize = Enum.AutomaticSize.XY
		textLabel.Size = UDim2.new(0, 0, 0, 0)
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.Parent = parent
		textLabel.LayoutOrder = order
		textLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.Font = Enum.Font.SourceSans
	textLabel.TextSize = 16
		end
		return
	end

	-- Process HTML elements
	if type(child) == "table" and child.tag then
		-- Check if this element should create its own GUI object
		local createStandaloneGui = shouldCreateOwnGui(child.tag)
		
		-- If parent is a rich text container and this is not a standalone element,
		-- handle it as rich text instead of creating a new GUI object
		if isRichTextContainer and not createStandaloneGui then
			local richTextContent = ""
			
			-- Handle specific rich text elements
			if child.tag == "b" or child.tag == "strong" then
				richTextContent = "<b>" .. GuiBuilder.reconstructHtml(child) .. "</b>"
			elseif child.tag == "i" or child.tag == "em" then
				richTextContent = "<i>" .. GuiBuilder.reconstructHtml(child) .. "</i>"
			elseif child.tag == "u" then
				richTextContent = "<u>" .. GuiBuilder.reconstructHtml(child) .. "</u>"
			elseif child.tag == "s" or child.tag == "strike" or child.tag == "del" then
				richTextContent = "<s>" .. GuiBuilder.reconstructHtml(child) .. "</s>"
			elseif child.tag == "br" then
				richTextContent = "<br />"
			elseif child.tag == "font" then
				local fontTag = "<font"
				if child.attributes then
					if child.attributes.color then
						fontTag = fontTag .. " color=\"" .. child.attributes.color .. "\""
					end
					if child.attributes.size then
						-- Make sure font size is applied correctly
						local fontSize = tonumber(child.attributes.size) or 3
						-- Convert HTML font size (1-7) to pixel size
						local pixelSize = (fontSize * 2) + 10  -- Simple formula: size 3 = 16px
						fontTag = fontTag .. " size=\"" .. pixelSize .. "\""
					end
				end
				fontTag = fontTag .. ">"
				richTextContent = fontTag .. GuiBuilder.reconstructHtml(child) .. "</font>"
			else
				-- For other elements, just include their content
				richTextContent = GuiBuilder.reconstructHtml(child)
			end
			
			parent.Text = parent.Text .. richTextContent
			isRichTextElement = true
		else
			-- Continue with normal GUI element creation
			local props = {
				text = "",
				attributes = child.attributes or {},
				parent = parent
			}
			
			-- Gather text content for this element
			if child.children then
				for _, grandchild in ipairs(child.children) do
					if type(grandchild) == "string" then
						props.text = props.text .. escapeText(grandchild)
					end
				end
			end
			
			-- Process CSS styles for this element
			local computedStyles = {}
			local computedHoverStyles = {}
			local computedActiveStyles = {}
			
			-- Handle HTML attributes as inline styles
			if child.attributes then
				-- Handle bgcolor attribute
				if child.attributes.bgcolor then
					computedStyles.backgroundcolor = child.attributes.bgcolor
				end
				
				-- Handle cellpadding for table elements
				if child.tag == "table" and child.attributes.cellpadding then
					child.cellpadding = tonumber(child.attributes.cellpadding) or 3
				end
			end
			
			-- Apply CSS from all style sheets
			for _, cssTable in ipairs(cssTables) do
				-- Process regular styles
				for _, rule in ipairs(cssTable.rules or {}) do
					-- Simple selector matching - check if tag matches
					if rule.selector:lower():match(child.tag:lower()) then
						for k, v in pairs(rule.properties) do
							computedStyles[k] = v
						end
			end
		end
		
				-- Process hover styles
				for _, rule in ipairs(cssTable.hoverRules or {}) do
					-- Simple selector matching - check if tag matches
					if rule.selector:lower():match(child.tag:lower()) then
						for k, v in pairs(rule.properties) do
							computedHoverStyles[k] = v
						end
		end
	end

				-- Process active styles
				for _, rule in ipairs(cssTable.activeRules or {}) do
					-- Simple selector matching - check if tag matches
					if rule.selector:lower():match(child.tag:lower()) then
						for k, v in pairs(rule.properties) do
							computedActiveStyles[k] = v
						end
					end
				end
			end
			
			-- Apply inline styles if present
			if child.attributes and child.attributes.style then
				local inlineStyles = parseStyleString(child.attributes.style)
				for k, v in pairs(inlineStyles) do
					computedStyles[k] = v
				end
			end

	-- Special handling for <select> to gather <option> texts
	if child.tag == 'select' then
		local options = {}
		local selectedText = nil
		for _, optNode in ipairs(child.children or {}) do
			if type(optNode) == 'table' and optNode.tag == 'option' then
				local txt = GuiBuilder.reconstructHtml(optNode)
				table.insert(options, txt)
				if optNode.attributes and (optNode.attributes.selected ~= nil) then
					selectedText = txt
				end
			end
		end
		props.options = options
		props.selected = selectedText or options[1]
	end

	-- Skip hidden inputs (they aren't visible)
	if child.tag == 'input' and child.attributes and child.attributes.type == 'hidden' then
		return
	end

	-- Handle margin by creating a wrapper frame
	local marginWrapper = nil
	local marginValues = { top = 0, right = 0, bottom = 0, left = 0 }
	local hasMargin = false
	if computedStyles.margin then
		local m = ComponentRegistry.parseBoxValue(computedStyles.margin)
		marginValues = { top = m.top, right = m.right, bottom = m.bottom, left = m.left }
		hasMargin = true
	end
	if computedStyles.margintop then marginValues.top = ComponentRegistry.parseUnit(computedStyles.margintop)[2]; hasMargin = true end
	if computedStyles.marginright then marginValues.right = ComponentRegistry.parseUnit(computedStyles.marginright)[2]; hasMargin = true end
	if computedStyles.marginbottom then marginValues.bottom = ComponentRegistry.parseUnit(computedStyles.marginbottom)[2]; hasMargin = true end
	if computedStyles.marginleft then marginValues.left = ComponentRegistry.parseUnit(computedStyles.marginleft)[2]; hasMargin = true end

	if hasMargin then
		marginWrapper = Instance.new("Frame")
		marginWrapper.Name = "MarginWrapper"
		marginWrapper.BackgroundTransparency = 1
		marginWrapper.AutomaticSize = Enum.AutomaticSize.Y
		marginWrapper.Size = UDim2.new(1, 0, 0, 0)
		
		local marginPadding = Instance.new("UIPadding")
		marginPadding.Parent = marginWrapper
		marginPadding.PaddingTop = UDim.new(0, marginValues.top)
		marginPadding.PaddingRight = UDim.new(0, marginValues.right)
		marginPadding.PaddingBottom = UDim.new(0, marginValues.bottom)
		marginPadding.PaddingLeft = UDim.new(0, marginValues.left)
	end
	
			-- Pass parent reference to ComponentRegistry.create for table cell handling
	local gui = ComponentRegistry.create and ComponentRegistry.create(child.tag, props)

	if gui then
		-- Apply base CSS styles immediately
		applyCssToGui(gui, computedStyles)
		
		-- Store table cellpadding as attribute for child cells to access
		if child.tag == "table" and child.cellpadding then
			gui:SetAttribute("CellPadding", child.cellpadding)
		end

		-- Simple hover/active effects using CSS tables
		if gui:IsA("GuiButton") then
			local registryEntry = ComponentRegistry.registry[child.tag] or {}
			local isHovering = false
			if next(computedHoverStyles) ~= nil then
				gui.MouseEnter:Connect(function()
					isHovering = true
					if registryEntry.hover then applyCssToGui(gui, registryEntry.hover) end
					applyCssToGui(gui, computedHoverStyles)
				end)
				gui.MouseLeave:Connect(function()
					isHovering = false
					applyCssToGui(gui, computedStyles)
				end)
			end
			if next(computedActiveStyles) ~= nil then
				gui.MouseButton1Down:Connect(function()
					if registryEntry.active then applyCssToGui(gui, registryEntry.active) end
					applyCssToGui(gui, computedActiveStyles)
				end)
				gui.MouseButton1Up:Connect(function()
					if isHovering and next(computedHoverStyles) ~= nil then
						if registryEntry.hover then applyCssToGui(gui, registryEntry.hover) end
						applyCssToGui(gui, computedHoverStyles)
					else
						applyCssToGui(gui, computedStyles)
					end
				end)
			end
		end

		local finalGuiParent = marginWrapper or parent
		gui.Parent = finalGuiParent

		if marginWrapper then
			marginWrapper.Parent = parent
			marginWrapper.LayoutOrder = order
		else
			gui.LayoutOrder = order
		end
		
		gui:SetAttribute("HtmlTag", child.tag)

		if child.attributes.id then 
			gui.Name = child.attributes.id 
		elseif child.attributes.name and (gui:IsA("TextBox") or gui:IsA("TextButton") or gui:IsA("Frame")) then 
			gui.Name = child.attributes.name 
		end

		if (gui:IsA("GuiButton") or gui:IsA("TextBox")) and child.attributes.onclick then
			gui.MouseButton1Click:Connect(function()
				warn("Executing onclick: " .. child.attributes.onclick)
			end)
		end

		if child.tag == "img" and child.attributes.src and gui:IsA("Frame") then
			local imageLabel = gui:FindFirstChildOfClass("ImageLabel") or Instance.new("ImageLabel")
			imageLabel.Parent = gui
			imageLabel.Size = UDim2.new(1,0,1,0)
			imageLabel.BackgroundTransparency = 1
			imageLabel.Image = child.attributes.src
			imageLabel.ScaleType = Enum.ScaleType.Fit
			gui.AutomaticSize = Enum.AutomaticSize.None
		elseif child.tag == "input" and gui:IsA("TextBox") then
			if child.attributes.type == "password" then
				local function updatePasswordDisplay()
					if gui:FindFirstChild("TextLabel") then
						gui.TextLabel.Text = string.rep("•", #gui.Text)
					end
				end
				gui:GetPropertyChangedSignal("Text"):Connect(updatePasswordDisplay)
				updatePasswordDisplay()
			end
			
			if child.attributes.maxlength then
				local maxLen = tonumber(child.attributes.maxlength)
				if maxLen then
					gui:GetPropertyChangedSignal("Text"):Connect(function()
						if #gui.Text > maxLen then
							gui.Text = gui.Text:sub(1, maxLen)
						end
					end)
				end
			end
		elseif child.tag == "li" then
			local parentLayout = parent:FindFirstChildOfClass("UIListLayout")
			if parentLayout and parentLayout.Parent and parentLayout.Parent:GetAttribute("HtmlTag") == "ol" then
				local bulletLabel = gui:FindFirstChildOfClass("TextLabel")
				if bulletLabel then
					local listCounter = parentLayout.Parent:GetAttribute("ListCounter") or 0
					listCounter = listCounter + 1
					parentLayout.Parent:SetAttribute("ListCounter", listCounter)
					bulletLabel.Text = tostring(listCounter) .. "."
				end
			end
		end

				-- Handle colspan if specified
				if child.tag == "td" or child.tag == "th" then
					-- Handle colspan attribute
					if child.attributes and child.attributes.colspan and gui then
						local colspan = tonumber(child.attributes.colspan) or 1
						if colspan > 1 then
							-- Adjust width based on colspan
							local baseWidth = gui.Size.X.Offset
							gui.Size = UDim2.new(0, baseWidth * colspan, gui.Size.Y.Scale, gui.Size.Y.Offset)
							gui:SetAttribute("ColSpan", colspan)
						end
					end
					
					-- Apply cell padding if parent table has it
					local parentTable = parent
					while parentTable and not parentTable:GetAttribute("HtmlTag") do
						parentTable = parentTable.Parent
					end
					
					if parentTable and parentTable:GetAttribute("HtmlTag") == "table" then
						local cellpadding = parentTable:GetAttribute("CellPadding")
						if cellpadding and cellpadding > 0 then
							-- Apply padding to the cell
							local padding = gui:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
							padding.PaddingLeft = UDim.new(0, cellpadding)
							padding.PaddingRight = UDim.new(0, cellpadding)
							padding.PaddingTop = UDim.new(0, cellpadding)
							padding.PaddingBottom = UDim.new(0, cellpadding)
							padding.Parent = gui
						end
					end
					
					-- Handle rowspan attribute
					if child.attributes and child.attributes.rowspan and gui then
						local rowspan = tonumber(child.attributes.rowspan) or 1
						if rowspan > 1 then
							gui:SetAttribute("RowSpan", rowspan)
							-- The actual height adjustment will happen in the parent table's layout
						end
					end
					
					-- Apply any width/height attributes directly
					if child.attributes and child.attributes.width and gui then
						local width = child.attributes.width
						if tonumber(width) then
							-- Numeric width is treated as pixels
							gui.Size = UDim2.new(0, tonumber(width), gui.Size.Y.Scale, gui.Size.Y.Offset)
						elseif width:match("%%$") then
							-- Percentage width
							local percent = tonumber(width:match("(%d+)%%"))
							if percent then
								gui.Size = UDim2.new(percent/100, 0, gui.Size.Y.Scale, gui.Size.Y.Offset)
							end
				end
			end
		end

		local isVoidElement = child.tag == "br" or child.tag == "img" or child.tag == "input" or 
			child.tag == "textarea" or child.tag == "label" or child.tag == "hr" or 
			child.tag == "area" or child.tag == "base" or child.tag == "col" or 
			child.tag == "embed" or child.tag == "link" or child.tag == "meta" or 
			child.tag == "param" or child.tag == "source" or child.tag == "track" or 
			child.tag == "wbr" or child.tag == "font" or child.tag == "option"

		if not isRichTextElement and not isVoidElement and child.children and #child.children > 0 then
			local childOrder = 0
			for _, grandchild in ipairs(child.children) do
				GuiBuilder.buildChild(gui, grandchild, childOrder, cssTables)
				childOrder = childOrder + 1
			end
		end
	else
		-- If a component doesn't create a gui object (e.g., <b>, <i>),
		-- still process its children and attach them to the current parent.
		if child.children and #child.children > 0 then
			local childOrder = order
			local effectiveParent = marginWrapper or parent
			if marginWrapper and not marginWrapper.Parent then
				marginWrapper.Parent = parent
				marginWrapper.LayoutOrder = order
			end

			for _, grandchild in ipairs(child.children) do
				GuiBuilder.buildChild(effectiveParent, grandchild, childOrder, cssTables)
				childOrder = childOrder + 1
			end
		end
			end

			-- Apply hover/active states if they exist
			if gui and (computedHoverStyles or computedActiveStyles) then
				applyHoverActiveStates(gui, child.tag, computedHoverStyles, computedActiveStyles, child)
			end
		end
	end
end

-- Collect <style> tag contents and <link> elements from the DOM tree and parse them into css tables
collectCssTables = function(node, out)
	if type(node) ~= "table" then return end
	
	-- Handle <style> tags
	if node.tag == "style" then
		local cssText = ""
		for _, child in ipairs(node.children or {}) do
			if type(child) == "string" then
				cssText ..= child
			end
		end
		if cssText ~= "" then
			local parsed = CssParser.parse(cssText)
			table.insert(out, parsed)
		end
	end
	
	-- Handle <link> tags with rel="stylesheet"
	if node.tag == "link" and node.attributes and 
	   node.attributes.rel == "stylesheet" and node.attributes.href then
		-- For now, we'll just store a placeholder for external stylesheets
		-- In a real implementation, this would fetch the CSS from the URL
		local href = node.attributes.href
		-- Set a flag that external CSS was requested
		node:SetAttribute("ExternalCssRequested", href)
	end
	
	-- Recursively process children
	for _, child in ipairs(node.children or {}) do
		collectCssTables(child, out)
	end
end

-- Helper function to get computed styles for an element

return GuiBuilder