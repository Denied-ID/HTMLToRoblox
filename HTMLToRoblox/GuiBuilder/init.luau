local ComponentRegistry = require(script:WaitForChild("ComponentRegistry"))

local GuiBuilder = {}

-- HTML entity decoding and escaping for Roblox RichText
-- `isRichTextContent` param: if true, < and > are NOT escaped, assuming they are RichText tags.
local function escapeText(text, isRichTextContent)
	if not text then return "" end
	text = tostring(text)

	-- First, handle specific unescaping requests from the user
	-- These conversions are applied before general escaping to ensure
	-- specific HTML entities are converted to their literal characters.
	text = text:gsub("&ldquo;", "\"")
	text = text:gsub("&rdquo;", "\"")

	-- Always escape '&' first to prevent double-escaping later
	text = text:gsub("&", "&amp;")

	-- Conditionally escape < and > based on whether it's RichText content
	if not isRichTextContent then
		text = text:gsub("<", "&lt;")
		text = text:gsub(">", "&gt;")
	end

	-- Always escape quotes
	text = text:gsub("\"", "&quot;")
	text = text:gsub("'", "&apos;")
	return text
end

-- Function to parse CSS style string into a table of properties
local function parseStyleString(styleString)
	local styles = {}
	if not styleString then return styles end
	for key, value in styleString:gmatch("([%w%-]+)%s*:%s*([^;]+);?") do
		styles[key:lower()] = value:trim() -- trim to remove leading/trailing spaces
	end
	return styles
end

-- Helper function to convert Color3 to RGB string for RichText (for <font color="...">)
local function Color3ToRichTextFormat(color)
	local r = math.floor(color.R * 255)
	local g = math.floor(color.G * 255)
	local b = math.floor(color.B * 255)
	return string.format("rgb(%d,%d,%d)", r, g, b) -- Use rgb format
end

-- Enhanced rich text style application (for content WITHIN TextLabels)
local function applyRichTextStyles(content, styleString)
	warn("applyRichTextStyles: Input content='" .. content .. "', style='" .. styleString .. "'")
	if not styleString or styleString == "" then
		return content
	end

	local styledContent = content

	-- Parse CSS-like styles
	for rule in styleString:gmatch("[^;]+") do
		local property, value = rule:match("^%s*([^:]+):%s*(.-)%s*$")
		if property and value then
			property = property:lower():gsub("[-_]", "")
			value = value:lower()

			-- Font weight
			if property == "fontweight" and (value == "bold" or (tonumber(value) and tonumber(value) >= 600)) then
				styledContent = string.format("<b>%s</b>", styledContent)
			end

			-- Font style
			if property == "fontstyle" and value == "italic" then
				styledContent = string.format("<i>%s</i>", styledContent)
			end

			-- Text decoration
			if property == "textdecoration" then
				if value:find("underline") then
					styledContent = string.format("<u>%s</u>", styledContent)
				end
				if value:find("line-through") then
					styledContent = string.format("<s>%s</s>", styledContent)
				end
			end

			-- Color
			if property == "color" then
				local colorValue = ComponentRegistry.parseColor(value)
				if colorValue then
					-- Use RGB format for RichText color
					local rgbColor = Color3ToRichTextFormat(colorValue) 
					styledContent = string.format('<font color="%s">%s</font>', rgbColor, styledContent)
				elseif value:match("^#") or value:match("rgb") then
					-- Fallback if parseColor didn't handle it, use raw value if it looks like a color
					styledContent = string.format('<font color="%s">%s</font>', value, styledContent)
				end
			end

			-- Font size
			if property == "fontsize" then
				local sizeValue = ComponentRegistry.parseSize(value)
				if sizeValue then
					styledContent = string.format('<font size="%d">%s</font>', sizeValue, styledContent)
				end
			end
		end
	end
	warn("applyRichTextStyles: Output for '" .. content .. "': " .. styledContent)
	return styledContent
end

-- Enhanced HTML reconstruction with better inline element handling
function GuiBuilder.reconstructHtml(node)
	if not node then return "" end

	if type(node) == "string" then
		-- Plain text content that is part of a rich text block,
		-- should be escaped for HTML entities but NOT for < or >.
		return escapeText(node, true) 
	end

	if type(node) ~= "table" or not node.children then 
		return "" 
	end

	local parts = {}

	for _, child in ipairs(node.children) do
		if type(child) == "string" then
			-- Plain text within a rich-text element (e.g., <p>text</p>)
			table.insert(parts, escapeText(child, true))
		elseif type(child) == "table" and child.tag then
			local tag = child.tag:lower()
			local innerContent = GuiBuilder.reconstructHtml(child)

			-- Apply inline styles if present
			if child.attributes and child.attributes.style then
				innerContent = applyRichTextStyles(innerContent, child.attributes.style)
			end

			-- Handle special inline elements
			if tag == "br" then
				table.insert(parts, "<br/>")
			elseif tag == "strong" or tag == "b" then
				table.insert(parts, string.format("<b>%s</b>", innerContent))
			elseif tag == "em" or tag == "i" then
				table.insert(parts, string.format("<i>%s</i>", innerContent))
			elseif tag == "u" then
				table.insert(parts, string.format("<u>%s</u>", innerContent))
			elseif tag == "s" or tag == "strike" or tag == "del" then
				table.insert(parts, string.format("<s>%s</s>", innerContent))
			elseif tag == "small" then
				table.insert(parts, string.format('<font size="12">%s</font>', innerContent)) -- Approx smaller size
			elseif tag == "big" then
				table.insert(parts, string.format('<font size="20">%s</font>', innerContent)) -- Approx bigger size
			elseif tag == "sub" then
				table.insert(parts, string.format('<font size="12">%s</font>', innerContent)) -- Roblox doesn't support true subscript
			elseif tag == "sup" then
				table.insert(parts, string.format('<font size="12">%s</font>', innerContent)) -- Roblox doesn't support true superscript
			elseif tag == "code" then
				-- Style code differently (assuming RobotoMono is available)
				table.insert(parts, string.format('<font face="RobotoMono" color="rgb(200,50,50)">%s</font>', innerContent))
			elseif tag == "span" then
				-- Span just wraps, applies style to its content, the content is already styled by applyRichTextStyles
				table.insert(parts, innerContent)
			else
				-- For other inline elements, just use the content, assuming rich text is applied if needed
				table.insert(parts, innerContent)
			end
		end
	end

	return table.concat(parts)
end

-- Function to apply CSS styles to a Roblox GUI object
-- This function will apply styles based on the computed CSS properties.
local function applyCssToGui(gui, styles)
	for key, value in pairs(styles) do
		pcall(function() -- Use pcall for safety
			if key == "color" then
				if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
					gui.TextColor3 = ComponentRegistry.parseColor(value)
				end
			elseif key == "background-color" then
				if gui.BackgroundColor3 then
					gui.BackgroundColor3 = ComponentRegistry.parseColor(value)
					gui.BackgroundTransparency = 0 -- Ensure background is visible
				end
			elseif key == "font-weight" then
				if (gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox")) and value == "bold" then
					gui.Font = Enum.Font.SourceSansBold
				end
			elseif key == "font-size" then
				if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
					local sizeNum = ComponentRegistry.parseSize(value)
					if sizeNum then gui.TextSize = sizeNum end
				end
			elseif key == "text-align" then
				if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
					local val = value:lower()
					if val == "center" then gui.TextXAlignment = Enum.TextXAlignment.Center
					elseif val == "right" then gui.TextXAlignment = Enum.TextXAlignment.Right
					else gui.TextXAlignment = Enum.TextXAlignment.Left
					end
				end
			elseif key == "width" then
				local num, unit = value:match("^(%d+)(px|%%)$")
				if num then
					num = tonumber(num)
					if unit == "px" then
						gui.Size = UDim2.new(0, num, gui.Size.Y.Scale, gui.Size.Y.Offset)
					elseif unit == "%%" then
						gui.Size = UDim2.new(num / 100, 0, gui.Size.Y.Scale, gui.Size.Y.Offset)
					end
				end
			elseif key == "height" then
				local num, unit = value:match("^(%d+)(px|%%)$")
				if num then
					num = tonumber(num)
					if unit == "px" then
						gui.Size = UDim2.new(gui.Size.X.Scale, gui.Size.X.Offset, 0, num)
					elseif unit == "%%" then
						gui.Size = UDim2.new(gui.Size.X.Scale, gui.Size.X.Offset, num / 100, 0)
					end
				end
			elseif key == "padding" then
				local num = tonumber(value:match("^(%d+)px$"))
				if num and gui:FindFirstChildOfClass("UIPadding") then
					gui.Padding.PaddingTop = UDim.new(0, num)
					gui.Padding.PaddingBottom = UDim.new(0, num)
					gui.Padding.PaddingLeft = UDim.new(0, num)
					gui.Padding.PaddingRight = UDim.new(0, num)
				end
			elseif key == "border" then
				local thickness = value:match("^(%d+)px")
				if thickness and gui:FindFirstChildOfClass("UIStroke") then
					gui.UIStroke.Thickness = tonumber(thickness)
					gui.UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					local colorPart = value:match("solid%s*(.+)") or value:match("dashed%s*(.+)") or value:match("dotted%s*(.+)")
					if colorPart then
						local color = ComponentRegistry.parseColor(colorPart)
						if color then gui.UIStroke.Color = color end
					end
				end
			elseif key == "border-radius" then
				local num = tonumber(value:match("^(%d+)px$"))
				if num and gui:FindFirstChildOfClass("UICorner") then
					gui.UICorner.CornerRadius = UDim.new(0, num)
				end
			elseif key == "font-weight" and (gui:IsA("TextButton") or gui:IsA("TextLabel")) then
				if value == "bold" then
					gui.Font = Enum.Font.SourceSansBold
				else
					gui.Font = Enum.Font.SourceSans
				end
			end
		end)
	end
end

local function getComputedStyles(node, cssTables, pseudoClass)
	local combinedStyles = {}
	pseudoClass = pseudoClass or ""  -- Default to empty string

	for _, cssTable in ipairs(cssTables or {}) do
		-- Tag selector (e.g., "button")
		if pseudoClass == "" and cssTable[node.tag] then
			for k, v in pairs(cssTable[node.tag]) do
				combinedStyles[k] = v
			end
		end

		-- Tag selector with pseudo-class (e.g., "button:hover")
		local tagSelector = node.tag .. pseudoClass
		if cssTable[tagSelector] then
			for k, v in pairs(cssTable[tagSelector]) do
				combinedStyles[k] = v
			end
		end

		-- Class selector (e.g., .red-text)
		if node.attributes and node.attributes.class then
			for className in node.attributes.class:gmatch("%S+") do
				-- Class without pseudo-class
				if pseudoClass == "" then
					local classSelector = "." .. className
					if cssTable[classSelector] then
						for k, v in pairs(cssTable[classSelector]) do
							combinedStyles[k] = v
						end
					end
				end

				-- Class with pseudo-class
				local classSelector = "." .. className .. pseudoClass
				if cssTable[classSelector] then
					for k, v in pairs(cssTable[classSelector]) do
						combinedStyles[k] = v
					end
				end
			end
		end

		-- ID selector (e.g., #main)
		if node.attributes and node.attributes.id then
			-- ID without pseudo-class
			if pseudoClass == "" then
				local idSelector = "#" .. node.attributes.id
				if cssTable[idSelector] then
					for k, v in pairs(cssTable[idSelector]) do
						combinedStyles[k] = v
					end
				end
			end

			-- ID with pseudo-class
			local idSelector = "#" .. node.attributes.id .. pseudoClass
			if cssTable[idSelector] then
				for k, v in pairs(cssTable[idSelector]) do
					combinedStyles[k] = v
				end
			end
		end
	end

	-- Inline styles (highest precedence, override external CSS)
	if node.attributes and node.attributes.style then
		local inlineStyles = parseStyleString(node.attributes.style)
		for k, v in pairs(inlineStyles) do
			combinedStyles[k] = v
		end
	end

	return combinedStyles
end

local function applyHoverStyles(gui, hoverStyles)
	if not hoverStyles then return end

	if hoverStyles["background-color"] then
		gui:SetAttribute("HoverBackgroundColor", ComponentRegistry.parseColor(hoverStyles["background-color"]))
	end
end


-- Enhanced main build function - now accepts cssTables
function GuiBuilder.build(parent, node, cssTables)
	if not node or not node.children then return end

	-- Handle document structure
	if node.tag == "root" then
		for _, child in ipairs(node.children) do
			if type(child) == "table" then
				if child.tag == "html" then
					GuiBuilder.build(parent, child, cssTables) -- Pass cssTables to recursive call
					return
				elseif child.tag == "body" then
					GuiBuilder.build(parent, child, cssTables) -- Pass cssTables to recursive call
					return
				end
			end
		end
		-- If no html/body found, build all children
		local order = 0
		for _, child in ipairs(node.children) do
			if type(child) == "table" then
				GuiBuilder.buildChild(parent, child, order, cssTables) -- Pass cssTables
				order = order + 1
			end
		end
		return
	end

	-- Handle HTML tag
	if node.tag == "html" then
		for _, child in ipairs(node.children) do
			if type(child) == "table" and child.tag == "body" then
				GuiBuilder.build(parent, child, cssTables) -- Pass cssTables to recursive call
				return
			end
		end
		return
	end

	-- Handle body tag
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
		layout.FillDirection = Enum.FillDirection.Vertical -- Ensure vertical layout
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left -- Align left

		local padding = Instance.new("UIPadding")
		padding.Parent = bodyFrame
		padding.PaddingTop = UDim.new(0, 16)
		padding.PaddingBottom = UDim.new(0, 16)
		padding.PaddingLeft = UDim.new(0, 16)
		padding.PaddingRight = UDim.new(0, 32) -- Extra right padding for scrollbar

		-- Apply body styles from computed CSS
		local computedBodyStyles = getComputedStyles(node, cssTables)
		applyCssToGui(bodyFrame, computedBodyStyles)

		local order = 0
		for _, child in ipairs(node.children) do
			GuiBuilder.buildChild(bodyFrame, child, order, cssTables) -- Pass cssTables
			order = order + 1
		end
	end
end

-- Enhanced child building with better element handling - now accepts cssTables
function GuiBuilder.buildChild(parent, child, order, cssTables)
	if type(child) == "string" then
		local textContent = child
		local cleanedText = textContent:gsub("%s", ""):gsub("\xC2\xA0", "") 

		if #cleanedText == 0 then
			return 
		end

		local textLabel = Instance.new("TextLabel")
		textLabel.AutomaticSize = Enum.AutomaticSize.Y
		textLabel.Size = UDim2.new(1, 0, 0, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Font = Enum.Font.SourceSans
		textLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		textLabel.TextSize = 16
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextWrapped = true
		textLabel.RichText = true
		textLabel.Text = escapeText(child, true) 
		textLabel.LayoutOrder = order
		textLabel.Parent = parent
		return
	end

	if type(child) ~= "table" then return end

	local props = { attributes = child.attributes }
	local isRichTextElement = ComponentRegistry.registry[child.tag] and
		(child.tag == 'p' or child.tag == 'h1' or child.tag == 'h2' or child.tag == 'h3' or
			child.tag == 'h4' or child.tag == 'h5' or child.tag == 'h6' or
			child.tag == 'li' or child.tag == 'a' or child.tag == 'button' or
			child.tag == 'label' or child.tag == 'textarea' or (child.tag == 'input' and (child.attributes.type ~= 'submit' and child.attributes.type ~= 'button')) or
			child.tag == 'td' or child.tag == 'th' or child.tag == 'pre' or child.tag == 'blockquote')

	if isRichTextElement then
		props.text = GuiBuilder.reconstructHtml(child)
		warn("Final TextLabel content for '" .. child.tag .. "': " .. props.text) -- Debugging output
		if child.tag == 'a' then
			props.text = string.format("<u>%s</u>", props.text)
		end
		if child.attributes.type == 'submit' or child.attributes.type == 'button' then
			props.text = child.attributes.value or "Submit"
		end
	end

	-- Compute styles for base, hover, and active states
	local computedStyles = getComputedStyles(child, cssTables, "")
	local computedHoverStyles = getComputedStyles(child, cssTables, ":hover")
	local computedActiveStyles = getComputedStyles(child, cssTables, ":active")

	-- Debug print to verify styles are being computed
	print("DEBUG: Computing styles for tag:", child.tag)
	print("Base styles:", computedStyles)
	print("Hover styles:", computedHoverStyles)
	print("Active styles:", computedActiveStyles)

	local gui = ComponentRegistry.create(child.tag, props, computedStyles, computedHoverStyles, computedActiveStyles) 

	if gui then
		gui.LayoutOrder = order
		gui.Parent = parent
		gui:SetAttribute("HtmlTag", child.tag)

		if child.attributes.id then gui.Name = child.attributes.id end
		if child.attributes.name and (gui:IsA("TextBox") or gui:IsA("TextButton") or gui:IsA("Frame")) then gui.Name = child.attributes.name end

		-- applyCssToGui is no longer needed here as ComponentRegistry.create handles the merge
		-- and applies all computed styles after its defaults.

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
			-- Image sizing handled by CSS now via computedStyles
			imageLabel.ScaleType = Enum.ScaleType.Fit
			gui.AutomaticSize = Enum.AutomaticSize.None
		elseif child.tag == "input" and gui:IsA("TextBox") then
			if child.attributes.type == "password" then
				gui.TextLabel.Text = string.rep("•", #gui.Text)
				gui:GetPropertyChangedSignal("Text"):Connect(function()
					gui.TextLabel.Text = string.rep("•", #gui.Text)
				end)
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

		-- Recursively build children for container elements that don't render rich text
		if not isRichTextElement and child.tag ~= "br" and child.tag ~= "img" and
			child.tag ~= "input" and child.tag ~= "textarea" and child.tag ~= "label" and
			child.tag ~= "hr" and child.tag ~= "area" and child.tag ~= "base" and
			child.tag ~= "col" and child.tag ~= "embed" and child.tag ~= "link" and
			child.tag ~= "meta" and child.tag ~= "param" and child.tag ~= "source" and
			child.tag ~= "track" and child.tag ~= "wbr" then

			if child.children and #child.children > 0 then
				local childOrder = 0
				for _, grandchild in ipairs(child.children) do
					GuiBuilder.buildChild(gui, grandchild, childOrder, cssTables)
					childOrder = childOrder + 1
				end
			end
		end
	else
		if child.children and #child.children > 0 then
			local childOrder = 0
			for _, grandchild in ipairs(child.children) do
				GuiBuilder.buildChild(parent, grandchild, childOrder, cssTables)
				childOrder = childOrder + 1
			end
		end
	end
end

return GuiBuilder