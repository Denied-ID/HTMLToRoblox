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
	-- Additional common entities
	["&bull;"] = "•",
	["&middot;"] = "·",
	["&laquo;"] = "«",
	["&raquo;"] = "»",
	["&times;"] = "×",
	["&divide;"] = "÷",
	["&cent;"] = "¢",
	["&pound;"] = "£",
	["&euro;"] = "€",
	["&yen;"] = "¥",
	["&sect;"] = "§",
	["&deg;"] = "°",
	["&plusmn;"] = "±",
	["&para;"] = "¶",
	["&micro;"] = "µ",
	["&not;"] = "¬",
	["&frac14;"] = "¼",
	["&frac12;"] = "½",
	["&frac34;"] = "¾",
	["&iexcl;"] = "¡",
	["&iquest;"] = "¿",
	["&szlig;"] = "ß",
	["&agrave;"] = "à",
	["&aacute;"] = "á",
	["&acirc;"] = "â",
	["&atilde;"] = "ã",
	["&auml;"] = "ä",
	["&aring;"] = "å",
	["&aelig;"] = "æ",
	["&ccedil;"] = "ç",
	["&egrave;"] = "è",
	["&eacute;"] = "é",
	["&ecirc;"] = "ê",
	["&euml;"] = "ë",
	["&igrave;"] = "ì",
	["&iacute;"] = "í",
	["&icirc;"] = "î",
	["&iuml;"] = "ï",
	["&ntilde;"] = "ñ",
	["&ograve;"] = "ò",
	["&oacute;"] = "ó",
	["&ocirc;"] = "ô",
	["&otilde;"] = "õ",
	["&ouml;"] = "ö",
	["&oslash;"] = "ø",
	["&ugrave;"] = "ù",
	["&uacute;"] = "ú",
	["&ucirc;"] = "û",
	["&uuml;"] = "ü",
	["&yuml;"] = "ÿ",
}

local function decodeEntities(text)
	if not text then return "" end
	text = tostring(text)
	
	-- Replace named entities
	for entity, char in pairs(HTML_ENTITIES) do
		text = text:gsub(entity, char)
	end
	
	-- Replace decimal numeric entities (&#nnnn;)
	text = text:gsub("&#(%d+);", function(decimal)
		local num = tonumber(decimal)
		if num and num >= 32 and num <= 65535 then
			return utf8.char(num)
		end
		return ""
	end)
	
	-- Replace hexadecimal numeric entities (&#xhhhh;)
	text = text:gsub("&#[xX](%x+);", function(hex)
		local num = tonumber("0x" .. hex)
		if num and num >= 32 and num <= 65535 then
			return utf8.char(num)
		end
		return ""
	end)
	
	return text
end

function HtmlParser.parseAttributes(attrString)
	local attrs = {}
	if not attrString then return attrs end

	-- 1) Handle key="value" or key='value' first (quoted values)
	for key, quote, value in attrString:gmatch("([%w%-:]+)%s*=%s*([\"'])(.-)%2") do
		attrs[key:lower()] = decodeEntities(value)
	end

	-- 2) Handle key=value where value is unquoted and stops at whitespace or >
	for key, value in attrString:gmatch("([%w%-:]+)%s*=%s*([^\"'%s>]+)") do
		if attrs[key:lower()] == nil then
			attrs[key:lower()] = decodeEntities(value)
		end
	end

	-- 3) Handle boolean attributes (e.g. disabled, checked)
	for key in attrString:gmatch("([%w%-:]+)%s*") do
		if attrs[key:lower()] == nil then
			attrs[key:lower()] = true
		end
	end

	return attrs
end

function HtmlParser.parse(html)
	if not html or html == "" then
		return { tag = "root", attributes = {}, children = {} }
	end
	
	local root = { tag = "root", attributes = {}, children = {} }
	local currentParent = root
	local stack = { root }
	local cursor = 1
	local maxIterations = #html * 2
	local iterations = 0
	
	-- Track head and title content for metadata
	local headContent = { tag = "head", attributes = {}, children = {} }
	local titleContent = ""
	local metaTags = {}
	
	while cursor <= #html and iterations < maxIterations do
		iterations = iterations + 1
		local remainingHtml = html:sub(cursor)
		local matched = false
		
		local whitespaceMatch = remainingHtml:match("^%s+")
		if whitespaceMatch and cursor == 1 then
			cursor = cursor + #whitespaceMatch
			continue
		end
		
		local commentStart, commentEnd = remainingHtml:find("<!%-%-(.-)%-%->")
		if commentStart == 1 then
			cursor = cursor + commentEnd
			matched = true
			continue
		end
		
		local doctypeStart, doctypeEnd = remainingHtml:find("<!DOCTYPE[^>]*>")
		if doctypeStart == 1 then
			cursor = cursor + doctypeEnd
			matched = true
			continue
		end
		
		local selfClosingStart, selfClosingEnd, tagName, attrsString = remainingHtml:find("^<([%w%-]+)([^/>]*)%s*/>")
		if selfClosingStart then
			local newNode = {
				tag = tagName:lower(),
				attributes = HtmlParser.parseAttributes(attrsString),
				children = {},
			}
			
			-- Track meta tags
			if newNode.tag == "meta" then
				table.insert(metaTags, newNode)
			end
			
			table.insert(currentParent.children, newNode)
			cursor = cursor + selfClosingEnd
			matched = true
			continue
		end
		
		local openStart, openEnd, openTagName, openAttrsString = remainingHtml:find("^<([%w%-]+)([^>]*)>")
		if openStart then
			openTagName = openTagName:lower()
			local newNode = {
				tag = openTagName,
				attributes = HtmlParser.parseAttributes(openAttrsString),
				children = {},
			}
			
			-- Special handling for head tag
			if openTagName == "head" then
				headContent = newNode
			end
			
			table.insert(currentParent.children, newNode)

			if not VOID_ELEMENTS[openTagName] then
				table.insert(stack, newNode)
				currentParent = newNode
			end
			cursor = cursor + openEnd
			matched = true
			continue
		end
		
		local closeStart, closeEnd, closeTagName = remainingHtml:find("^</([%w%-]+)>")
		if closeStart then
			closeTagName = closeTagName:lower()
			local foundMatch = false
			
			-- Skip warnings for void elements that shouldn't have closing tags
			if VOID_ELEMENTS[closeTagName] then
				cursor = cursor + closeEnd
				matched = true
				continue
			end
			
			-- Capture title content when closing title tag
			if closeTagName == "title" and currentParent.tag == "title" then
				-- Store the title text from the current parent's children
				for _, child in ipairs(currentParent.children) do
					if type(child) == "string" then
						titleContent = titleContent .. child
					end
				end
			end
			
			for i = #stack, 1, -1 do
				if stack[i].tag == closeTagName then
					while #stack > i do
						table.remove(stack)
					end
					table.remove(stack)
					currentParent = stack[#stack] or root
					foundMatch = true
					break
				end
			end
			
			if not foundMatch then
				warn("HTML Parsing Warning: Unmatched closing tag '" .. closeTagName .. "'")
			end
			
			cursor = cursor + closeEnd
			matched = true
			continue
		end
		
		if not matched then
			local nextTagStart = remainingHtml:find("<")
			local textEnd = nextTagStart and (nextTagStart - 1) or #remainingHtml
			
			if textEnd > 0 then
				local textContent = remainingHtml:sub(1, textEnd)
				textContent = decodeEntities(textContent)
				
				if textContent:match("%S") then
					table.insert(currentParent.children, textContent)
				end
				
				cursor = cursor + textEnd
			else
				cursor = cursor + 1
			end
		end
	end
	
	if iterations >= maxIterations then
		warn("HTML Parser: Maximum iterations reached, possible infinite loop prevented")
	end
	
	-- Store metadata in the root node
	root.metadata = {
		title = titleContent,
		head = headContent,
		meta = metaTags
	}
	
	return root
end

return HtmlParser