-- HtmlParser.lua
local HtmlParser = {}

-- A comprehensive list of void elements (self-closing tags in HTML5)
local VOID_ELEMENTS = {
	area = true, base = true, br = true, col = true, embed = true, hr = true,
	img = true, input = true, link = true, meta = true, param = true,
	source = true, track = true, wbr = true,
}

-- HTML entities mapping for decoding purposes
local HTML_ENTITIES = {
	["&amp;"] = "&",
	["&lt;"] = "<",
	["&gt;"] = ">",
	["&quot;"] = "\"", -- Corrected: escaped double quote
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
	["&ldquo;"] = "\"", -- Corrected: escaped double quote
	["&rdquo;"] = "\"", -- Corrected: escaped double quote
	-- Add more common entities as needed
}

-- Function to decode HTML entities in a string
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

	-- Now capture boolean attributes (e.g. `disabled`, `checked`, etc.)
	for key in attrString:gmatch("([%w%-]+)%s*") do
		if attrs[key:lower()] == nil then
			attrs[key:lower()] = true
		end
	end

	return attrs
end

-- Main HTML parsing function
function HtmlParser.parse(html)
	local root = { tag = "root", attributes = {}, children = {} }
	local currentParent = root
	local stack = { root } -- Stack to keep track of parent elements for nesting

	local cursor = 1
	while cursor <= #html do
		local remainingHtml = html:sub(cursor)

		-- Match HTML comments (<!-- ... -->)
		local commentMatch = remainingHtml:match("^<!--(.*?)-->", 1)
		if commentMatch then
			cursor = cursor + #commentMatch + 7
			continue
		else
			-- Match DOCTYPE declaration (<!DOCTYPE ...>)
			local doctypeMatch = remainingHtml:match("^<!DOCTYPE[^>]*>", 1)
			if doctypeMatch then
				cursor = cursor + #doctypeMatch
				continue
			else
				-- Match full self-closing tags (e.g., <img src="x" /> or <br/>)
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
					-- Match open tags (e.g., <div> or <p class="text">)
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
							-- It's a regular tag, push it to the stack to wait for a closing tag
							table.insert(stack, newNode)
							currentParent = newNode
						end
						cursor = cursor + #fullOpenTagMatch
						continue
					else
						-- Match close tags (e.g., </div> or </p>)
						local fullCloseTagMatch, closingTagName = remainingHtml:match("^(</([%w%-]+)>)", 1)
						if fullCloseTagMatch then
							closingTagName = closingTagName:lower()
							-- Pop elements from the stack until we find the matching opening tag
							local foundMatch = false
							while #stack > 1 do
								if currentParent.tag == closingTagName then
									table.remove(stack) -- Pop the matching tag
									currentParent = stack[#stack] -- Set new current parent
									foundMatch = true
									break
								else
									-- If the current parent doesn't match, it might be an implicitly closed tag
									-- or malformed HTML. For robustness, we pop it.
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
							-- Handles text content between tags
							-- Find the next '<' character, or assume the rest is text
							local nextTagStart = remainingHtml:find("<", 1, true)
							if not nextTagStart then nextTagStart = #remainingHtml + 1 end
							local textContent = remainingHtml:sub(1, nextTagStart - 1)

							if #textContent > 0 then
								-- Insert raw text. RichText will handle whitespace collapsing.
								table.insert(currentParent.children, decodeEntities(textContent)) -- Decode entities in text content
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
