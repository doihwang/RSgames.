local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

Players.CharacterAutoLoads = false
workspace.Gravity = 145
Lighting.ClockTime = 19
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(115, 130, 170)
local event = Instance.new("RemoteEvent")
event.Name = "Feedback"
event.Parent = ReplicatedStorage
local arena = Instance.new("Folder", workspace)
arena.Name = "Arena"
local tiles, states = {}, {}
local active, roundStart = false, 0
local SIZE, STEP, LIFE = 9, 8, 1.65
local cyan = Color3.fromRGB(45, 204, 223)
local function part(name, size, position, color, parent)
    local p = Instance.new("Part")
    p.Name, p.Size, p.Position = name, size, position
    p.Anchored = true
    p.Color, p.Material = color, Enum.Material.SmoothPlastic
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end
local function feedback(player, kind, position, value)
    if player.Parent then event:FireClient(player, kind, position, value) end
end
local function collapse(tile)
    if not tile or tile.dead then return end
    tile.dead = true
    tile.part.CanCollide, tile.part.CanQuery = false, false
    TweenService:Create(tile.part, TweenInfo.new(0.45), {
        Position = tile.part.Position - Vector3.new(0, 12, 0), Transparency = 1,
        Orientation = Vector3.new(12, 0, 16),
    }):Play()
    Debris:AddItem(tile.part, 0.5)
end
local function crack(tile, now)
    if tile.dead or tile.expires then return end
    tile.expires = now + LIFE
    tile.part.Color = Color3.fromRGB(255, 177, 66)
    for n = 1, 3 do
        local fissure = part("Crack", Vector3.new(0.10, 0.035, 3.3),
            tile.part.Position + Vector3.new((n - 2) * 1.3, 0.62, 0),
            Color3.fromRGB(52, 28, 42), tile.part)
        fissure.Orientation = Vector3.new(0, n * 48, 0)
    end
end
local function ring(position, powered)
    local p = part("Impact", Vector3.new(0.12, 2, 2), position + Vector3.new(0, 0.7, 0),
        powered and Color3.fromRGB(255, 105, 205) or cyan, workspace)
    p.Shape, p.Material = Enum.PartType.Cylinder, Enum.Material.Neon
    p.Orientation = Vector3.new(0, 0, 90)
    p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
    TweenService:Create(p, TweenInfo.new(0.32), {
        Size = Vector3.new(0.05, powered and 24 or 10, powered and 24 or 10), Transparency = 1,
    }):Play()
    Debris:AddItem(p, 0.35)
end
local function setCharge(player, charged)
    player:SetAttribute("Charged", charged)
    local character = player.Character
    if not character then return end
    local old = character:FindFirstChild("ChargeGlow")
    if old then old:Destroy() end
    if charged then
        local glow = Instance.new("Highlight")
        glow.Name, glow.FillColor = "ChargeGlow", Color3.fromRGB(255, 100, 205)
        glow.FillTransparency, glow.OutlineTransparency = 0.65, 0.1
        glow.Parent = character
    end
end
local function rebuild()
    arena:ClearAllChildren()
    tiles = {}
    for x = 1, SIZE do
        for z = 1, SIZE do
            local p = part("Tile", Vector3.new(7.7, 1.2, 7.7),
                Vector3.new((x - 5) * STEP, 0, (z - 5) * STEP),
                (x + z) % 2 == 0 and cyan or Color3.fromRGB(42, 156, 195), arena)
            tiles[p] = {part = p, x = x, z = z}
        end
    end
end
local function spawnPlayer(player, index)
    setCharge(player, false)
    player:SetAttribute("Survival", 0)
    states[player] = {alive = true, grounded = false, airStart = os.clock()}
    local ok = pcall(function() player:LoadCharacterAsync() end)
    if not ok or not player.Parent then states[player] = nil return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then states[player] = nil return end
    humanoid.WalkSpeed, humanoid.UseJumpPower, humanoid.JumpPower = 23, true, 48
    character:PivotTo(CFrame.new(((index - 1) % 5 - 2) * STEP, 6, math.floor((index - 1) / 5) % 5 * STEP - 16))
end
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {arena}
RunService.Heartbeat:Connect(function()
    if not active then return end
    local now = os.clock()
    for player, state in pairs(states) do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if state.alive and root and humanoid then
            if root.Position.Y < -12 or humanoid.Health <= 0 then
                state.alive = false
                player:SetAttribute("Survival", math.floor((now - roundStart) * 10) / 10)
                feedback(player, "Out", nil, player:GetAttribute("Survival"))
                humanoid.Health = 0
            else
                local distance = humanoid.HipHeight + root.Size.Y / 2 + 0.75
                local hit = workspace:Raycast(root.Position, Vector3.new(0, -distance, 0), params)
                local tile = hit and tiles[hit.Instance]
                local grounded = tile and not tile.dead and math.abs(root.AssemblyLinearVelocity.Y) < 7
                if grounded then
                    if not state.grounded and now - state.airStart > 0.12 then
                        local powered = player:GetAttribute("Charged") == true
                        if powered then
                            setCharge(player, false)
                            for _, other in pairs(tiles) do
                                if other ~= tile and other.expires and not other.dead
                                    and math.abs(other.x - tile.x) <= 1 and math.abs(other.z - tile.z) <= 1 then
                                    collapse(other)
                                end
                            end
                        end
                        ring(tile.part.Position, powered)
                        feedback(player, powered and "Slam" or "Land", tile.part.Position)
                    end
                    crack(tile, now)
                    state.lastTile = tile
                elseif state.grounded then
                    state.airStart = now
                    local previous = state.lastTile
                    if root.AssemblyLinearVelocity.Y > 8 and previous and not previous.dead and previous.expires then
                        local remaining = previous.expires - now
                        if remaining > 0 and remaining <= 0.65 and not player:GetAttribute("Charged") then
                            setCharge(player, true)
                            feedback(player, "Charge")
                        end
                    end
                end
                state.grounded = grounded and true or false
            end
        end
    end
    for _, tile in pairs(tiles) do
        if tile.expires and not tile.dead then
            local remaining = tile.expires - now
            if remaining <= 0 then collapse(tile)
            elseif remaining < 0.65 then
                tile.part.Color = math.floor(now * 12) % 2 == 0
                    and Color3.fromRGB(255, 63, 92) or Color3.fromRGB(255, 133, 87)
            end
        end
    end
end)
Players.PlayerRemoving:Connect(function(player) states[player] = nil end)
Players.PlayerAdded:Connect(function(player) player:SetAttribute("Charged", false) end)
task.spawn(function()
    while true do
        active = false
        for seconds = 4, 1, -1 do
            workspace:SetAttribute("Status", "곧 시작 · " .. seconds)
            task.wait(1)
        end
        rebuild()
        states = {}
        local roster = Players:GetPlayers()
        for i, player in ipairs(roster) do spawnPlayer(player, i) end
        roundStart = os.clock()
        active = true
        local lastHazard = 0
        while #roster > 0 and os.clock() - roundStart < 60 do
            local elapsed, alive = os.clock() - roundStart, 0
            for _, state in pairs(states) do if state.alive then alive = alive + 1 end end
            workspace:SetAttribute("Status", string.format("%02d초 / 60초     생존 %d", math.floor(elapsed), alive))
            if alive == 0 or (#roster > 1 and alive <= 1) then break end
            if elapsed > 8 and elapsed - lastHazard > 0.8 then
                lastHazard = elapsed
                local available = {}
                for _, tile in pairs(tiles) do
                    if not tile.dead and not tile.expires then table.insert(available, tile) end
                end
                if #available > 0 then crack(available[math.random(#available)], os.clock()) end
            end
            task.wait(0.1)
        end
        active = false
        workspace:SetAttribute("Status", "라운드 종료 · 잠시 후 다시 도전")
        for player, state in pairs(states) do
            if state.alive then feedback(player, "Win") end
        end
        task.wait(3)
    end
end)
