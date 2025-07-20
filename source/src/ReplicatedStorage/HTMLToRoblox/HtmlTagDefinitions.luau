--[[
HtmlTagDefinitions
A centralized registry of HTML tag metadata used by other modules such as
HtmlParser and GuiBuilder. Moving this data into a single place keeps the
parser / renderer logic clean and makes it trivial to add or modify tag
behaviours.

Each entry in `definitions` may contain:
  void   (boolean) – tag is self-closing / cannot have children.
  ignore (boolean) – tag should be completely ignored by the GUI builder
                     (e.g. <script>, comments, etc.)

If a tag is not present in the table it is considered a normal element that
can have children and should be rendered as a generic container.

]]

local TagDefinitions = {}

-- Core definitions table.  The list below covers all HTML5 void elements and
-- the most common structural tags.  Additional tags can be added easily.
local defs = {
    -- Special pseudo-tags ---------------------------------------------------
    ["!--"]       = { ignore = true }, -- comment node produced by HtmlParser
    ["#comment"]  = { ignore = true },

    -- Head-only / non-visual tags ------------------------------------------
    head   = { ignore = true },
    meta   = { void = true,  ignore = true },
    link   = { void = true,  ignore = true },
    script = { ignore = true },
    style  = { ignore = true },
    noscript = { ignore = true },

    -- Void / self-closing elements -----------------------------------------
    area    = { void = true },
    base    = { void = true },
    br      = { void = true },
    col     = { void = true },
    command = { void = true },
    embed   = { void = true },
    hr      = { void = true },
    img     = { void = true },
    input   = { void = true },
    keygen  = { void = true },
    param   = { void = true },
    source  = { void = true },
    track   = { void = true },
    wbr     = { void = true },
    -- HTML Living Standard additions
    main    = {},
    slot    = { void = true },

    -- Text semantics remapped via 'component' -------------------------------
    h1 = { component = "p" },
    h2 = { component = "p" },
    h3 = { component = "p" },
    h4 = { component = "p" },
    h5 = { component = "p" },
    h6 = { component = "p" },

    b  = { component = "span", defaults = { Font = Enum.Font.SourceSansBold } },
    strong = { component = "span", defaults = { Font = Enum.Font.SourceSansBold } },
    i  = { component = "span", defaults = { Font = Enum.Font.SourceSansItalic } },
    em = { component = "span", defaults = { Font = Enum.Font.SourceSansItalic } },

    -- Common container / inline tags ---------------------------------------
    html = {}, body = {}, div = {}, span = {}, p = {}, a = {},
    ul = {}, ol = {}, li = {}, table = {}, tr = {}, td = {}, th = {},
    section = {}, article = {}, header = {}, footer = {}, nav = {}, aside = {},
}

TagDefinitions.definitions = defs

function TagDefinitions.getDefinition(tag: string)
    return defs[string.lower(tag)]
end

function TagDefinitions.getRegistryTag(tag: string): string
    local info = defs[string.lower(tag)]
    if info and type(info.component) == "string" then
        return info.component
    end
    return string.lower(tag)
end

-- Returns true if the tag is defined as void / self-closing.
function TagDefinitions.isVoid(tag: string): boolean
    local info = defs[string.lower(tag)]
    return info ~= nil and info.void == true
end

-- Returns true if the tag should be ignored completely by the GUI builder.
function TagDefinitions.shouldIgnore(tag: string): boolean
    local info = defs[string.lower(tag)]
    return info ~= nil and info.ignore == true
end

-- Returns a set-like table of void elements: { tagName = true, ... }
function TagDefinitions.getVoidElementSet()
    local set = {}
    for tag, info in pairs(defs) do
        if type(info) == "table" and info.void == true then
            set[tag] = true
        end
    end
    return set
end

return TagDefinitions