local data = loadstring(game:HttpGet("https://raw.githubusercontent.com/playvoras/saveinstances/main/getprop"))()
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

    function serializeattribute(key, value)
        local valueType = typeof(value)
        if valueType == "string" then
            return string.format("<Attribute name=\"%s\" type=\"string\">%s</Attribute>", key, seralize(value))
        elseif valueType == "number" then
            return string.format("<Attribute name=\"%s\" type=\"number\">%s</Attribute>", key, tostring(value))
        elseif valueType == "boolean" then
            return string.format("<Attribute name=\"%s\" type=\"boolean\">%s</Attribute>", key, tostring(value))
        elseif valueType == "Vector3" then
            return string.format("<Attribute name=\"%s\" type=\"Vector3\"><X>%s</X><Y>%s</Y><Z>%s</Z></Attribute>", key, value.X, value.Y, value.Z)
        elseif valueType == "Color3" then
            return string.format("<Attribute name=\"%s\" type=\"Color3\"><R>%s</R><G>%s</G><B>%s</B></Attribute>", key, value.R, value.G, value.B)
        elseif valueType == "Vector2" then
            return string.format("<Attribute name=\"%s\" type=\"Vector2\"><X>%s</X><Y>%s</Y></Attribute>", key, value.X, value.Y)
        elseif valueType == "UDim2" then
            return string.format("<Attribute name=\"%s\" type=\"UDim2\"><XS>%s</XS><XO>%s</XO><YS>%s</YS><YO>%s</YO></Attribute>", key, value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
        elseif valueType == "UDim" then
            return string.format("<Attribute name=\"%s\" type=\"UDim\"><S>%s</S><O>%s</O></Attribute>", key, value.Scale, value.Offset)
        elseif valueType == "Rect" then
            return string.format("<Attribute name=\"%s\" type=\"Rect\"><XMin>%s</XMin><YMin>%s</YMin><XMax>%s</XMax><YMax>%s</YMax></Attribute>", key, value.Min.X, value.Min.Y, value.Max.X, value.Max.Y)
        elseif valueType == "CFrame" then
        local components = {value:GetComponents()}
        return string.format("<Attribute name=\"%s\" type=\"CFrame\"><X>%s</X><Y>%s</Y><Z>%s</Z>" ..
        "<R00>%s</R00><R01>%s</R01><R02>%s</R02><R10>%s</R10><R11>%s</R11><R12>%s</R12>" ..
        "<R20>%s</R20><R21>%s</R21><R22>%s</R22></Attribute>", key, components[1], components[2], components[3],
        components[4], components[5], components[6], components[7], components[8], components[9],
        components[10], components[11], components[12])
    else
        return string.format("<Attribute name=\"%s\" type=\"%s\">%s</Attribute>", key, valueType, tostring(value))
        end
    end

    function validatetype(data, obj)
        pcall(function()
            if data[2] == "Vector3" then
                add("<Vector3 name=\"" .. data[1] .. "\"><X>" .. obj[data[1]].X .. "</X><Y>" .. obj[data[1]].Y .. "</Y><Z>" .. obj[data[1]].Z .. "</Z></Vector3>")
            elseif data[2] == "Vector2" then
                add("<Vector2 name=\"" .. data[1] .. "\"><X>" .. obj[data[1]].X .. "</X><Y>" .. obj[data[1]].Y .. "</Y></Vector2>")
            elseif data[2] == "Color3" and data[1] ~= "ColorSequence" then
                add("<Color3 name=\"" .. data[1] .. "\"><R>" .. obj[data[1]].R .. "</R><G>" .. obj[data[1]].G .. "</G><B>" .. obj[data[1]].B .. "</B></Color3>")
            elseif data[1] == "CFrame" then
                add("<CoordinateFrame name=\"" .. data[1] .. "\"><X>" .. obj.CFrame.X .. "</X><Y>" .. obj.CFrame.Y .. "</Y><Z>" .. obj.CFrame.Z .. "</Z>")
                local components = {obj.CFrame:GetComponents()}
                for i = 4, 12 do
                    add(string.format("<R%02d>%s</R%02d>", i - 4, components[i], i - 4))
                end
                add("</CoordinateFrame>")
            elseif data[2] == "UDim2" then
                add("<UDim2 name=\"" .. data[1] .. "\"><XS>" .. obj[data[1]].X.Scale .. "</XS><XO>" .. obj[data[1]].X.Offset .. "</XO><YS>" .. obj[data[1]].Y.Scale .. "</YS><YO>" .. obj[data[1]].Y.Offset .. "</YO></UDim2>")
            elseif data[2] == "UDim" then
                add("<UDim name=\"" .. data[1] .. "\"><S>" .. obj[data[1]].Scale .. "</S><O>" .. obj[data[1]].Offset .. "</O></UDim>")
            elseif data[2] == "Rect" then
                add("<Rect name=\"" .. data[1] .. "\"><XMin>" .. obj[data[1]].Min.X .. "</XMin><YMin>" .. obj[data[1]].Min.Y .. "</YMin><XMax>" .. obj[data[1]].Max.X .. "</XMax><YMax>" .. obj[data[1]].Max.Y .. "</YMax></Rect>")
            elseif data[2] == "EnumItem" then
                add("<token name=\"" .. data[1] .. "\">" .. tostring(obj[data[1]].Name) .. "</token>")
            elseif data[2] == "NumberRange" then
                add("<NumberRange name=\"" .. data[1] .. "\"><Min>" .. obj[data[1]].Min .. "</Min><Max>" .. obj[data[1]].Max .. "</Max></NumberRange>")
            elseif data[2] == "NumberSequence" then
                add("<NumberSequence name=\"" .. data[1] .. "\">")
                for _, keypoint in ipairs(obj[data[1]].Keypoints) do
                    add("<Keypoint><Time>" .. keypoint.Time .. "</Time><Value>" .. keypoint.Value .. "</Value><Envelope>" .. keypoint.Envelope .. "</Envelope></Keypoint>")
                end
                add("</NumberSequence>")
            elseif data[2] == "ColorSequence" then
                add("<ColorSequence name=\"" .. data[1] .. "\">")
                for _, keypoint in ipairs(obj[data[1]].Keypoints) do
                    add("<Keypoint><Time>" .. keypoint.Time .. "</Time><Value><R>" .. keypoint.Value.R .. "</R><G>" .. keypoint.Value.G .. "</G><B>" .. keypoint.Value.B .. "</B></Value></Keypoint>")
                end
                add("</ColorSequence>")
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
        processed[v] = true

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
        add("</Properties>")

        add("<Attributes>")
        for key, value in pairs(v:GetAttributes()) do
            add(serializeattribute(key, value))
        end
        add("</Attributes>")

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
