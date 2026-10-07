-- Read-only exporter. No remote commands, property writes, or Studio content mutations.
local Http = game:GetService("HttpService")
local Editor = game:GetService("ScriptEditorService")
local Run = game:GetService("RunService")
local TOKEN = "__PAIRING_TOKEN__"
local toolbar = plugin:CreateToolbar("Warrr Studio Bridge")
local button = toolbar:CreateButton("UserOwnedSnapshot", "내 작업을 로컬 참고 사본으로 업데이트", "", "내 작업 업데이트")
button.ClickableWhenViewportHidden = true
local busy = false
local properties = {
    "Value", "CFrame", "Size", "Color", "Material", "Transparency", "Reflectance", "Anchored",
    "CanCollide", "CanTouch", "CanQuery", "CastShadow", "Shape", "PrimaryPart", "PivotOffset",
    "MeshId", "TextureID", "TextureId", "Texture", "SoundId", "Volume", "PlaybackSpeed", "Looped",
    "Enabled", "Disabled", "RunContext", "Brightness", "Range", "Shadows",
    "Position", "Rotation", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency",
    "BorderSizePixel", "Visible", "ZIndex", "LayoutOrder", "AutomaticSize", "ClipsDescendants",
    "Text", "TextColor3", "TextSize", "TextScaled", "TextWrapped", "Font", "Image", "ImageColor3",
    "ImageTransparency", "ScaleType", "DisplayOrder", "ResetOnSpawn", "IgnoreGuiInset",
    "Attachment0", "Attachment1", "Part0", "Part1", "C0", "C1", "Rate", "Lifetime", "Speed",
    "Color", "Width0", "Width1", "Face", "StudsPerTileU", "StudsPerTileV", "ToolTip", "RequiresHandle",
}
local function encode(value)
    local kind = typeof(value)
    if kind == "string" or kind == "boolean" then return value end
    if kind == "number" then return value == value and math.abs(value) < math.huge and value or tostring(value) end
    if kind == "Vector3" then return {type=kind, value={value.X,value.Y,value.Z}} end
    if kind == "Vector2" then return {type=kind, value={value.X,value.Y}} end
    if kind == "Color3" then return {type=kind, value={value.R,value.G,value.B}} end
    if kind == "CFrame" then return {type=kind, value={value:GetComponents()}} end
    if kind == "UDim" then return {type=kind, value={value.Scale,value.Offset}} end
    if kind == "UDim2" then return {type=kind, value={value.X.Scale,value.X.Offset,value.Y.Scale,value.Y.Offset}} end
    if kind == "Instance" then return {type=kind, path=value:GetFullName()} end
    return {type=kind, display=tostring(value)}
end
button.Click:Connect(function()
    if busy then return end
    if Run:IsRunning() then warn("[Studio Bridge] Stop Play first, then click Update.") return end
    busy = true
    button:SetActive(true)
    local ok, result = pcall(function()
        local warnings, count = {}, 0
        local function read(instance, depth)
            count = count + 1
            assert(count <= 20000 and depth <= 100, "Snapshot is too large or deeply nested")
            local node = {name=instance.Name, className=instance.ClassName, properties={}, attributes={}, tags=instance:GetTags(), children={}}
            for _, property in ipairs(properties) do
                local success, value = pcall(function() return instance[property] end)
                if success and value ~= nil then node.properties[property] = encode(value) end
            end
            for key, value in pairs(instance:GetAttributes()) do node.attributes[key] = encode(value) end
            if instance:IsA("LuaSourceContainer") then
                local success, source = pcall(function() return Editor:GetEditorSource(instance) end)
                if success then node.source = source
                else table.insert(warnings, "Could not read script: " .. instance:GetFullName()) end
            end
            for _, child in ipairs(instance:GetChildren()) do table.insert(node.children, read(child, depth + 1)) end
            return node
        end
        local roots = {}
        local function add(parent, path)
            local folder = parent:FindFirstChild("UserOwned")
            if folder and folder:IsA("Folder") then
                table.insert(roots, {path=path .. "/UserOwned", tree=read(folder, 0)})
            else table.insert(warnings, "Missing UserOwned folder: " .. path) end
        end
        for _, name in ipairs({"Workspace","ServerScriptService","ServerStorage","ReplicatedStorage","ReplicatedFirst","StarterGui","StarterPack","Lighting","SoundService"}) do
            add(game:GetService(name), name)
        end
        local starter = game:GetService("StarterPlayer")
        for _, name in ipairs({"StarterPlayerScripts","StarterCharacterScripts"}) do
            local parent = starter:FindFirstChild(name)
            if parent then add(parent, "StarterPlayer/" .. name) end
        end
        local body = Http:JSONEncode({version=1, placeId=tostring(game.PlaceId), placeName=game.Name,
            capturedAt=DateTime.now():ToIsoDate(), roots=roots, warnings=warnings,
            coverage="Reference only: selected properties and script source. No terrain voxels, CSG geometry, asset binaries, or guaranteed restorable serialization."})
        assert(#body <= 10 * 1024 * 1024, "Snapshot exceeds 10 MB")
        local response = Http:RequestAsync({Url="http://127.0.0.1:34873/snapshot", Method="POST",
            Headers={["Content-Type"]="application/json", ["X-Warrr-Token"]=TOKEN}, Body=body})
        assert(response.Success, "Receiver returned " .. response.StatusCode .. ": " .. response.Body)
        local receipt = Http:JSONDecode(response.Body)
        for _, warning in ipairs(warnings) do warn("[Studio Bridge] " .. warning) end
        return string.format("업데이트 완료: %d개 · %s", count, receipt.snapshot)
    end)
    busy = false
    button:SetActive(false)
    if ok then print("[Studio Bridge] " .. result)
    else warn("[Studio Bridge] 업데이트 실패: " .. tostring(result) .. " — 로컬 수신기와 플러그인 HTTP 권한을 확인하세요.") end
end)
