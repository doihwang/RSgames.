local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "WarrrHUD", false, false
gui.Parent = player:WaitForChild("PlayerGui")
local function label(name, text, size, position, fontSize)
    local l = Instance.new("TextLabel")
    l.Name, l.Text, l.Size, l.Position = name, text, size, position
    l.BackgroundColor3 = Color3.fromRGB(16, 22, 39)
    l.BackgroundTransparency = 0.15
    l.TextColor3 = Color3.fromRGB(235, 245, 255)
    l.Font, l.TextSize, l.TextWrapped = Enum.Font.GothamBold, fontSize, true
    l.Parent = gui
    local corner = Instance.new("UICorner", l)
    corner.CornerRadius = UDim.new(0, 14)
    return l
end
label("Title", "와르르!  /  IMPACT LAB", UDim2.fromOffset(280, 42), UDim2.new(0.5, -140, 0, 8), 19)
local status = label("Status", "경기 준비", UDim2.fromOffset(330, 42), UDim2.new(0.5, -165, 0, 58), 18)
local charge = label("Charge", "충격 충전 없음", UDim2.fromOffset(240, 40), UDim2.new(0.5, -120, 1, -118), 19)
label("Help", "이동 WASD · 점프 Space / 모바일 기본 조작\n빨갛게 깜빡일 때 점프 → 충전 → 다음 착지로 주변 균열 붕괴!",
    UDim2.new(0.9, 0, 0, 62), UDim2.new(0.05, 0, 1, -70), 15)
local toast = label("Toast", "", UDim2.new(0.8, 0, 0, 72), UDim2.new(0.1, 0, 0.30, 0), 29)
toast.BackgroundTransparency = 1
local serial = 0
local function message(text, color)
    serial = serial + 1
    local current = serial
    toast.Text, toast.TextColor3, toast.TextTransparency = text, color, 0
    task.delay(1.5, function()
        if current == serial then
            TweenService:Create(toast, TweenInfo.new(0.35), {TextTransparency = 1}):Play()
        end
    end)
end
local function refresh()
    status.Text = workspace:GetAttribute("Status") or "다음 라운드 참가 대기"
    local charged = player:GetAttribute("Charged")
    charge.Text = charged and "⚡ 강한 착지 준비!" or "빨간 발판에서 탈출해 충전"
    charge.TextColor3 = charged and Color3.fromRGB(255, 131, 217) or Color3.fromRGB(150, 205, 220)
end
workspace:GetAttributeChangedSignal("Status"):Connect(refresh)
player:GetAttributeChangedSignal("Charged"):Connect(refresh)
refresh()
local thud = Instance.new("Sound", gui)
thud.SoundId = "rbxasset://sounds/impact_water.mp3"
thud.Volume = 0.25
local bumpSerial = 0
ReplicatedStorage:WaitForChild("Feedback").OnClientEvent:Connect(function(kind, _, value)
    if kind == "Charge" then
        message("아슬아슬!  충격 충전", Color3.fromRGB(255, 139, 220))
    elseif kind == "Out" then
        message(string.format("%.1f초 생존!  다시 도전하자", value), Color3.fromRGB(255, 163, 125))
    elseif kind == "Win" then
        message("생존 성공!", Color3.fromRGB(112, 255, 212))
    elseif kind == "Land" or kind == "Slam" then
        thud.PlaybackSpeed = kind == "Slam" and 0.7 or 1.15
        thud:Play()
        if kind == "Slam" then message("와르르!", Color3.fromRGB(255, 120, 199)) end
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            bumpSerial = bumpSerial + 1
            local current = bumpSerial
            humanoid.CameraOffset = Vector3.new(0, kind == "Slam" and -0.35 or -0.14, 0)
            task.delay(0.06, function()
                if current == bumpSerial and humanoid.Parent then
                    TweenService:Create(humanoid, TweenInfo.new(0.16), {CameraOffset = Vector3.zero}):Play()
                end
            end)
        end
    end
end)
