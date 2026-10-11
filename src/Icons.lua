local IconModule = {  
	IconsType = "lucide",  

	New = nil,  
	IconThemeTag = nil,  

	Icons = {  
		["lucide"] = {
			["star"] = "5078542968",
			
		}
	}
}

function IconModule:Get(iconName)
	if not iconName then return "" end
	
	if type(iconName) == "number" or tostring(iconName):match("^%d+$") then
		return "rbxassetid://" .. tostring(iconName)
	end
	
	if tostring(iconName):match("^rbxassetid://") then
		return iconName
	end
	
	local iconSet = self.Icons[self.IconsType]
	if iconSet and iconSet[iconName] then
		local id = iconSet[iconName]
		if tostring(id):match("^rbxassetid://") then
			return id
		else
			return "rbxassetid://" .. tostring(id)
		end
	end
	
	return ""
end

return IconModule
