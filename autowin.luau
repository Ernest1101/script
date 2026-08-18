pcall(function() if _G.autowinStop then _G.autowinStop() end end)
pcall(function() if _G.autoHitStop then _G.autoHitStop() end end)

local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Window = MacLib:Window({
    Title = "AutoWin Hub", Subtitle = "AutoWin + Armor",
    Size = UDim2.fromOffset(900, 650), DragStyle = 1,
    DisabledWindowControls = {}, ShowUserInfo = true,
    Keybind = Enum.KeyCode.RightControl, AcrylicBlur = true,
})

local TabGroup = Window:TabGroup()
local MainTab = TabGroup:Tab({ Name = "AutoWin", Image = "rbxassetid://18821914323" })
local ArmorTab = TabGroup:Tab({ Name = "Armor", Image = "rbxassetid://18821914323" })
local SettingsTab = TabGroup:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" })

local LeftSection = MainTab:Section({ Side = "Left" })
local RightSection = MainTab:Section({ Side = "Right" })

local winsCount = 1
local isRunning = false
local delayBetween = 0.5
local flySpeed = 100
local noclipConnection = nil
local killWatchConnection = nil

local function disableKillParts()
    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local lava = map:FindFirstChild("Lava")
    if lava then
        for _, part in ipairs(lava:GetDescendants()) do
            if part:IsA("BasePart") then part.CanTouch = false end
        end
    end
    for _, desc in ipairs(map:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Name:lower():find("kill") then desc.CanTouch = false end
    end
    local stages = map:FindFirstChild("Stages")
    if stages then
        for _, desc in ipairs(stages:GetDescendants()) do
            if desc:IsA("BasePart") and (desc.Material == Enum.Material.Neon or desc.Name:lower():find("kill") or desc.Name:lower():find("lava")) then
                desc.CanTouch = false
            end
        end
    end
end

local function addForceField()
    local char = Players.LocalPlayer.Character
    if not char then return end
    if char:FindFirstChildOfClass("ForceField") then return end
    local ff = Instance.new("ForceField"); ff.Visible = false; ff.Parent = char
end

local function startNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.RenderStepped:Connect(function()
        local char = Players.LocalPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then h.PlatformStand = true end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false; p.Velocity = Vector3.zero; p.RotVelocity = Vector3.zero end
            end
        end
    end)
end

local function startKillWatch()
    if killWatchConnection then return end
    killWatchConnection = RunService.Heartbeat:Connect(function()
        local char = Players.LocalPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h and h.Health <= 0 then h.Health = h.MaxHealth end
        end
    end)
end

local function stopAll()
    isRunning = false
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    if killWatchConnection then killWatchConnection:Disconnect(); killWatchConnection = nil end
    local char = Players.LocalPlayer.Character
    if char then local h = char:FindFirstChildOfClass("Humanoid"); if h then h.PlatformStand = false end end
end

_G.autowinStop = stopAll

LeftSection:Header({ Text = "AutoWin Controls" })
LeftSection:Paragraph({ Header = "Welcome", Body = "Set target button and press Start." })
LeftSection:Divider()

LeftSection:Slider({ Name = "Button Target", Default = 1, Minimum = 1, Maximum = 10, DisplayMethod = "Value", Precision = 0, Callback = function(v) winsCount = v end }, "WinsSlider")
LeftSection:Slider({ Name = "Delay (s)", Default = 0.5, Minimum = 0.1, Maximum = 5, DisplayMethod = "Value", Precision = 1, Callback = function(v) delayBetween = v end }, "DelaySlider")
LeftSection:Slider({ Name = "Fly Speed", Default = 100, Minimum = 50, Maximum = 500, DisplayMethod = "Value", Precision = 0, Callback = function(v) flySpeed = v end }, "FlySpeedSlider")
LeftSection:Divider()

local startLabel = "Start AutoWin"
local startBtn

local function getHR()
    local char = Players.LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function isAlive()
    local char = Players.LocalPlayer.Character
    if not char then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function ensureAlive()
    local start = tick()
    while tick() - start < 30 do
        if Players.LocalPlayer.Character and isAlive() then
            task.wait(0.3); addForceField(); disableKillParts(); startNoclip(); startKillWatch(); return true
        end
        task.wait(0.2)
    end
    return false
end

local function flyTo(targetPos)
    local hr = getHR()
    if not hr then return false end
    addForceField(); disableKillParts(); startNoclip(); startKillWatch()
    local bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(1e9,1e9,1e9); bv.Velocity = Vector3.zero; bv.P = 10000; bv.Parent = hr
    local bg = Instance.new("BodyGyro"); bg.MaxTorque = Vector3.new(1e9,1e9,1e9); bg.P = 10000; bg.D = 500; bg.Parent = hr
    local reached = false
    while isRunning do
        hr = getHR()
        if not hr then break end
        local dir = targetPos - hr.Position
        if dir.Magnitude < 3 then reached = true; break end
        bv.Velocity = dir.Unit * flySpeed; bg.CFrame = CFrame.lookAt(hr.Position, targetPos)
        task.wait()
    end
    pcall(function() bv:Destroy(); bg:Destroy() end)
    return reached
end

local function touchButton(buttonModel)
    local hr = getHR()
    if not hr then return false end
    local touchPart = buttonModel:FindFirstChild("Touch")
    if touchPart then
        flyTo(touchPart.Position + Vector3.new(0, 2, 0))
        hr = getHR()
        if not hr then return false end
        firetouchinterest(hr, touchPart, 0); task.wait(0.15); firetouchinterest(hr, touchPart, 1)
        return true
    end
    for _, desc in ipairs(buttonModel:GetDescendants()) do
        if desc:IsA("TouchTransmitter") then
            flyTo(desc.Parent.Position + Vector3.new(0, 2, 0))
            hr = getHR()
            if not hr then return false end
            firetouchinterest(hr, desc.Parent, 0); task.wait(0.15); firetouchinterest(hr, desc.Parent, 1)
            return true
        end
    end
    local modelCF = buttonModel:IsA("Model") and buttonModel:GetModelCFrame() or nil
    if modelCF then
        hr.CFrame = modelCF + Vector3.new(0, 3, 0); task.wait(0.5)
        local tp = Instance.new("Part"); tp.Size = Vector3.new(5,5,5); tp.Position = modelCF.Position; tp.Anchored = true; tp.CanCollide = false; tp.Transparency = 1; tp.Parent = workspace
        firetouchinterest(hr, tp, 0); task.wait(0.15); firetouchinterest(hr, tp, 1); task.wait(0.5); tp:Destroy()
        return true
    end
    return false
end

startBtn = LeftSection:Button({
    Name = startLabel,
    Callback = function()
        if isRunning then return end
        local giveWins = workspace:FindFirstChild("GiveWins")
        if not giveWins then return end
        local btnName = "Button" .. winsCount
        local button = giveWins:FindFirstChild(btnName)
        if not button then Window:Notify({ Title = "AutoWin Hub", Description = btnName .. " not found!", Lifetime = 5 }); return end
        disableKillParts(); isRunning = true; startBtn:UpdateName("Running...")
        task.spawn(function()
            if not ensureAlive() then stopAll(); startBtn:UpdateName(startLabel); return end
            Window:Notify({ Title = "AutoWin Hub", Description = "Flying to " .. btnName, Lifetime = 3 })
            touchButton(button)
            Window:Notify({ Title = "AutoWin Hub", Description = btnName .. " done!", Lifetime = 5 })
            stopAll(); startBtn:UpdateName(startLabel)
        end)
    end,
})

LeftSection:Button({ Name = "Stop AutoWin", Callback = function() stopAll(); startBtn:UpdateName(startLabel) end })

RightSection:Header({ Text = "Quick Actions" })
RightSection:Button({ Name = "Disable Kill Parts", Callback = function() disableKillParts() end })
RightSection:Button({
    Name = "List Buttons",
    Callback = function()
        local gw = workspace:FindFirstChild("GiveWins")
        if not gw then return end
        local f = {}
        for i = 1, 10 do if gw:FindFirstChild("Button" .. i) then table.insert(f, "Button" .. i) end end
        Window:Notify({ Title = "AutoWin Hub", Description = #f > 0 and table.concat(f, ", ") or "None!", Lifetime = 6 })
    end,
})

-- ARMOR TAB
local ArmorLeft = ArmorTab:Section({ Side = "Left" })
local ArmorRight = ArmorTab:Section({ Side = "Right" })

local selectedStand = "Basic"
local autoHitRunning = false
local autoHitConnection = nil
local hitDelay = 0.05
local stands = {"Basic", "Lightning", "Gold", "Obsidian"}

ArmorLeft:Header({ Text = "Armor Stand Auto-Hit" })
ArmorLeft:Paragraph({ Header = "Select stand & hit!", Body = "Pick a stand and press Start." })
ArmorLeft:Divider()

ArmorLeft:Dropdown({
    Name = "Stand", Search = false, Multi = false, Required = true,
    Options = stands, Default = 1,
    Callback = function(v) selectedStand = v end,
}, "StandDropdown")

ArmorLeft:Slider({
    Name = "Hits Per Second", Default = 20, Minimum = 5, Maximum = 50,
    DisplayMethod = "Value", Precision = 0,
    Callback = function(v) hitDelay = 1 / v end,
}, "HitSpeed")

local autoHitLabel = "Start Auto-Hit"
local autoHitBtn

local function getStandPart(name)
    local as = workspace:FindFirstChild("Armorstands")
    if not as then return nil end
    local stand = as:FindFirstChild(name)
    if not stand then return nil end
    return stand:FindFirstChild("Mesh") or stand:FindFirstChild("Part") or stand.PrimaryPart
end

autoHitBtn = ArmorLeft:Button({
    Name = autoHitLabel,
    Callback = function()
        if autoHitRunning then return end

        local armorstands = workspace:FindFirstChild("Armorstands")
        if not armorstands then return end
        local stand = armorstands:FindFirstChild(selectedStand)
        if not stand then
            Window:Notify({ Title = "AutoWin Hub", Description = selectedStand .. " not found!", Lifetime = 5 })
            return
        end

        local offset = stand:FindFirstChild("TrainingOffsetPart")
        local prompt = offset and offset:FindFirstChild("TrainPrompt")
        if not prompt then
            Window:Notify({ Title = "AutoWin Hub", Description = "No TrainPrompt!", Lifetime = 5 })
            return
        end

        if not ensureAlive() then return end

        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
        local char = Players.LocalPlayer.Character
        if char then local h = char:FindFirstChildOfClass("Humanoid"); if h then h.PlatformStand = false end end

        autoHitRunning = true
        _G.autoHitStop = function()
            autoHitRunning = false
            if autoHitConnection then autoHitConnection:Disconnect(); autoHitConnection = nil end
            if autoHitBtn then autoHitBtn:UpdateName(autoHitLabel) end
        end
        autoHitBtn:UpdateName("Training " .. selectedStand .. "...")

        local hr = getHR()
        if hr then
            hr.CFrame = offset.CFrame + Vector3.new(0, 0, 2)
        end

        task.wait(0.3)

        autoHitConnection = RunService.Heartbeat:Connect(function()
            if not autoHitRunning then return end
            local hr = getHR()
            if not hr then return end
            local s = armorstands:FindFirstChild(selectedStand)
            if not s then return end
            local o = s:FindFirstChild("TrainingOffsetPart")
            local p = o and o:FindFirstChild("TrainPrompt")
            if p and o then
                local dist = (hr.Position - o.Position).Magnitude
                if dist > 15 then
                    hr.CFrame = o.CFrame + Vector3.new(0, 0, 2)
                end
                fireproximityprompt(p, 0)
            end
        end)
    end,
})

ArmorLeft:Button({
    Name = "Stop Auto-Hit",
    Callback = function()
        if _G.autoHitStop then _G.autoHitStop() end
        Window:Notify({ Title = "AutoWin Hub", Description = "Stopped!", Lifetime = 3 })
    end,
})

ArmorRight:Header({ Text = "Stand Info" })
for _, sn in ipairs(stands) do
    local p = getStandPart(sn)
    if p then
        ArmorRight:Paragraph({ Header = sn, Body = "Pos: " .. math.floor(p.Position.X) .. ", " .. math.floor(p.Position.Z) })
    end
end

ArmorRight:Divider()
ArmorRight:Button({
    Name = "Teleport to Stand",
    Callback = function()
        local as = workspace:FindFirstChild("Armorstands")
        if not as then return end
        local s = as:FindFirstChild(selectedStand)
        if not s then return end
        local o = s:FindFirstChild("TrainingOffsetPart")
        if not o then return end
        local hr = getHR()
        if hr then hr.CFrame = o.CFrame + Vector3.new(0, 0, 2) end
    end,
})

-- SETTINGS
local SettingsLeft = SettingsTab:Section({ Side = "Left" })
local SettingsRight = SettingsTab:Section({ Side = "Right" })
SettingsLeft:Header({ Text = "Settings" })
SettingsLeft:Button({ Name = "Reset All", Callback = function()
    winsCount = 1; delayBetween = 0.5; flySpeed = 100; hitDelay = 0.05
end })

SettingsRight:Header({ Text = "Auto Rebirth" })

local Events = game:GetService("ReplicatedStorage"):WaitForChild("Events")
local RequestRebirth = Events:WaitForChild("RequestRebirth")

local autoRebirthRunning = false
local autoRebirthConnection = nil
local autoRebirthDelay = 1

SettingsRight:Slider({
    Name = "Check Interval (s)", Default = 1, Minimum = 1, Maximum = 10,
    DisplayMethod = "Value", Precision = 0,
    Callback = function(v) autoRebirthDelay = v end,
}, "RebirthDelay")

local rebirthBtnLabel = "Start Auto Rebirth"
local rebirthBtn

rebirthBtn = SettingsRight:Button({
    Name = rebirthBtnLabel,
    Callback = function()
        if autoRebirthRunning then return end
        autoRebirthRunning = true
        rebirthBtn:UpdateName("Auto Rebirth ON")

        task.spawn(function()
            while autoRebirthRunning do
                local ls = Players.LocalPlayer:FindFirstChild("leaderstats")
                if ls then
                    local reb = ls:FindFirstChild("Rebirths")
                    local lvl = ls:FindFirstChild("Level")
                    if reb and lvl then
                        local required = (reb.Value + 1) * 5
                        if lvl.Value >= required then
                            pcall(function()
                                RequestRebirth:InvokeServer()
                            end)
                            task.wait(1)
                        end
                    end
                end
                task.wait(autoRebirthDelay)
            end
        end)
    end,
})

SettingsRight:Button({
    Name = "Stop Auto Rebirth",
    Callback = function()
        autoRebirthRunning = false
        if rebirthBtn then rebirthBtn:UpdateName(rebirthBtnLabel) end
        Window:Notify({ Title = "AutoWin Hub", Description = "Auto Rebirth stopped!", Lifetime = 3 })
    end,
})

Window.onUnloaded(function()
    stopAll()
    if _G.autoHitStop then _G.autoHitStop() end
    autoRebirthRunning = false
end)
MainTab:Select()