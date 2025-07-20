-- AssetConverter Module
-- Handles converting external image URLs to Roblox asset IDs

local AssetConverter = {}

-- Table to cache URL to asset ID mappings
local urlToAssetCache = {}

-- Table of known URL patterns and their corresponding Roblox asset IDs
local urlToAssetMap = {
	-- Archive.org Roblox images (match by substring so it works regardless of web.archive prefix)
	["imagesak.roblox.com/161d0d393d74c103e5f50eef988b7217.png"] = "rbxassetid://91843033554443",
	
	-- Add more mappings as needed
}

-- Function to convert a URL to a Roblox asset ID
function AssetConverter.convertUrlToAssetId(url)
	if not url then return nil end
	
	-- Check cache first
	if urlToAssetCache[url] then
		return urlToAssetCache[url]
	end
	
	-- Check if we have a direct mapping
	if urlToAssetMap[url] then
		print("AssetConverter: Found direct mapping for", url)
		urlToAssetCache[url] = urlToAssetMap[url]
		return urlToAssetMap[url]
	end
	
	-- Try to match URL patterns (substring match)
	-- If a key is intended as an exact match include full URL; otherwise use a substring part.
	for pattern, assetId in pairs(urlToAssetMap) do
		if url:find(pattern) then
			print("AssetConverter: Found pattern match for", url)
			urlToAssetCache[url] = assetId
			return assetId
		end
	end
	
	-- No match found, return nil
	warn("AssetConverter: No mapping found for", url)
	return nil
end

-- Function to register a new URL to asset ID mapping
function AssetConverter.registerMapping(url, assetId)
    if url and assetId then
        urlToAssetCache[url] = assetId
        urlToAssetMap[url] = assetId
        return true
    end
    return false
end

return AssetConverter 