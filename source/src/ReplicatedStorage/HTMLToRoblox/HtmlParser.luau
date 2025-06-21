local HtmlParser = {}

local VOID_ELEMENTS = {
	area = true, base = true, br = true, col = true, embed = true, hr = true,
	img = true, input = true, link = true, meta = true, param = true,
	source = true, track = true, wbr = true,
}

local HTML_ENTITIES = {
	["&amp;"] = "&",
	["&lt;"] = "<",
	["&gt;"] = ">",
	["&quot;"] = "\"",
	["&apos;"] = "'",
	["&nbsp;"] = " ",
	["&copy;"] = "©",
	["&reg;"] = "®",
	["&trade;"] = "™",
	["&hellip;"] = "…",
	["&mdash;"] = "—",
	["&ndash;"] = "–",
	["&lsquo;"] = "'",
	["&rsquo;"] = "'",
	["&ldquo;"] = "\"",
	["&rdquo;"] = "\"",
}

local function decodeEntities(text)
	if not text then return "" end
	text = tostring(text)
	for entity, char in pairs(HTML_ENTITIES) do
		text = text:gsub(entity, char)
	end
	return text
end

function HtmlParser.parseAttributes(attrString)
	local attrs = {}
	if not attrString then return attrs end

	for key, quote, value in attrString:gmatch("([%w%-]+)%s*=%s*([\"'])(.-)%2") do
		attrs[key:lower()] = decodeEntities(value)
	end

	for key in attrString:gmatch("([%w%-]+)%s*") do
		if attrs[key:lower()] == nil then
			attrs[key:lower()] = true
		end
	end

	return attrs
end

function HtmlParser.parse(html)
	local root = { tag = "root", attributes = {}, children = {} }
	local currentParent = root
	local stack = { root }
	local cursor = 1
	while cursor <= #html do
		local remainingHtml = html:sub(cursor)
		local commentMatch = remainingHtml:match("^<!--(.*?)-->", 1)
		if commentMatch then
			cursor = cursor + #commentMatch + 7
			continue
		else
			local doctypeMatch = remainingHtml:match("^<!DOCTYPE[^>]*>", 1)
			if doctypeMatch then
				cursor = cursor + #doctypeMatch
				continue
			else
				local fullSelfClosingTagMatch, selfClosingTagName, selfClosingAttrsString = remainingHtml:match("^(<([%w%-]+)([^/>]*)%s*/>)", 1)
				if fullSelfClosingTagMatch then
					local newNode = {
						tag = selfClosingTagName:lower(),
						attributes = HtmlParser.parseAttributes(selfClosingAttrsString),
						children = {},
					}
					table.insert(currentParent.children, newNode)
					cursor = cursor + #fullSelfClosingTagMatch
					continue
				else
					local fullOpenTagMatch, tagName, attrsString = remainingHtml:match("^(<([%w%-]+)([^>]*)>)", 1)
					if fullOpenTagMatch then
						tagName = tagName:lower()
						local newNode = {
							tag = tagName,
							attributes = HtmlParser.parseAttributes(attrsString),
							children = {},
						}
						table.insert(currentParent.children, newNode)

						if not VOID_ELEMENTS[tagName] then
							table.insert(stack, newNode)
							currentParent = newNode
						end
						cursor = cursor + #fullOpenTagMatch
						continue
					else
						local fullCloseTagMatch, closingTagName = remainingHtml:match("^(</([%w%-]+)>)", 1)
						if fullCloseTagMatch then
							closingTagName = closingTagName:lower()
							local foundMatch = false
							while #stack > 1 do
								if currentParent.tag == closingTagName then
									table.remove(stack)
									currentParent = stack[#stack]
									foundMatch = true
									break
								else
									warn("HTML Parsing Warning: Mismatched closing tag. Expected '" .. currentParent.tag .. "', got '" .. closingTagName .. "'. Popping stack.")
									table.remove(stack)
									currentParent = stack[#stack]
								end
							end
							if not foundMatch and #stack == 1 then
								warn("HTML Parsing Warning: Unmatched closing tag '" .. closingTagName .. "'. Stack is empty or root.")
							end

							cursor = cursor + #fullCloseTagMatch
							continue
						else
							local nextTagStart = remainingHtml:find("<", 1, true)
							if not nextTagStart then nextTagStart = #remainingHtml + 1 end
							local textContent = remainingHtml:sub(1, nextTagStart - 1)

							if #textContent > 0 then
								table.insert(currentParent.children, decodeEntities(textContent))
							end
							cursor = cursor + #textContent

							continue
						end
					end
				end
			end
		end
	end
	return root
end

return HtmlParser
