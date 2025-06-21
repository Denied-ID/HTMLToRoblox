local ComponentRegistry = require(script:WaitForChild("ComponentRegistry"))

local GuiBuilder = {}

local function escapeText(text, isRichTextContent)
	if not text then return "" end
	text = tostring(text)

	text = text:gsub("&ldquo;", "\"")
	text = text:gsub("&rdquo;", "\"")

	text = text:gsub("&", "&amp;")

	if not isRichTextContent then
		text = text:gsub("<", "&lt;")
		text = text:gsub(">", "&gt;")
	end

	text = text:gsub("\"", "&quot;")
	text = text:gsub("'", "&apos;")
	return text
end

local function parseStyleString(styleString)
	local styles = {}
	if not styleString then return styles end
	for key, value in styleString:gmatch("([%w%-]+)%s*:%s*([^;]+);?") do
		styles[key:lower()] = value:trim()
	end
	return styles
end

local function Color3ToRichTextFormat(color)
	local r = math.floor(color.R * 255)
	local g = math.floor(color.G * 255)
	local b = math.floor(color.B * 255)
	return string.format("rgb(%d,%d,%d)", r, g, b)
end

local function applyRichTextStyles(content, styleString)
	warn("applyRichTextStyles: Input content='" .. content .. "', style='" .. styleString .. "'")
	if not styleString or styleString == "" then
		return content
	end

	local styledContent = content

	for rule in styleString:gmatch("[^;]+") do
		local property, value = rule:match("^%s*([^:]+):%s*(.-)%s*$")
		if property and value then
			property = property:lower():gsub("[-_]", "")
			value = value:lower()

			if property == "fontweight" and (value == "bold" or (tonumber(value) and tonumber(value) >= 600)) then
				styledContent = string.format("<b>%s</b>", styledContent)
			end

			if property == "fontstyle" and value == "italic" then
				styledContent = string.format("<i>%s</i>", styledContent)
			end

			if property == "textdecoration" then
				if value:find("underline") then
					styledContent = string.format("<u>%s</u>", styledContent)
				end
				if value:find("line-through") then
					styledContent = string.format("<s>%s</s>", styledContent)
				end
			end

			if property == "color" then
				local colorValue = ComponentRegistry.parseColor(value)
				if colorValue then
					local rgbColor = Color3ToRichTextFormat(colorValue) 
					styledContent = string.format('<font color="%s">%s</font>', rgbColor, styledContent)
				elseif value:match("^#") or value:match("rgb") then
					styledContent = string.format('<font color="%s">%s</font>', value, styledContent)
				end
			end

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

function GuiBuilder.reconstructHtml(node)
	if not node then return "" end

	if type(node) == "string" then
		return escapeText(node, true) 
	end

	if type(node) ~= "table" or not node.children then 
		return "" 
	end

	local parts = {}

	for _, child in ipairs(node.children) do
		if type(child) == "string" then
			table.insert(parts, escapeText(child, true))
		elseif type(child) == "table" and child.tag then
			local tag = child.tag:lower()
			local innerContent = GuiBuilder.reconstructHtml(child)

			if child.attributes and child.attributes.style then
				innerContent = applyRichTextStyles(innerContent, child.attributes.style)
			end

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
				table.insert(parts, string.format('<font size="12">%s</font>', innerContent))
			elseif tag == "big" then
				table.insert(parts, string.format('<font size="20">%s</font>', innerContent))
			elseif tag == "sub" then
				table.insert(parts, string.format('<font size="12">%s</font>', innerContent))
			elseif tag == "sup" then
				table.insert(parts, string.format('<font size="12">%s</font>', innerContent))
			elseif tag == "code" then
				table.insert(parts, string.format('<font face="RobotoMono" color="rgb(200,50,50)">%s</font>', innerContent))
			elseif tag == "span" then
				table.insert(parts, innerContent)
			else
				table.insert(parts, innerContent)
			end
		end
	end

	return table.concat(parts)
end

local function applyCssToGui(gui, styles)
	for key, value in pairs(styles) do
		pcall(function()
			if key == "color" then
				if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
					gui.TextColor3 = ComponentRegistry.parseColor(value)
				end
			elseif key == "background-color" then
				if gui.BackgroundColor3 then
					gui.BackgroundColor3 = ComponentRegistry.parseColor(value)
					gui.BackgroundTransparency = 0
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
	pseudoClass = pseudoClass or ""

	for _, cssTable in ipairs(cssTables or {}) do
		if pseudoClass == "" and cssTable[node.tag] then
			for k, v in pairs(cssTable[node.tag]) do
				combinedStyles[k] = v
			end
		end

		local tagSelector = node.tag .. pseudoClass
		if cssTable[tagSelector] then
			for k, v in pairs(cssTable[tagSelector]) do
				combinedStyles[k] = v
			end
		end

		if node.attributes and node.attributes.class then
			for className in node.attributes.class:gmatch("%S+") do
				if pseudoClass == "" then
					local classSelector = "." .. className
					if cssTable[classSelector] then
						for k, v in pairs(cssTable[classSelector]) do
							combinedStyles[k] = v
						end
					end
				end

				local classSelector = "." .. className .. pseudoClass
				if cssTable[classSelector] then
					for k, v in pairs(cssTable[classSelector]) do
						combinedStyles[k] = v
					end
				end
			end
		end

		if node.attributes and node.attributes.id then
			if pseudoClass == "" then
				local idSelector = "#" .. node.attributes.id
				if cssTable[idSelector] then
					for k, v in pairs(cssTable[idSelector]) do
						combinedStyles[k] = v
					end
				end
			end

			local idSelector = "#" .. node.attributes.id .. pseudoClass
			if cssTable[idSelector] then
				for k, v in pairs(cssTable[idSelector]) do
					combinedStyles[k] = v
				end
			end
		end
	end

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


function GuiBuilder.build(parent, node, cssTables)
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

		local computedBodyStyles = getComputedStyles(node, cssTables)
		applyCssToGui(bodyFrame, computedBodyStyles)

		local order = 0
		for _, child in ipairs(node.children) do
			GuiBuilder.buildChild(bodyFrame, child, order, cssTables)
			order = order + 1
		end
	end
end

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
		warn("Final TextLabel content for '" .. child.tag .. "': " .. props.text)
		if child.tag == 'a' then
			props.text = string.format("<u>%s</u>", props.text)
		end
		if child.attributes.type == 'submit' or child.attributes.type == 'button' then
			props.text = child.attributes.value or "Submit"
		end
	end

	local computedStyles = getComputedStyles(child, cssTables, "")
	local computedHoverStyles = getComputedStyles(child, cssTables, ":hover")
	local computedActiveStyles = getComputedStyles(child, cssTables, ":active")

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