local TweenService = game:GetService("TweenService")
local ComponentRegistry = {}

function ComponentRegistry.parseColor(colorString)
	colorString = colorString:lower():gsub(" ", "")
	local NAMED_COLORS = {
		red = Color3.fromRGB(255, 0, 0),
		blue = Color3.fromRGB(0, 0, 255),
		green = Color3.fromRGB(0, 128, 0),
		black = Color3.fromRGB(0, 0, 0),
		white = Color3.fromRGB(255, 255, 255),
		grey = Color3.fromRGB(128, 128, 128),
		gray = Color3.fromRGB(128, 128, 128),
		transparent = Color3.new(0, 0, 0),
	}
	if NAMED_COLORS[colorString] then
		return NAMED_COLORS[colorString]
	end
	colorString = colorString:gsub("#", "")
	if #colorString == 6 then
		local r = tonumber(colorString:sub(1,2), 16)
		local g = tonumber(colorString:sub(3,4), 16)
		local b = tonumber(colorString:sub(5,6), 16)
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	end
	local rgbMatch = colorString:match("^rgb%((%d+),(%d+),(%d+)%)$")
	if rgbMatch then
		return Color3.fromRGB(tonumber(rgbMatch[1]), tonumber(rgbMatch[2]), tonumber(rgbMatch[3]))
	end
	return Color3.new(1,1,1)
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

local function applyRobloxProperties(gui, props)
	if not gui or not props then return end
	for key, value in pairs(props) do
		pcall(function()
			gui[key] = value
		end)
	end
end

local function applyStyleProperties(gui, styles)
	if not gui or not styles then return end
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
				if (gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox")) then
					if value == "bold" then
						gui.Font = Enum.Font.SourceSansBold
					else
						gui.Font = Enum.Font.SourceSans
					end
				end
			elseif key == "font-size" then
				if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
					local sizeNum = ComponentRegistry.parseSize(value)
					if sizeNum then gui.TextSize = sizeNum end
				end
			elseif key == "width" then
				local num, unit = value:match("^(%d+)(px|%%)$")
				if num then
					num = tonumber(num)
					gui.Size = UDim2.new(
						(unit == "%%" and num / 100) or 0,
						(unit == "px" and num) or 0,
						gui.Size.Y.Scale,
						gui.Size.Y.Offset
					)
				end
			elseif key == "height" then
				local num, unit = value:match("^(%d+)(px|%%)$")
				if num then
					num = tonumber(num)
					gui.Size = UDim2.new(
						gui.Size.X.Scale,
						gui.Size.X.Offset,
						(unit == "%%" and num / 100) or 0,
						(unit == "px" and num) or 0
					)
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
			end
		end)
	end
end

local function getTweenTargetProperties(registryStateProps, cssStateStyles, currentGui)
	local targetProps = {}
	if currentGui then
		targetProps.BackgroundColor3 = currentGui.BackgroundColor3
		targetProps.TextColor3 = currentGui.TextColor3
		targetProps.TextSize = currentGui.TextSize
		targetProps.BackgroundTransparency = currentGui.BackgroundTransparency
		targetProps.Size = currentGui.Size
	end
	if registryStateProps then
		for k, v in pairs(registryStateProps) do
			if (k == "BackgroundColor3" or k == "TextColor3" or k == "TextSize" or k == "BackgroundTransparency" or k == "Size") then
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
						targetProps.Size.Y.Scale,
						targetProps.Size.Y.Offset
					)
				end
			elseif k == "height" then
				local num, unit = v:match("^(%d+)(px|%%)$")
				if num then
					num = tonumber(num)
					targetProps.Size = UDim2.new(
						targetProps.Size.X.Scale,
						targetProps.Size.X.Offset,
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
		defaults = { BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 16, Size = UDim2.new(1, 0, 0, 0) },
	},
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
			textBox.Size = UDim2.new(1, 0, 0, 32)
			textBox.PlaceholderText = props.attributes and props.attributes.placeholder or ""
			textBox.Text = props.attributes and props.attributes.value or ""
			local padding = Instance.new("UIPadding")
			padding.Parent = textBox
			padding.PaddingLeft = UDim.new(0, 8)
			padding.PaddingRight = UDim.new(0, 8)
			local corner = Instance.new("UICorner")
			corner.Parent = textBox
			corner.CornerRadius = UDim.new(0, 4)
			local stroke = Instance.new("UIStroke")
			stroke.Parent = textBox
			stroke.Thickness = 1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Color = Color3.fromRGB(118, 118, 118)
			return textBox
		end,
		defaults = { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.SourceSans, TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 16 },
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

			return frame 
		end,
		defaults = { BackgroundTransparency = 1 },
	},
	div = {
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
	form = {
		create = function(props) 
			local frame = Instance.new("Frame")
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
			frame.BackgroundTransparency = 1
			local l = Instance.new("UIListLayout")
			l.Parent = frame
			l.Padding = UDim.new(0, 8)
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
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
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
			frame.AutomaticSize = Enum.AutomaticSize.Y
			frame.Size = UDim2.new(1, 0, 0, 0)
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
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Size = UDim2.new(0, 100, 0, 0)
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
			label.Size = UDim2.new(0, 100, 0, 0)
			label.Text = props.text or ""
			label.RichText = true
			label.TextXAlignment = Enum.TextXAlignment.Left
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
	img = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(0, 200, 0, 150)
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
			return frame
		end,
		defaults = {},
	},
	span = {
		create = function(props) return nil end,
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
	code = {
		create = function(props) return nil end,
	},
	pre = {
		create = function(props)
			local label = Instance.new("TextLabel")
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.Text = props.text or ""
			label.RichText = false
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
	br = {
		create = function(props)
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 0, 10)
			frame.BackgroundTransparency = 1
			return frame
		end,
		defaults = {},
	},
}

function ComponentRegistry.create(tag, props, baseCssStyles, hoverCssStyles, activeCssStyles)
	print("tag: " .. tag)
	print(props)
	print(baseCssStyles)
	print(hoverCssStyles)
	print(activeCssStyles)
	local entry = ComponentRegistry.registry[tag]
	if not entry or not entry.create then return nil end
	local gui = entry.create(props or {})
	if not gui then return nil end
	applyRobloxProperties(gui, entry.defaults)
	if baseCssStyles then
		applyStyleProperties(gui, baseCssStyles)
	end
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
			local currentHoverProps = getTweenTargetProperties(entry.hover, hoverCssStyles, gui)
			TweenService:Create(gui, transitionInfo, currentHoverProps):Play()
			setFontForState(hoverCssStyles, baseCssStyles, entry.hover)
		end)
		gui.MouseLeave:Connect(function()
			isHovering = false
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
			if isHovering then
				local currentHoverProps = getTweenTargetProperties(entry.hover, hoverCssStyles, gui)
				TweenService:Create(gui, transitionInfo, currentHoverProps):Play()
				setFontForState(hoverCssStyles, baseCssStyles, entry.hover)
			else
				local currentBaseProps = getTweenTargetProperties({}, baseCssStyles, gui)
				TweenService:Create(gui, transitionInfo, currentBaseProps):Play()
				setFontForState(baseCssStyles, nil, entry.defaults)
			end
		end)
	end
	return gui
end

return ComponentRegistry