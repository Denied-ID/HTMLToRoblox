local StdLib = {}

-- Console
StdLib.console = {
    log = function(...)
        print(...)
    end,
    warn = function(...)
        warn(...)
    end,
    error = function(...)
        error(table.concat({...}, " "), 0)
    end,
}

-- Math object mapping to Lua's math library
StdLib.Math = {
    abs = math.abs,
    floor = math.floor,
    ceil = math.ceil,
    max = math.max,
    min = math.min,
    pow = math.pow or function(a, b) return a ^ b end,
    random = math.random,
    sqrt = math.sqrt,
    sin = math.sin,
    cos = math.cos,
    tan = math.tan,
    PI = math.pi,
    E = math.exp(1),
}

-- JSON using HttpService
local HttpService = game:GetService("HttpService")
StdLib.JSON = {
    stringify = function(tbl)
        return HttpService:JSONEncode(tbl)
    end,
    parse = function(str)
        return HttpService:JSONDecode(str)
    end,
}

-- Timing utilities similar to setTimeout / setInterval
local TimerManager = {}
local intervalThreads = {}

function StdLib.setTimeout(callback, ms)
    return task.delay((ms or 0)/1000, callback)
end

function StdLib.clearTimeout(thread)
    if thread then
        task.cancel(thread)
    end
end

function StdLib.setInterval(callback, ms)
    local running = true
    local thread
    thread = task.spawn(function()
        while running do
            task.wait((ms or 0)/1000)
            callback()
        end
    end)
    intervalThreads[thread] = function()
        running = false
    end
    return thread
end

function StdLib.clearInterval(thread)
    local closer = intervalThreads[thread]
    if closer then closer() end
    if thread then task.cancel(thread) end
end

-- Global helpers
function StdLib.parseInt(value, base)
    base = base or 10
    local num = tonumber(value, base)
    if num then return math.floor(num) end
    return nil
end

function StdLib.parseFloat(value)
    return tonumber(value)
end

function StdLib.isNaN(value)
    return value ~= value
end

-- String utilities to match JS trim
globalTrim = function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end
StdLib.string = {
    trim = globalTrim,
    trimStart = function(s) return (s:gsub("^%s*", "")) end,
    trimEnd = function(s) return (s:gsub("%s*$", "")) end,
    toLowerCase = function(s) return string.lower(s) end,
    toUpperCase = function(s) return string.upper(s) end,
}

-- table (Object) helpers
StdLib.Object = {
    keys = function(tbl)
        local arr = {}
        for k in pairs(tbl) do table.insert(arr, k) end
        return arr
    end,
    values = function(tbl)
        local arr = {}
        for _, v in pairs(tbl) do table.insert(arr, v) end
        return arr
    end,
    entries = function(tbl)
        local arr = {}
        for k, v in pairs(tbl) do table.insert(arr, {k, v}) end
        return arr
    end,
}

-- DOM helpers
StdLib.DOM = {
    -- Create a new element
    createElement = function(tagName)
        return {
            tagName = tagName,
            attributes = {},
            children = {},
            style = {},
            
            -- Methods
            setAttribute = function(self, name, value)
                self.attributes[name] = value
                return self
            end,
            
            appendChild = function(self, child)
                table.insert(self.children, child)
                return self
            end,
            
            setStyle = function(self, property, value)
                self.style[property] = value
                return self
            end,
            
            setInnerHTML = function(self, html)
                self.innerHTML = html
                return self
            end,
            
            setInnerText = function(self, text)
                self.innerText = text
                return self
            end
        }
    end,
    
    -- Query selector helpers
    querySelector = function(selector)
        -- This is a stub - the actual implementation is in JSEngine
        return nil
    end,
    
    querySelectorAll = function(selector)
        -- This is a stub - the actual implementation is in JSEngine
        return {}
    end,
    
    -- Event handling
    addEventListener = function(element, eventType, handler)
        -- This is a stub - the actual implementation is in JSEngine
    end,
    
    -- Form validation
    validateForm = function(formElement)
        -- This is a stub - the actual implementation is in JSEngine
        return true
    end
}

-- Window helpers
StdLib.Window = {
    alert = function(message)
        print("ALERT: " .. tostring(message))
    end,
    
    confirm = function(message)
        print("CONFIRM: " .. tostring(message))
        return true -- Always return true in this implementation
    end,
    
    prompt = function(message, defaultValue)
        print("PROMPT: " .. tostring(message) .. " (default: " .. tostring(defaultValue) .. ")")
        return defaultValue
    end,
    
    open = function(url)
        print("Opening URL: " .. tostring(url))
        -- This would normally open a new window, but we'll just print it
    end,
    
    location = {
        href = "",
        host = "",
        pathname = "",
        search = "",
        hash = "",
        
        reload = function()
            print("Reloading page")
        end,
        
        replace = function(url)
            print("Replacing location with: " .. tostring(url))
        end
    }
}

return StdLib 