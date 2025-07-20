-- ComponentRegistry.lua
local TweenService = game:GetService("TweenService")

local ComponentRegistry = {}





-- Helper to parse CSS color strings (hex, rgb) into Color3
function ComponentRegistry.parseColor(colorString)
	colorString = colorString:lower():gsub(" ", "") -- Normalize

	-- Try named colors first
	local NAMED_COLORS = {
		red = Color3.fromRGB(255, 0, 0),
		orange = Color3.fromRGB(255, 165, 0),
		blue = Color3.fromRGB(0, 0, 255),
		green = Color3.fromRGB(0, 128, 0),
		black = Color3.fromRGB(0, 0, 0),
		white = Color3.fromRGB(255, 255, 255),
		grey = Color3.fromRGB(128, 128, 128),
		gray = Color3.fromRGB(128, 128, 128),
		lime = Color3.fromRGB(0, 255, 0),
		transparent = Color3.new(0, 0, 0), -- Placeholder for transparent, will be handled by BackgroundTransparency
		-- Add more named colors here
	}

	if NAMED_COLORS[colorString] then
		return NAMED_COLORS[colorString]
	end

	-- Try hex color #RRGGBB or RRGGBB
	colorString = colorString:gsub("#", "")
	if #colorString == 6 then
		local r = tonumber(colorString:sub(1,2), 16)
		local g = tonumber(colorString:sub(3,4), 16)
		local b = tonumber(colorString:sub(5,6), 16)
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	end

	-- Try RGB color rgb(r,g,b)
	local rgbMatch = colorString:match("^rgb%((%d+),(%d+),(%d+)%)$")
	if rgbMatch then
		return Color3.fromRGB(tonumber(rgbMatch[1]), tonumber(rgbMatch[2]), tonumber(rgbMatch[3]))
	end

	-- Default fallback
	return Color3.new(1,1,1) -- Default to white if parsing fails
end

-- Helper to parse CSS size strings (e.g., "16px") into a number
function ComponentRegistry.parseSize(sizeString)
	if not sizeString then return nil end
	sizeString = sizeString:lower():gsub(" ", "") -- Normalize

	local pxMatch = sizeString:match("^(%d+)px$")
	if pxMatch then
		return tonumber(pxMatch)
	end

	-- Add other units if necessary (e.g., em, pt, %, but requires context)
	return nil
end

-- Helper to apply direct Roblox properties (from entry.defaults, entry.hover, entry.active)
local function applyRobloxProperties(gui, props)
	if not gui or not props then return end
	for key, value in pairs(props) do
		pcall(function()
			gui[key] = value
		end)
	end
end

-- This function converts any style source (registry or CSS) into a flat table
-- suitable for TweenInfo.Properties. It prioritizes CSS strings.
-- 'currentGui' is used to correctly merge UDim2 components if only one dimension is specified by CSS.
local function getTweenTargetProperties(registryStateProps, cssStateStyles, currentGui)
	local targetProps = {}

	-- Initialize targetProps with current GUI's properties.
	-- This is crucial for UDim2s when only one dimension is specified by CSS,
	-- or for properties not covered by registryStateProps/cssStateStyles.
	if currentGui then
		targetProps.BackgroundColor3 = currentGui.BackgroundColor3
		targetProps.TextColor3 = currentGui.TextColor3
		targetProps.TextSize = currentGui.TextSize
		targetProps.BackgroundTransparency = currentGui.BackgroundTransparency
		targetProps.Size = currentGui.Size -- Start with current size
	end

	-- 1. Apply Roblox property values from registryStateProps (e.g., entry.defaults or entry.hover).
	-- These are the *default* values for the component type's state (base, hover, active).
	if registryStateProps then
		for k, v in pairs(registryStateProps) do
			-- Only include properties that are tweenable. Exclude 'Font'.
			if (k == "BackgroundColor3" or k == "TextColor3" or k == "TextSize" or k == "BackgroundTransparency" or k == "Size") then
				-- For Size, merge components, don't just overwrite
				if k == "Size" then
					targetProps.Size = UDim2.new(
						v.X.Scale, v.X.Offset,
						v.Y.Scale, v.Y.Offset
					)
				else
					targetProps[k] = v
				end
			end
		end
	end

	-- 2. Overlay CSS properties (these are strings and need parsing).
	-- These *must* take precedence over registryStateProps.
	if cssStateStyles then
		for k, v in pairs(cssStateStyles) do
			if k == "background-color" then
				targetProps.BackgroundColor3 = ComponentRegistry.parseColor(v)
				targetProps.BackgroundTransparency = 0
			elseif k == "color" then
				targetProps.TextColor3 = ComponentRegistry.parseColor(v)
			elseif k == "font-size" then
				local size = ComponentRegistry.parseSize(v)
				if size then targetProps.TextSize = size end
			elseif k == "width" then
				local num, unit = v:match("^(%d+)(px|%%)$")
				if num then
					num = tonumber(num)
					targetProps.Size = UDim2.new(
						(unit == "%%" and num / 100) or 0,
						(unit == "px" and num) or 0,
						targetProps.Size.Y.Scale, -- Preserve Y from current targetProps
						targetProps.Size.Y.Offset  -- Preserve Y from current targetProps
					)
				end
			elseif k == "height" then
				local num, unit = v:match("^(%d+)(px|%%)$")
				if num then
					num = tonumber(num)
					targetProps.Size = UDim2.new(
						targetProps.Size.X.Scale, -- Preserve X from current targetProps
						targetProps.Size.X.Offset,  -- Preserve X from current targetProps
						(unit == "%%" and num / 100) or 0,
						(unit == "px" and num) or 0
					)
				end
			end
		end
	end

	return targetProps
end


ComponentRegistry.registry = {
	-- Headings
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

	-- Text elements
	p = {
		create = function(props) 
			local label = Instance.new("TextLabel") 
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			local p = Instance.new("UIPadding")
			p.Parent = label
			p.PaddingBottom = UDim.new(0, 14)
			return label 
		end,
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextColor3 = Color3.fromRGB(51, 51, 51), TextSize = 16, Size = UDim2.new(1, 0, 0, 0) },
	},

	center = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0) -- Full width, auto height
			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Vertical
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = frame
			return frame
		end,
		defaults = { BackgroundTransparency = 1 },
	},

	font = {
		isRichText = true,
		create = function(props)
			local label = Instance.new("TextLabel")
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			return label
		end,
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 16, Size = UDim2.new(1, 0, 0, 0) },
	},

	body = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.Name = "Body"
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			local layout = Instance.new("UIListLayout")
			layout.Parent = frame
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			return frame
		end,
		defaults = { BackgroundTransparency = 1 },
	},

	-- Interactive elements
	button = {
		create = function(props)
			local btn = Instance.new("TextButton")
			btn.AutomaticSize = Enum.AutomaticSize.XY
			btn.Text = props.text or "Button"
			btn.RichText = true
			btn.TextWrapped = true
			local padding = Instance.new("UIPadding")
			padding.Parent = btn
			padding.PaddingLeft = UDim.new(0, 7)
			padding.PaddingRight = UDim.new(0, 7)
			padding.PaddingTop = UDim.new(0, 3)
			padding.PaddingBottom = UDim.new(0, 3)
			local corner = Instance.new("UICorner")
			corner.Parent = btn
			corner.CornerRadius = UDim.new(0, 4)
			local stroke = Instance.new("UIStroke")
			stroke.Parent = btn
			stroke.Thickness = 1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = Color3.fromRGB(118, 118, 118)
			return btn
		end,
		defaults = { BackgroundColor3 = Color3.fromRGB(239, 239, 239), Font = Enum.Font.SourceSans, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 16, AutoButtonColor = false, },
		hover = { BackgroundColor3 = Color3.fromRGB(229, 241, 251) },
		active = { BackgroundColor3 = Color3.fromRGB(204, 228, 247) },
		transitions = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	},

	input = {
		create = function(props)
			local textBox = Instance.new("TextBox")
			textBox.Size = UDim2.new(0, 169, 0, 15)
			textBox.PlaceholderText = props.attributes and props.attributes.placeholder or ""
			textBox.Text = props.attributes and props.attributes.value or ""
			textBox.TextXAlignment = Enum.TextXAlignment.Left
			textBox.ClipsDescendants = true
			textBox.ClearTextOnFocus = false
			local padding = Instance.new("UIPadding")
			padding.Parent = textBox
			padding.PaddingLeft = UDim.new(0, 2)
			padding.PaddingRight = UDim.new(0, 2)
			padding.PaddingTop = UDim.new(0, 1)
			padding.PaddingBottom = UDim.new(0, 1)
			local corner = Instance.new("UICorner")
			corner.Parent = textBox
			corner.CornerRadius = UDim.new(0, 1)
			local stroke = Instance.new("UIStroke")
			stroke.Parent = textBox
			stroke.Thickness = 1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = Color3.fromRGB(118, 118, 118)
			return textBox
		end,
		defaults = { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.SourceSans, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 14 },
	},

	a = {
		create = function(props) 
			local label = Instance.new("TextButton") 
			label.AutomaticSize = Enum.AutomaticSize.XY
			label.Text = props.text or ""
			label.RichText = true
			label.TextWrapped = true
			return label 
		end,
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextColor3 = Color3.fromRGB(0, 0, 238), TextSize = 16, AutoButtonColor = false, },
		hover = { TextColor3 = Color3.fromRGB(0, 0, 200) },
		active = { TextColor3 = Color3.fromRGB(238, 0, 0) },
		transitions = TweenInfo.new(0.1, Enum.EasingStyle.Linear),
	},

	-- Lists
	ul = {
		create = function(props) 
			local frame = Instance.new("Frame") 
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.Padding = UDim.new(0, 2)
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
			l.Padding = UDim.new(0, 2)
			local p = Instance.new("UIPadding")
			p.Parent = frame
			p.PaddingLeft = UDim.new(0, 20)
			p.PaddingTop = UDim.new(0, 8)
			p.PaddingBottom = UDim.new(0, 8)
			-- Store counter for ordered list
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
			bullet.Text = "•" -- Will be overridden for ordered lists
			bullet.Size = UDim2.new(0, 20, 0, 20)
			bullet.BackgroundTransparency = 1
			bullet.Font = Enum.Font.SourceSans
			bullet.TextSize = 16
			bullet.TextYAlignment = Enum.TextYAlignment.Top
			bullet.TextXAlignment = Enum.TextXAlignment.Left

			return frame 
		end,
		defaults = { BackgroundTransparency = 1 },
	},

	-- Block elements
	div = {
		create = function(props)
			local frame = Instance.new("Frame")
			-- Setting AutomaticSize to Y by default for containers is often desired
			frame.AutomaticSize = Enum.AutomaticSize.Y 
			local layout = Instance.new("UIListLayout")
			layout.Parent = frame
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			return frame
		end,
		defaults = { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0) },
	},

	br = {
		create = function(props)
			-- Creates a small, invisible frame to act as a line break in UIListLayouts
			local frame = Instance.new("Frame")
			frame.Name = "br"
			frame.Size = UDim2.new(1, 0, 0, 16) -- Height of a standard line of text
			frame.BackgroundTransparency = 1
			return frame
		end,
		defaults = {},
	},

	select = {
		create = function(props)
			local container = Instance.new("Frame")
			container.Name = "SelectDropdown"
			container.Size = UDim2.new(0, 200, 0, 30)
			container.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
			container.BorderSizePixel = 1
			container.ClipsDescendants = false -- Allow options to show outside

			local selectedLabel = Instance.new("TextButton")
			selectedLabel.Name = "SelectedLabel"
			selectedLabel.Parent = container
			selectedLabel.Size = UDim2.new(1, 0, 1, 0)
			selectedLabel.Text = "Select an option..."
			selectedLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			selectedLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
			selectedLabel.Font = Enum.Font.SourceSans

			local optionsFrame = Instance.new("ScrollingFrame")
			optionsFrame.Name = "OptionsFrame"
			optionsFrame.Parent = container
			optionsFrame.Size = UDim2.new(1, 0, 4, 0) -- Show height for 4 options
			optionsFrame.Position = UDim2.new(0, 0, 1, 2) -- Position below the main button
			optionsFrame.Visible = false
			optionsFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
			optionsFrame.BorderSizePixel = 1
			optionsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
			optionsFrame.ZIndex = 2 -- Ensure it renders above other elements

			local listLayout = Instance.new("UIListLayout")
			listLayout.Parent = optionsFrame
			listLayout.SortOrder = Enum.SortOrder.LayoutOrder
			listLayout.Padding = UDim.new(0, 2)

			selectedLabel.MouseButton1Click:Connect(function()
				optionsFrame.Visible = not optionsFrame.Visible
			end)

			return container
		end,
		defaults = { BackgroundTransparency = 1 },
	},

	option = {
		create = function(props)
			local optionButton = Instance.new("TextButton")
			optionButton.Name = "OptionButton"
			optionButton.Size = UDim2.new(1, 0, 0, 25)
			optionButton.Text = props.text or ""
			optionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			optionButton.TextColor3 = Color3.fromRGB(30, 30, 30)
			optionButton.Font = Enum.Font.SourceSans
			optionButton.TextXAlignment = Enum.TextXAlignment.Left

			local padding = Instance.new("UIPadding")
			padding.PaddingLeft = UDim.new(0, 5)
			padding.Parent = optionButton

			optionButton.MouseButton1Click:Connect(function()
				local selectContainer = optionButton.Parent.Parent
				if selectContainer and selectContainer.Name == "SelectDropdown" then
					local selectedLabel = selectContainer:FindFirstChild("SelectedLabel")
					local optionsFrame = selectContainer:FindFirstChild("OptionsFrame")
					if selectedLabel then
						selectedLabel.Text = optionButton.Text
					end
					if optionsFrame then
						optionsFrame.Visible = false
					end
				end
			end)

			return optionButton
		end,
		defaults = { BackgroundTransparency = 0 },
	},

	section = {
		create = function(props) 
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local l = Instance.new("UIListLayout")
			l.Parent = frame
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
			l.FillDirection = Enum.FillDirection.Horizontal
			l.Padding = UDim.new(0, 8)
			return frame 
		end,
		defaults = { BackgroundTransparency = 1 },
	},

	-- Formatting elements
	blockquote = {
		create = function(props) 
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundColor3 = Color3.fromRGB(248, 248, 248)
			local l = Instance.new("UIListLayout")
			l.Parent = frame
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
			frame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
			frame.BorderSizePixel = 0
			local p = Instance.new("UIPadding")
			p.Parent = frame
			p.PaddingTop = UDim.new(0, 8)
			p.PaddingBottom = UDim.new(0, 8)
			return frame
		end,
		defaults = {},
	},

	-- Form elements
	form = {
		create = function(props) 
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.Padding = UDim.new(0, 8)
			l.SortOrder = Enum.SortOrder.LayoutOrder
			l.FillDirection = Enum.FillDirection.Horizontal
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

	-- Table elements
	table = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.XY
			frame.Size = UDim2.new(0, 0, 0, 0)
			frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			local stroke = Instance.new("UIStroke")
			stroke.Parent = frame
			stroke.Thickness = 1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = Color3.fromRGB(200, 200, 200)
			local l = Instance.new("UIListLayout")
			l.Parent = frame
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
			return frame
		end,
		defaults = { BackgroundTransparency = 1 },
	},

	tr = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.XY
			frame.Size = UDim2.new(0, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local stroke = Instance.new("UIStroke")
			stroke.Parent = frame
			stroke.Thickness = 1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = Color3.fromRGB(200, 200, 200)
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.FillDirection = Enum.FillDirection.Horizontal
			return frame
		end,
		defaults = {},
	},

	td = {
		create = function(props)
			local label = Instance.new("TextLabel")
			label.AutomaticSize = Enum.AutomaticSize.XY
			label.Size = UDim2.new(0, 100, 0, 0) -- Default width, can be overridden
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			local p = Instance.new("UIPadding")
			p.Parent = label
			p.PaddingLeft = UDim.new(0, 8)
			p.PaddingRight = UDim.new(0, 8)
			p.PaddingTop = UDim.new(0, 4)
			p.PaddingBottom = UDim.new(0, 4)
			local stroke = Instance.new("UIStroke")
			stroke.Parent = label
			stroke.Thickness = 1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = Color3.fromRGB(200, 200, 200)
			return label
		end,
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 14 },
	},

	th = {
		create = function(props)
			local label = Instance.new("TextLabel")
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Size = UDim2.new(0, 100, 0, 0) -- Default width, can be overridden
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Center
			label.TextWrapped = true
			local p = Instance.new("UIPadding")
			p.Parent = label
			p.PaddingLeft = UDim.new(0, 8)
			p.PaddingRight = UDim.new(0, 8)
			p.PaddingTop = UDim.new(0, 6)
			p.PaddingBottom = UDim.new(0, 6)
			local stroke = Instance.new("UIStroke")
			stroke.Parent = label
			stroke.Thickness = 1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = Color3.fromRGB(200, 200, 200)
			return label
		end,
		defaults = { BackgroundColor3 = Color3.fromRGB(240, 240, 240), Font = Enum.Font.SourceSansBold, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 14 },
	},

	-- Media elements
	img = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(0, 200, 0, 150) -- Default size
			frame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
			local stroke = Instance.new("UIStroke")
			stroke.Parent = frame
			stroke.Thickness = 1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = Color3.fromRGB(200, 200, 200)
			local label = Instance.new("TextLabel")
			label.Parent = frame
			label.Size = UDim2.new(1, 0, 1, 0)
			label.Text = "Image"
			label.TextColor3 = Color3.fromRGB(100, 100, 100)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.SourceSans
			label.TextSize = 14
			-- Note: In a real implementation, you'd load the image from props.attributes.src
			return frame
		end,
		defaults = {},
	},

	pre = {
		create = function(props)
			local label = Instance.new("TextLabel")
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Text = props.text or ""
			label.RichText = false -- Pre should preserve formatting
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			label.BackgroundColor3 = Color3.fromRGB(248, 248, 248)
			local p = Instance.new("UIPadding")
			p.Parent = label
			p.PaddingLeft = UDim.new(0, 12)
			p.PaddingRight = UDim.new(0, 12)
			p.PaddingTop = UDim.new(0, 8)
			p.PaddingBottom = UDim.new(0, 8)
			local corner = Instance.new("UICorner")
			corner.Parent = label
			corner.CornerRadius = UDim.new(0, 4)
			return label
		end,
		defaults = { Font = Enum.Font.RobotoMono, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 14, Size = UDim2.new(1, 0, 0, 0) },
	},
	
	
	
	---------------------------------------------------------
	-- Forced To Ignore
	---------------------------------------------------------
	-- Anything set with nil contents will be ignored from the unsupported checks (booleans won't work here due to different code handling).
	---------------------------------------------------------
	["#comment"] = {}
}



function ComponentRegistry.create(tag, props, baseCssStyles, hoverCssStyles, activeCssStyles)
	--[[
	print("tag: " .. tag)
	print(props)
	print(baseCssStyles)
	print(hoverCssStyles)
	print(activeCssStyles)
	]]
	local entry = ComponentRegistry.registry[tag]
	if not entry or not entry.create then return nil end

	-- Create the base GUI object (this applies initial UDim2 sizes, UI layouts etc. from entry.create)
	local gui = entry.create(props or {})
	if not gui then return nil end

	-- Apply component's internal defaults (direct Roblox property assignments like BackgroundColor3, Font etc.)
	applyRobloxProperties(gui, entry.defaults)

	-- Handle interactive elements (buttons, links)
	if gui:IsA("GuiButton") then
		local transitionInfo = entry.transitions or TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		-- Track hover state to know what to revert to after :active ends
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

		-- Set initial font
		setFontForState(baseCssStyles, nil, entry.defaults)

		gui.MouseEnter:Connect(function()
			isHovering = true
			local currentHoverProps = getTweenTargetProperties(entry.hover, hoverCssStyles, gui)
			TweenService:Create(gui, transitionInfo, currentHoverProps):Play()
			setFontForState(hoverCssStyles, baseCssStyles, entry.hover)
		end)

		gui.MouseLeave:Connect(function()
			isHovering = false
			-- Always revert to base style on leave
			local currentBaseProps = getTweenTargetProperties({}, baseCssStyles, gui)
			TweenService:Create(gui, transitionInfo, currentBaseProps):Play()
			setFontForState(baseCssStyles, nil, entry.defaults)
		end)

		gui.MouseButton1Down:Connect(function()
			local currentActiveProps = getTweenTargetProperties(entry.active, activeCssStyles, gui)
			TweenService:Create(gui, transitionInfo, currentActiveProps):Play()
			setFontForState(activeCssStyles, baseCssStyles, entry.active)
		end)

		gui.MouseButton1Up:Connect(function()
			-- FIXED: Check if mouse is still hovering to decide what state to revert to
			if isHovering then
				-- Mouse is still over the button, revert to hover state
				local currentHoverProps = getTweenTargetProperties(entry.hover, hoverCssStyles, gui)
				TweenService:Create(gui, transitionInfo, currentHoverProps):Play()
				setFontForState(hoverCssStyles, baseCssStyles, entry.hover)
			else
				-- Mouse has left the button, revert to base state
				local currentBaseProps = getTweenTargetProperties({}, baseCssStyles, gui)
				TweenService:Create(gui, transitionInfo, currentBaseProps):Play()
				setFontForState(baseCssStyles, nil, entry.defaults)
			end
		end)
	end

	return gui
end



return ComponentRegistry