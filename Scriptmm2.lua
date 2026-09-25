-- ============================================================
-- Universal Script MM2 v2 - ESP total + Floating Aimbot + Gun ESP
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local Config = {
    WalkSpeed = 16,
    JumpPower = 50,
    InfiniteJump = true,
    FullBright = false,
    NoClip = false,

    AimbotEnabled = false,
    AimbotKey = Enum.KeyCode.E,
    AimbotSmoothness = 0.5,
    AimbotFOV = 500,
    TeamCheck = true,
    WallCheck = false,
    TargetPart = "Head",
    LockMode = true,
    PrioritizeGunHolder = false,

    ESPEnabled = false,
    ESPNames = true,
    ESPGun = true,

    ESPColors = {
        Murderer = Color3.fromRGB(255, 40, 40),
        Sheriff  = Color3.fromRGB(40, 120, 255),
        Innocent = Color3.fromRGB(40, 220, 80),
        Unknown  = Color3.fromRGB(255, 255, 255),
    },
}

local ESPObjects = {}
local ESPGui = nil
local GunESPObjects = {}

-- ==================== HELPERS ====================

local function isGunTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local n = string.lower(tool.Name)
    return n:find("gun") or n:find("revolver") or n:find("pistol") or n:find("sheriff") or n:find("firearm")
end

local function isKnifeTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local n = string.lower(tool.Name)
    return n:find("knife") or n:find("murder") or n:find("dagger") or n:find("facão")
end

local function findToolIn(container)
    if not container then return nil end
    for _, t in ipairs(container:GetChildren()) do
        if t:IsA("Tool") then
            if isKnifeTool(t) then return t, "Murderer" end
            if isGunTool(t) then return t, "Sheriff" end
        end
    end
    return nil
end

local function getGunHolder()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local ch = plr.Character
            local tool = findToolIn(ch)
            if tool and isGunTool(tool) then return plr end
            local bp = plr:FindFirstChildOfClass("Backpack")
            local bpTool = findToolIn(bp)
            if bpTool and isGunTool(bpTool) then return plr end
        end
    end
    return nil
end

-- ==================== ROLE DETECT ====================

local function detectRole(plr)
    if not plr or not plr.Character then return "Unknown" end
    local ch = plr.Character
    local h = ch:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return "Dead" end

    local attr = plr:GetAttribute("Role") or ch:GetAttribute("Role")
    if attr then return attr end

    local tool, role = findToolIn(ch)
    if tool then return role end

    local bp = plr:FindFirstChildOfClass("Backpack")
    local bpTool, bpRole = findToolIn(bp)
    if bpTool then return bpRole end

    if plr.Team then
        local tn = string.lower(plr.Team.Name)
        if tn:find("murder") then return "Murderer" end
        if tn:find("sheriff") then return "Sheriff" end
        if tn:find("innocent") then return "Innocent" end
    end

    return "Innocent"
end

local function getRoleColor(r)
    return Config.ESPColors[r] or Config.ESPColors.Unknown
end

-- ==================== ESP ====================

local function createESPGui()
    if ESPGui and ESPGui.Parent then return end
    ESPGui = Instance.new("ScreenGui")
    ESPGui.Name = "ESPGui_" .. tostring(math.random(1000,9999))
    ESPGui.ResetOnSpawn = false
    ESPGui.IgnoreGuiInset = true
    ESPGui.Parent = PG
end

local function removeESP(plr)
    local d = ESPObjects[plr]
    if not d then return end
    for _, o in pairs(d) do
        if o and o.Parent then o:Destroy() end
    end
    ESPObjects[plr] = nil
end

local function createESP(plr)
    if plr == LP then return end
    if ESPObjects[plr] then return end
    if not plr.Character then return end

    local role = detectRole(plr)
    local color = getRoleColor(role)

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_HL"
    hl.Adornee = plr.Character
    hl.FillColor = color
    hl.FillTransparency = 0.6
    hl.OutlineColor = color
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = Config.ESPEnabled
    hl.Parent = plr.Character

    local head = plr.Character:FindFirstChild("Head")
    local bb = nil
    if head then
        bb = Instance.new("BillboardGui")
        bb.Name = "ESP_BB"
        bb.Adornee = head
        bb.Size = UDim2.new(0, 160, 0, 40)
        bb.StudsOffset = Vector3.new(0, 2.5, 0)
        bb.AlwaysOnTop = true
        bb.Enabled = Config.ESPEnabled and Config.ESPNames
        bb.Parent = head

        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.new(1, 0, 0.5, 0)
        nl.BackgroundTransparency = 1
        nl.Text = plr.Name
        nl.TextColor3 = color
        nl.TextStrokeTransparency = 0
        nl.TextStrokeColor3 = Color3.new(0,0,0)
        nl.TextSize = 14
        nl.Font = Enum.Font.GothamBold
        nl.Parent = bb

        local rl = Instance.new("TextLabel")
        rl.Size = UDim2.new(1, 0, 0.5, 0)
        rl.Position = UDim2.new(0, 0, 0.5, 0)
        rl.BackgroundTransparency = 1
        rl.Text = "[" .. role .. "]"
        rl.TextColor3 = color
        rl.TextStrokeTransparency = 0
        rl.TextStrokeColor3 = Color3.new(0,0,0)
        rl.TextSize = 12
        rl.Font = Enum.Font.Gotham
        rl.Parent = bb
    end

    ESPObjects[plr] = { highlight = hl, billboard = bb, role = role }
end

local function updateESP(plr)
    local d = ESPObjects[plr]
    if not d then return end
    if not plr.Character then removeESP(plr) return end

    d.highlight.Adornee = plr.Character

    local head = plr.Character:FindFirstChild("Head")
    if d.billboard and d.billboard.Adornee ~= head then
        d.billboard:Destroy()
        d.billboard = nil
        if head then
            local bb = Instance.new("BillboardGui")
            bb.Name = "ESP_BB"
            bb.Adornee = head
            bb.Size = UDim2.new(0, 160, 0, 40)
            bb.StudsOffset = Vector3.new(0, 2.5, 0)
            bb.AlwaysOnTop = true
            bb.Parent = head

            local nl = Instance.new("TextLabel")
            nl.Size = UDim2.new(1, 0, 0.5, 0)
            nl.BackgroundTransparency = 1
            nl.Text = plr.Name
            nl.TextSize = 14
            nl.Font = Enum.Font.GothamBold
            nl.TextStrokeTransparency = 0
            nl.TextStrokeColor3 = Color3.new(0,0,0)
            nl.Parent = bb

            local rl = Instance.new("TextLabel")
            rl.Size = UDim2.new(1, 0, 0.5, 0)
            rl.Position = UDim2.new(0, 0, 0.5, 0)
            rl.BackgroundTransparency = 1
            rl.TextSize = 12
            rl.Font = Enum.Font.Gotham
            rl.TextStrokeTransparency = 0
            rl.TextStrokeColor3 = Color3.new(0,0,0)
            rl.Parent = bb

            d.billboard = bb
        end
    end

    local nr = detectRole(plr)
    local nc = getRoleColor(nr)
    if nr ~= d.role then
        d.role = nr
        if d.highlight then
            d.highlight.FillColor = nc
            d.highlight.OutlineColor = nc
        end
        if d.billboard then
            for _, l in ipairs(d.billboard:GetChildren()) do
                if l:IsA("TextLabel") then
                    l.TextColor3 = nc
                    if l.Text:find("%[") then l.Text = "[" .. nr .. "]" end
                end
            end
        end
    end
end

-- ESP na arma caída
local function refreshGunESP()
    if not Config.ESPEnabled or not Config.ESPGun then
        for _, o in pairs(GunESPObjects) do
            if o and o.Parent then o:Destroy() end
        end
        GunESPObjects = {}
        return
    end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and isGunTool(obj) and not obj.Parent:IsA("Player") then
            if not GunESPObjects[obj] then
                local handle = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
                if handle then
                    local hl = Instance.new("Highlight")
                    hl.Name = "GunESP_HL"
                    hl.Adornee = handle
                    hl.FillColor = Color3.fromRGB(255, 215, 0)
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = Color3.fromRGB(255, 215, 0)
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = handle

                    local bb = Instance.new("BillboardGui")
                    bb.Name = "GunESP_BB"
                    bb.Adornee = handle
                    bb.Size = UDim2.new(0, 120, 0, 30)
                    bb.StudsOffset = Vector3.new(0, 2, 0)
                    bb.AlwaysOnTop = true
                    bb.Parent = handle

                    local tl = Instance.new("TextLabel")
                    tl.Size = UDim2.new(1, 0, 1, 0)
                    tl.BackgroundTransparency = 1
                    tl.Text = "🔫 ARMA"
                    tl.TextColor3 = Color3.fromRGB(255, 215, 0)
                    tl.TextStrokeTransparency = 0
                    tl.TextStrokeColor3 = Color3.new(0,0,0)
                    tl.TextSize = 14
                    tl.Font = Enum.Font.GothamBold
                    tl.Parent = bb

                    GunESPObjects[obj] = { hl, bb }
                end
            end
        end
    end

    for obj, arr in pairs(GunESPObjects) do
        if not obj or not obj.Parent then
            for _, o in ipairs(arr) do if o.Parent then o:Destroy() end end
            GunESPObjects[obj] = nil
        end
    end
end

local function refreshAllESP()
    for plr, _ in pairs(ESPObjects) do
        if not plr.Parent then removeESP(plr) end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            if not ESPObjects[plr] then
                if Config.ESPEnabled then
                    if plr.Character then
                        createESP(plr)
                    end
                end
            else
                if plr.Character then
                    updateESP(plr)
                    local d = ESPObjects[plr]
                    if d.highlight then d.highlight.Enabled = Config.ESPEnabled end
                    if d.billboard then d.billboard.Enabled = Config.ESPEnabled and Config.ESPNames end
                else
                    local d = ESPObjects[plr]
                    if d.highlight then d.highlight.Enabled = false end
                    if d.billboard then d.billboard.Enabled = false end
                end
            end
        end
    end
end

local function setupESP()
    createESPGui()

    RunService.Heartbeat:Connect(function()
        refreshAllESP()
        refreshGunESP()
    end)

    local function hookPlayer(plr)
        if plr == LP then return end
        plr.CharacterAdded:Connect(function()
            task.wait(0.3)
            if Config.ESPEnabled then
                removeESP(plr)
                createESP(plr)
            end
        end)
    end

    for _, plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end
    Players.PlayerAdded:Connect(hookPlayer)
    Players.PlayerRemoving:Connect(removeESP)
end

-- ==================== AIMBOT ====================

local function isValidTarget(plr)
    if not plr or plr == LP or not plr.Character then return false end
    local h = plr.Character:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return false end
    if Config.TeamCheck and plr.Team and LP.Team and plr.Team == LP.Team then return false end
    local tp = plr.Character:FindFirstChild(Config.TargetPart)
    if not tp then return false end
    if Config.WallCheck then
        local ro = Camera.CFrame.Position
        local rd = tp.Position - ro
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = {LP.Character, plr.Character}
        if Workspace:Raycast(ro, rd, rp) then return false end
    end
    return true, tp
end

local function getClosestTarget()
    -- Prioridade pro portador da arma
    if Config.PrioritizeGunHolder then
        local gh = getGunHolder()
        if gh then
            local ok, part = isValidTarget(gh)
            if ok then return gh, part end
        end
    end

    local closest, closestPart = nil, nil
    local shortest = math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, plr in ipairs(Players:GetPlayers()) do
        local ok, part = isValidTarget(plr)
        if ok then
            local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if d <= Config.AimbotFOV and d < shortest then
                    shortest = d
                    closest = plr
                    closestPart = part
                end
            end
        end
    end
    return closest, closestPart
end

local function setupAimbot()
    RunService.RenderStepped:Connect(function()
        if not Config.AimbotEnabled then return end
        local tgt, tp = getClosestTarget()
        if not tgt or not tp then return end
        local shouldLock = Config.LockMode or UIS:IsKeyDown(Config.AimbotKey)
        if shouldLock then
            local newCF = CFrame.new(Camera.CFrame.Position, tp.Position)
            Camera.CFrame = Camera.CFrame:Lerp(newCF, Config.AimbotSmoothness)
        end
    end)
end

-- ==================== GUI ====================

local floatingBtn = nil
local floatingLabel = nil

local function createFloatingAimbotBtn(parentGui)
    if floatingBtn and floatingBtn.Parent then return end

    floatingBtn = Instance.new("TextButton")
    floatingBtn.Name = "FloatAimbot"
    floatingBtn.Size = UDim2.new(0, 70, 0, 70)
    floatingBtn.Position = UDim2.new(1, -90, 0.5, 100)
    floatingBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 80)
    floatingBtn.Text = "AIM"
    floatingBtn.TextColor3 = Color3.new(1,1,1)
    floatingBtn.TextSize = 14
    floatingBtn.Font = Enum.Font.GothamBold
    floatingBtn.Active = true
    floatingBtn.ZIndex = 150
    floatingBtn.Parent = parentGui

    local c = Instance.new("UICorner", floatingBtn)
    c.CornerRadius = UDim.new(1, 0)

    local s = Instance.new("UIStroke", floatingBtn)
    s.Color = Color3.fromRGB(90, 100, 140)
    s.Thickness = 2

    -- Drag
    local drag = false
    local dStart, sPos
    floatingBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
            dStart = i.Position
            sPos = floatingBtn.Position
            local moved = false
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    if not moved then
                        Config.AimbotEnabled = not Config.AimbotEnabled
                        if Config.AimbotEnabled then
                            floatingBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
                            s.Color = Color3.fromRGB(120, 255, 150)
                        else
                            floatingBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 80)
                            s.Color = Color3.fromRGB(90, 100, 140)
                        end
                    end
                    drag = false
                end
            end)
            task.spawn(function()
                while i.UserInputState ~= Enum.UserInputState.End do
                    task.wait(0.05)
                    if (i.Position - dStart).Magnitude > 8 then
                        moved = true
                        drag = true
                        local d = i.Position - dStart
                        floatingBtn.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
                    end
                end
            end)
        end
    end)
end

local function createMenu()
    local sg = Instance.new("ScreenGui")
    sg.Name = "UniversalMenu_" .. tostring(math.random(1000,9999))
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = PG

    local mf = Instance.new("Frame")
    mf.Size = UDim2.new(0, 300, 0, 450)
    mf.Position = UDim2.new(0.5, -150, 0.5, -225)
    mf.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    mf.BorderSizePixel = 0
    mf.Active = true
    mf.ClipsDescendants = true
    mf.Parent = sg

    Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 10)
    local ms = Instance.new("UIStroke", mf)
    ms.Color = Color3.fromRGB(80, 130, 255)
    ms.Thickness = 1.5

    local tb = Instance.new("Frame", mf)
    tb.Size = UDim2.new(1, 0, 0, 40)
    tb.BackgroundColor3 = Color3.fromRGB(38, 48, 90)
    tb.BorderSizePixel = 0
    tb.ZIndex = 10
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 10)

    local tfix = Instance.new("Frame", tb)
    tfix.Size = UDim2.new(1, 0, 0, 10)
    tfix.Position = UDim2.new(0, 0, 1, -10)
    tfix.BackgroundColor3 = Color3.fromRGB(38, 48, 90)
    tfix.BorderSizePixel = 0
    tfix.ZIndex = 10

    local tl = Instance.new("TextLabel", tb)
    tl.Size = UDim2.new(1, -50, 1, 0)
    tl.Position = UDim2.new(0, 12, 0, 0)
    tl.BackgroundTransparency = 1
    tl.Text = "Universal Script v2"
    tl.TextColor3 = Color3.new(1,1,1)
    tl.TextSize = 16
    tl.Font = Enum.Font.GothamBold
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.ZIndex = 11

    local cb = Instance.new("TextButton", tb)
    cb.Size = UDim2.new(0, 28, 0, 28)
    cb.Position = UDim2.new(1, -34, 0, 6)
    cb.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    cb.Text = "X"
    cb.TextColor3 = Color3.new(1,1,1)
    cb.TextSize = 14
    cb.Font = Enum.Font.GothamBold
    cb.ZIndex = 12
    Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 6)

    local ob = Instance.new("TextButton", sg)
    ob.Size = UDim2.new(0, 50, 0, 50)
    ob.Position = UDim2.new(0, 20, 0.5, -25)
    ob.BackgroundColor3 = Color3.fromRGB(38, 48, 90)
    ob.Text = "+"
    ob.TextColor3 = Color3.new(1,1,1)
    ob.TextSize = 24
    ob.Font = Enum.Font.GothamBold
    ob.Visible = false
    ob.ZIndex = 100
    Instance.new("UICorner", ob).CornerRadius = UDim.new(1, 0)

    local sc = Instance.new("ScrollingFrame", mf)
    sc.Size = UDim2.new(1, 0, 1, -40)
    sc.Position = UDim2.new(0, 0, 0, 40)
    sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0
    sc.ScrollBarThickness = 6
    sc.ScrollBarImageColor3 = Color3.fromRGB(80, 130, 255)
    sc.CanvasSize = UDim2.new(0, 0, 0, 0)
    sc.ScrollingDirection = Enum.ScrollingDirection.Y

    local layout = Instance.new("UIListLayout", sc)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)

    local pad = Instance.new("UIPadding", sc)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sc.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    local function mkToggle(text, initial, callback)
        local state = initial
        local b = Instance.new("TextButton", sc)
        b.Size = UDim2.new(1, 0, 0, 36)
        b.BackgroundColor3 = state and Color3.fromRGB(0, 140, 60) or Color3.fromRGB(50, 55, 80)
        b.Text = ""
        b.AutoButtonColor = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local st = Instance.new("UIStroke", b)
        st.Color = Color3.fromRGB(90, 100, 140)
        st.Thickness = 1

        local lb = Instance.new("TextLabel", b)
        lb.Size = UDim2.new(1, -70, 1, 0)
        lb.Position = UDim2.new(0, 10, 0, 0)
        lb.BackgroundTransparency = 1
        lb.Text = text
        lb.TextColor3 = Color3.new(1,1,1)
        lb.TextSize = 14
        lb.Font = Enum.Font.GothamSemibold
        lb.TextXAlignment = Enum.TextXAlignment.Left

        local sl = Instance.new("TextLabel", b)
        sl.Size = UDim2.new(0, 55, 1, 0)
        sl.Position = UDim2.new(1, -60, 0, 0)
        sl.BackgroundTransparency = 1
        sl.Text = state and "ON" or "OFF"
        sl.TextColor3 = state and Color3.fromRGB(120, 255, 150) or Color3.fromRGB(200, 200, 200)
        sl.TextSize = 13
        sl.Font = Enum.Font.GothamBold
        sl.TextXAlignment = Enum.TextXAlignment.Right

        b.MouseButton1Click:Connect(function()
            state = not state
            sl.Text = state and "ON" or "OFF"
            sl.TextColor3 = state and Color3.fromRGB(120, 255, 150) or Color3.fromRGB(200, 200, 200)
            b.BackgroundColor3 = state and Color3.fromRGB(0, 140, 60) or Color3.fromRGB(50, 55, 80)
            if callback then callback(state) end
        end)
        return b
    end

    local function mkSection(text)
        local s = Instance.new("TextLabel", sc)
        s.Size = UDim2.new(1, 0, 0, 24)
        s.BackgroundTransparency = 1
        s.Text = text
        s.TextColor3 = Color3.fromRGB(120, 180, 255)
        s.TextSize = 13
        s.Font = Enum.Font.GothamBold
        s.TextXAlignment = Enum.TextXAlignment.Left
        return s
    end

    mkSection("ESP")
    mkToggle("ESP Ativado", Config.ESPEnabled, function(v)
        Config.ESPEnabled = v
        if v then refreshAllESP() end
    end)
    mkToggle("Nome / Role", Config.ESPNames, function(v) Config.ESPNames = v end)
    mkToggle("ESP Arma no Chao", Config.ESPGun, function(v)
        Config.ESPGun = v
        refreshGunESP()
    end)

    mkSection("AIMBOT")
    mkToggle("Aimbot", Config.AimbotEnabled, function(v) Config.AimbotEnabled = v end)
    mkToggle("Lock Mode", Config.LockMode, function(v) Config.LockMode = v end)
    mkToggle("Team Check", Config.TeamCheck, function(v) Config.TeamCheck = v end)
    mkToggle("Wall Check", Config.WallCheck, function(v) Config.WallCheck = v end)
    mkToggle("Priorizar arma", Config.PrioritizeGunHolder, function(v) Config.PrioritizeGunHolder = v end)

    local tgt = Instance.new("TextButton", sc)
    tgt.Size = UDim2.new(1, 0, 0, 36)
    tgt.BackgroundColor3 = Color3.fromRGB(50, 55, 80)
    tgt.Text = ""
    tgt.AutoButtonColor = false
    Instance.new("UICorner", tgt).CornerRadius = UDim.new(0, 6)
    local tgl = Instance.new("TextLabel", tgt)
    tgl.Size = UDim2.new(1, -80, 1, 0)
    tgl.Position = UDim2.new(0, 10, 0, 0)
    tgl.BackgroundTransparency = 1
    tgl.Text = "Target Part"
    tgl.TextColor3 = Color3.new(1,1,1)
    tgl.TextSize = 14
    tgl.Font = Enum.Font.GothamSemibold
    tgl.TextXAlignment = Enum.TextXAlignment.Left
    local tst = Instance.new("TextLabel", tgt)
    tst.Size = UDim2.new(0, 65, 1, 0)
    tst.Position = UDim2.new(1, -70, 0, 0)
    tst.BackgroundTransparency = 1
    tst.Text = Config.TargetPart
    tst.TextColor3 = Color3.fromRGB(255, 220, 120)
    tst.TextSize = 12
    tst.Font = Enum.Font.GothamBold
    tst.TextXAlignment = Enum.TextXAlignment.Right
    tgt.MouseButton1Click:Connect(function()
        if Config.TargetPart == "Head" then
            Config.TargetPart = "HumanoidRootPart"
        else
            Config.TargetPart = "Head"
        end
        tst.Text = Config.TargetPart
    end)

    mkSection("BOTOES NA TELA")
    mkToggle("Botao Aimbot Flutuante", false, function(v)
        if v then
            createFloatingAimbotBtn(sg)
        else
            if floatingBtn then floatingBtn:Destroy() floatingBtn = nil end
        end
    end)

    mkSection("MOVIMENTO")
    mkToggle("No Clip", Config.NoClip, function(v) Config.NoClip = v end)
    mkToggle("Infinite Jump", Config.InfiniteJump, function(v) Config.InfiniteJump = v end)
    mkToggle("Full Bright", Config.FullBright, function(v)
        Config.FullBright = v
        local l = game:GetService("Lighting")
        if v then
            l.Ambient = Color3.new(1,1,1)
            l.Brightness = 3
            l.FogEnd = 100000
            l.OutdoorAmbient = Color3.new(1,1,1)
        else
            l.Ambient = Color3.fromRGB(128,128,128)
            l.Brightness = 2
            l.FogEnd = 1000
            l.OutdoorAmbient = Color3.fromRGB(128,128,128)
        end
    end)

    mkSection("ACOES")
    local rb = Instance.new("TextButton", sc)
    rb.Size = UDim2.new(1, 0, 0, 36)
    rb.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
    rb.Text = "Reset Character"
    rb.TextColor3 = Color3.new(1,1,1)
    rb.TextSize = 14
    rb.Font = Enum.Font.GothamSemibold
    rb.AutoButtonColor = false
    Instance.new("UICorner", rb).CornerRadius = UDim.new(0, 6)
    rb.MouseButton1Click:Connect(function()
        if LP.Character then LP.Character:BreakJoints() end
    end)

    cb.MouseButton1Click:Connect(function()
        mf.Visible = false
        ob.Visible = true
    end)
    ob.MouseButton1Click:Connect(function()
        mf.Visible = true
        ob.Visible = false
    end)

    -- Drag main
    local drag = false
    local dIn, dStart, sPos
    local function upd(i)
        local d = i.Position - dStart
        mf.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
    end
    tb.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true
            dStart = i.Position
            sPos = mf.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    tb.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            dIn = i
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if i == dIn and drag then upd(i) end
    end)

    -- Drag botao minimizado
    local od = false
    local odStart, oSpos
    ob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            od = true
            odStart = i.Position
            oSpos = ob.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then od = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if od and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - odStart
            ob.Position = UDim2.new(oSpos.X.Scale, oSpos.X.Offset + d.X, oSpos.Y.Scale, oSpos.Y.Offset + d.Y)
        end
    end)

    UIS.InputBegan:Connect(function(i, gp)
