-- TODO: Fix the colors in some instances being stuck to something like 'lime' (seen in theoldnet on the Visitors statistic)

local ComponentRegistry = require(script:WaitForChild("ComponentRegistry"))
local JSEngine = require(script:WaitForChild("JSEngine"))

local GuiBuilder = {}

-- Maps legacy HTML <font size=...> values (1-7) to pixel sizes
local FONT_SIZE_MAP = {
	["1"] = 10,
	["2"] = 13,
	["3"] = 16,
	["4"] = 18,
	["5"] = 24,
	["6"] = 32,
	["7"] = 48,
}

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
	text = text:gsub("\"", "'")
	text = text:gsub("'", "'")
	return text
end

-- Function to parse CSS style string into a table of properties
-- since it's not friendly enough to parse other things, it may reach to an point to FAIL
local function trim(s)
	return s:match("^%s*(.-)%s*$")
end
 


local function parseStyleString(styleString)
	local styles = {}
	if not styleString then return styles end
	for key, value in styleString:gmatch("([%w%-]+)%s*:%s*([^;]+);?") do
		styles[key:lower()] = trim(value)
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
	print(content, styleString)
	warn("applyRichTextStyles: Input content='" .. tostring(content) .. "', style='" .. tostring(styleString) .. "'")
	
	if not styleString or styleString == "" or typeof(styleString) == "boolean" then
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
					local rgbColor = Color3ToRichTextFormat(colorValue) 
					styledContent = string.format('<font color="%s">%s</font>', rgbColor, styledContent)
				else
					if value:match("^rgb%s*%(") or value:match("^#") then
						styledContent = string.format('<font color="%s">%s</font>', value, styledContent)
					end
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

local function equalizeTableColumnWidths(tableFrame)
    if not tableFrame or tableFrame:GetAttribute("HtmlTag") ~= "table" then
        return
    end
    
    local rows = {}
    local columnWidths = {}
    local maxColumns = 0
    
    -- Collect all rows (both thead/tbody and direct tr children)
    local function collectRows(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:GetAttribute("HtmlTag") == "tr" then
                table.insert(rows, child)
            elseif child:GetAttribute("HtmlTag") == "thead" or 
                   child:GetAttribute("HtmlTag") == "tbody" or 
                   child:GetAttribute("HtmlTag") == "tfoot" then
                collectRows(child)
            end
        end
    end
    
    collectRows(tableFrame)
    
    -- First pass: measure all cells and find maximum width for each column
    for _, row in ipairs(rows) do
        local cells = {}
        local columnIndex = 1
        
        -- Collect all td/th elements in this row
        for _, child in ipairs(row:GetChildren()) do
            if child:GetAttribute("HtmlTag") == "td" or child:GetAttribute("HtmlTag") == "th" then
                table.insert(cells, child)
            end
        end
        
        -- Measure each cell and track maximum width per column
        for _, cell in ipairs(cells) do
            -- Handle colspan - a cell with colspan=2 affects multiple columns
            local colspan = 1
            if cell:GetAttribute("Colspan") then
                colspan = tonumber(cell:GetAttribute("Colspan")) or 1
            end
            
            -- Calculate the effective width of this cell
            local cellWidth = cell.AbsoluteSize.X
            
            -- If this cell spans multiple columns, we need to distribute its width
            if colspan > 1 then
                cellWidth = cellWidth / colspan
            end
            
            -- Apply this width to all columns this cell spans
            for i = 0, colspan - 1 do
                local currentColumn = columnIndex + i
                if not columnWidths[currentColumn] then
                    columnWidths[currentColumn] = 0
                end
                columnWidths[currentColumn] = math.max(columnWidths[currentColumn], cellWidth)
                maxColumns = math.max(maxColumns, currentColumn)
            end
            
            columnIndex = columnIndex + colspan
        end
    end
    
    -- Second pass: apply uniform widths to all cells
    for _, row in ipairs(rows) do
        local cells = {}
        local columnIndex = 1
        
        -- Collect all td/th elements in this row
        for _, child in ipairs(row:GetChildren()) do
            if child:GetAttribute("HtmlTag") == "td" or child:GetAttribute("HtmlTag") == "th" then
                table.insert(cells, child)
            end
        end
        
        -- Apply uniform widths
        for _, cell in ipairs(cells) do
            local colspan = 1
            if cell:GetAttribute("Colspan") then
                colspan = tonumber(cell:GetAttribute("Colspan")) or 1
            end
            
            -- Calculate total width for this cell (sum of all columns it spans)
            local totalWidth = 0
            for i = 0, colspan - 1 do
                local currentColumn = columnIndex + i
                if columnWidths[currentColumn] then
                    totalWidth = totalWidth + columnWidths[currentColumn]
                end
            end
            
            -- Apply the calculated width
            cell.Size = UDim2.new(0, totalWidth, cell.Size.Y.Scale, cell.Size.Y.Offset)
            
            columnIndex = columnIndex + colspan
        end
    end
    
    -- Update table width to accommodate all columns
    local totalTableWidth = 0
    for i = 1, maxColumns do
        if columnWidths[i] then
            totalTableWidth = totalTableWidth + columnWidths[i]
        end
    end
    
    -- Apply the total width to the table frame
    tableFrame.Size = UDim2.new(0, totalTableWidth, tableFrame.Size.Y.Scale, tableFrame.Size.Y.Offset)
end

-- Enhanced HTML reconstruction with better inline element handling
function GuiBuilder.reconstructHtml(node)
	if not node then return "" end

	if type(node) == "string" then
		return escapeText(node, true)
	end

	if not node.tag then -- It's a root-like node, just process children
		local parts = {}
		for _, child in ipairs(node.children or {}) do
			table.insert(parts, GuiBuilder.reconstructHtml(child))
		end
		return table.concat(parts)
	end

	-- It's a tagged element
	local tag = node.tag:lower()
	local innerContent = ""
	local parts = {}
	for _, child in ipairs(node.children or {}) do
		table.insert(parts, GuiBuilder.reconstructHtml(child))
	end
	innerContent = table.concat(parts)

	-- Apply inline styles from the 'style' attribute
	if node.attributes and node.attributes.style then
		innerContent = applyRichTextStyles(innerContent, node.attributes.style)
	end

	-- Handle specific tags for RichText formatting
	if tag == "b" or tag == "strong" then
		return string.format("<b>%s</b>", innerContent)
	elseif tag == "i" or tag == "em" then
		return string.format("<i>%s</i>", innerContent)
	elseif tag == "u" then
		return string.format("<u>%s</u>", innerContent)
	elseif tag == "s" or tag == "strike" then
		return string.format("<s>%s</s>", innerContent)
	elseif tag == "br" then
		return "\n"
	elseif tag == "font" then
		local attrs = node.attributes
		local fontTag = "<font"
		if attrs.color then
			local color3 = ComponentRegistry.parseColor(attrs.color)
			if color3 then
				local rgbString = Color3ToRichTextFormat(color3)
				fontTag = fontTag .. string.format(' color="%s"', rgbString)
			elseif attrs.color:match("^#") or attrs.color:match("rgb") then
				fontTag = fontTag .. string.format(' color="%s"', attrs.color)
			end
		end
		if attrs.size then
			local pixelSize = FONT_SIZE_MAP[tostring(attrs.size)]
			if pixelSize then
				fontTag = fontTag .. string.format(' size="%d"', pixelSize)
			end
		end
		if attrs.face then fontTag = fontTag .. string.format(' face="%s"', attrs.face) end
		fontTag = fontTag .. ">"
		return string.format('%s%s</font>', fontTag, innerContent)
	elseif tag == "sup" then
		return string.format('<font size="12">%s</font>', innerContent)
	elseif tag == "code" then
		return string.format('<font face="RobotoMono" color="rgb(200,50,50)">%s</font>', innerContent)
	elseif tag == "span" then
		return innerContent -- Styles already applied
	elseif tag == "img" or tag == "table" or tag == "tr" or tag == "tbody" or tag == "thead" or tag == "tfoot" then
		-- Return an empty string for tags that will be handled as separate GUI objects.
		-- This prevents them from being duplicated in the text content.
		return ""
	else
		-- For other container-like tags (p, div, etc.), just return their inner content.
		return innerContent
	end
end

-- Helper to get raw text content from a node, stripping all tags.
function GuiBuilder.getTextFromNode(node)
    if not node then return "" end

    if type(node) == "string" then
        return node
    end

    if not node.children then return "" end

    local parts = {}
    for _, child in ipairs(node.children) do
        table.insert(parts, GuiBuilder.getTextFromNode(child))
    end
    return table.concat(parts, " ")
end

-- Table-driven CSS style handlers to simplify maintenance and extension
local STYLE_HANDLERS = {
	["color"] = function(gui, value)
		if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
			gui.TextColor3 = ComponentRegistry.parseColor(value)
		end
	end,

	["background-color"] = function(gui, value)
		if gui.BackgroundColor3 then
			gui.BackgroundColor3 = ComponentRegistry.parseColor(value)
			gui.BackgroundTransparency = 0 -- Ensure background is visible
		end
	end,

	["font-weight"] = function(gui, value)
		if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
			if tostring(value):lower() == "bold" then
				gui.Font = Enum.Font.SourceSansBold
			else
				gui.Font = Enum.Font.SourceSans
			end
		end
	end,

	["font-size"] = function(gui, value)
		if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
			local sizeNum = ComponentRegistry.parseSize(value)
			if sizeNum then gui.TextSize = sizeNum end
		end
	end,

	["text-align"] = function(gui, value)
		if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
			local val = tostring(value):lower()
			if val == "center" then gui.TextXAlignment = Enum.TextXAlignment.Center
			elseif val == "right" then gui.TextXAlignment = Enum.TextXAlignment.Right
			else gui.TextXAlignment = Enum.TextXAlignment.Left end
		end
	end,

	["width"] = function(gui, value)
		local num, unit = tostring(value):match("^(%d+)(px|%%)$")
		if num then
			num = tonumber(num)
			if unit == "px" then
				gui.Size = UDim2.new(0, num, gui.Size.Y.Scale, gui.Size.Y.Offset)
			else -- percentage
				gui.Size = UDim2.new(num / 100, 0, gui.Size.Y.Scale, gui.Size.Y.Offset)
			end
		end
	end,

	["height"] = function(gui, value)
		local num, unit = tostring(value):match("^(%d+)(px|%%)$")
		if num then
			num = tonumber(num)
			if unit == "px" then
				gui.Size = UDim2.new(gui.Size.X.Scale, gui.Size.X.Offset, 0, num)
			else -- percentage
				gui.Size = UDim2.new(gui.Size.X.Scale, gui.Size.X.Offset, num / 100, 0)
			end
		end
	end,

	["padding"] = function(gui, value)
		local num = tonumber(tostring(value):match("^(%d+)px$"))
		local padding = gui:FindFirstChildOfClass("UIPadding")
		if num and padding then
			padding.PaddingTop = UDim.new(0, num)
			padding.PaddingBottom = UDim.new(0, num)
			padding.PaddingLeft = UDim.new(0, num)
			padding.PaddingRight = UDim.new(0, num)
		end
	end,

	["border"] = function(gui, value)
		local thickness = tostring(value):match("^(%d+)px")
		local stroke = gui:FindFirstChildOfClass("UIStroke")
		if thickness and stroke then
			stroke.Thickness = tonumber(thickness)
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			local colorPart = value:match("solid%s*(.+)") or value:match("dashed%s*(.+)") or value:match("dotted%s*(.+)")
			if colorPart then
				local col = ComponentRegistry.parseColor(colorPart)
				if col then stroke.Color = col end
			end
		end
	end,

	["border-radius"] = function(gui, value)
		local num = tonumber(tostring(value):match("^(%d+)px$"))
		local corner = gui:FindFirstChildOfClass("UICorner")
		if num and corner then
			corner.CornerRadius = UDim.new(0, num)
		end
	end,

	["display"] = function(gui, value)
        if tostring(value):lower() == "none" then
            gui.Visible = false
        else
            gui.Visible = true
        end
    end,
}

-- Attribute handlers for HTML attributes (easy to extend)
local ATTRIBUTE_HANDLERS = {
	id = function(gui, value)
		gui.Name = tostring(value)
	end,

	name = function(gui, value)
		if gui.Name == "" or gui.Name == gui.ClassName then
			gui.Name = tostring(value)
		end
	end,

	onclick = function(gui, value)
		if gui:IsA("GuiButton") or gui:IsA("TextBox") then
			gui.MouseButton1Click:Connect(function()
				warn("Executing onclick: " .. value)
				JSEngine.execute(value)
			end)
		end
	end,
	href = function(gui, value)
		if gui:IsA("GuiButton") or gui:IsA("TextBox") then
			gui.MouseButton1Click:Connect(function()
				warn("Page navigation to", value, "isn't yet supported due to HtmlToRoblox not having support for it quite yet.")
			end)
		end
	end,
	
	-- Table cell spanning
	colspan = function(gui, value)
		local num = tonumber(value) or 1
		gui:SetAttribute("Colspan", num)
	end,
	rowspan = function(gui, value)
		local num = tonumber(value) or 1
		gui:SetAttribute("Rowspan", num)
	end,
	
	cellspacing = function(gui, value)
		local spacing = tonumber(value) or 0
		gui:SetAttribute("CellSpacing", spacing)

		-- Apply spacing to table layout if it exists
		local layout = gui:FindFirstChildOfClass("UIListLayout")
		if layout then
			layout.Padding = UDim.new(0, spacing)
		end

		-- Also apply spacing to any existing rows
		for _, child in ipairs(gui:GetChildren()) do
			if child:GetAttribute("HtmlTag") == "tr" or 
				child:GetAttribute("HtmlTag") == "thead" or 
				child:GetAttribute("HtmlTag") == "tbody" or 
				child:GetAttribute("HtmlTag") == "tfoot" then
				local rowLayout = child:FindFirstChildOfClass("UIListLayout")
				if rowLayout then
					rowLayout.Padding = UDim.new(0, spacing)
				end
			end
		end
	end,

	cellpadding = function(gui, value)
		local padding = tonumber(value) or 0
		gui:SetAttribute("CellPadding", padding)

		-- Apply padding to all table cells
		local function applyCellPadding(parent)
			for _, child in ipairs(parent:GetChildren()) do
				if child:GetAttribute("HtmlTag") == "td" or child:GetAttribute("HtmlTag") == "th" then
					local uiPadding = child:FindFirstChildOfClass("UIPadding")
					if not uiPadding then
						uiPadding = Instance.new("UIPadding")
						uiPadding.Parent = child
					end
					uiPadding.PaddingTop = UDim.new(0, padding)
					uiPadding.PaddingBottom = UDim.new(0, padding)
					uiPadding.PaddingLeft = UDim.new(0, padding)
					uiPadding.PaddingRight = UDim.new(0, padding)
				elseif child:GetAttribute("HtmlTag") == "tr" or 
					child:GetAttribute("HtmlTag") == "thead" or 
					child:GetAttribute("HtmlTag") == "tbody" or 
					child:GetAttribute("HtmlTag") == "tfoot" then
					applyCellPadding(child)
				end
			end
		end

		applyCellPadding(gui)
	end,
	
	-- TODO: Add support for cellspacing, and cellpadding.

	-- Dimensions via attribute
	width = function(gui, value)
		local num, unit = tostring(value):match("^(%d+)(px|%%)$")
		if num then
			num = tonumber(num)
			if unit == "px" then
				gui.Size = UDim2.new(0, num, gui.Size.Y.Scale, gui.Size.Y.Offset)
			else
				gui.Size = UDim2.new(num / 100, 0, gui.Size.Y.Scale, gui.Size.Y.Offset)
			end
		end
	end,
	height = function(gui, value)
		local num, unit = tostring(value):match("^(%d+)(px|%%)$")
		if num then
			num = tonumber(num)
			if unit == "px" then
				gui.Size = UDim2.new(gui.Size.X.Scale, gui.Size.X.Offset, 0, num)
			else
				gui.Size = UDim2.new(gui.Size.X.Scale, gui.Size.X.Offset, num / 100, 0)
			end
		end
	end,
	
	size = function(gui, value)
		if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
			local computedSize = math.floor(2.6667 * value + 7.333 + 0.5)

			if computedSize < 10 then
				computedSize = 10
			elseif computedSize > 18 then
				computedSize = 18
			end

			gui.TextSize = computedSize
		end
	end,
	
	bgcolor = function(gui, value)
		local color = ComponentRegistry.parseColor(value)
		if color and gui.BackgroundColor3 then
			gui.BackgroundColor3 = color
			gui.BackgroundTransparency = 0
		end
	end,
	
	

	---------------------------------------------------------
	-- Forced To Ignore
	---------------------------------------------------------
	-- Anything set to "true" will be ignored from the unsupported checks.
	---------------------------------------------------------
	src = true		-- Cannot provide support for because images cannot be transported to this engine due to safety, compatibility, and performance reasons.
}

-- Apply CSS styles using the handler table defined above
local function applyCssToGui(gui, styles)
	for key, value in pairs(styles) do
		local handler = STYLE_HANDLERS[key]
		if handler then
			local ok, err = pcall(handler, gui, value)
			if not ok then
				warn("HTMLToRoblox: Error applying style '" .. key .. "': " .. tostring(err))
			end
		else
			warn("HTMLToRoblox: Unsupported style property: '" .. key .. "' with value '" .. tostring(value) .. "'")
		end
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
			--if typeof(node.attributes.class) ~= "string" then continue end
			-- print(node)
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
			--if typeof(node.attributes.id) ~= "string" then continue end
			--print(node)
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
		bodyFrame.BackgroundTransparency = 0
		bodyFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
function GuiBuilder.buildChild(parent, child, order, cssTables, isParentRichText)
	-- Forward-declare the gui variable so that it is visible to the entire function scope.
	local gui
	if isParentRichText then return end

	if type(child) == "string" then
		local textContent = child
		local trimmed = textContent:match("^%s*(.-)%s*$")
		if trimmed == "" then return end

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
		(ComponentRegistry.registry[child.tag].isRichText == true or -- Check a flag in the registry
		(child.tag == 'p' or child.tag == 'h1' or child.tag == 'h2' or child.tag == 'h3' or
			child.tag == 'h4' or child.tag == 'h5' or child.tag == 'h6' or child.tag == 'a' or child.tag == 'button' or
			child.tag == 'label' or child.tag == 'textarea' or (child.tag == 'input' and (child.attributes.type ~= 'submit' and child.attributes.type ~= 'button')) or
			child.tag == 'td' or child.tag == 'th' or child.tag == 'pre' or child.tag == 'blockquote'))

	-- Warn for unsupported tags
	if not ComponentRegistry.registry[child.tag] then
		warn("HTMLToRoblox: Unsupported tag found: <" .. tostring(child.tag) .. ">")
	end

	if isRichTextElement then
		props.text = GuiBuilder.reconstructHtml(child)
		print("Final TextLabel content for '" .. child.tag .. "': " .. props.text) -- Debugging output
		if child.tag == 'a' then
			props.text = string.format("<u>%s</u>", props.text)
		end
	end

	local computedStyles = getComputedStyles(child, cssTables, "")

	-- Create the GUI element using the component registry
	gui = ComponentRegistry.create(child.tag, props, computedStyles.base, computedStyles.hover, computedStyles.active) 

	-- Handle special alignment attributes post-creation
	if gui and child.tag == "td" then
		local align = child.attributes and child.attributes.align
		if align == "center" or align == "middle" then
				gui.TextXAlignment = Enum.TextXAlignment.Center
		elseif align == "right" then
			gui.TextXAlignment = Enum.TextXAlignment.Right
		else
			gui.TextXAlignment = Enum.TextXAlignment.Left
		end
	end 

	if gui then
		-- For <select> elements, we need to manually move the <option> children into the dropdown frame
		if child.tag == "select" and gui:FindFirstChild("OptionsFrame") then
			local optionsFrame = gui:FindFirstChild("OptionsFrame")
			for _, optionInstance in ipairs(gui:GetChildren()) do
				if optionInstance:GetAttribute("HtmlTag") == "option" then
					optionInstance.Parent = optionsFrame
				end
			end
		end

		gui.LayoutOrder = order
		gui.Parent = parent
		gui:SetAttribute("HtmlTag", child.tag)
		if child.attributes.id then
			gui.Name = child.attributes.id
		elseif child.attributes.name then
		if type(child.attributes.name) == "string" and (gui:IsA("TextBox") or gui:IsA("TextButton") or gui:IsA("Frame")) then
				gui.Name = child.attributes.name
			end
		end
		if child.tag:match("^h[1-6]$") then
			local parentLayout = parent:FindFirstChildOfClass("UIListLayout")
			if not parentLayout then
				local layout = Instance.new("UIListLayout")
				layout.FillDirection = Enum.FillDirection.Vertical
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.Parent = parent
			end
		end

			if gui and child.attributes then
				for attr, value in pairs(child.attributes) do
					local attrLower = attr:lower()
					local handler = ATTRIBUTE_HANDLERS[attrLower]
					local styleHandler = STYLE_HANDLERS[attrLower]
	
					if type(handler) == "function" then
						local ok, err = pcall(handler, gui, value)
						if not ok then
							warn("HTMLToRoblox: Error applying attribute '" .. attr .. "': " .. tostring(err))
						end
					elseif not handler and not styleHandler then
						if not attrLower:match("^data-") then
							warn("HTMLToRoblox: Unsupported attribute '" .. attr .. "' for tag <" .. child.tag .. ">")
						end
					end
				end
			end
		end
		-- Always recurse to build children, allowing for mixed content (e.g., images and tables inside styled text containers)
		if child.children and #child.children > 0 then
			local childOrder = 0
			for _, grandchild in ipairs(child.children) do
				GuiBuilder.buildChild(gui, grandchild, childOrder, cssTables, isRichTextElement)
				childOrder = childOrder + 1
			end
		end

		-- Post-build adjustments for specific tags
		if child.tag == "center" and gui then
			for _, descendant in ipairs(gui:GetDescendants()) do
				if descendant:IsA("TextLabel") then
					if descendant.Parent:GetAttribute("HtmlTag") ~= "tr" then
						descendant.TextXAlignment = Enum.TextXAlignment.Center
					end
				end
				if descendant:IsA("UIListLayout") then
					descendant.HorizontalAlignment = Enum.HorizontalAlignment.Center
				end
			end
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
				gui.Text = string.rep("•", #gui.Text)
				local realPassword = ""
				local ignore = false
				local textbox = gui

				textbox:GetPropertyChangedSignal("Text"):Connect(function()
					if ignore then return end

					local visualText = textbox.Text
					local numBullets = #visualText
					local numReal = #realPassword

					if numBullets < numReal then
						realPassword = string.sub(realPassword, 1, numBullets)
					elseif numBullets > numReal then
						local addedCount = numBullets - numReal
						realPassword = realPassword .. string.rep("?", addedCount)
					end

					-- Now mask the textbox
					ignore = true
					textbox.Text = string.rep("•", #realPassword)
					ignore = false
					textbox.CursorPosition = #textbox.Text + 1
				end)

			end
			if child.attributes.maxlength then
				local maxLen = tonumber(child.attributes.maxlength)
				if maxLen then
					gui:GetPropertyChangedSignal("Text"):Connect(function()
						if gui.Text:len() > maxLen then
							gui.Text = gui.Text:sub(1, maxLen)
						end
					end)
				end
			end
		elseif child.tag == "li" then
			local parentLayout = parent:FindFirstChildOfClass("UIListLayout")
			local bulletLabel = gui:FindFirstChildOfClass("TextLabel")

			if parentLayout and parentLayout.Parent and parentLayout.Parent:GetAttribute("HtmlTag") == "ol" then
				local listCounter = parentLayout.Parent:GetAttribute("ListCounter") or 0
				listCounter = listCounter + 1
				parentLayout.Parent:SetAttribute("ListCounter", listCounter)
				if bulletLabel then
					bulletLabel.Text = tostring(listCounter) .. "."
				end
			else
				if bulletLabel then
					bulletLabel.Text = "•" -- fallback unordered bullet
				end
			end
		end
	

	if not gui and child.children and #child.children > 0 then
		local childOrder = 0
		for _, grandchild in ipairs(child.children) do
			GuiBuilder.buildChild(parent, grandchild, childOrder, cssTables)
			childOrder = childOrder + 1
		end
	end

	if child.tag == "table" and gui then
		gui:SetAttribute("NeedsColumnEqualization", true)
	end

	local function finalizeTableWidths(parent)
		-- Guard against nil parent to prevent runtime errors when no parent instance is available
		if not parent then
			return
		end
		for _, descendant in ipairs(parent:GetDescendants()) do
			if descendant:GetAttribute("HtmlTag") == "table" and descendant:GetAttribute("NeedsColumnEqualization") then
				spawn(function()
					wait(0.1)
					equalizeTableColumnWidths(descendant)
					descendant:SetAttribute("NeedsColumnEqualization", nil)
				end)
			end
		end
	end

	finalizeTableWidths(parent)
end

return GuiBuilder