local data = loadstring(game:HttpGet("https://raw.githubusercontent.com/HTDBarsi/grin/main/getprop.lua"))()
local basictypes = {["float"] = true, ["int64"] = true, ["bool"] = true, ["string"] = true}
local escapes = {
    ['"'] = '&quot;',
    ['&'] = '&amp;',
    ['<'] = '&lt;',
    ['>'] = '&gt;',
    ['\''] = '&apos;'
}
local processed = {}

function seralize(word)
    for i, v in pairs(escapes) do
        word = string.gsub(word, i, v)
    end
    return word
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

    function validatetype(data, obj)
        pcall(function()
            if data[2] == "Vector3" then
                add("<Vector3 name=\"" .. data[1] .. "\"><X>" .. obj[data[1]].X .. "</X><Y>" .. obj[data[1]].Y .. "</Y><Z>" .. obj[data[1]].Z .. "</Z></Vector3>")
            elseif data[2] == "Color3" and data[1] ~= "ColorSequence" then
                add("<Color3 name=\"" .. data[1] .. "\"><R>" .. obj[data[1]].r .. "</R><G>" .. obj[data[1]].g .. "</G><B>" .. obj[data[1]].b .. "</B></Color3>")
            elseif data[1] == "CFrame" then
                add("<CoordinateFrame name=\"" .. data[1] .. "\"><X>" .. obj.CFrame.X .. "</X><Y>" .. obj.CFrame.Y .. "</Y><Z>" .. obj.CFrame.Z .. "</Z><R00>1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22></CoordinateFrame>")
            elseif data[2] == "UDim2" then
                add("<UDim2 name=\"" .. data[1] .. "\"><XS>" .. obj[data[1]].X.Scale .. "</XS><XO>" .. obj[data[1]].X.Offset .. "</XO><YS>" .. obj[data[1]].Y.Scale .. "</YS><YO>" .. obj[data[1]].Y.Offset .. "</YO></UDim2>")
            elseif data[2] == "Content" then
                add("<Content name=\"" .. data[1] .. "\"><url>" .. obj[data[1]] .. "</url></Content>")
            elseif settings["noscripts"] == nil and (obj:IsA("LocalScript") or obj:IsA("ModuleScript")) then
                add("<ProtectedString name=\"Source\"><![CDATA[" .. seralize(decompile(obj)) .. "]]></ProtectedString>")
            elseif basictypes[data[2]] == nil then
                local s, _ = pcall(function()
                    add("<token name=\"" .. data[1] .. "\">" .. tostring(obj[data[1]].Value) .. "</token>")
                end)
                if not s then
                    add("<" .. data[2] .. " name=\"" .. data[1] .. "\">" .. tostring(obj[data[1]]) .. "</" .. data[2] .. ">")
                end
            else
                add("<" .. data[2] .. " name=\"" .. data[1] .. "\">" .. seralize(tostring(obj[data[1]])) .. "</" .. data[2] .. ">")
            end
        end)
    end

    function getobjects(v)
        if v == game:GetService("CoreGui") or v == game:GetService("CorePackages") or processed[v] then
            return
        end
        processed[v] = true -- Mark object as processed

        add("<Item class=\"" .. v.ClassName .. "\"><Properties>")
        if data[v.ClassName] ~= nil then
            if not settings["noproperties"] then
                for u, k in pairs(data[v.ClassName]) do
                    validatetype({u, k}, v)
                end
            else
                add("<string name=\"Name\">" .. v.Name .. "</string>")
                if not settings["noscripts"] and (v:IsA("ModuleScript") or v:IsA("LocalScript")) then
                    pcall(function()
                        add("<ProtectedString name=\"Source\"><![CDATA[" .. decompile(v) .. "]]></ProtectedString>")
                    end)
                end
            end
        end
        if v:IsA("UnionOperation") then
            add("<Union name=\"" .. v.Name .. "\"/>")
        elseif v:IsA("MeshPart") then
            add("<Mesh name=\"" .. v.Name .. "\"/>")
        end
        add("</Properties>")
        for _, k in pairs(v:GetChildren()) do
            getobjects(k)
        end
        add("</Item>")
    end

    writefile(name, [[<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">]])
    for i, v in pairs(game:GetChildren()) do
        getobjects(v)
    end
    add("</roblox>")
    appendfile(name, current)
    print("Done! took " .. tick() - start .. "s")
end

saveinstance("places.rbxlx", {noscripts = true})
