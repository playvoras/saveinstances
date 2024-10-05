local data = loadstring(game:HttpGet("https://raw.githubusercontent.com/HTDBarsi/grin/main/getprop.lua"))()
local basicTypes = {["float"] = true, ["int64"] = true, ["bool"] = true, ["string"] = true}
local escapes = {
    ['"'] = '&quot;',
    ['&'] = '&amp;',
    ['<'] = '&lt;',
    ['>'] = '&gt;',
    ['\''] = '&apos;'
}

local indentLevel = 0
local indentString = "    "

function seralize(word)
    for i, v in pairs(escapes) do
        word = string.gsub(word, i, v)
    end
    return word
end

function addIndent()
    return string.rep(indentString, indentLevel)
end

getgenv().saveinstance = function(name, settings)
    if not settings then
        settings = {}
        if not decompile then
            settings["noscripts"] = true
        end
    end

    local start = tick()
    local c = 0
    local current = ""

    function add(str)
        c += 1
        current = current .. str
        if c == 2000 then
            c = 0
            appendfile(name, current)
            current = ""
        end
    end

    function ValidateType(data, obj)
        pcall(function()
            if data[2] == "Vector3" then
                add(addIndent() .. "<Vector3 name=\"" .. data[1] .. "\"><X>" .. obj[data[1]].X .. "</X><Y>" .. obj[data[1]].Y .. "</Y><Z>" .. obj[data[1]].Z .. "</Z></Vector3>\n")
            elseif data[2] == "Color3" and data[1] ~= "ColorSequence" then
                add(addIndent() .. "<Color3 name=\"" .. data[1] .. "\"><R>" .. obj[data[1]].r .. "</R><G>" .. obj[data[1]].g .. "</G><B>" .. obj[data[1]].b .. "</B></Color3>\n")
            elseif data[1] == "CFrame" then
                add(addIndent() .. "<CoordinateFrame name=\"" .. data[1] .. "\"><X>" .. obj.CFrame.X .. "</X><Y>" .. obj.CFrame.Y .. "</Y><Z>" .. obj.CFrame.Z .. "</Z><R00>1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22></CoordinateFrame>\n")
            elseif data[2] == "UDim2" then
                add(addIndent() .. "<UDim2 name=\"" .. data[1] .. "\"><XS>" .. obj[data[1]].X.Scale .. "</XS><XO>" .. obj[data[1]].X.Offset .. "</XO><YS>" .. obj[data[1]].Y.Scale .. "</YS><YO>" .. obj[data[1]].Y.Offset .. "</YO></UDim2>\n")
            elseif data[2] == "Content" then
                add(addIndent() .. "<Content name=\"" .. data[1] .. "\"><url>" .. obj[data[1]] .. "</url></Content>\n")
            elseif settings.noscripts == nil and (obj:IsA("LocalScript") or obj:IsA("ModuleScript")) then
                add(addIndent() .. "<ProtectedString name=\"Source\"><![CDATA[" .. seralize(decompile(obj)) .. "]]></ProtectedString>\n")
            elseif basicTypes[data[2]] == nil then
                local s, _ = pcall(function()
                    add(addIndent() .. "<token name=\"" .. data[1] .. "\">" .. tostring(obj[data[1]].Value) .. "</token>\n")
                end)
                if not s then
                    add(addIndent() .. "<" .. data[2] .. " name=\"" .. data[1] .. "\">" .. tostring(obj[data[1]]) .. "</" .. data[2] .. ">\n")
                end
            else
                add(addIndent() .. "<" .. data[2] .. " name=\"" .. data[1] .. "\">" .. seralize(tostring(obj[data[1]])) .. "</" .. data[2] .. ">\n")
            end
        end)
    end

    function getObjects(v)
        add(addIndent() .. "<Item class=\"" .. v.ClassName .. "\">\n")
        indentLevel = indentLevel + 1
        add(addIndent() .. "<Properties>\n")
        indentLevel = indentLevel + 1

        if data[v.ClassName] ~= nil then
            if not settings["noproperties"] then
                for u, k in pairs(data[v.ClassName]) do
                    ValidateType({u, k}, v)
                end
            else
                add(addIndent() .. "<string name=\"Name\">" .. v.Name .. "</string>\n")
                if not settings["noscripts"] and (v:IsA("ModuleScript") or v:IsA("LocalScript")) then
                    pcall(function()
                        add(addIndent() .. "<ProtectedString name=\"Source\"><![CDATA[" .. decompile(v) .. "]]></ProtectedString>\n")
                    end)
                end
            end
        end

        indentLevel = indentLevel - 1
        add(addIndent() .. "</Properties>\n")

        for _, k in pairs(v:GetChildren()) do
            getObjects(k)
        end

        indentLevel = indentLevel - 1
        add(addIndent() .. "</Item>\n")
    end

    local function shouldSkipObject(obj)
        return obj == game.CoreGui or obj == game.CorePackages
    end

    writefile(name, [[<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n]])
    
    for i, v in pairs(game:GetChildren()) do
        if not shouldSkipObject(v) then
            getObjects(v)
        end
    end

    add("</roblox>\n")
    appendfile(name, current)
    print("Done! Took " .. tick() - start .. "s")
end

saveinstance("places.rbxlx", {noscripts = true})
