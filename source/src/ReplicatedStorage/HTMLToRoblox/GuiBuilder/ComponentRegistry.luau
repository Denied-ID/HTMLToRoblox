local TweenService = game:GetService("TweenService")
local ComponentRegistry = {}
local radioGroups = {}

-- Helper function to sanitize attribute names by removing illegal characters
function ComponentRegistry.sanitizeAttributeName(name)
	if type(name) ~= "string" then return tostring(name) end
	-- Replace illegal characters with underscores
	-- Roblox attributes cannot contain: -, :, ., spaces, or other special characters
	return name:gsub("[-:%.%s]", "_")
end

function ComponentRegistry.parseColor(color)
	if not color then return Color3.fromRGB(0, 0, 0) end
	color = color:lower():gsub(" ", "")
	local NAMED_COLORS = {
		aliceblue = Color3.fromRGB(240,248,255),
		antiquewhite = Color3.fromRGB(250,235,215),
		aqua = Color3.fromRGB(0,255,255),
		aquamarine = Color3.fromRGB(127,255,212),
		azure = Color3.fromRGB(240,255,255),
		beige = Color3.fromRGB(245,245,220),
		bisque = Color3.fromRGB(255,228,196),
		black = Color3.fromRGB(0,0,0),
		blanchedalmond = Color3.fromRGB(255,235,205),
		blue = Color3.fromRGB(0,0,255),
		blueviolet = Color3.fromRGB(138,43,226),
		brown = Color3.fromRGB(165,42,42),
		burlywood = Color3.fromRGB(222,184,135),
		cadetblue = Color3.fromRGB(95,158,160),
		chartreuse = Color3.fromRGB(127,255,0),
		chocolate = Color3.fromRGB(210,105,30),
		coral = Color3.fromRGB(255,127,80),
		cornflowerblue = Color3.fromRGB(100,149,237),
		cornsilk = Color3.fromRGB(255,248,220),
		crimson = Color3.fromRGB(220,20,60),
		cyan = Color3.fromRGB(0,255,255),
		darkblue = Color3.fromRGB(0,0,139),
		darkcyan = Color3.fromRGB(0,139,139),
		darkgoldenrod = Color3.fromRGB(184,134,11),
		darkgray = Color3.fromRGB(169,169,169),
		darkgreen = Color3.fromRGB(0,100,0),
		darkgrey = Color3.fromRGB(169,169,169),
		darkkhaki = Color3.fromRGB(189,183,107),
		darkmagenta = Color3.fromRGB(139,0,139),
		darkolivegreen = Color3.fromRGB(85,107,47),
		darkorange = Color3.fromRGB(255,140,0),
		darkorchid = Color3.fromRGB(153,50,204),
		darkred = Color3.fromRGB(139,0,0),
		darksalmon = Color3.fromRGB(233,150,122),
		darkseagreen = Color3.fromRGB(143,188,143),
		darkslateblue = Color3.fromRGB(72,61,139),
		darkslategray = Color3.fromRGB(47,79,79),
		darkslategrey = Color3.fromRGB(47,79,79),
		darkturquoise = Color3.fromRGB(0,206,209),
		darkviolet = Color3.fromRGB(148,0,211),
		deeppink = Color3.fromRGB(255,20,147),
		deepskyblue = Color3.fromRGB(0,191,255),
		dimgray = Color3.fromRGB(105,105,105),
		dimgrey = Color3.fromRGB(105,105,105),
		dodgerblue = Color3.fromRGB(30,144,255),
		firebrick = Color3.fromRGB(178,34,34),
		floralwhite = Color3.fromRGB(255,250,240),
		forestgreen = Color3.fromRGB(34,139,34),
		fuchsia = Color3.fromRGB(255,0,255),
		gainsboro = Color3.fromRGB(220,220,220),
		ghostwhite = Color3.fromRGB(248,248,255),
		gold = Color3.fromRGB(255,215,0),
		goldenrod = Color3.fromRGB(218,165,32),
		gray = Color3.fromRGB(128,128,128),
		green = Color3.fromRGB(0,128,0),
		greenyellow = Color3.fromRGB(173,255,47),
		grey = Color3.fromRGB(128,128,128),
		hotpink = Color3.fromRGB(255,105,180),
		indianred = Color3.fromRGB(205,92,92),
		indigo = Color3.fromRGB(75,0,130),
		ivory = Color3.fromRGB(255,255,240),
		khaki = Color3.fromRGB(240,230,140),
		lavender = Color3.fromRGB(230,230,250),
		lavenderblush = Color3.fromRGB(255,240,245),
		lawngreen = Color3.fromRGB(124,252,0),
		lemonchiffon = Color3.fromRGB(255,250,205),
		lightblue = Color3.fromRGB(173,216,230),
		lightcoral = Color3.fromRGB(240,128,128),
		lightcyan = Color3.fromRGB(224,255,255),
		lightgoldenrodyellow = Color3.fromRGB(250,250,210),
		lightgray = Color3.fromRGB(211,211,211),
		lightgreen = Color3.fromRGB(144,238,144),
		lightgrey = Color3.fromRGB(211,211,211),
		lightpink = Color3.fromRGB(255,182,193),
		lightsalmon = Color3.fromRGB(255,160,122),
		lightseagreen = Color3.fromRGB(32,178,170),
		lightskyblue = Color3.fromRGB(135,206,250),
		lightslategray = Color3.fromRGB(119,136,153),
		lightslategrey = Color3.fromRGB(119,136,153),
		lightsteelblue = Color3.fromRGB(176,196,222),
		lightyellow = Color3.fromRGB(255,255,224),
		lime = Color3.fromRGB(0,255,0),
		limegreen = Color3.fromRGB(50,205,50),
		linen = Color3.fromRGB(250,240,230),
		magenta = Color3.fromRGB(255,0,255),
		maroon = Color3.fromRGB(128,0,0),
		middleaquamarine = Color3.fromRGB(102,205,170),
		middleblue = Color3.fromRGB(0,0,205),
		middleorchid = Color3.fromRGB(186,85,211),
		middlepurple = Color3.fromRGB(147,112,219),
		middleseagreen = Color3.fromRGB(60,179,113),
		middleslateblue = Color3.fromRGB(123,104,238),
		middlespringgreen = Color3.fromRGB(0,250,154),
		middleturquoise = Color3.fromRGB(72,209,204),
		middlevioletred = Color3.fromRGB(199,21,133),
		midnightblue = Color3.fromRGB(25,25,112),
		mintcream = Color3.fromRGB(245,255,250),
		mistyrose = Color3.fromRGB(255,228,225),
		moccasin = Color3.fromRGB(255,228,181),
		navajowhite = Color3.fromRGB(255,222,173),
		navy = Color3.fromRGB(0,0,128),
		oldlace = Color3.fromRGB(253,245,230),
		olive = Color3.fromRGB(128,128,0),
		olivedrab = Color3.fromRGB(107,142,35),
		orange = Color3.fromRGB(255,165,0),
		orangered = Color3.fromRGB(255,69,0),
		orchid = Color3.fromRGB(218,112,214),
		palegoldenrod = Color3.fromRGB(238,232,170),
		palegreen = Color3.fromRGB(152,251,152),
		paleturquoise = Color3.fromRGB(175,238,238),
		palevioletred = Color3.fromRGB(219,112,147),
		papayawhip = Color3.fromRGB(255,239,213),
		peachpuff = Color3.fromRGB(255,218,185),
		peru = Color3.fromRGB(205,133,63),
		pink = Color3.fromRGB(255,192,203),
		plum = Color3.fromRGB(221,160,221),
		powderblue = Color3.fromRGB(176,224,230),
		purple = Color3.fromRGB(128,0,128),
		red = Color3.fromRGB(255,0,0),
		rosybrown = Color3.fromRGB(188,143,143),
		royalblue = Color3.fromRGB(65,105,225),
		saddlebrown = Color3.fromRGB(139,69,19),
		salmon = Color3.fromRGB(250,128,114),
		sandybrown = Color3.fromRGB(244,164,96),
		seagreen = Color3.fromRGB(46,139,87),
		seashell = Color3.fromRGB(255,245,238),
		sienna = Color3.fromRGB(160,82,45),
		silver = Color3.fromRGB(192,192,192),
		skyblue = Color3.fromRGB(135,206,235),
		slateblue = Color3.fromRGB(106,90,205),
		slategray = Color3.fromRGB(112,128,144),
		slategrey = Color3.fromRGB(112,128,144),
		snow = Color3.fromRGB(255,250,250),
		springgreen = Color3.fromRGB(0,255,127),
		steelblue = Color3.fromRGB(70,130,180),
		tan = Color3.fromRGB(210,180,140),
		teal = Color3.fromRGB(0,128,128),
		thistle = Color3.fromRGB(216,191,216),
		tomato = Color3.fromRGB(255,99,71),
		turquoise = Color3.fromRGB(64,224,208),
		violet = Color3.fromRGB(238,130,238),
		wheat = Color3.fromRGB(245,222,179),
		white = Color3.fromRGB(255,255,255),
		whitesmoke = Color3.fromRGB(245,245,245),
		yellow = Color3.fromRGB(255,255,0),
		yellowgreen = Color3.fromRGB(154,205,50),
		transparent = Color3.new(0,0,0),
		mediumaquamarine = Color3.fromRGB(102,205,170),
		mediumblue = Color3.fromRGB(0,0,205),
		mediumorchid = Color3.fromRGB(186,85,211),
		mediumpurple = Color3.fromRGB(147,112,219),
		mediumseagreen = Color3.fromRGB(60,179,113),
		mediumslateblue = Color3.fromRGB(123,104,238),
		mediumspringgreen = Color3.fromRGB(0,250,154),
		mediumturquoise = Color3.fromRGB(72,209,204),
		mediumvioletred = Color3.fromRGB(199,21,133),
	}
	if NAMED_COLORS[color] then
		return NAMED_COLORS[color]
	end
	-- Hex codes (#fff or #ffffff)
	color = color:gsub("#", "")
	if #color == 3 then
		local r = tonumber(color:sub(1,1):rep(2), 16)
		local g = tonumber(color:sub(2,2):rep(2), 16)
		local b = tonumber(color:sub(3,3):rep(2), 16)
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	elseif #color == 6 then
		local r = tonumber(color:sub(1,2), 16)
		local g = tonumber(color:sub(3,4), 16)
		local b = tonumber(color:sub(5,6), 16)
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	end

	-- rgb() or rgba()
	local r,g,b,a
	r,g,b = color:match("^rgb%((%d+)%s*,%s*(%d+)%s*,%s*(%d+)%)$")
	if r then
		return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
	end

	r,g,b,a = color:match("^rgba%((%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d*%.?%d+)%)$")
	if r then
		return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)) -- alpha ignored for now
	end

	-- fall back to white
	return Color3.fromRGB(255,255,255)
end

function ComponentRegistry.parseSize(sizeString)
	if not sizeString then return nil end
	sizeString = sizeString:lower():gsub(" ", "")
	local pxMatch = sizeString:match("^(%d+)px$")
	if pxMatch then
		return tonumber(pxMatch)
	end
	return nil
end

function ComponentRegistry.parseUnit(value)
	if type(value) ~= "string" then
		return "px", 0
	end

	local num, unit = value:match("^(-?%d+%.?%d*)%s*(px|%%|em|rem)$")
	num = tonumber(num or value:match("^(-?%d+%.?%d*)"))

	if not num then return "px", 0 end
	if not unit then unit = "px" end
	
	if unit == "em" or unit == "rem" then
		-- For simplicity, treat em/rem as a multiple of a base size.
		-- A real implementation would need context of parent font size.
		return "px", num * 16
	end
	
	return unit, num
end

function ComponentRegistry.parseBorder(value)
	if not value or value == "none" or value == "0" then
		return nil
	end
	local parts = {
		width = 1,
		style = "solid",
		color = Color3.fromRGB(0,0,0)
	}
	local widthMatch = value:match("(%d+%.?%d*)px")
	if widthMatch then parts.width = tonumber(widthMatch) end

	if value:find("dotted") then parts.style = "dotted"
	elseif value:find("dashed") then parts.style = "dashed"
	end

	local colorString = value:match("%s*((#?%x%x%x%x?%x?%x?)|(rgb%b())|(rgba%b())|(%a+))$")
	if colorString then
		parts.color = ComponentRegistry.parseColor(colorString)
	end

	return parts
end

function ComponentRegistry.parseBoxValue(value)
	local values = {}
	for v in value:gmatch("%d+%.?%d*") do
		table.insert(values, tonumber(v))
	end

	if #values == 1 then
		return { top = values[1], right = values[1], bottom = values[1], left = values[1] }
	elseif #values == 2 then
		return { top = values[1], right = values[2], bottom = values[1], left = values[2] }
	elseif #values == 3 then
		return { top = values[1], right = values[2], bottom = values[3], left = values[2] }
	elseif #values >= 4 then
		return { top = values[1], right = values[2], bottom = values[3], left = values[4] }
	end
	return { top = 0, right = 0, bottom = 0, left = 0 }
end

function ComponentRegistry.parseFontFamily(value)
	local fontMap = {
		["arial"] = Enum.Font.Arial,
		["arialbold"] = Enum.Font.ArialBold,
		["sans-serif"] = Enum.Font.SourceSans,
		["sourcesans"] = Enum.Font.SourceSans,
		["sourcesansbold"] = Enum.Font.SourceSansBold,
		["sourcesanslight"] = Enum.Font.SourceSansLight,
		["sourcesansitalic"] = Enum.Font.SourceSansItalic,
		["monospace"] = Enum.Font.RobotoMono,
		["robotomono"] = Enum.Font.RobotoMono,
		["bodoni"] = Enum.Font.Bodoni,
		["garamond"] = Enum.Font.Garamond,
		["timesnewroman"] = Enum.Font.Garamond,
		["code"] = Enum.Font.Code,
		["highway"] = Enum.Font.Highway,
	}

	for name, font in pairs(fontMap) do
		if value:lower():find(name) then
			return font
		end
	end
	return Enum.Font.SourceSans
end

local function applyRobloxProperties(gui, props)
	if not gui or not props then return end
	for key, value in pairs(props) do
		pcall(function()
			gui[key] = value
		end)
	end
end

function ComponentRegistry.getTweenTargetProperties(registryStateProps, cssStateStyles, currentGui)
	local function nKey(k)
		return k and k:lower():gsub("[-_]", "") or ""
	end
	
	local targetProps = {}
	
	if cssStateStyles then
		for k, v in pairs(cssStateStyles) do
			local nk = nKey(k)
			if nk == "backgroundcolor" then
				targetProps.BackgroundColor3 = ComponentRegistry.parseColor(v)
				targetProps.BackgroundTransparency = 0
			elseif nk == "color" then
				targetProps.TextColor3 = ComponentRegistry.parseColor(v)
			elseif nk == "fontsize" then
				targetProps.TextSize = tonumber(v:match("(%d+)")) or currentGui.TextSize
			elseif nk == "fontweight" then
				-- Font is not a tween-able property, so we'll need to apply it directly
				-- instead of through a tween. We'll handle this elsewhere if needed.
				-- Removed: targetProps.Font = ...
			end
				end
			end
	
	return targetProps
end

ComponentRegistry.registry = {
	h1 = {
		create = function(props) 
			local label = Instance.new("TextLabel") 
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			local p = Instance.new("UIPadding")
			p.Parent = label
			p.PaddingTop = UDim.new(0, 16)
			p.PaddingBottom = UDim.new(0, 16)
			return label 
		end,
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 32, Size = UDim2.new(1, 0, 0, 0) },
	},
	h2 = {
		create = function(props) 
			local label = Instance.new("TextLabel") 
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			local p = Instance.new("UIPadding")
			p.Parent = label
			p.PaddingTop = UDim.new(0, 14)
			p.PaddingBottom = UDim.new(0, 14)
			return label 
		end,
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 28, Size = UDim2.new(1, 0, 0, 0) },
	},
	h3 = {
		create = function(props) 
			local label = Instance.new("TextLabel") 
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			local p = Instance.new("UIPadding")
			p.Parent = label
			p.PaddingTop = UDim.new(0, 12)
			p.PaddingBottom = UDim.new(0, 12)
			return label 
		end,
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 24, Size = UDim2.new(1, 0, 0, 0) },
	},
	h4 = {
		create = function(props) 
			local label = Instance.new("TextLabel") 
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			local p = Instance.new("UIPadding")
			p.Parent = label
			p.PaddingTop = UDim.new(0, 10)
			p.PaddingBottom = UDim.new(0, 10)
			return label 
		end,
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 20, Size = UDim2.new(1, 0, 0, 0) },
	},
	h5 = {
		create = function(props) 
			local label = Instance.new("TextLabel") 
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			local p = Instance.new("UIPadding")
			p.Parent = label
			p.PaddingTop = UDim.new(0, 8)
			p.PaddingBottom = UDim.new(0, 8)
			return label 
		end,
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 18, Size = UDim2.new(1, 0, 0, 0) },
	},
	h6 = {
		create = function(props) 
			local label = Instance.new("TextLabel") 
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			local p = Instance.new("UIPadding")
			p.Parent = label
			p.PaddingTop = UDim.new(0, 6)
			p.PaddingBottom = UDim.new(0, 6)
			return label 
		end,
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 16, Size = UDim2.new(1, 0, 0, 0) },
	},
	p = {
		create = function(props) 
			local hasDirectText = props.text and props.text:gsub("%s+","") ~= ""
			if hasDirectText then
			local label = Instance.new("TextLabel") 
			label.AutomaticSize = Enum.AutomaticSize.Y
				label.Size = UDim2.new(1, 0, 0, 0)
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
				local pad = Instance.new("UIPadding")
				pad.Parent = label
				pad.PaddingTop = UDim.new(0, 8)
				pad.PaddingBottom = UDim.new(0, 8)
			return label 
			else
				-- Create a container for inline elements like <font>
				local frame = Instance.new("Frame")
				frame.AutomaticSize = Enum.AutomaticSize.Y
				frame.Size = UDim2.new(1, 0, 0, 0)
				frame.BackgroundTransparency = 1
				
				local layout = Instance.new("UIListLayout")
				layout.Parent = frame
				layout.FillDirection = Enum.FillDirection.Horizontal
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.Padding = UDim.new(0, 2) -- will be updated dynamically
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
				layout.VerticalAlignment = Enum.VerticalAlignment.Center
				
				-- If parent is inside a <center> container with centered alignment, honor it
				local currentParent = props.parent
				while currentParent do
					local listLayout = currentParent:FindFirstChildOfClass("UIListLayout")
					if listLayout then
						if listLayout.HorizontalAlignment == Enum.HorizontalAlignment.Center then
							layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
						end
						break
					end
					currentParent = currentParent.Parent
				end
				
				-- Dynamically adjust padding based on child text sizes
				local function updatePadding()
					local maxSize = 0
					for _, child in ipairs(frame:GetChildren()) do
						if child:IsA("TextLabel") or child:IsA("TextButton") then
							maxSize = math.max(maxSize, child.TextSize)
						end
					end
					if maxSize > 0 then
						layout.Padding = UDim.new(0, math.floor(maxSize * 0.25)) -- approx 1/4 em
					end
				end
				frame.ChildAdded:Connect(function()
					task.defer(updatePadding)
				end)
				frame.ChildRemoved:Connect(function()
					task.defer(updatePadding)
				end)
				return frame
			end
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	button = {
		create = function(props)
			local button = Instance.new("TextButton")
			button.AutomaticSize = Enum.AutomaticSize.XY
			button.Size = UDim2.new(0, 0, 0, 0)
			button.Text = props.text or ""
			button.RichText = true
			button.TextWrapped = true
			
			-- Apply Chrome-like button styling
			button.BackgroundColor3 = Color3.fromRGB(239, 239, 239)
			button.BorderSizePixel = 1
			button.BorderColor3 = Color3.fromRGB(118, 118, 118)
			
			-- Add padding for button content
			local padding = Instance.new("UIPadding")
			padding.Parent = button
			padding.PaddingLeft = UDim.new(0, 8)
			padding.PaddingRight = UDim.new(0, 8)
			padding.PaddingTop = UDim.new(0, 1)
			padding.PaddingBottom = UDim.new(0, 1)
			
			-- Add corner rounding
			local corner = Instance.new("UICorner")
			corner.Parent = button
			corner.CornerRadius = UDim.new(0, 2)
			
			-- Handle button click
			if props.attributes and props.attributes.onclick then
				-- Store the onclick code as an attribute for external handling
				button:SetAttribute("OnClick", props.attributes.onclick)
			end
			
			-- Add hover/active states
			button.MouseEnter:Connect(function()
				button.BackgroundColor3 = Color3.fromRGB(229, 241, 251) -- Light blue on hover
			end)
			
			button.MouseLeave:Connect(function()
				button.BackgroundColor3 = Color3.fromRGB(239, 239, 239) -- Default color
			end)
			
			button.MouseButton1Down:Connect(function()
				button.BackgroundColor3 = Color3.fromRGB(204, 228, 247) -- Darker blue when clicked
			end)
			
			button.MouseButton1Up:Connect(function()
				button.BackgroundColor3 = Color3.fromRGB(229, 241, 251) -- Back to hover color
			end)
			
			return button
		end,
		defaults = { TextColor3 = Color3.fromRGB(0, 0, 0), Font = Enum.Font.SourceSans, TextSize = 16 },
	},
	input = {
		create = function(props)
			local inputType = props.attributes and props.attributes.type or "text"
			
			if inputType == "submit" or inputType == "button" then
				-- Create a button
				local button = Instance.new("TextButton")
				button.AutomaticSize = Enum.AutomaticSize.X
				button.Size = UDim2.new(0, 0, 0, 15)
				button.Text = props.attributes and props.attributes.value or "Submit"
				button.Font = Enum.Font.SourceSans
				button.TextSize = 16
				button.TextColor3 = Color3.fromRGB(0,0,0)
				button.BackgroundColor3 = Color3.fromRGB(240,240,240)
				button.BorderColor3 = Color3.fromRGB(200,200,200)
				button.BorderSizePixel = 1
				
				-- Add padding
				local padding = Instance.new("UIPadding")
				padding.Parent = button
				padding.PaddingLeft = UDim.new(0, 6)
				padding.PaddingRight = UDim.new(0, 6)
				padding.PaddingTop = UDim.new(0, 1)
				padding.PaddingBottom = UDim.new(0, 1)
				
				-- Store input attributes
				if props.attributes then
					for k, v in pairs(props.attributes) do
						-- Sanitize attribute name (remove hyphens and other illegal characters)
						local sanitizedKey = ComponentRegistry.sanitizeAttributeName(k)
						button:SetAttribute(sanitizedKey, v)
					end
					
					-- Store name and value for form submission
					if props.attributes.name then
						button:SetAttribute("InputName", props.attributes.name)
					end
					if props.attributes.value then
						button:SetAttribute("InputValue", props.attributes.value)
					end
				end
				
				-- Handle click event
				button.MouseButton1Click:Connect(function()
					-- Find parent form
					local currentParent = button.Parent
					while currentParent do
						if currentParent:GetAttribute("FormAction") then
							-- Trigger form submission
							currentParent:SetAttribute("FormSubmitted", true)
							break
						end
						currentParent = currentParent.Parent
					end
				end)
				
				return button
			else
				-- Create a text box for other input types
				local textBox = Instance.new("TextBox")
				textBox.Size = UDim2.new(0, 177, 0, 15)
				textBox.ClearTextOnFocus = false
				textBox.Font = Enum.Font.SourceSans
				textBox.TextSize = 16
				textBox.TextColor3 = Color3.fromRGB(0, 0, 0)
				textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				textBox.BorderColor3 = Color3.fromRGB(200, 200, 200)
				textBox.BorderSizePixel = 1
				textBox.TextXAlignment = Enum.TextXAlignment.Left
				
				-- Add padding
				local padding = Instance.new("UIPadding")
				padding.Parent = textBox
				padding.PaddingLeft = UDim.new(0, 2)
				padding.PaddingRight = UDim.new(0, 2)
				padding.PaddingTop = UDim.new(0, 1)
				padding.PaddingBottom = UDim.new(0, 1)
				
				-- Apply input attributes
				if props.attributes then
					-- Set placeholder text
					if props.attributes.placeholder then
						textBox.PlaceholderText = props.attributes.placeholder
					end
					
					-- Set initial value
					if props.attributes.value then
						textBox.Text = props.attributes.value
					end
					
					-- Handle password type
					if inputType == "password" then
						textBox.TextScaled = false
						textBox.TextSize = 16
						
						-- Create a display layer for password dots
						local displayLabel = Instance.new("TextLabel")
						displayLabel.Name = "PasswordDisplay"
						displayLabel.Size = UDim2.new(1, 0, 1, 0)
						displayLabel.BackgroundTransparency = 1
						displayLabel.TextXAlignment = Enum.TextXAlignment.Left
						displayLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
						displayLabel.Font = Enum.Font.SourceSans
						displayLabel.TextSize = 16
						displayLabel.Parent = textBox
						displayLabel.ZIndex = 2
						
						-- Add padding to match parent
						local displayPadding = Instance.new("UIPadding")
						displayPadding.Parent = displayLabel
						displayPadding.PaddingLeft = UDim.new(0, 2)
						displayPadding.PaddingRight = UDim.new(0, 2)
						displayPadding.PaddingTop = UDim.new(0, 1)
						displayPadding.PaddingBottom = UDim.new(0, 1)
						
						-- Update password display when text changes
						local function updatePasswordDisplay()
							displayLabel.Text = string.rep("•", #textBox.Text)
						end
						
						textBox:GetPropertyChangedSignal("Text"):Connect(updatePasswordDisplay)
						updatePasswordDisplay()
					end
					
					-- Store input attributes
					for k, v in pairs(props.attributes) do
						-- Sanitize attribute name (remove hyphens and other illegal characters)
						local sanitizedKey = ComponentRegistry.sanitizeAttributeName(k)
						textBox:SetAttribute(sanitizedKey, v)
					end
					
					-- Store name and value for form submission
					if props.attributes.name then
						textBox:SetAttribute("InputName", props.attributes.name)
					end
				end
				
				return textBox
			end
		end,
		defaults = {},
	},
	select = {
		create = function(props)
			-- Create a dropdown button that will show options when clicked
			local dropdown = Instance.new("TextButton")
			dropdown.AutomaticSize = Enum.AutomaticSize.X
			dropdown.Size = UDim2.new(0, 0, 0, 15)
			dropdown.Text = props.selected or "Select..."
			dropdown.TextWrapped = true
			dropdown.BackgroundColor3 = Color3.fromRGB(248, 248, 248)
			dropdown.BorderSizePixel = 1
			dropdown.BorderColor3 = Color3.fromRGB(200, 200, 200)
			dropdown.Font = Enum.Font.SourceSans
			dropdown.TextSize = 16
			dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
			dropdown.AutoButtonColor = false
			
			-- Add dropdown arrow
			local arrow = Instance.new("TextLabel")
			arrow.Parent = dropdown
			arrow.BackgroundTransparency = 1
			arrow.Text = "▼"
			arrow.TextColor3 = Color3.fromRGB(100, 100, 100)
			arrow.Size = UDim2.new(0, 20, 1, 0)
			arrow.Position = UDim2.new(1, -25, 0, 0)
			arrow.TextSize = 14
			arrow.Font = Enum.Font.SourceSans
			
			-- Create options container (initially hidden)
			local optionsFrame = Instance.new("Frame")
			optionsFrame.Parent = dropdown
			optionsFrame.Visible = false
			optionsFrame.Size = UDim2.new(1, 0, 0, 0)
			optionsFrame.Position = UDim2.new(0, 0, 1, 0)
			optionsFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			optionsFrame.BorderSizePixel = 1
			optionsFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
			optionsFrame.ZIndex = 10
			optionsFrame.AutomaticSize = Enum.AutomaticSize.Y
			
			local optionsLayout = Instance.new("UIListLayout")
			optionsLayout.Parent = optionsFrame
			optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
			
			-- Add options from props
			if props.options then
				for i, optionText in ipairs(props.options) do
					local option = Instance.new("TextButton")
					option.Parent = optionsFrame
					option.Size = UDim2.new(1, 0, 0, 15)
					option.Text = optionText
					option.TextWrapped = true
					option.BackgroundColor3 = Color3.fromRGB(248, 248, 248)
					option.BorderSizePixel = 0
					option.Font = Enum.Font.SourceSans
					option.TextSize = 14
					option.TextColor3 = Color3.fromRGB(0, 0, 0)
					option.ZIndex = 11
					option.LayoutOrder = i
					
					-- Highlight on hover
					option.MouseEnter:Connect(function()
						option.BackgroundColor3 = Color3.fromRGB(230, 230, 250)
					end)
					
					option.MouseLeave:Connect(function()
						option.BackgroundColor3 = Color3.fromRGB(248, 248, 248)
					end)
					
					-- Select option on click
					option.MouseButton1Click:Connect(function()
						dropdown.Text = optionText
						optionsFrame.Visible = false
						dropdown:SetAttribute("SelectedValue", optionText)
					end)
				end
			end
			
			-- Toggle dropdown visibility on click
			dropdown.MouseButton1Click:Connect(function()
				optionsFrame.Visible = not optionsFrame.Visible
			end)

			-- Store select attributes
			if props.attributes then
				for k, v in pairs(props.attributes) do
					-- Sanitize attribute name (remove hyphens and other illegal characters)
					local sanitizedKey = ComponentRegistry.sanitizeAttributeName(k)
					dropdown:SetAttribute(sanitizedKey, v)
				end
				
				-- Store name attribute for form submission
				if props.attributes.name then
					dropdown:SetAttribute("InputName", props.attributes.name)
				end
			end
			
			-- Set selected value if provided
			if props.selected then
				dropdown:SetAttribute("SelectedValue", props.selected)
			end
			
			return dropdown
		end,
		defaults = {},
	},
	a = {
		create = function(props) 
			local button = Instance.new("TextButton")
			button.AutomaticSize = Enum.AutomaticSize.XY
			button.Size = UDim2.new(0, 0, 0, 0)
			button.Text = props.text or ""
			button.RichText = true
			button.TextWrapped = true
			button.BackgroundTransparency = 1
			button.BorderSizePixel = 0
			button.AutoButtonColor = false
			
			-- Default link color is blue
			button.TextColor3 = Color3.fromRGB(0, 0, 238) -- #0000EE
			
			-- Store href attribute
			if props.attributes and props.attributes.href then
				button:SetAttribute("Href", props.attributes.href)
				
				-- Add underline effect
				local underline = Instance.new("Frame")
				underline.Parent = button
				underline.BackgroundColor3 = button.TextColor3
				underline.BorderSizePixel = 0
				underline.Size = UDim2.new(1, 0, 0, 1)
				underline.Position = UDim2.new(0, 0, 1, 0)
				underline.AnchorPoint = Vector2.new(0, 0)
				
				-- Handle hover state
				button.MouseEnter:Connect(function()
					button.TextColor3 = Color3.fromRGB(85, 26, 139) -- #551A8B (visited link color)
					underline.BackgroundColor3 = button.TextColor3
				end)
				
				button.MouseLeave:Connect(function()
					button.TextColor3 = Color3.fromRGB(0, 0, 238) -- #0000EE
					underline.BackgroundColor3 = button.TextColor3
				end)
				
				-- Handle click
				button.MouseButton1Click:Connect(function()
					-- Store that this link was visited
					button:SetAttribute("Visited", true)
					
					-- External handler will need to handle the actual navigation
					button:SetAttribute("Clicked", true)
				end)
			end
			
			return button
		end,
		defaults = { Font = Enum.Font.SourceSans, TextSize = 16 },
	},
	ul = {
		create = function(props) 
			local frame = Instance.new("Frame") 
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.SortOrder = Enum.SortOrder.LayoutOrder
			local p = Instance.new("UIPadding")
			p.Parent = frame
			p.PaddingLeft = UDim.new(0, 20)
			p.PaddingTop = UDim.new(0, 8)
			p.PaddingBottom = UDim.new(0, 8)
			return frame 
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	ol = {
		create = function(props) 
			local frame = Instance.new("Frame") 
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.SortOrder = Enum.SortOrder.LayoutOrder
			local p = Instance.new("UIPadding")
			p.Parent = frame
			p.PaddingLeft = UDim.new(0, 20)
			p.PaddingTop = UDim.new(0, 8)
			p.PaddingBottom = UDim.new(0, 8)
			frame:SetAttribute("ListCounter", 0)
			return frame 
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	li = {
		create = function(props) 
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local layout = Instance.new("UIListLayout")
			layout.Parent = frame
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.VerticalAlignment = Enum.VerticalAlignment.Top
			layout.Padding = UDim.new(0, 5)

			local bullet = Instance.new("TextLabel")
			bullet.Parent = frame
			bullet.Text = "•"
			bullet.Size = UDim2.new(0, 20, 0, 20)
			bullet.BackgroundTransparency = 1
			bullet.Font = Enum.Font.SourceSans
			bullet.TextSize = 16
			bullet.TextYAlignment = Enum.TextYAlignment.Top
			bullet.TextXAlignment = Enum.TextXAlignment.Left

			local label = Instance.new("TextLabel")
			label.Parent = frame
			label.Text = props.text or ""
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Size = UDim2.new(1, -25, 0, 0)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.SourceSans
			label.TextSize = 16
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			label.RichText = true
			label.TextColor3 = Color3.fromRGB(0, 0, 0)

			-- Determine background color for cell
			local bgColorStr = props.attributes and props.attributes.bgcolor
			if not bgColorStr then
				-- Inherit from nearest ancestor with BgColor attribute (tr or table)
				local anc = props.parent
				while anc do
					if anc:GetAttribute("BgColor") then
						bgColorStr = anc:GetAttribute("BgColor")
						break
					end
					anc = anc.Parent
				end
			end
			if bgColorStr then
				label.BackgroundColor3 = ComponentRegistry.parseColor(bgColorStr)
				label.BackgroundTransparency = 0
			end

			return frame 
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	div = {
		create = function(props) 
			local frame = Instance.new("Frame")
			frame.Name = "Div"
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.SortOrder = Enum.SortOrder.LayoutOrder
			return frame 
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	section = {
		create = function(props) 
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.SortOrder = Enum.SortOrder.LayoutOrder
			local p = Instance.new("UIPadding")
			p.Parent = frame
			p.PaddingTop = UDim.new(0, 8)
			p.PaddingBottom = UDim.new(0, 8)
			return frame 
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	article = {
		create = function(props) 
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.SortOrder = Enum.SortOrder.LayoutOrder
			local p = Instance.new("UIPadding")
			p.Parent = frame
			p.PaddingTop = UDim.new(0, 12)
			p.PaddingBottom = UDim.new(0, 12)
			return frame 
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	header = {
		create = function(props) 
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.SortOrder = Enum.SortOrder.LayoutOrder
			local p = Instance.new("UIPadding")
			p.Parent = frame
			p.PaddingBottom = UDim.new(0, 16)
			return frame 
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	footer = {
		create = function(props) 
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.SortOrder = Enum.SortOrder.LayoutOrder
			local p = Instance.new("UIPadding")
			p.Parent = frame
			p.PaddingTop = UDim.new(0, 16)
			return frame 
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	nav = {
		create = function(props) 
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.SortOrder = Enum.SortOrder.LayoutOrder
			l.FillDirection = Enum.FillDirection.Horizontal
			l.Padding = UDim.new(0, 8)
			return frame 
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	blockquote = {
		create = function(props) 
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundColor3 = Color3.fromRGB(248, 248, 248)
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.SortOrder = Enum.SortOrder.LayoutOrder
			local p = Instance.new("UIPadding")
			p.Parent = frame
			p.PaddingLeft = UDim.new(0, 16)
			p.PaddingRight = UDim.new(0, 16)
			p.PaddingTop = UDim.new(0, 8)
			p.PaddingBottom = UDim.new(0, 8)
			local stroke = Instance.new("UIStroke")
			stroke.Parent = frame
			stroke.Thickness = 4
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = Color3.fromRGB(200, 200, 200)
			return frame 
		end,
		defaults = {},
	},
	hr = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 0, 1)
			frame.BackgroundColor3 = Color3.fromRGB(211, 211, 211)
			frame.BorderSizePixel = 0
			
			-- Add margin above and below
			local marginWrapper = Instance.new("Frame")
			marginWrapper.Size = UDim2.new(1, 0, 0, 21) -- 10px margin above and below + 1px line
			marginWrapper.BackgroundTransparency = 1
			
			local padding = Instance.new("UIPadding")
			padding.Parent = marginWrapper
			padding.PaddingTop = UDim.new(0, 10)
			padding.PaddingBottom = UDim.new(0, 10)
			
			frame.Parent = marginWrapper
			frame.Position = UDim2.new(0, 0, 0.5, 0)
			frame.AnchorPoint = Vector2.new(0, 0.5)
			
			return marginWrapper
		end,
		defaults = {},
	},
	form = {
		create = function(props) 
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			
			-- Create layout for form elements
			local layout = Instance.new("UIListLayout")
			layout.Parent = frame
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.Padding = UDim.new(0, 5)
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			layout.VerticalAlignment = Enum.VerticalAlignment.Center
			
			-- Store form attributes
			if props.attributes then
				for k, v in pairs(props.attributes) do
					-- Sanitize attribute name (remove hyphens and other illegal characters)
					local sanitizedKey = ComponentRegistry.sanitizeAttributeName(k)
					frame:SetAttribute(sanitizedKey, v)
				end
				
				-- Store action URL
				if props.attributes.action then
					frame:SetAttribute("FormAction", props.attributes.action)
				end
				
				-- Store method
				if props.attributes.method then
					frame:SetAttribute("FormMethod", props.attributes.method:upper())
				else
					frame:SetAttribute("FormMethod", "GET")
				end
				
				-- Store ID with sanitized name
				if props.attributes.id then
					frame:SetAttribute("FormId", props.attributes.id)
					-- Use sanitized ID for the Name property
					frame.Name = ComponentRegistry.sanitizeAttributeName(props.attributes.id)
				end
			end
			
			return frame 
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	label = {
		create = function(props) 
			local label = Instance.new("TextLabel") 
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			return label 
		end,
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 16, Size = UDim2.new(1, 0, 0, 0) },
	},
	table = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.XY
			frame.Size = UDim2.new(0, 0, 0, 0)

			-- Parse table attributes
			local attrs = props.attributes or {}
			local borderSize = tonumber(attrs.border) or 0
			local borderColor = attrs.bordercolor and ComponentRegistry.parseColor(attrs.bordercolor) or Color3.fromRGB(128, 128, 128)
			local cellSpacing = tonumber(attrs.cellspacing) or 2
			local cellPadding = tonumber(attrs.cellpadding) or 1
			
			-- Store these attributes for child elements to access
			frame:SetAttribute("TableBorder", borderSize)
			frame:SetAttribute("TableBorderColor", attrs.bordercolor or "#808080")
			frame:SetAttribute("CellSpacing", cellSpacing)
			frame:SetAttribute("CellPadding", cellPadding)
			
			-- Store all other attributes with sanitized names
			if props.attributes then
				for k, v in pairs(props.attributes) do
					-- Skip attributes we've already handled
					if k ~= "border" and k ~= "bordercolor" and k ~= "cellspacing" and k ~= "cellpadding" then
						local sanitizedKey = ComponentRegistry.sanitizeAttributeName(k)
						frame:SetAttribute(sanitizedKey, v)
					end
				end
			end
			
			-- Apply table border if specified
			if borderSize > 0 then
				local stroke = Instance.new("UIStroke")
				stroke.Parent = frame
				
				stroke.Thickness = borderSize
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				stroke.Color = borderColor
				
				-- Add a slight background color to match browser tables with borders
				frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				frame.BackgroundTransparency = 0
			else
				frame.BackgroundTransparency = 1
			end
			
			-- Set up layout for table rows
			local layout = Instance.new("UIListLayout")
			layout.Parent = frame
			layout.Padding = UDim.new(0, cellSpacing)
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			
			-- Add padding if needed for border
			if borderSize > 0 then
				local padding = Instance.new("UIPadding")
				padding.Parent = frame
				padding.PaddingTop = UDim.new(0, borderSize)
				padding.PaddingBottom = UDim.new(0, borderSize)
				padding.PaddingLeft = UDim.new(0, borderSize)
				padding.PaddingRight = UDim.new(0, borderSize)
			end

			-- Handle background color
			if attrs.bgcolor then
				frame.BackgroundColor3 = ComponentRegistry.parseColor(attrs.bgcolor)
				frame.BackgroundTransparency = 0
				frame:SetAttribute("BgColor", attrs.bgcolor)
			end

			return frame
		end,
		defaults = {},
	},
	thead = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
			
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			
			-- Get cellspacing from parent table if available
			local currentParent = props.parent
			while currentParent do
				if currentParent:GetAttribute("CellSpacing") then
					l.Padding = UDim.new(0, currentParent:GetAttribute("CellSpacing"))
					break
				end
				currentParent = currentParent.Parent
			end
			
			return frame
		end,
		defaults = {},
	},
	tbody = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			
			-- Get cellspacing from parent table if available
			local currentParent = props.parent
			while currentParent do
				if currentParent:GetAttribute("CellSpacing") then
					l.Padding = UDim.new(0, currentParent:GetAttribute("CellSpacing"))
					break
				end
				currentParent = currentParent.Parent
			end
			
			return frame
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	tfoot = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
			
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			
			-- Get cellspacing from parent table if available
			local currentParent = props.parent
			while currentParent do
				if currentParent:GetAttribute("CellSpacing") then
					l.Padding = UDim.new(0, currentParent:GetAttribute("CellSpacing"))
					break
				end
				currentParent = currentParent.Parent
			end
			
			return frame
		end,
		defaults = {},
	},
	colgroup = {
		create = function(props)
			-- In Roblox we can't directly style columns, but we can store column info
			-- for cells to reference later
			local frame = Instance.new("Frame")
			frame.Visible = false
			frame.Size = UDim2.new(0, 0, 0, 0)
			
			-- Store column attributes for later reference
			if props.attributes then
				for k, v in pairs(props.attributes) do
					frame:SetAttribute(k, v)
				end
			end
			
			return frame
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	col = {
		create = function(props)
			-- Similar to colgroup, this is just a placeholder to store column info
			local frame = Instance.new("Frame")
			frame.Visible = false
			frame.Size = UDim2.new(0, 0, 0, 0)
			
			-- Store column attributes for later reference
			if props.attributes then
				for k, v in pairs(props.attributes) do
					frame:SetAttribute(k, v)
				end
				
				-- Store width if specified
				if props.attributes.width then
					frame:SetAttribute("ColWidth", props.attributes.width)
				end
			end
			
			return frame
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	tr = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.SortOrder = Enum.SortOrder.LayoutOrder
			l.FillDirection = Enum.FillDirection.Horizontal
			l.VerticalAlignment = Enum.VerticalAlignment.Top
			
			-- Get cellspacing from parent table if available
			local currentParent = props.parent
			while currentParent do
				if currentParent:GetAttribute("CellSpacing") then
					l.Padding = UDim.new(0, currentParent:GetAttribute("CellSpacing"))
					break
				end
				currentParent = currentParent.Parent
			end
			
			-- Background color for row
			if props.attributes and props.attributes.bgcolor then
				frame.BackgroundColor3 = ComponentRegistry.parseColor(props.attributes.bgcolor)
				frame.BackgroundTransparency = 0
				frame:SetAttribute("BgColor", props.attributes.bgcolor)
			end
			
			return frame
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	td = {
		create = function(props)
			local label = Instance.new("TextLabel")
			
			-- Auto-size in both directions by default
			label.AutomaticSize = Enum.AutomaticSize.XY
			label.Size = UDim2.new(0, 0, 0, 0)
			
			-- Get table attributes from ancestors
			local hasBorder = false
			local borderColor = Color3.fromRGB(128, 128, 128)
			local cellPadding = 1 -- Browser default
			
			-- Find parent table to inherit attributes
			local currentParent = props.parent
			while currentParent do
				if currentParent:GetAttribute("TableBorder") then
					hasBorder = currentParent:GetAttribute("TableBorder") > 0
					
					if currentParent:GetAttribute("TableBorderColor") then
						borderColor = ComponentRegistry.parseColor(currentParent:GetAttribute("TableBorderColor"))
					end
					break
				end
				
				if currentParent:GetAttribute("CellPadding") then
					cellPadding = currentParent:GetAttribute("CellPadding")
					break
				end
				
				currentParent = currentParent.Parent
			end

			-- Cell content
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			
			-- Apply padding
			local padNum = tonumber(props.attributes and props.attributes.cellpadding) or cellPadding
			local p = Instance.new("UIPadding")
			p.Parent = label
			p.PaddingLeft = UDim.new(0, padNum)
			p.PaddingRight = UDim.new(0, padNum)
			p.PaddingTop = UDim.new(0, padNum)
			p.PaddingBottom = UDim.new(0, padNum)
			
			-- Apply border if table has border
			if hasBorder then
			local stroke = Instance.new("UIStroke")
			stroke.Parent = label
			stroke.Thickness = 1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				stroke.Color = borderColor
			end
			
			-- Handle colspan if specified
			if props.attributes and props.attributes.colspan then
				local colspan = tonumber(props.attributes.colspan) or 1
				if colspan > 1 then
					label:SetAttribute("ColSpan", colspan)
				end
			end

			return label
		end,
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 16 },
	},
	th = {
		create = function(props)
			-- Reuse td creation logic but customize for th
			local label = ComponentRegistry.registry.td.create(props)
			
			-- Override with th-specific styling
			label.Font = Enum.Font.SourceSansBold
			label.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
			label.BackgroundTransparency = 0
			
			-- Center text by default for headers
			label.TextXAlignment = Enum.TextXAlignment.Center
			
			return label
		end,
		defaults = { TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 16 },
	},
	img = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.XY
			frame.Size = UDim2.new(0, 0, 0, 0)
			frame.BackgroundTransparency = 1
			
			local img = Instance.new("ImageLabel")
			img.Parent = frame
			img.BackgroundTransparency = 1
			img.Size = UDim2.new(1, 0, 1, 0)
			img.ScaleType = Enum.ScaleType.Fit
			
			-- Default size if no width/height specified
			local defaultWidth = 100
			local defaultHeight = 100
			
			-- Handle width and height attributes
			if props.attributes then
				if props.attributes.src then
					img.Image = props.attributes.src
				end
				
				if props.attributes.width then
					local width = tonumber(props.attributes.width)
					if width then
						frame.Size = UDim2.new(0, width, frame.Size.Y.Scale, frame.Size.Y.Offset)
						defaultWidth = width
					end
				end
				
				if props.attributes.height then
					local height = tonumber(props.attributes.height)
					if height then
						frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, height)
						defaultHeight = height
					end
				end
				
				-- If neither width nor height specified, use defaults
				if not props.attributes.width and not props.attributes.height then
					frame.Size = UDim2.new(0, defaultWidth, 0, defaultHeight)
				end
				
				-- Handle alt text
				if props.attributes.alt then
					img:SetAttribute("Alt", props.attributes.alt)
					
					-- Create tooltip for alt text
					local tooltip = Instance.new("TextLabel")
					tooltip.Parent = frame
					tooltip.Visible = false
					tooltip.Text = props.attributes.alt
					tooltip.TextSize = 14
					tooltip.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
					tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
					tooltip.Size = UDim2.new(0, 200, 0, 50)
					tooltip.Position = UDim2.new(1, 5, 0, 0)
					tooltip.TextWrapped = true
					tooltip.ZIndex = 10
					
					local corner = Instance.new("UICorner")
					corner.Parent = tooltip
					corner.CornerRadius = UDim.new(0, 4)
					
					local padding = Instance.new("UIPadding")
					padding.Parent = tooltip
					padding.PaddingLeft = UDim.new(0, 5)
					padding.PaddingRight = UDim.new(0, 5)
					padding.PaddingTop = UDim.new(0, 5)
					padding.PaddingBottom = UDim.new(0, 5)
					
					-- Show tooltip on hover
					frame.MouseEnter:Connect(function()
						tooltip.Visible = true
					end)
					
					frame.MouseLeave:Connect(function()
						tooltip.Visible = false
					end)
				end
			end
			
			return frame
		end,
		defaults = {},
	},
	span = {
		create = function(props)
			-- Treated as a block element for now for layout simplicity
			-- A true inline element would require a different layout system
			local label = Instance.new("TextLabel")
			label.Name = "Span"
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Size = UDim2.new(1, 0, 0, 0)
			label.BackgroundTransparency = 1
			label.RichText = true
			label.Text = props.text or ""
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			return label
		end,
		defaults = { TextColor3 = Color3.fromRGB(0,0,0), Font = Enum.Font.SourceSans, TextSize = 16 },
	},
	strong = {
		create = function(props) return nil end,
	},
	b = {
		create = function(props) return nil end,
	},
	em = {
		create = function(props) return nil end,
	},
	i = {
		create = function(props) return nil end,
	},
	u = {
		create = function(props) return nil end,
	},
	small = {
		create = function(props) return nil end,
	},
	option = {
		create = function(props) return nil end,
	},
	code = {
		create = function(props) return nil end,
	},
	pre = {
		create = function(props)
			local label = Instance.new("TextLabel")
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Size = UDim2.new(1, 0, 0, 0)
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = false
			label.Font = Enum.Font.Code
			return label
		end,
		defaults = { BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 14 },
	},
	br = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 0, 17)
			frame.BackgroundTransparency = 1
			return frame
		end,
		defaults = {},
	},
	center = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			
			-- Create a UIListLayout to center children horizontally
			local layout = Instance.new("UIListLayout")
			layout.Parent = frame
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			layout.VerticalAlignment = Enum.VerticalAlignment.Center
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			
			return frame
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	font = {
		create = function(props)
			local label = Instance.new("TextLabel")
			label.AutomaticSize = Enum.AutomaticSize.XY -- Auto width and height
			label.Size = UDim2.new(0, 0, 0, 0)
			label.Text = props.text or ""
			label.RichText = true
			label.TextWrapped = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.BackgroundTransparency = 1
			
			-- Apply font attributes (color, size)
			if props.attributes then
				if props.attributes.color then
					label.TextColor3 = ComponentRegistry.parseColor(props.attributes.color)
				end
				if props.attributes.size then
					local size = tonumber(props.attributes.size)
					if size then
						-- HTML font sizes 1-7, convert to Roblox sizes
						local fontSizes = {[1]=10,[2]=12,[3]=14,[4]=16,[5]=18,[6]=24,[7]=32}
						label.TextSize = fontSizes[size] or (size * 4)
					end
				end
			end
			return label
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	caption = {
		create = function(props)
			local label = Instance.new("TextLabel")
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Size = UDim2.new(1, 0, 0, 0)
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Center
			label.TextWrapped = true
			
			-- Add padding
			local p = Instance.new("UIPadding")
			p.Parent = label
			p.PaddingTop = UDim.new(0, 5)
			p.PaddingBottom = UDim.new(0, 5)
			
			return label
		end,
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 16 },
	},
	link = {
		create = function(props)
			-- Create an invisible frame to represent the link tag
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(0, 0, 0, 0)
			frame.Visible = false
			frame.BackgroundTransparency = 1
			
			-- Store link attributes for external handling
			if props.attributes then
				for k, v in pairs(props.attributes) do
					frame:SetAttribute(k, v)
				end
				
				-- Special handling for stylesheet links
				if props.attributes.rel == "stylesheet" and props.attributes.href then
					frame:SetAttribute("StylesheetLink", props.attributes.href)
				end
				
				-- Special handling for favicon
				if props.attributes.rel == "icon" or props.attributes.rel == "shortcut icon" then
					frame:SetAttribute("Favicon", props.attributes.href)
				end
			end
			
			return frame
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	meta = {
		create = function(props)
			-- Create an invisible frame to represent the meta tag
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(0, 0, 0, 0)
			frame.Visible = false
			frame.BackgroundTransparency = 1
			
			-- Store meta attributes for external handling
			if props.attributes then
				for k, v in pairs(props.attributes) do
					frame:SetAttribute(k, v)
				end
				
				-- Special handling for viewport meta tag
				if props.attributes.name == "viewport" and props.attributes.content then
					frame:SetAttribute("Viewport", props.attributes.content)
				end
				
				-- Special handling for charset meta tag
				if props.attributes.charset then
					frame:SetAttribute("Charset", props.attributes.charset)
				end
				
				-- Special handling for description meta tag
				if props.attributes.name == "description" and props.attributes.content then
					frame:SetAttribute("Description", props.attributes.content)
				end
			end
			
			return frame
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	title = {
		create = function(props)
			-- Create an invisible frame to represent the title tag
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(0, 0, 0, 0)
			frame.Visible = false
			frame.BackgroundTransparency = 1
			
			-- Store title text for external handling
			if props.text then
				frame:SetAttribute("Title", props.text)
			end
			
			return frame
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	head = {
		create = function(props)
			-- Create an invisible frame to represent the head tag
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(0, 0, 0, 0)
			frame.Visible = false
			frame.BackgroundTransparency = 1
			frame.Name = "Head"
			
			return frame
		end,
		defaults = { BackgroundTransparency = 1 },
	},
}

function ComponentRegistry.create(tag, props, baseCssStyles, hoverCssStyles, activeCssStyles)
	local entry = ComponentRegistry.registry[tag]
	if not entry or not entry.create then 
		if tag:match("h%d") then
			entry = ComponentRegistry.registry.p -- Fallback for heading tags
		else
			return nil 
		end
	end
	local gui = entry.create(props or {})
	if not gui then return nil end

	applyRobloxProperties(gui, entry.defaults)

	if gui:IsA("GuiButton") then
		local transitionInfo = entry.transitions or TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local isHovering = false
		local function setFontForState(targetCssStyles, fallbackCssStyles, registryDefaults)
			local targetFont
			if targetCssStyles and targetCssStyles["font-weight"] then
				targetFont = (targetCssStyles["font-weight"] == "bold") and Enum.Font.SourceSansBold or Enum.Font.SourceSans
			elseif fallbackCssStyles and fallbackCssStyles["font-weight"] then
				targetFont = (fallbackCssStyles["font-weight"] == "bold") and Enum.Font.SourceSansBold or Enum.Font.SourceSans
			elseif registryDefaults and registryDefaults.Font then
				targetFont = registryDefaults.Font
			else
				targetFont = Enum.Font.SourceSans
			end
			gui.Font = targetFont
		end
		setFontForState(baseCssStyles, nil, entry.defaults)
		gui.MouseEnter:Connect(function()
			isHovering = true
			local currentHoverProps = ComponentRegistry.getTweenTargetProperties(entry.hover, hoverCssStyles, gui)
			TweenService:Create(gui, transitionInfo, currentHoverProps):Play()
			setFontForState(hoverCssStyles, baseCssStyles, entry.hover)
		end)
		gui.MouseLeave:Connect(function()
			isHovering = false
			local currentBaseProps = ComponentRegistry.getTweenTargetProperties({}, baseCssStyles, gui)
			TweenService:Create(gui, transitionInfo, currentBaseProps):Play()
			setFontForState(baseCssStyles, nil, entry.defaults)
		end)
		gui.MouseButton1Down:Connect(function()
			local currentActiveProps = ComponentRegistry.getTweenTargetProperties(entry.active, activeCssStyles, gui)
			TweenService:Create(gui, transitionInfo, currentActiveProps):Play()
			setFontForState(activeCssStyles, baseCssStyles, entry.active)
		end)
		gui.MouseButton1Up:Connect(function()
			if isHovering then
				local currentHoverProps = ComponentRegistry.getTweenTargetProperties(entry.hover, hoverCssStyles, gui)
				TweenService:Create(gui, transitionInfo, currentHoverProps):Play()
				setFontForState(hoverCssStyles, baseCssStyles, entry.hover)
			else
				local currentBaseProps = ComponentRegistry.getTweenTargetProperties({}, baseCssStyles, gui)
				TweenService:Create(gui, transitionInfo, currentBaseProps):Play()
				setFontForState(baseCssStyles, nil, entry.defaults)
			end
		end)
	end
	
	-- Inherit cellpadding/spacing from parent table for td/th
	if tag == "td" or tag == "th" then
		local currentParent = gui.Parent
		while currentParent do
			if currentParent:GetAttribute("CellPadding") then
				local pad = currentParent:GetAttribute("CellPadding")
				local paddingObj = gui:FindFirstChildOfClass("UIPadding")
				if paddingObj then
					paddingObj.PaddingLeft = UDim.new(0,pad)
					paddingObj.PaddingRight = UDim.new(0,pad)
					paddingObj.PaddingTop = UDim.new(0, math.floor(pad/2))
					paddingObj.PaddingBottom = UDim.new(0, math.floor(pad/2))
				end
				break
			end
			currentParent = currentParent.Parent
		end
	end
	return gui
end

return ComponentRegistry