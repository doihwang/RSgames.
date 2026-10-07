-- Run ONCE from Studio Command Bar in EDIT mode (Stop first).
-- Creates missing ownership folders only; existing content is untouched.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before creating folders")
local targets = {
    game:GetService("Workspace"),
    game:GetService("ServerScriptService"),
    game:GetService("ServerStorage"),
    game:GetService("ReplicatedStorage"),
    game:GetService("ReplicatedFirst"),
    game:GetService("StarterGui"),
    game:GetService("StarterPack"),
    game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"),
    game:GetService("StarterPlayer"):WaitForChild("StarterCharacterScripts"),
    game:GetService("Lighting"),
    game:GetService("SoundService"),
}
-- Validate every target before creating anything.
for _, parent in ipairs(targets) do
    local existing = parent:FindFirstChild("UserOwned")
    assert(not existing or existing:IsA("Folder"), parent:GetFullName() .. ".UserOwned is not a Folder")
end
local created = 0
for _, parent in ipairs(targets) do
    if not parent:FindFirstChild("UserOwned") then
        local folder = Instance.new("Folder")
        folder.Name = "UserOwned"
        folder.Parent = parent
        created = created + 1
    end
end
print("UserOwned folders ready. Created: " .. created .. ". Save your Studio place now.")
