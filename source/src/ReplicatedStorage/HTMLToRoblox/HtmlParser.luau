local HtmlParser = {}

-- Token types based on HTML5 specification
local TokenType = {
    DOCTYPE = "DOCTYPE",
    START_TAG = "START_TAG",
    END_TAG = "END_TAG",
    COMMENT = "COMMENT",
    CHARACTER = "CHARACTER",
    END_OF_FILE = "END_OF_FILE"
}

local TagDefinitions = require(script.Parent.HtmlTagDefinitions)
local VOID_ELEMENTS = TagDefinitions.getVoidElementSet()

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

-- Improved pattern definitions for better matching
local PATTERNS = {
    -- More robust tag patterns
    START_TAG = "^<%s*([%w%-:]+)([^>]*)>",
    END_TAG = "^<%s*/%s*([%w%-:]+)%s*>",
    SELF_CLOSING = "^<%s*([%w%-:]+)([^/>]*)%s*/>",
    COMMENT = "^<!%-%-%s*(.-)%s*%-%->",
    DOCTYPE = "^<!DOCTYPE%s+[^>]*>",
    -- Improved attribute patterns
    ATTR_NAME = "([%w%-:]+)",
    ATTR_VALUE_QUOTED = '=(%s*["\'])([^"\']*)["\']',
    ATTR_VALUE_UNQUOTED = "=(%s*)([^%s>]+)",
    -- Character patterns
    WHITESPACE = "^%s+",
    TEXT = "^[^<]+",
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
        if num and num >= 32 and num <= 1114111 then -- Extended Unicode range
            return utf8.char(num)
        end
        return ""
    end)
    
    -- Replace hexadecimal numeric entities (&#xhhhh;)
    text = text:gsub("&#[xX](%x+);", function(hex)
        local num = tonumber("0x" .. hex)
        if num and num >= 32 and num <= 1114111 then -- Extended Unicode range
            return utf8.char(num)
        end
        return ""
    end)
    
    return text
end

-- Tokenizer implementation
local function Tokenizer(html)
    local tokens = {}
    local pos = 1
    local len = #html
    
    local function peek(offset)
        offset = offset or 0
        return html:sub(pos + offset, pos + offset)
    end
    
    local function advance(count)
        count = count or 1
        pos = pos + count
        return pos <= len
    end
    
    local function remaining()
        return html:sub(pos)
    end
    
    local function addToken(tokenType, data)
        table.insert(tokens, {
            type = tokenType,
            data = data or {},
            position = pos
        })
    end
    
    while pos <= len do
        local rem = remaining()
        
        -- Skip leading whitespace at document start
        if pos == 1 then
            local wsMatch = rem:match(PATTERNS.WHITESPACE)
            if wsMatch then
                advance(#wsMatch)
                continue
            end
        end
        
        -- DOCTYPE
        local doctypeMatch = rem:match(PATTERNS.DOCTYPE)
        if doctypeMatch then
            addToken(TokenType.DOCTYPE, { content = doctypeMatch })
            advance(#doctypeMatch)
            continue
        end
        
        -- Comments
        local commentStart, commentEnd, commentContent = rem:find(PATTERNS.COMMENT)
        if commentStart == 1 then
            addToken(TokenType.COMMENT, { content = commentContent })
            advance(commentEnd)
            continue
        end
        
        -- Self-closing tags
        local selfStart, selfEnd, selfTag, selfAttrs = rem:find(PATTERNS.SELF_CLOSING)
        if selfStart == 1 then
            addToken(TokenType.START_TAG, {
                name = selfTag:lower(),
                attributes = selfAttrs,
                selfClosing = true
            })
            advance(selfEnd)
            continue
        end
        
        -- Start tags
        local startStart, startEnd, startTag, startAttrs = rem:find(PATTERNS.START_TAG)
        if startStart == 1 then
            addToken(TokenType.START_TAG, {
                name = startTag:lower(),
                attributes = startAttrs,
                selfClosing = false
            })
            advance(startEnd)
            continue
        end
        
        -- End tags
        local endStart, endEnd, endTag = rem:find(PATTERNS.END_TAG)
        if endStart == 1 then
            addToken(TokenType.END_TAG, {
                name = endTag:lower()
            })
            advance(endEnd)
            continue
        end
        
        -- Character data
        local textMatch = rem:match(PATTERNS.TEXT)
        if textMatch then
            local decodedText = decodeEntities(textMatch)
            if decodedText:match("%S") then -- Only add non-whitespace text
                addToken(TokenType.CHARACTER, { content = decodedText })
            end
            advance(#textMatch)
            continue
        end
        
        -- If nothing matches, advance one character to prevent infinite loop
        advance(1)
    end
    
    addToken(TokenType.END_OF_FILE)
    return tokens
end

-- Improved attribute parser with better regex handling
function HtmlParser.parseAttributes(attrString)
    local attrs = {}
    if not attrString or attrString == "" then
        return attrs
    end
    
    -- Trim whitespace
    attrString = attrString:match("^%s*(.-)%s*$") or attrString
    
    local i = 1
    while i <= #attrString do
        -- Skip whitespace
        local wsStart, wsEnd = attrString:find("^%s+", i)
        if wsStart then
            i = wsEnd + 1
            continue
        end
        
        -- Match attribute name - improved pattern
        local nameStart, nameEnd, attrName = attrString:find("^([%w%-:_%.]+)", i)
        if not attrName then
            break
        end
        
        local key = attrName:lower()
        i = nameEnd + 1
        
        -- Skip whitespace after name
        wsStart, wsEnd = attrString:find("^%s*", i)
        if wsStart then
            i = wsEnd + 1
        end
        
        -- Check for equals sign
        local eqStart, eqEnd = attrString:find("^=", i)
        if eqStart then
            i = eqEnd + 1
            
            -- Skip whitespace after equals
            wsStart, wsEnd = attrString:find("^%s*", i)
            if wsStart then
                i = wsEnd + 1
            end
            
            -- Parse value
            local quote = attrString:sub(i, i)
            if quote == '"' or quote == "'" then
                -- Quoted value - improved pattern
                local valueStart = i + 1
                local valueEnd = attrString:find(quote, valueStart, true)
                if valueEnd then
                    local value = attrString:sub(valueStart, valueEnd - 1)
                    attrs[key] = decodeEntities(value)
                    i = valueEnd + 1
                else
                    -- Unterminated quote
                    attrs[key] = true
                    break
                end
            else
                -- Unquoted value - improved pattern
                local valueStart, valueEnd, value = attrString:find("^([^%s>]+)", i)
                if value then
                    attrs[key] = decodeEntities(value)
                    i = valueEnd + 1
                else
                    attrs[key] = true
                end
            end
        else
            -- Boolean attribute
            attrs[key] = true
        end
    end
    
    return attrs
end

-- Main parser using tokenization
function HtmlParser.parse(html)
    if not html or html == "" then
        return { tag = "root", attributes = {}, children = {} }
    end
    
    local tokens = Tokenizer(html)
    local root = { tag = "root", attributes = {}, children = {} }
    local stack = { root }
    local current = root
    
    -- Metadata tracking
    local headContent = { tag = "head", attributes = {}, children = {} }
    local titleContent = ""
    local metaTags = {}
    
    for i, token in ipairs(tokens) do
        if token.type == TokenType.DOCTYPE then
            -- Store DOCTYPE info in metadata
            root.doctype = token.data.content
            
        elseif token.type == TokenType.START_TAG then
            local tagName = token.data.name
            local node = {
                tag = tagName,
                attributes = HtmlParser.parseAttributes(token.data.attributes),
                children = {}
            }
            
            -- Track special elements
            if tagName == "head" then
                headContent = node
            elseif tagName == "meta" then
                table.insert(metaTags, node)
            end
            
            table.insert(current.children, node)
            
            -- Handle void elements and self-closing tags
            if not (VOID_ELEMENTS[tagName] or token.data.selfClosing) then
                table.insert(stack, node)
                current = node
            end
            
        elseif token.type == TokenType.END_TAG then
            local tagName = token.data.name
            
            -- Skip closing tags for void elements
            if VOID_ELEMENTS[tagName] then
                continue
            end
            
            -- Capture title content
            if tagName == "title" and current.tag == "title" then
                for _, child in ipairs(current.children) do
                    if type(child) == "string" then
                        titleContent = titleContent .. child
                    end
                end
            end
            
            -- Find matching opening tag
            local found = false
            for j = #stack, 1, -1 do
                if stack[j].tag == tagName then
                    -- Close all tags up to this one
                    while #stack > j do
                        table.remove(stack)
                    end
                    table.remove(stack)
                    current = stack[#stack] or root
                    found = true
                    break
                end
            end
            
            if not found and tagName ~= "html" and tagName ~= "body" then
                warn("HTML Parser: Unmatched closing tag '" .. tagName .. "'")
            end
            
        elseif token.type == TokenType.CHARACTER then
            local text = token.data.content
            if text and text:match("%S") then
                table.insert(current.children, text)
            end
            
        elseif token.type == TokenType.COMMENT then
            -- Store comments as special nodes (ignored later)
            local commentNode = {
                tag = "#comment",
                attributes = {},
                children = { token.data.content }
            }
            table.insert(current.children, commentNode)
        end
    end
    
    -- Add metadata
    root.metadata = {
        title = titleContent,
        head = headContent,
        meta = metaTags,
        doctype = root.doctype
    }
    
    return root
end

-- Utility function to get tokens without parsing
function HtmlParser.tokenize(html)
    return Tokenizer(html)
end

-- Function to normalize whitespace in text content (helps with spacing issues)
function HtmlParser.normalizeWhitespace(text)
    if not text then return "" end
    -- Replace multiple whitespace with single space, trim edges
    return text:gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
end

-- Enhanced error handling
function HtmlParser.parseWithErrorHandling(html)
    local success, result = pcall(HtmlParser.parse, html)
    if success then
        return result, nil
    else
        return nil, result
    end
end

return HtmlParser