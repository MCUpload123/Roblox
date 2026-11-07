local LibraryURL = "https://raw.githubusercontent.com/MCUpload123/Fluriore-library/refs/heads/main/Flur.lua"

local function loadLibrary()
    local requestOK, source = pcall(function()
        return game:HttpGet(LibraryURL)
    end)
    if not requestOK or type(source) ~= "string" or source == "" then
        error("[ZenX] FlurioreLib download failed: " .. tostring(source))
    end
    local chunk, compileError = loadstring(source)
    if type(chunk) ~= "function" then
        error("[ZenX] FlurioreLib compile failed: " .. tostring(compileError))
    end
    local runOK, library = pcall(chunk)
    if not runOK or type(library) ~= "table" then
        error("[ZenX] FlurioreLib initialization failed: " .. tostring(library))
    end
    return library
end

local FlurioreLib = loadLibrary()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

local Locales = {}
local LanguageList = {
    {Code = "en", Name = "English"},
    {Code = "th", Name = "ไทย"},
    {Code = "vi", Name = "Tiếng Việt"},
    {Code = "ru", Name = "Русский"},
    {Code = "es", Name = "Español"},
    {Code = "id", Name = "Bahasa Indonesia"},
}
local SETTINGS_FOLDER = "ZenX_Settings"
local CONFIG_FOLDER = "ZenX_Configs"

local function isKnownLanguage(code)
    for _, item in ipairs(LanguageList) do
        if item.Code == code then
            return true
        end
    end
    return false
end

local function languageCodeOf(name)
    for _, item in ipairs(LanguageList) do
        if item.Name == name then
            return item.Code
        end
    end
    return nil
end

local function languageNameOf(code)
    for _, item in ipairs(LanguageList) do
        if item.Code == code then
            return item.Name
        end
    end
    return "English"
end

local function readSavedLanguage()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return "en"
    end
    local path = SETTINGS_FOLDER .. "/language.txt"
    local existsOK, exists = pcall(isfile, path)
    if not existsOK or not exists then
        return "en"
    end
    local readOK, raw = pcall(readfile, path)
    if readOK and type(raw) == "string" then
        local code = raw:match("^%s*(.-)%s*$")
        if isKnownLanguage(code) then
            return code
        end
    end
    return "en"
end

local Language = readSavedLanguage()

local function L(text)
    if type(text) ~= "string" then
        return text
    end
    local map = Locales[Language]
    return map and map[text] or text
end

local function saveLanguage(code)
    if type(writefile) ~= "function" then
        return
    end
    pcall(function()
        if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(SETTINGS_FOLDER) then
            makefolder(SETTINGS_FOLDER)
        end
        writefile(SETTINGS_FOLDER .. "/language.txt", code)
    end)
end

local function copyTable(source)
    local out = {}
    for key, value in pairs(source) do
        out[key] = value
    end
    return out
end

local ZenThemes = {
    ["Neon Pink"] = {
        Accent = Color3.fromRGB(255, 0, 180),
        Background = Color3.fromRGB(14, 14, 22),
        Surface = Color3.fromRGB(28, 28, 42),
        Text = Color3.fromRGB(245, 245, 250),
        MutedText = Color3.fromRGB(150, 150, 170),
        Border = Color3.fromRGB(60, 50, 90),
    },
    Ocean = {
        Accent = Color3.fromRGB(0, 170, 255),
        Background = Color3.fromRGB(10, 18, 30),
        Surface = Color3.fromRGB(20, 34, 54),
        Text = Color3.fromRGB(235, 245, 255),
        MutedText = Color3.fromRGB(130, 160, 190),
        Border = Color3.fromRGB(40, 70, 105),
    },
    Sunset = {
        Accent = Color3.fromRGB(255, 130, 50),
        Background = Color3.fromRGB(24, 14, 14),
        Surface = Color3.fromRGB(44, 26, 26),
        Text = Color3.fromRGB(255, 240, 235),
        MutedText = Color3.fromRGB(180, 140, 130),
        Border = Color3.fromRGB(90, 50, 40),
    },
    Matcha = {
        Accent = Color3.fromRGB(120, 200, 110),
        Background = Color3.fromRGB(14, 20, 14),
        Surface = Color3.fromRGB(26, 38, 26),
        Text = Color3.fromRGB(240, 250, 235),
        MutedText = Color3.fromRGB(150, 175, 140),
        Border = Color3.fromRGB(55, 80, 50),
    },
    Violet = {
        Accent = Color3.fromRGB(165, 95, 255),
        Background = Color3.fromRGB(16, 12, 28),
        Surface = Color3.fromRGB(32, 26, 52),
        Text = Color3.fromRGB(240, 235, 255),
        MutedText = Color3.fromRGB(160, 150, 190),
        Border = Color3.fromRGB(70, 55, 110),
    },
}
local ThemeOrder = {"Neon Pink", "Ocean", "Sunset", "Matcha", "Violet", "Midnight", "Rose", "Mint", "Dark"}
local ActiveTheme = "Neon Pink"

local function localizeValue(value)
    if type(value) == "string" then
        return L(value)
    end
    if type(value) == "table" then
        for _, key in ipairs({"Name", "Title", "Content", "Placeholder"}) do
            if type(value[key]) == "string" then
                value[key] = L(value[key])
            end
        end
    end
    return value
end

local function localized(object)
    return setmetatable({}, {
        __index = function(_, key)
            local member = object[key]
            if type(member) ~= "function" then
                return member
            end
            return function(_, first, ...)
                local result = member(object, localizeValue(first), ...)
                if type(result) == "table" then
                    return localized(result)
                end
                return result
            end
        end,
    })
end

local function joinLocalized(lines)
    local out = {}
    for index, line in ipairs(lines) do
        out[index] = L(line)
    end
    return table.concat(out, "\n")
end

local Unloaded = false
local Window
local cleanup
local Connections = {}
local Runtime = {}
local UI = {Dropdowns = {}}
local rebuildWindow
local buildCount = 0

local COLOR_PINK = Color3.fromRGB(255, 0, 180)
local COLOR_RED = Color3.fromRGB(255, 90, 90)
local COLOR_GREEN = Color3.fromRGB(80, 220, 120)
local COLOR_YELLOW = Color3.fromRGB(255, 200, 0)

local function notify(title, description, content, color)
    if Unloaded then
        return
    end
    FlurioreLib:MakeNotify({
        Title = L(title),
        Description = L(description),
        Content = L(content),
        Color = color or COLOR_PINK,
        Time = 0.35,
        Delay = 4,
    })
end

local function addConnection(connection)
    table.insert(Connections, connection)
    return connection
end

local function getCharacter()
    return LP.Character
end

local function getHumanoid(character)
    character = character or getCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(character)
    character = character or getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function firstSelected(value)
    if type(value) == "table" then
        return value[1]
    end
    return value
end

local function clampNumber(value, minimum, maximum, fallback)
    local number = tonumber(value)
    if not number then
        return fallback
    end
    return math.clamp(number, minimum, maximum)
end

local function setterNumber(target, key, minimum, maximum, fallback)
    return function(value)
        target[key] = clampNumber(value, minimum, maximum, fallback)
    end
end

local function setterFlag(target, key)
    return function(value)
        target[key] = not not value
    end
end

local function choiceSetter(target, key, choices)
    return function(value)
        local choice = firstSelected(value)
        if choices[choice] then
            target[key] = choice
        end
    end
end

local function hasDrawing()
    return type(Drawing) == "table" and type(Drawing.new) == "function"
end

local function newDrawing(kind, properties)
    if not hasDrawing() then
        return nil
    end
    local ok, object = pcall(Drawing.new, kind)
    if not ok or not object then
        return nil
    end
    for key, value in pairs(properties) do
        pcall(function()
            object[key] = value
        end)
    end
    return object
end

local function destroyDrawing(object)
    if object then
        pcall(function()
            object:Remove()
        end)
    end
end

local State = {
    SpeedEnabled = false,
    SpeedValue = 50,
    JumpEnabled = false,
    JumpValue = 100,
    NoclipEnabled = false,
    InfiniteJumpEnabled = false,
    FlyEnabled = false,
    FlySpeed = 60,
    FlyMode = "Camera",
    FlyFaceCamera = false,
    AntiFlingEnabled = false,
    FlingEnabled = false,
    FlingTargetName = nil,
    ESPEnabled = false,
    ESP = {
        Chams = true,
        ChamsFill = 0.55,
        ChamsOutline = 0,
        Box = true,
        BoxStyle = "Full",
        Tracer = false,
        TracerOrigin = "Bottom",
        Skeleton = false,
        HealthBar = true,
        Name = true,
        Distance = true,
        Health = false,
        TeamCheck = false,
        WallCheck = false,
        IgnoreDead = true,
        MaxDistance = 1000,
    },
    FullbrightEnabled = false,
    AntiAFKEnabled = false,
    AimEnabled = false,
    SilentAim = false,
    AimRequireKey = true,
    AimMethod = "Camera",
    AimBone = "Head",
    AimFOV = 120,
    AimSmoothing = 4,
    AimMaxDistance = 1000,
    AimPrediction = 100,
    AimTeamCheck = true,
    AimWallCheck = true,
    AimIgnoreDead = true,
    AimSticky = true,
    AimShowFOV = true,
    AimLockFOV = true,
    NoFogEnabled = false,
    CustomTimeEnabled = false,
    TimeHour = 14,
    CustomFOVEnabled = false,
    CameraFOV = 70,
    SpectateEnabled = false,
    BypassEnabled = false,
    BypassBlockKick = true,
    BypassSpoofMovement = true,
}

local ESPColors = {
    Enemy = Color3.fromRGB(255, 50, 80),
    Team = Color3.fromRGB(80, 200, 255),
}

local SpeedSaved = setmetatable({}, {__mode = "k"})
local JumpSaved = setmetatable({}, {__mode = "k"})
local CollisionSaved = setmetatable({}, {__mode = "k"})
local AntiFlingSaved = setmetatable({}, {__mode = "k"})
local LightingSaved
local ESPEntries = {}

local function applyMovement(humanoid)
    if not humanoid or not humanoid.Parent then
        return
    end
    if State.SpeedEnabled then
        if SpeedSaved[humanoid] == nil then
            SpeedSaved[humanoid] = humanoid.WalkSpeed
        end
        humanoid.WalkSpeed = State.SpeedValue
    end
    if State.JumpEnabled then
        if JumpSaved[humanoid] == nil then
            JumpSaved[humanoid] = {
                UseJumpPower = humanoid.UseJumpPower,
                JumpPower = humanoid.JumpPower,
                JumpHeight = humanoid.JumpHeight,
            }
        end
        humanoid.UseJumpPower = true
        humanoid.JumpPower = State.JumpValue
    end
end

local function restoreSpeed()
    for humanoid, value in pairs(SpeedSaved) do
        if humanoid and humanoid.Parent then
            humanoid.WalkSpeed = value
        end
        SpeedSaved[humanoid] = nil
    end
end

local function restoreJump()
    for humanoid, saved in pairs(JumpSaved) do
        if humanoid and humanoid.Parent then
            humanoid.UseJumpPower = saved.UseJumpPower
            humanoid.JumpPower = saved.JumpPower
            humanoid.JumpHeight = saved.JumpHeight
        end
        JumpSaved[humanoid] = nil
    end
end

local function setSpeed(enabled)
    enabled = not not enabled
    if Unloaded or State.SpeedEnabled == enabled then
        return
    end
    State.SpeedEnabled = enabled
    if enabled then
        applyMovement(getHumanoid())
    else
        restoreSpeed()
    end
end

local function setJump(enabled)
    enabled = not not enabled
    if Unloaded or State.JumpEnabled == enabled then
        return
    end
    State.JumpEnabled = enabled
    if enabled then
        applyMovement(getHumanoid())
    else
        restoreJump()
    end
end

local function updateSpeed(value)
    State.SpeedValue = clampNumber(value, 16, 120, 50)
    if State.SpeedEnabled then
        for humanoid in pairs(SpeedSaved) do
            if humanoid and humanoid.Parent then
                humanoid.WalkSpeed = State.SpeedValue
            end
        end
    end
end

local function updateJump(value)
    State.JumpValue = clampNumber(value, 50, 150, 100)
    if State.JumpEnabled then
        for humanoid in pairs(JumpSaved) do
            if humanoid and humanoid.Parent then
                humanoid.UseJumpPower = true
                humanoid.JumpPower = State.JumpValue
            end
        end
    end
end

local function saveCollision(part)
    if CollisionSaved[part] == nil then
        CollisionSaved[part] = part.CanCollide
    end
    part.CanCollide = false
end

local function setNoclip(enabled)
    enabled = not not enabled
    if Unloaded or State.NoclipEnabled == enabled then
        return
    end
    State.NoclipEnabled = enabled
    if Runtime.Noclip then
        Runtime.Noclip:Disconnect()
        Runtime.Noclip = nil
    end
    if not enabled then
        for part, original in pairs(CollisionSaved) do
            if part and part.Parent then
                part.CanCollide = original
            end
            CollisionSaved[part] = nil
        end
        return
    end
    Runtime.Noclip = RunService.Stepped:Connect(function()
        local character = getCharacter()
        if not character then
            return
        end
        for _, object in ipairs(character:GetDescendants()) do
            if object:IsA("BasePart") then
                saveCollision(object)
            end
        end
    end)
end

local function setInfiniteJump(enabled)
    enabled = not not enabled
    if Unloaded or State.InfiniteJumpEnabled == enabled then
        return
    end
    State.InfiniteJumpEnabled = enabled
    if Runtime.Jump then
        Runtime.Jump:Disconnect()
        Runtime.Jump = nil
    end
    if enabled then
        Runtime.Jump = UserInputService.JumpRequest:Connect(function()
            if Unloaded then
                return
            end
            local humanoid = getHumanoid()
            if humanoid and humanoid.Health > 0 then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

local function setFullbright(enabled)
    enabled = not not enabled
    if Unloaded or State.FullbrightEnabled == enabled then
        return
    end
    State.FullbrightEnabled = enabled
    if enabled then
        LightingSaved = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            GlobalShadows = Lighting.GlobalShadows,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            Ambient = Lighting.Ambient,
        }
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000000
        Lighting.FogStart = 0
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        Lighting.Ambient = Color3.fromRGB(180, 180, 180)
    elseif LightingSaved then
        for property, value in pairs(LightingSaved) do
            pcall(function()
                Lighting[property] = value
            end)
        end
        LightingSaved = nil
    end
end

local FogSaved, TimeSaved, FOVSaved

local function setNoFog(enabled)
    enabled = not not enabled
    State.NoFogEnabled = enabled
    if enabled then
        FogSaved = FogSaved or {FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd}
        Lighting.FogStart = 0
        Lighting.FogEnd = 1000000
    elseif FogSaved then
        Lighting.FogStart = FogSaved.FogStart
        Lighting.FogEnd = FogSaved.FogEnd
        FogSaved = nil
    end
end

local function setCustomTime(enabled)
    enabled = not not enabled
    State.CustomTimeEnabled = enabled
    if enabled then
        TimeSaved = TimeSaved or Lighting.ClockTime
        Lighting.ClockTime = State.TimeHour
    elseif TimeSaved then
        Lighting.ClockTime = TimeSaved
        TimeSaved = nil
    end
end

local function setTimeHour(value)
    State.TimeHour = clampNumber(value, 0, 24, 14)
    if State.CustomTimeEnabled then
        Lighting.ClockTime = State.TimeHour
    end
end

local function setCustomFOV(enabled)
    enabled = not not enabled
    State.CustomFOVEnabled = enabled
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    if enabled then
        FOVSaved = FOVSaved or camera.FieldOfView
        camera.FieldOfView = State.CameraFOV
    elseif FOVSaved then
        camera.FieldOfView = FOVSaved
        FOVSaved = nil
    end
end

local function setCameraFOV(value)
    State.CameraFOV = clampNumber(value, 30, 120, 70)
    local camera = Workspace.CurrentCamera
    if State.CustomFOVEnabled and camera then
        camera.FieldOfView = State.CameraFOV
    end
end

local function setSpectate(enabled)
    enabled = not not enabled
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    local me = getCharacter()
    local subject = me and getHumanoid(me)
    if enabled then
        local name = State.FlingTargetName
        local target = name and Players:FindFirstChild(name)
        local targetHumanoid = target and target.Character and getHumanoid(target.Character)
        if not targetHumanoid then
            State.SpectateEnabled = false
            if UI.SpectateToggle then
                UI.SpectateToggle:Set(false)
            end
            notify("Spectate", "Unavailable", "Select a player with a loaded character", COLOR_RED)
            return
        end
        subject = targetHumanoid
        State.SpectateEnabled = true
        notify("Spectate", "Active", string.format(L("Spectating %s"), name), COLOR_GREEN)
    else
        State.SpectateEnabled = false
    end
    if subject then
        camera.CameraSubject = subject
    end
end

local function getEspParent()
    if type(gethui) == "function" then
        local ok, hidden = pcall(gethui)
        if ok and hidden then
            return hidden
        end
    end
    local ok = pcall(function()
        return CoreGui.Name
    end)
    if ok then
        return CoreGui
    end
    return LP:WaitForChild("PlayerGui")
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ZenX_ESP"
ESPFolder.Parent = getEspParent()

local function setAntiAFK(enabled)
    enabled = not not enabled
    if Unloaded or State.AntiAFKEnabled == enabled then
        return
    end
    State.AntiAFKEnabled = enabled
    if Runtime.AFK then
        Runtime.AFK:Disconnect()
        Runtime.AFK = nil
    end
    if enabled then
        local virtualUser = game:GetService("VirtualUser")
        Runtime.AFK = LP.Idled:Connect(function()
            if Unloaded then
                return
            end
            pcall(function()
                virtualUser:CaptureController()
                virtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end
end

local function refreshPlayerInfo()
    local character = getCharacter()
    local humanoid = getHumanoid(character)
    local root = getRoot(character)
    local camera = Workspace.CurrentCamera
    local function line(label, value)
        return L(label) .. ": " .. value
    end
    local lines = {
        line("Name", LP.Name),
        line("Display name", LP.DisplayName),
        line("User ID", tostring(LP.UserId)),
        line("Account age", tostring(LP.AccountAge) .. " " .. L("days")),
        line("Character", character and character.Name or L("Not spawned")),
        line("Health", humanoid and string.format("%.0f / %.0f", humanoid.Health, humanoid.MaxHealth) or L("Unavailable")),
        line("WalkSpeed", humanoid and tostring(humanoid.WalkSpeed) or L("Unavailable")),
        line("Jump mode", humanoid and (humanoid.UseJumpPower and "JumpPower" or "JumpHeight") or L("Unavailable")),
        line("Position", root and tostring(root.Position) or L("Unavailable")),
        line("Camera FOV", camera and tostring(math.floor(camera.FieldOfView + 0.5)) or L("Unavailable")),
    }
    if UI.PlayerInfo then
        UI.PlayerInfo:Set({Title = "Local Player", Content = table.concat(lines, "\n")})
    end
end

local function getPlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            table.insert(names, player.Name)
        end
    end
    table.sort(names)
    return names
end

local function refreshDropdown(dropdown, names)
    local current = firstSelected(dropdown.Value)
    local selecting = {}
    if current and table.find(names, current) then
        selecting = {current}
    end
    dropdown:Refresh(names, selecting)
end

local function rebuildPlayerList()
    local names = getPlayerNames()
    for _, dropdown in ipairs(UI.Dropdowns) do
        refreshDropdown(dropdown, names)
    end
end


local function getFlyDirection(camera, humanoid)
    if UserInputService:GetFocusedTextBox() then
        return Vector3.zero
    end
    local look = camera.CFrame.LookVector
    local right = camera.CFrame.RightVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    local flatRight = Vector3.new(right.X, 0, right.Z)
    if flatLook.Magnitude > 0 then
        flatLook = flatLook.Unit
    end
    if flatRight.Magnitude > 0 then
        flatRight = flatRight.Unit
    end
    local move = humanoid.MoveDirection
    local forward = State.FlyMode == "Horizontal" and flatLook or look
    local direction = forward * move:Dot(flatLook) + flatRight * move:Dot(flatRight)
    local vertical = 0
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or os.clock() < (Runtime.FlyClimbUntil or 0) then
        vertical = vertical + 1
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        vertical = vertical - 1
    end
    direction = direction + Vector3.new(0, vertical, 0)
    if direction.Magnitude > 1 then
        direction = direction.Unit
    end
    return direction
end

local function captureFlyState(humanoid)
    return {Humanoid = humanoid, PlatformStand = humanoid.PlatformStand, AutoRotate = humanoid.AutoRotate}
end

local function restoreFlyState(saved)
    if saved and saved.Humanoid and saved.Humanoid.Parent then
        saved.Humanoid.PlatformStand = saved.PlatformStand
        saved.Humanoid.AutoRotate = saved.AutoRotate
    end
end

local function disconnectFly()
    if Runtime.Fly then
        Runtime.Fly:Disconnect()
        Runtime.Fly = nil
    end
    if Runtime.FlyJump then
        Runtime.FlyJump:Disconnect()
        Runtime.FlyJump = nil
    end
end

local function setFly(enabled)
    enabled = not not enabled
    if Unloaded or State.FlyEnabled == enabled then
        return
    end
    disconnectFly()
    if not enabled then
        State.FlyEnabled = false
        restoreFlyState(Runtime.FlySaved)
        Runtime.FlySaved = nil
        local root = getRoot()
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
        end
        return
    end
    local humanoid = getHumanoid()
    local root = getRoot()
    if not (humanoid and root and Workspace.CurrentCamera) or humanoid.Health <= 0 then
        notify("Fly", "Character not ready", "Wait for your character to load before enabling Fly", COLOR_RED)
        if UI.FlyToggle then
            UI.FlyToggle:Set(false)
        end
        return
    end
    State.FlyEnabled = true
    Runtime.FlySaved = captureFlyState(humanoid)
    Runtime.FlyJump = UserInputService.JumpRequest:Connect(function()
        Runtime.FlyClimbUntil = os.clock() + 0.35
    end)
    Runtime.Fly = RunService.Heartbeat:Connect(function()
        if Unloaded then
            return
        end
        local character = getCharacter()
        local currentHumanoid = getHumanoid(character)
        local currentRoot = getRoot(character)
        local camera = Workspace.CurrentCamera
        if not (currentHumanoid and currentRoot and camera) or currentHumanoid.Health <= 0 then
            return
        end
        local saved = Runtime.FlySaved
        if not saved or saved.Humanoid ~= currentHumanoid then
            restoreFlyState(saved)
            saved = captureFlyState(currentHumanoid)
            Runtime.FlySaved = saved
        end
        currentHumanoid.PlatformStand = true
        currentRoot.AssemblyAngularVelocity = Vector3.zero
        currentRoot.AssemblyLinearVelocity = getFlyDirection(camera, currentHumanoid) * State.FlySpeed
        if State.FlyFaceCamera then
            currentHumanoid.AutoRotate = false
            local look = camera.CFrame.LookVector
            local flatLook = Vector3.new(look.X, 0, look.Z)
            if flatLook.Magnitude > 0.01 then
                currentRoot.CFrame = CFrame.new(currentRoot.Position, currentRoot.Position + flatLook)
            end
        else
            currentHumanoid.AutoRotate = saved.AutoRotate
        end
    end)
end

local function setFlyMode(value)
    local mode = firstSelected(value)
    if mode == "Camera" or mode == "Horizontal" then
        State.FlyMode = mode
    end
end

local function restoreAntiFling()
    for part, original in pairs(AntiFlingSaved) do
        if part and part.Parent then
            part.CanCollide = original
        end
        AntiFlingSaved[part] = nil
    end
end

local function neutralizeOwnVelocity(character)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored then
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

local function softenOtherCollisions(myRoot)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local otherRoot = getRoot(player.Character)
            local isFlingTarget = State.FlingEnabled and player.Name == State.FlingTargetName
            local near = myRoot ~= nil and otherRoot ~= nil and not isFlingTarget
                and (otherRoot.Position - myRoot.Position).Magnitude <= 35
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if near then
                        if AntiFlingSaved[part] == nil then
                            AntiFlingSaved[part] = part.CanCollide
                        end
                        part.CanCollide = false
                    elseif AntiFlingSaved[part] ~= nil then
                        part.CanCollide = AntiFlingSaved[part]
                        AntiFlingSaved[part] = nil
                    end
                end
            end
        end
    end
end

local function setAntiFling(enabled)
    enabled = not not enabled
    if Unloaded or State.AntiFlingEnabled == enabled then
        return
    end
    State.AntiFlingEnabled = enabled
    if Runtime.AntiFling then
        Runtime.AntiFling:Disconnect()
        Runtime.AntiFling = nil
    end
    if not enabled then
        restoreAntiFling()
        return
    end
    local lastNotify = 0
    local lastScan = 0
    Runtime.AntiFling = RunService.Heartbeat:Connect(function()
        if Unloaded then
            return
        end
        local character = getCharacter()
        local root = getRoot(character)
        if root and character:IsDescendantOf(Workspace) then
            local speedLimit = 250
            if State.FlyEnabled then
                speedLimit = math.max(speedLimit, State.FlySpeed * 2 + 60)
            end
            local velocity = root.AssemblyLinearVelocity
            local horizontal = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
            local abnormal = horizontal > speedLimit
                or math.abs(velocity.Y) > speedLimit * 2
                or root.AssemblyAngularVelocity.Magnitude > 250
            if abnormal and not State.FlingEnabled then
                neutralizeOwnVelocity(character)
                local now = os.clock()
                if now - lastNotify > 3 then
                    lastNotify = now
                    notify("Anti Fling", "Fling blocked", "Abnormal velocity was neutralized", COLOR_YELLOW)
                end
            end
        end
        local now = os.clock()
        if now - lastScan >= 0.25 then
            lastScan = now
            softenOtherCollisions(root)
        end
    end)
end

local function stopFling(reason)
    if Runtime.Fling then
        Runtime.Fling:Disconnect()
        Runtime.Fling = nil
    end
    local wasEnabled = State.FlingEnabled
    State.FlingEnabled = false
    local root = getRoot()
    if root then
        root.AssemblyAngularVelocity = Vector3.zero
        root.AssemblyLinearVelocity = Vector3.zero
    end
    if wasEnabled and reason then
        notify("Fling", "Stopped", reason, COLOR_YELLOW)
    end
    if reason and UI.FlingToggle then
        UI.FlingToggle:Set(false)
    end
end

local function setFlingTarget(name)
    if type(name) == "string" and name ~= "" then
        State.FlingTargetName = name
    else
        State.FlingTargetName = nil
    end
end

local function getFlingPreflight()
    local name = State.FlingTargetName
    if not name then
        return false, "Fling unavailable", "Select a player in the dropdown first"
    end
    local target = Players:FindFirstChild(name)
    if not target or target == LP then
        return false, "Invalid target", "The selected player is no longer in this server"
    end
    local targetRoot = getRoot(target.Character)
    local targetHumanoid = getHumanoid(target.Character)
    if not (targetRoot and targetHumanoid) or targetHumanoid.Health <= 0 then
        return false, "Temporarily unavailable", "The target character is not loaded or has died"
    end
    local root = getRoot()
    local humanoid = getHumanoid()
    if not (root and humanoid) or humanoid.Health <= 0 then
        return false, "Character not ready", "Wait for your character to load"
    end
    if type(isnetworkowner) == "function" then
        local ok, owned = pcall(isnetworkowner, root)
        if ok and not owned then
            return false, "Permission limitation", "Your root part is not network-owned on this server"
        end
    end
    return true
end

local function setFling(enabled)
    enabled = not not enabled
    if Unloaded or State.FlingEnabled == enabled then
        return
    end
    if not enabled then
        stopFling(nil)
        return
    end
    local ok, title, reason = getFlingPreflight()
    if not ok then
        notify("Fling", title, reason, COLOR_RED)
        if UI.FlingToggle then
            UI.FlingToggle:Set(false)
        end
        return
    end
    State.FlingEnabled = true
    Runtime.Fling = RunService.Heartbeat:Connect(function()
        if Unloaded then
            return
        end
        local name = State.FlingTargetName
        local target = name and Players:FindFirstChild(name)
        local targetRoot = target and getRoot(target.Character)
        local root = getRoot()
        if not (targetRoot and root) then
            stopFling("Target was cleared, left the server, or its character was removed")
            return
        end
        root.AssemblyAngularVelocity = Vector3.new(0, 10000, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = targetRoot.CFrame
    end)
    notify("Fling", "Active", string.format(L("Flinging %s"), tostring(State.FlingTargetName)), COLOR_GREEN)
end


local function removeESP(player)
    local entry = ESPEntries[player]
    if not entry then
        return
    end
    if entry.Highlight then
        entry.Highlight:Destroy()
    end
    if entry.Billboard then
        entry.Billboard:Destroy()
    end
    for _, drawing in ipairs(entry.Drawings) do
        destroyDrawing(drawing)
    end
    ESPEntries[player] = nil
end

local function clearESP()
    for player in pairs(ESPEntries) do
        removeESP(player)
    end
    if ESPFolder then
        ESPFolder:ClearAllChildren()
    end
end

local function createESP(player)
    local character = player.Character
    local root = getRoot(character)
    local humanoid = getHumanoid(character)
    if not (character and root and humanoid) then
        return nil
    end
    removeESP(player)

    local highlight = Instance.new("Highlight")
    highlight.Name = "ZenX_PlayerHighlight"
    highlight.Adornee = character
    highlight.FillTransparency = 0.55
    highlight.OutlineTransparency = 0
    highlight.Parent = ESPFolder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ZenX_PlayerTag"
    billboard.Adornee = root
    billboard.Size = UDim2.fromOffset(190, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = ESPFolder

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.35
    label.Text = ""
    label.Parent = billboard

    local motors = {}
    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("Motor6D") then
            table.insert(motors, object)
        end
    end

    local entry = {
        Player = player,
        Character = character,
        Humanoid = humanoid,
        Root = root,
        Highlight = highlight,
        Billboard = billboard,
        Label = label,
        Motors = motors,
        Drawings = {},
        Corners = {},
        Bones = {},
    }

    local function make(kind, properties)
        local object = newDrawing(kind, properties)
        if object then
            table.insert(entry.Drawings, object)
        end
        return object
    end

    entry.Box = make("Square", {Thickness = 1.5, Filled = false, Visible = false})
    for index = 1, 8 do
        entry.Corners[index] = make("Line", {Thickness = 1.5, Visible = false})
    end
    entry.Tracer = make("Line", {Thickness = 1.2, Visible = false})
    entry.HealthBack = make("Square", {Filled = true, Color = Color3.new(0, 0, 0), Transparency = 0.5, Visible = false})
    entry.HealthFill = make("Square", {Filled = true, Visible = false})
    for index = 1, #motors do
        entry.Bones[index] = make("Line", {Thickness = 1, Visible = false})
    end

    ESPEntries[player] = entry
    return entry
end

local function hideDrawings(entry)
    for _, drawing in ipairs(entry.Drawings) do
        drawing.Visible = false
    end
    entry.Highlight.Enabled = false
    entry.Billboard.Enabled = false
end

local function projectPoint(camera, position)
    local screen = camera:WorldToViewportPoint(position)
    return Vector2.new(screen.X, screen.Y), screen.Z > 0
end

local function getScreenBox(camera, character)
    local cframe, size = character:GetBoundingBox()
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for _, sx in ipairs({-1, 1}) do
        for _, sy in ipairs({-1, 1}) do
            for _, sz in ipairs({-1, 1}) do
                local point = cframe * Vector3.new(sx * size.X / 2, sy * size.Y / 2, sz * size.Z / 2)
                local screen, inFront = projectPoint(camera, point)
                if not inFront then
                    return nil
                end
                minX = math.min(minX, screen.X)
                minY = math.min(minY, screen.Y)
                maxX = math.max(maxX, screen.X)
                maxY = math.max(maxY, screen.Y)
            end
        end
    end
    return minX, minY, maxX, maxY
end

local function updateBoxes(entry, options, color, x1, y1, x2, y2)
    local width = x2 - x1
    local height = y2 - y1
    local showFull = options.Box and options.BoxStyle == "Full"
    local showCorner = options.Box and options.BoxStyle == "Corner"
    if entry.Box then
        entry.Box.Visible = showFull
        if showFull then
            entry.Box.Position = Vector2.new(x1, y1)
            entry.Box.Size = Vector2.new(width, height)
            entry.Box.Color = color
        end
    end
    local lengthX = width * 0.25
    local lengthY = height * 0.25
    local segments = {
        {Vector2.new(x1, y1), Vector2.new(x1 + lengthX, y1)},
        {Vector2.new(x1, y1), Vector2.new(x1, y1 + lengthY)},
        {Vector2.new(x2, y1), Vector2.new(x2 - lengthX, y1)},
        {Vector2.new(x2, y1), Vector2.new(x2, y1 + lengthY)},
        {Vector2.new(x1, y2), Vector2.new(x1 + lengthX, y2)},
        {Vector2.new(x1, y2), Vector2.new(x1, y2 - lengthY)},
        {Vector2.new(x2, y2), Vector2.new(x2 - lengthX, y2)},
        {Vector2.new(x2, y2), Vector2.new(x2, y2 - lengthY)},
    }
    for index, line in ipairs(entry.Corners) do
        local segment = segments[index]
        line.Visible = showCorner
        if showCorner then
            line.From = segment[1]
            line.To = segment[2]
            line.Color = color
        end
    end
end

local function updateHealthBar(entry, humanoid, show, x1, y1, height)
    if not entry.HealthBack then
        return
    end
    entry.HealthBack.Visible = show
    entry.HealthFill.Visible = show
    if not show then
        return
    end
    local ratio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
    local barX = x1 - 6
    entry.HealthBack.Position = Vector2.new(barX - 1, y1 - 1)
    entry.HealthBack.Size = Vector2.new(4, height + 2)
    entry.HealthFill.Position = Vector2.new(barX, y1 + height * (1 - ratio))
    entry.HealthFill.Size = Vector2.new(2, height * ratio)
    entry.HealthFill.Color = Color3.new(1 - ratio, ratio, 0.2)
end

local function getTracerOrigin(camera, mode)
    local viewport = camera.ViewportSize
    if mode == "Top" then
        return Vector2.new(viewport.X / 2, 0)
    end
    if mode == "Center" then
        return Vector2.new(viewport.X / 2, viewport.Y / 2)
    end
    return Vector2.new(viewport.X / 2, viewport.Y)
end

local function updateBones(entry, camera, show, color)
    for index, line in ipairs(entry.Bones) do
        local motor = entry.Motors[index]
        local part0 = motor and motor.Part0
        local part1 = motor and motor.Part1
        local drawLine = false
        if show and part0 and part1 then
            local from, frontA = projectPoint(camera, part0.Position)
            local to, frontB = projectPoint(camera, part1.Position)
            if frontA and frontB then
                line.From = from
                line.To = to
                line.Color = color
                drawLine = true
            end
        end
        line.Visible = drawLine
    end
end

local function updateESP(entry, camera, myRoot, options, rayParams)
    local player = entry.Player
    local root = entry.Root
    local humanoid = entry.Humanoid
    local character = entry.Character
    local distance = myRoot and (root.Position - myRoot.Position).Magnitude or 0
    local teammate = player.Team ~= nil and player.Team == LP.Team
    local alive = humanoid.Health > 0
    local valid = distance <= options.MaxDistance
        and (not options.IgnoreDead or alive)
        and not (options.TeamCheck and teammate)

    local occluded = false
    if valid and options.WallCheck then
        local origin = camera.CFrame.Position
        rayParams.FilterDescendantsInstances = {LP.Character, character}
        occluded = Workspace:Raycast(origin, root.Position - origin, rayParams) ~= nil
    end
    local visible = valid and not occluded
    local color = teammate and ESPColors.Team or ESPColors.Enemy

    entry.Highlight.Enabled = visible and options.Chams
    entry.Highlight.FillColor = color
    entry.Highlight.OutlineColor = color
    entry.Highlight.DepthMode = options.WallCheck and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
    entry.Highlight.FillTransparency = options.ChamsFill
    entry.Highlight.OutlineTransparency = options.ChamsOutline

    local lines = {}
    if options.Name then
        table.insert(lines, player.Name)
    end
    if options.Health then
        table.insert(lines, string.format("%d HP", math.floor(humanoid.Health)))
    end
    if options.Distance then
        table.insert(lines, string.format("%.0fm", distance))
    end
    entry.Label.Text = table.concat(lines, "  |  ")
    entry.Billboard.Enabled = visible and #lines > 0
    entry.Billboard.AlwaysOnTop = not options.WallCheck

    if not visible then
        hideDrawings(entry)
        return
    end

    local x1, y1, x2, y2 = getScreenBox(camera, character)
    if not x1 then
        hideDrawings(entry)
        return
    end

    updateBoxes(entry, options, color, x1, y1, x2, y2)
    updateHealthBar(entry, humanoid, options.HealthBar, x1, y1, y2 - y1)

    local rootScreen, rootFront = projectPoint(camera, root.Position)
    if entry.Tracer then
        local showTracer = options.Tracer and rootFront
        entry.Tracer.Visible = showTracer
        if showTracer then
            entry.Tracer.From = getTracerOrigin(camera, options.TracerOrigin)
            entry.Tracer.To = rootScreen
            entry.Tracer.Color = color
        end
    end

    updateBones(entry, camera, options.Skeleton, color)
end

local function espStep()
    if Unloaded or not State.ESPEnabled then
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    local myRoot = getRoot()
    local options = State.ESP
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local entry = ESPEntries[player]
            local character = player.Character
            if entry and entry.Character ~= character then
                removeESP(player)
                entry = nil
            end
            if not entry and character then
                entry = createESP(player)
            end
            if entry then
                updateESP(entry, camera, myRoot, options, Runtime.RayParams)
            end
        end
    end
    for player in pairs(ESPEntries) do
        if not player.Parent then
            removeESP(player)
        end
    end
end

local function setESP(enabled)
    enabled = not not enabled
    if Unloaded or State.ESPEnabled == enabled then
        return
    end
    if not enabled then
        State.ESPEnabled = false
        if Runtime.ESPRender then
            Runtime.ESPRender:Disconnect()
            Runtime.ESPRender = nil
        end
        if Runtime.ESPRemoving then
            Runtime.ESPRemoving:Disconnect()
            Runtime.ESPRemoving = nil
        end
        clearESP()
        return
    end
    if not hasDrawing() then
        notify("Player ESP", "Unsupported", "Drawing API not found. Box, corner, tracer, health bar and skeleton are disabled", COLOR_YELLOW)
    end
    State.ESPEnabled = true
    Runtime.RayParams = RaycastParams.new()
    Runtime.RayParams.FilterType = Enum.RaycastFilterType.Exclude
    Runtime.ESPRender = RunService.RenderStepped:Connect(espStep)
    Runtime.ESPRemoving = Players.PlayerRemoving:Connect(removeESP)
end


local AIM_STEP_NAME = "ZenX_Aim"
local Hooks = {}

local function aimOrigin(camera)
    if State.AimLockFOV and camera then
        local viewport = camera.ViewportSize
        return Vector2.new(viewport.X / 2, viewport.Y / 2)
    end
    return UserInputService:GetMouseLocation()
end

local function findAimTarget(camera)
    local viewport = camera.ViewportSize
    local mouse = aimOrigin(camera)
    local myCharacter = getCharacter()
    local myRoot = getRoot(myCharacter)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local best, bestScore, bestPart, bestPosition
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local character = player.Character
            local humanoid = getHumanoid(character)
            local part = character:FindFirstChild(State.AimBone) or getRoot(character)
            local valid = part ~= nil and humanoid ~= nil
            if valid and State.AimIgnoreDead and humanoid.Health <= 0 then
                valid = false
            end
            if valid and State.AimTeamCheck and player.Team ~= nil and player.Team == LP.Team then
                valid = false
            end
            if valid and myRoot and (part.Position - myRoot.Position).Magnitude > State.AimMaxDistance then
                valid = false
            end
            local predicted = part and (part.Position + part.AssemblyLinearVelocity * (State.AimPrediction / 1000))
            local screen, distanceToMouse
            if valid then
                local front
                screen, front = projectPoint(camera, predicted)
                valid = front and screen.X >= 0 and screen.Y >= 0 and screen.X <= viewport.X and screen.Y <= viewport.Y
            end
            if valid then
                distanceToMouse = (screen - mouse).Magnitude
                if distanceToMouse > State.AimFOV then
                    valid = false
                end
            end
            if valid and State.AimWallCheck then
                local origin = camera.CFrame.Position
                rayParams.FilterDescendantsInstances = {myCharacter, character}
                if Workspace:Raycast(origin, predicted - origin, rayParams) then
                    valid = false
                end
            end
            if valid then
                local score = distanceToMouse
                if State.AimSticky and Runtime.AimPlayer == player then
                    score = -1
                end
                if not best or score < bestScore then
                    best, bestScore, bestPart, bestPosition = player, score, part, predicted
                end
            end
        end
    end
    return best, bestPart, bestPosition
end

local function updateFOVCircle()
    local show = State.AimEnabled and State.AimShowFOV and hasDrawing()
    if show and not Runtime.FOVCircle then
        Runtime.FOVCircle = newDrawing("Circle", {Thickness = 1, NumSides = 64, Filled = false, Color = COLOR_PINK, Visible = true})
    elseif not show and Runtime.FOVCircle then
        destroyDrawing(Runtime.FOVCircle)
        Runtime.FOVCircle = nil
    end
end

local function aimStep()
    if Unloaded then
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    local keyOK = not State.AimRequireKey or Runtime.AimKeyHeld
    local wantAim = State.AimEnabled and keyOK
    local wantSilent = State.SilentAim and keyOK

    if Runtime.FOVCircle then
        Runtime.FOVCircle.Position = aimOrigin(Workspace.CurrentCamera)
        Runtime.FOVCircle.Radius = State.AimFOV
        Runtime.FOVCircle.Visible = true
    end

    if not (wantAim or wantSilent) then
        Runtime.AimPlayer = nil
        Runtime.SilentPosition = nil
        Runtime.SilentPart = nil
        return
    end

    local player, part, position = findAimTarget(camera)
    Runtime.AimPlayer = player
    Runtime.SilentPosition = part and position or nil
    Runtime.SilentPart = part
    if not part or not wantAim then
        return
    end

    if State.AimMethod == "Mouse" then
        if type(mousemoverel) ~= "function" then
            return
        end
        local screen = camera:WorldToViewportPoint(position)
        local mouse = aimOrigin(camera)
        local smoothing = math.max(State.AimSmoothing, 1)
        mousemoverel((screen.X - mouse.X) / smoothing, (screen.Y - mouse.Y) / smoothing)
    else
        local alpha = 1 / math.max(State.AimSmoothing, 1)
        local goal = CFrame.lookAt(camera.CFrame.Position, position)
        camera.CFrame = camera.CFrame:Lerp(goal, alpha)
    end
end

local function updateAimBinding()
    local wanted = State.AimEnabled or State.SilentAim
    if wanted and not Runtime.AimBound then
        RunService:BindToRenderStep(AIM_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, aimStep)
        Runtime.AimBound = true
    elseif not wanted and Runtime.AimBound then
        RunService:UnbindFromRenderStep(AIM_STEP_NAME)
        Runtime.AimBound = false
        Runtime.AimPlayer = nil
        Runtime.SilentPosition = nil
        Runtime.SilentPart = nil
    end
end

local function setAimbot(enabled)
    enabled = not not enabled
    if Unloaded or State.AimEnabled == enabled then
        return
    end
    State.AimEnabled = enabled
    updateFOVCircle()
    updateAimBinding()
end

local function setAimMethod(value)
    local method = firstSelected(value)
    if method == "Mouse" and type(mousemoverel) ~= "function" then
        notify("Aimbot", "Unsupported", "mousemoverel is not available in this executor. Camera method stays active", COLOR_YELLOW)
        State.AimMethod = "Camera"
        return
    end
    if method == "Camera" or method == "Mouse" then
        State.AimMethod = method
    end
end

local function setAimBone(value)
    local bone = firstSelected(value)
    local valid = {Head = true, UpperTorso = true, HumanoidRootPart = true, Torso = true}
    if valid[bone] then
        State.AimBone = bone
    end
end

local function setShowFOV(value)
    State.AimShowFOV = not not value
    updateFOVCircle()
end

local function canHook()
    return (type(hookmetamethod) == "function" or type(getrawmetatable) == "function")
        and type(newcclosure) == "function"
        and type(checkcaller) == "function"
end

local SpoofValues = {
    WalkSpeed = 16,
    JumpPower = 50,
    JumpHeight = 7.2,
    HipHeight = 2,
    MaxSlopeAngle = 89,
}

local BlockedRemoteKeys = {
    anticheat = true, ["anti-cheat"] = true, ac = true,
    detect = true, detection = true, report = true,
    ban = true, kick = true, punish = true,
    log = true, security = true, moderation = true,
    exploit = true, cheat = true, flag = true,
    handshake = true, verify = true, integrity = true,
    accheck = true, clientcheck = true, speedcheck = true,
    movementcheck = true, validation = true,
}

local function isBlockedRemote(inst)
    if not inst or typeof(inst) ~= "Instance" then return false end
    local n = string.lower(inst.Name)
    for key in pairs(BlockedRemoteKeys) do
        if string.find(n, key, 1, true) then return true end
    end
    local ok, path = pcall(function() return string.lower(inst:GetFullName()) end)
    if ok and path then
        for key in pairs(BlockedRemoteKeys) do
            if string.find(path, key, 1, true) then return true end
        end
    end
    return false
end

local function isExecutorCall()
    if type(checkcaller) == "function" then
        local ok, res = pcall(checkcaller)
        if ok and res then return true end
    end
    if type(getcallingscript) == "function" then
        local ok, scr = pcall(getcallingscript)
        if ok and scr == nil then return true end
    end
    return false
end

local function installGameHook()
    if Hooks.Game then
        return true
    end
    if not canHook() or type(getnamecallmethod) ~= "function" then
        return false
    end

    local oldIndex, oldNewIndex, oldNamecall
    local setro = setreadonly or function() end

    if type(hookmetamethod) == "function" then
        oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if isExecutorCall() then
                return oldIndex(self, key)
            end
            if State.BypassEnabled and State.BypassSpoofMovement and typeof(self) == "Instance" and self:IsA("Humanoid") then
                if key == "WalkSpeed" then return SpoofValues.WalkSpeed end
                if key == "JumpPower" then return SpoofValues.JumpPower end
                if key == "JumpHeight" then return SpoofValues.JumpHeight end
                if key == "HipHeight" then return SpoofValues.HipHeight end
                if key == "MaxSlopeAngle" then return SpoofValues.MaxSlopeAngle end
            end
            if State.BypassEnabled and typeof(self) == "Instance" then
                if key == "ZenX_ESP" or (type(key) == "string" and string.find(key, "ZenX", 1, true)) then
                    return nil
                end
            end
            return oldIndex(self, key)
        end))

        oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
            if isExecutorCall() then
                return oldNewIndex(self, key, value)
            end
            if State.BypassEnabled and State.BypassSpoofMovement and typeof(self) == "Instance" and self:IsA("Humanoid") then
                if key == "WalkSpeed" or key == "JumpPower" or key == "JumpHeight" or key == "HipHeight" or key == "MaxSlopeAngle" then
                    if type(value) == "number" then
                        if key == "WalkSpeed" then SpoofValues.WalkSpeed = value
                        elseif key == "JumpPower" then SpoofValues.JumpPower = value
                        elseif key == "JumpHeight" then SpoofValues.JumpHeight = value
                        elseif key == "HipHeight" then SpoofValues.HipHeight = value
                        elseif key == "MaxSlopeAngle" then SpoofValues.MaxSlopeAngle = value end
                    end
                    return
                end
            end
            return oldNewIndex(self, key, value)
        end))

        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if isExecutorCall() then
                return oldNamecall(self, ...)
            end
            if State.BypassEnabled and State.BypassBlockKick then
                local m = string.lower(tostring(method or ""))
                if m == "kick" then
                    return
                end
            end
            if State.BypassEnabled and (method == "FireServer" or method == "InvokeServer") then
                if isBlockedRemote(self) then
                    return
                end
                if args[1] and type(args[1]) == "string" then
                    local a = string.lower(args[1])
                    if string.find(a, "detect", 1, true) or string.find(a, "cheat", 1, true)
                        or string.find(a, "exploit", 1, true) or string.find(a, "ban", 1, true)
                        or string.find(a, "kick", 1, true) or string.find(a, "flag", 1, true)
                        or string.find(a, "speed", 1, true) or string.find(a, "validation", 1, true) then
                        return
                    end
                end
            end
            if State.BypassEnabled then
                local m = tostring(method or "")
                if (m == "FindFirstChild" or m == "FindFirstChildOfClass" or m == "FindFirstChildWhichIsA" or m == "WaitForChild") and args[1] then
                    local name = tostring(args[1])
                    if name == "ZenX_ESP" or string.find(name, "ZenX", 1, true) then
                        return nil
                    end
                end
            end
            return oldNamecall(self, ...)
        end))

        Hooks.Game = {Mode = "hookmetamethod", Index = oldIndex, NewIndex = oldNewIndex, Namecall = oldNamecall}
        return true
    end

    local mt = getrawmetatable(game)
    if type(mt) ~= "table" then
        return false
    end
    oldNamecall = rawget(mt, "__namecall")
    oldIndex = rawget(mt, "__index")
    oldNewIndex = rawget(mt, "__newindex")
    if type(oldNamecall) ~= "function" or type(oldIndex) ~= "function" then
        return false
    end
    if type(clonefunction) == "function" then
        oldNamecall = clonefunction(oldNamecall) or oldNamecall
        oldIndex = clonefunction(oldIndex) or oldIndex
        if type(oldNewIndex) == "function" then
            oldNewIndex = clonefunction(oldNewIndex) or oldNewIndex
        end
    end
    pcall(setro, mt, false)

    mt.__index = newcclosure(function(self, key)
        if isExecutorCall() then
            return oldIndex(self, key)
        end
        if State.BypassEnabled and State.BypassSpoofMovement and typeof(self) == "Instance" and self:IsA("Humanoid") then
            if key == "WalkSpeed" then return SpoofValues.WalkSpeed end
            if key == "JumpPower" then return SpoofValues.JumpPower end
            if key == "JumpHeight" then return SpoofValues.JumpHeight end
            if key == "HipHeight" then return SpoofValues.HipHeight end
            if key == "MaxSlopeAngle" then return SpoofValues.MaxSlopeAngle end
        end
        if State.BypassEnabled and typeof(self) == "Instance" then
            if key == "ZenX_ESP" or (type(key) == "string" and string.find(key, "ZenX", 1, true)) then
                return nil
            end
        end
        return oldIndex(self, key)
    end)

    if type(oldNewIndex) == "function" then
        mt.__newindex = newcclosure(function(self, key, value)
            if isExecutorCall() then
                return oldNewIndex(self, key, value)
            end
            if State.BypassEnabled and State.BypassSpoofMovement and typeof(self) == "Instance" and self:IsA("Humanoid") then
                if key == "WalkSpeed" or key == "JumpPower" or key == "JumpHeight" or key == "HipHeight" or key == "MaxSlopeAngle" then
                    if type(value) == "number" then
                        if key == "WalkSpeed" then SpoofValues.WalkSpeed = value
                        elseif key == "JumpPower" then SpoofValues.JumpPower = value
                        elseif key == "JumpHeight" then SpoofValues.JumpHeight = value
                        elseif key == "HipHeight" then SpoofValues.HipHeight = value
                        elseif key == "MaxSlopeAngle" then SpoofValues.MaxSlopeAngle = value end
                    end
                    return
                end
            end
            return oldNewIndex(self, key, value)
        end)
    end

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if isExecutorCall() then
            return oldNamecall(self, ...)
        end
        if State.BypassEnabled and State.BypassBlockKick then
            local m = string.lower(tostring(method or ""))
            if m == "kick" then
                return
            end
        end
        if State.BypassEnabled and (method == "FireServer" or method == "InvokeServer") then
            if isBlockedRemote(self) then
                return
            end
            if args[1] and type(args[1]) == "string" then
                local a = string.lower(args[1])
                if string.find(a, "detect", 1, true) or string.find(a, "cheat", 1, true)
                    or string.find(a, "exploit", 1, true) or string.find(a, "ban", 1, true)
                    or string.find(a, "kick", 1, true) or string.find(a, "flag", 1, true)
                    or string.find(a, "speed", 1, true) or string.find(a, "validation", 1, true) then
                    return
                end
            end
        end
        if State.BypassEnabled then
            local m = tostring(method or "")
            if (m == "FindFirstChild" or m == "FindFirstChildOfClass" or m == "FindFirstChildWhichIsA" or m == "WaitForChild") and args[1] then
                local name = tostring(args[1])
                if name == "ZenX_ESP" or string.find(name, "ZenX", 1, true) then
                    return nil
                end
            end
        end
        return oldNamecall(self, ...)
    end)

    pcall(setro, mt, true)
    Hooks.Game = {Mode = "raw", Metatable = mt, Namecall = oldNamecall, Index = oldIndex, NewIndex = oldNewIndex}
    return true
end

local function installMouseHook()
    if Hooks.Mouse then
        return true
    end
    if not canHook() then
        return false
    end
    local okMouse, mouse = pcall(function()
        return LP:GetMouse()
    end)
    if not okMouse or not mouse then
        return false
    end
    local metatable = getrawmetatable(mouse)
    if type(metatable) ~= "table" then
        return false
    end
    local originalIndex = rawget(metatable, "__index")
    if type(originalIndex) ~= "function" then
        return false
    end
    local setro = setreadonly or function() end
    pcall(setro, metatable, false)
    metatable.__index = newcclosure(function(self, key)
        if State.SilentAim and self == mouse and not checkcaller() then
            if key == "Hit" and Runtime.SilentPosition then
                return CFrame.new(Runtime.SilentPosition)
            end
            if key == "Target" and Runtime.SilentPart then
                return Runtime.SilentPart
            end
        end
        return originalIndex(self, key)
    end)
    pcall(setro, metatable, true)
    Hooks.Mouse = {Metatable = metatable, Index = originalIndex}
    return true
end

local function restoreHooks()
    local gameHook = Hooks.Game
    if gameHook then
        if gameHook.Mode == "raw" and gameHook.Metatable then
            pcall(function()
                local setro = setreadonly or function() end
                setro(gameHook.Metatable, false)
                gameHook.Metatable.__namecall = gameHook.Namecall
                gameHook.Metatable.__index = gameHook.Index
                if gameHook.NewIndex then
                    gameHook.Metatable.__newindex = gameHook.NewIndex
                end
                setro(gameHook.Metatable, true)
            end)
        end
        Hooks.Game = nil
    end
    local mouse = Hooks.Mouse
    if mouse then
        pcall(function()
            local setro = setreadonly or function() end
            setro(mouse.Metatable, false)
            mouse.Metatable.__index = mouse.Index
            setro(mouse.Metatable, true)
        end)
        Hooks.Mouse = nil
    end
end

local function setSilentAim(enabled)
    enabled = not not enabled
    if Unloaded or State.SilentAim == enabled then
        return
    end
    if enabled and not installMouseHook() then
        notify("Silent Aim", "Unsupported", "Mouse hook could not be installed on this executor", COLOR_RED)
        if UI.SilentToggle then
            UI.SilentToggle:Set(false)
        end
        return
    end
    State.SilentAim = enabled
    updateAimBinding()
end

do
local LocaleKeys = {
    "Local Player",
    "ZenX Universal Hub",
    "Credits",
    "Features",
    "Executor API Check",
    "Refresh API Check",
    "Refresh Information",
    "Speed Boost",
    "Speed Value",
    "Jump Boost",
    "Jump Power",
    "Noclip",
    "Infinite Jump",
    "Fly",
    "Fly Speed",
    "Fly Mode",
    "Face Camera",
    "Fly Keybind",
    "Anti Fling",
    "Reset Character",
    "Sit / Unsit",
    "Target Player",
    "Fling Player",
    "Refresh Player List",
    "Aimbot",
    "Aim Key",
    "Require Aim Key",
    "Aim Method",
    "Target Bone",
    "FOV Radius",
    "Smoothing",
    "Max Distance",
    "Prediction",
    "Team Check",
    "Wall Check",
    "Ignore Dead",
    "Sticky Target",
    "Show FOV Circle",
    "Silent Aim",
    "Player ESP",
    "Refresh ESP",
    "Box Style",
    "Tracer Origin",
    "Fill Transparency",
    "Outline Transparency",
    "Enemy Color",
    "Team Color",
    "Fullbright",
    "Select Player",
    "Teleport Selected",
    "Status",
    "Block Kick",
    "Spoof Movement Values",
    "Anti-AFK",
    "Rejoin Server",
    "Unload Hub",
    "Theme",
    "Language",
    "Config Name",
    "Save Config",
    "Select Config",
    "Load Config",
    "Refresh Config List",
    "A universal player utility hub built with FlurioreLib.",
    "Created by: **Zenx Teams** · Version: **2.1**",
    "Check the currently exposed executor functions",
    "Loading player information...",
    "Update your character and player details",
    "Save the current WalkSpeed and restore it when disabled",
    "16 - 120 studs per second",
    "Independent toggle; saves JumpPower, JumpHeight and UseJumpPower",
    "50 - 150; temporarily uses JumpPower while enabled",
    "Disable character part collisions; restore original collision values when off",
    "Request another jump while airborne",
    "Hover and fly with the speed and mode below. Mobile: move with the joystick and tap Jump to rise",
    "10 - 300 studs per second; applies instantly while flying",
    "Camera follows look direction; Horizontal keeps your altitude",
    "Turn the character to face where the camera looks while flying",
    "Press to toggle Fly",
    "Neutralize abnormal velocity on your character and soften collisions with nearby players",
    "Respawn your current character",
    "Toggle the current Humanoid sit state",
    "Target for the fling",
    "Spin your character through the selected player. Requires a loaded character",
    "Update every player dropdown",
    "Lock the camera or mouse toward the best target inside the FOV",
    "Hold to aim while Require Aim Key is on",
    "Aim only while the Aim Key is held",
    "Camera lock or relative mouse movement",
    "Body part used as the aim point",
    "10 - 800 pixels around the cursor",
    "1 = instant, higher values are slower",
    "50 - 3000 studs",
    "0 - 500 ms of target velocity lead",
    "Skip players on your team",
    "Skip targets hidden behind geometry",
    "Skip characters with zero health",
    "Keep the current target while it stays valid",
    "Draw the FOV radius around the cursor",
    "Redirect mouse Hit and Target to the aim target through a mouse hook",
    "Master switch for every player visual below",
    "Rebuild the current player visuals",
    "Full outline or corner brackets",
    "Where tracer lines start on screen",
    "0 = solid, 1 = fully see-through",
    "0 = solid outline, 1 = hidden",
    "Color for players on other teams",
    "Color for players on your team",
    "Save and restore the original Lighting properties",
    "Choose a player to teleport near",
    "Move beside the selected player's character",
    "Installed automatically when the hub loads and restored on unload. Options below control what it changes.",
    "Ignore LocalPlayer:Kick calls coming from game scripts",
    "Report the saved WalkSpeed and JumpPower to game scripts while boosts are on",
    "Handle the local idle event",
    "Reconnect to this game instance",
    "Restore modified values and remove the UI",
    "Pick a color theme. Applies instantly",
    "Interface language. Changes apply right away",
    "Name used when saving the current settings",
    "Save current settings under the name above",
    "Choose a saved config to load",
    "Apply the selected config",
    "Reload the list of saved configs",
    "Character not ready",
    "Wait for your character to load before enabling Fly",
    "Fling blocked",
    "Abnormal velocity was neutralized",
    "Unsupported",
    "Drawing API not found. Box, corner, tracer, health bar and skeleton are disabled",
    "mousemoverel is not available in this executor. Camera method stays active",
    "Mouse hook could not be installed on this executor",
    "Unavailable",
    "Select a player with a loaded character",
    "Failed",
    "Enter a config name first",
    "Select a config first",
    "Executor does not expose the required metatable functions. Bypass is disabled",
    "ZenX Universal",
    "FlurioreLib loaded",
    "Hub modules initialized",
    "days",
    "Not spawned",
    "Flinging %s",
    "yes",
    "no",
    "Saved as %s",
    "Loaded %s",
    "Name",
    "Display name",
    "User ID",
    "Account age",
    "Health",
    "WalkSpeed",
    "Jump mode",
    "Position",
    "Camera FOV",
    "Saved",
    "Loaded",
    "Fling",
    "Active",
    "Stopped",
    "Teleport",
    "Metatable Bypass",
    "Miscellaneous",
    "Appearance",
    "Config",
    "Main",
    "Players",
    "Trolls",
    "Aim",
    "Esp",
    "Visual",
    "Utility",
    "Settings",
    "Welcome",
    "Runtime",
    "Your Information",
    "Movement",
    "Protection",
    "Character",
    "Target Filters",
    "Styles",
    "Chams",
    "Labels",
    "Filters",
    "Colors",
    "World",
    "Box",
    "Box drawn from the projected bounding box",
    "Tracer",
    "Line from the screen edge to each player",
    "Skeleton",
    "Lines between joints (Motor6D)",
    "Health Bar",
    "Vertical health bar beside the box",
    "Highlight players; hidden behind walls when Wall Check is on",
    "Show the player name above the character",
    "Distance",
    "Show distance in studs",
    "Health Text",
    "Show numeric health above the character",
    "Hide players on your team",
    "Show only players in line of sight",
    "Hide characters with zero health",
    "Fling unavailable",
    "Select a player in the dropdown first",
    "Invalid target",
    "The selected player is no longer in this server",
    "Temporarily unavailable",
    "The target character is not loaded or has died",
    "Wait for your character to load",
    "Permission limitation",
    "Your root part is not network-owned on this server",
    "Target was cleared, left the server, or its character was removed",
    "Aim: Aimbot with FOV, smoothing, prediction and team/wall checks, plus Silent Aim.",
    "Esp: Chams, Box, Corner box, Tracer, Skeleton, health bar, team and wall checks.",
    "Players · Trolls · Aim · Esp · Visual · Utility",
    "Players: Speed, Jump, Noclip, Infinite Jump, Fly and Anti Fling.",
    "Settings: themes, language and config save/load.",
    "Trolls: Fling Player with a target dropdown.",
    "Utility: Teleport, Metatable Bypass, Anti-AFK and Rejoin.",
    "Visual: Fullbright.",
    "Universal script for almost any map.",
    "Mobile: tap Jump to go up",
    "Lock FOV",
    "No Fog",
    "Custom Time",
    "Hour",
    "Camera",
    "Custom FOV",
    "Field of View",
    "Spectate",
    "Spectate Player",
    "Spectating %s",
    "Server",
    "Server Info",
    "Copy Job ID",
    "Copied",
    "Job ID copied",
    "Clipboard unavailable",
}

local function buildLocale(values)
    local map = {}
    for index, key in ipairs(LocaleKeys) do
        if values[index] then
            map[key] = values[index]
        end
    end
    return map
end

Locales.th = buildLocale({
    "ผู้เล่นของคุณ",
    "ZenX Universal Hub",
    "เครดิต",
    "ฟีเจอร์",
    "เช็ค API ของ Executor",
    "เช็ค API ใหม่",
    "รีเฟรชข้อมูล",
    "เพิ่มความเร็ว",
    "ค่าความเร็ว",
    "เพิ่มแรงกระโดด",
    "แรงกระโดด",
    "เดินทะลุ",
    "กระโดดไม่จำกัด",
    "บิน",
    "ความเร็วบิน",
    "โหมดบิน",
    "หันตามกล้อง",
    "ปุ่มลัดบิน",
    "กันโดนปา",
    "รีเซ็ตตัวละคร",
    "นั่ง / ลุก",
    "เลือกเป้า",
    "ปาผู้เล่น",
    "รีเฟรชรายชื่อ",
    "Aimbot",
    "ปุ่มเล็ง",
    "ต้องกดปุ่มเล็ง",
    "วิธีเล็ง",
    "จุดที่เล็ง",
    "รัศมี FOV",
    "ความนุ่ม",
    "ระยะสูงสุด",
    "การทำนาย",
    "เช็คทีม",
    "เช็คกำแพง",
    "ข้ามคนตาย",
    "ล็อกเป้าเดิม",
    "แสดงวง FOV",
    "เล็งเงียบ",
    "ESP ผู้เล่น",
    "รีเฟรช ESP",
    "สไตล์กล่อง",
    "จุดเริ่มเส้น",
    "ความล่องหนของสี",
    "ความล่องหนของเส้นขอบ",
    "สีศัตรู",
    "สีทีมเรา",
    "สว่างเต็มที่",
    "เลือกผู้เล่น",
    "วาร์ปไปหาคนที่เลือก",
    "สถานะ",
    "กันโดนเตะ",
    "หลอกค่าการเคลื่อนที่",
    "กันหลุด AFK",
    "เข้าเซิร์ฟใหม่",
    "ปิดฮับ",
    "ธีม",
    "ภาษา",
    "ชื่อคอนฟิก",
    "บันทึกคอนฟิก",
    "เลือกคอนฟิก",
    "โหลดคอนฟิก",
    "รีเฟรชรายการคอนฟิก",
    "ฮับเครื่องมือผู้เล่นสำหรับทุกเกม สร้างด้วย FlurioreLib",
    "สร้างโดย: **Zenx Teams** · เวอร์ชัน: **2.1**",
    "ดูฟังก์ชันของ executor ที่ใช้ได้ตอนนี้",
    "กำลังโหลดข้อมูล...",
    "อัปเดตข้อมูลตัวละครและผู้เล่น",
    "จำค่า WalkSpeed เดิมไว้ แล้วคืนค่าตอนปิด",
    "16 - 120 studs ต่อวินาที",
    "ปุ่มแยกต่างหาก จำค่า JumpPower, JumpHeight และ UseJumpPower",
    "50 - 150 ใช้ JumpPower ชั่วคราวตอนเปิด",
    "ปิดการชนของชิ้นส่วนตัวละคร คืนค่าเดิมตอนปิด",
    "กระโดดซ้ำกลางอากาศได้",
    "บินด้วยความเร็วและโหมดด้านล่าง มือถือ: ใช้จอยเดิน แตะ Jump เพื่อขึ้น",
    "10 - 300 studs ต่อวินาที มีผลทันทีตอนบิน",
    "Camera บินตามทิศที่มองกล้อง Horizontal บินระดับเดิม",
    "ตอนบินให้ตัวละครหันตามกล้อง",
    "กดเพื่อเปิด/ปิดบิน",
    "ล้างความเร็วผิดปกติของตัวละคร และลดการชนกับคนใกล้ๆ",
    "เกิดตัวละครใหม่",
    "สลับสถานะนั่งของตัวละคร",
    "เป้าหมายที่จะปา",
    "หมุนตัวละครพุ่งผ่านผู้เล่นที่เลือก ต้องให้ตัวละครโหลดแล้ว",
    "อัปเดตรายชื่อในทุกเมนู",
    "ล็อกกล้องหรือเมาส์ไปที่เป้าที่ดีที่สุดในวง FOV",
    "กดค้างเพื่อเล็ง ตอนเปิดต้องกดปุ่มเล็ง",
    "เล็งเฉพาะตอนกดค้างปุ่มเล็ง",
    "ล็อกกล้อง หรือขยับเมาส์แบบสัมพันธ์",
    "ส่วนของร่างกายที่ใช้เป็นจุดเล็ง",
    "10 - 800 pixel รอบเคอร์เซอร์",
    "1 = ทันที ค่ามากจะช้าลง",
    "50 - 3000 studs",
    "0 - 500 ms ทำนายความเร็วของเป้า",
    "ข้ามผู้เล่นในทีมเดียวกัน",
    "ข้ามเป้าที่ซ่อนหลังสิ่งกีดขวาง",
    "ข้ามตัวละครที่เลือดเป็น 0",
    "คงเป้าเดิมไว้ตราบที่ยังใช้ได้",
    "วาดวงรัศมี FOV รอบเคอร์เซอร์",
    "เปลี่ยนจุดที่เมาส์โดนและเป้า ไปยังเป้าที่เล็ง ผ่าน mouse hook",
    "ปุ่มหลักของทุกภาพด้านล่าง",
    "สร้างภาพผู้เล่นใหม่",
    "กรอบเต็ม หรือเฉพาะมุม",
    "เส้นเริ่มจากตรงไหนบนจอ",
    "0 = ทึบ, 1 = ล่องหนเต็มที่",
    "0 = เส้นทึบ, 1 = ซ่อนเส้น",
    "สีของผู้เล่นทีมอื่น",
    "สีของผู้เล่นในทีมเรา",
    "จำค่าแสงเดิมไว้ แล้วคืนค่าตอนปิด",
    "เลือกผู้เล่นที่จะวาร์ปไปใกล้ๆ",
    "ย้ายไปข้างตัวละครผู้เล่นที่เลือก",
    "ทำงานเองตอนโหลดฮับ และคืนค่าตอนปิด ตัวเลือกด้านล่างคุมว่าเปลี่ยนอะไรบ้าง",
    "ข้ามคำสั่ง Kick ที่สคริปต์เกมส่งมาหาเรา",
    "ส่งค่าเดิมให้สคริปต์เกมเห็น ตอนเปิดเพิ่มความเร็วหรือแรงกระโดด",
    "จัดการเหตุการณ์ว่างงานของเรา",
    "กลับเข้าเซิร์ฟเดิม",
    "คืนค่าที่แก้ และลบ UI",
    "เลือกธีมสี มีผลทันที",
    "ภาษาของ UI เปลี่ยนทันที",
    "ชื่อที่ใช้ตอนบันทึกการตั้งค่า",
    "บันทึกการตั้งค่าปัจจุบันด้วยชื่อด้านบน",
    "เลือกคอนฟิกที่จะโหลด",
    "ใช้คอนฟิกที่เลือก",
    "โหลดรายการคอนฟิกใหม่",
    "ตัวละครยังไม่พร้อม",
    "รอให้ตัวละครโหลดก่อนเปิดบิน",
    "บล็อกการปาแล้ว",
    "ล้างความเร็วผิดปกติแล้ว",
    "ไม่รองรับ",
    "ไม่พบ Drawing API ปิดกล่อง มุม เส้น หลอดเลือด และโครงกระดูกแล้ว",
    "executor นี้ไม่มี mousemoverel ใช้โหมดกล้องแทน",
    "ติดตั้ง mouse hook บน executor นี้ไม่ได้",
    "ใช้ไม่ได้",
    "เลือกผู้เล่นที่ตัวละครโหลดแล้ว",
    "ล้มเหลว",
    "ใส่ชื่อคอนฟิกก่อน",
    "เลือกคอนฟิกก่อน",
    "executor ไม่มีฟังก์ชัน metatable ที่ต้องใช้ ปิด Bypass แล้ว",
    "ZenX Universal",
    "FlurioreLib โหลดแล้ว",
    "โมดูลฮับพร้อมแล้ว",
    "วัน",
    "ยังไม่เกิด",
    "กำลังปา %s",
    "ใช่",
    "ไม่",
    "บันทึกเป็น %s",
    "โหลด %s แล้ว",
    "ชื่อ",
    "ชื่อที่แสดง",
    "ไอดี",
    "อายุบัญชี",
    "เลือด",
    "WalkSpeed",
    "โหมดกระโดด",
    "ตำแหน่ง",
    "FOV กล้อง",
    "บันทึกแล้ว",
    "โหลดแล้ว",
    "ปา",
    "ทำงานอยู่",
    "หยุดแล้ว",
    "วาร์ป",
    "Metatable Bypass",
    "อื่นๆ",
    "หน้าตา",
    "คอนฟิก",
    "หลัก",
    "ผู้เล่น",
    "แกล้งคน",
    "เล็ง",
    "Esp",
    "ภาพ",
    "เครื่องมือ",
    "ตั้งค่า",
    "ยินดีต้อนรับ",
    "ระบบ",
    "ข้อมูลของคุณ",
    "การเคลื่อนที่",
    "ป้องกัน",
    "ตัวละคร",
    "ตัวกรองเป้า",
    "สไตล์",
    "Chams",
    "ป้ายชื่อ",
    "ตัวกรอง",
    "สี",
    "โลก",
    "กล่อง",
    "วาดกล่องตามขนาดจริงของตัวละครบนจอ",
    "เส้นนำสายตา",
    "เส้นจากขอบจอไปหาผู้เล่นแต่ละคน",
    "โครงกระดูก",
    "เส้นระหว่างข้อต่อ (Motor6D)",
    "หลอดเลือด",
    "หลอดเลือดแนวตั้งข้างกล่อง",
    "ไฮไลต์ผู้เล่น จะซ่อนหลังกำแพงถ้าเปิดเช็คกำแพง",
    "แสดงชื่อผู้เล่นเหนือหัว",
    "ระยะ",
    "แสดงระยะเป็น studs",
    "ตัวเลขเลือด",
    "แสดงตัวเลขเลือดเหนือหัว",
    "ซ่อนผู้เล่นในทีมเดียวกัน",
    "แสดงเฉพาะคนที่มองเห็นได้",
    "ซ่อนตัวละครที่เลือดเป็น 0",
    "ปาไม่ได้",
    "เลือกผู้เล่นในเมนูก่อน",
    "เป้าไม่ถูกต้อง",
    "ผู้เล่นที่เลือกออกจากเซิร์ฟไปแล้ว",
    "ใช้ไม่ได้ชั่วคราว",
    "ตัวละครเป้ายังไม่โหลดหรือตายแล้ว",
    "รอให้ตัวละครโหลดก่อน",
    "ถูกจำกัดสิทธิ์",
    "ตัวละครเราไม่ได้ถูก network-own ในเซิร์ฟนี้",
    "เป้าหมายหายไป ออกจากเซิร์ฟ หรือตัวละครถูกลบ",
    "เล็ง: Aimbot มี FOV, ความนุ่ม, การทำนาย, เช็คทีม/กำแพง และ Silent Aim",
    "Esp: Chams, กล่อง, กล่องมุม, เส้น, โครงกระดูก, หลอดเลือด, เช็คทีมและกำแพง",
    "ผู้เล่น · แกล้งคน · เล็ง · Esp · ภาพ · เครื่องมือ",
    "ผู้เล่น: ความเร็ว, กระโดด, เดินทะลุ, กระโดดไม่จำกัด, บิน และกันโดนปา",
    "ตั้งค่า: ธีม, ภาษา และบันทึก/โหลดคอนฟิก",
    "แกล้งคน: ปาผู้เล่นด้วยเมนูเลือกเป้า",
    "เครื่องมือ: วาร์ป, Metatable Bypass, กันหลุด AFK และเข้าเซิร์ฟใหม่",
    "ภาพ: สว่างเต็มที่",
    "สคริปเดียวใช้ได้เกือบทุกแมพ",
    "มือถือ: แตะ Jump เพื่อขึ้น",
    "ล็อก FOV",
    "ไม่มีหมอก",
    "ตั้งเวลาเอง",
    "ชั่วโมง",
    "กล้อง",
    "ตั้ง FOV เอง",
    "มุมมองกล้อง",
    "ดูผู้เล่น",
    "ดูผู้เล่นที่เลือก",
    "กำลังดู %s",
    "เซิร์ฟเวอร์",
    "ข้อมูลเซิร์ฟเวอร์",
    "คัดลอก Job ID",
    "คัดลอกแล้ว",
    "คัดลอก Job ID แล้ว",
    "ใช้คัดลอกไม่ได้",
})

Locales.vi = buildLocale({
    "Nhân vật của bạn",
    "ZenX Universal Hub",
    "Tác giả",
    "Tính năng",
    "Kiểm tra API Executor",
    "Kiểm tra API lại",
    "Làm mới thông tin",
    "Tăng tốc",
    "Tốc độ",
    "Tăng nhảy",
    "Lực nhảy",
    "Xuyên tường",
    "Nhảy vô hạn",
    "Bay",
    "Tốc độ bay",
    "Chế độ bay",
    "Quay theo camera",
    "Phím tắt bay",
    "Chống bị fling",
    "Đặt lại nhân vật",
    "Ngồi / Đứng",
    "Chọn mục tiêu",
    "Fling người chơi",
    "Làm mới danh sách",
    "Aimbot",
    "Phím ngắm",
    "Bắt buộc giữ phím ngắm",
    "Cách ngắm",
    "Bộ phận ngắm",
    "Bán kính FOV",
    "Làm mượt",
    "Khoảng cách tối đa",
    "Dự đoán",
    "Kiểm tra đội",
    "Kiểm tra tường",
    "Bỏ qua người chết",
    "Giữ mục tiêu",
    "Hiện vòng FOV",
    "Ngắm im lặng",
    "ESP người chơi",
    "Làm mới ESP",
    "Kiểu khung",
    "Điểm bắt đầu tia",
    "Độ trong suốt màu",
    "Độ trong suốt viền",
    "Màu địch",
    "Màu đồng đội",
    "Sáng tối đa",
    "Chọn người chơi",
    "Dịch chuyển tới người đã chọn",
    "Trạng thái",
    "Chặn bị kick",
    "Giả giá trị di chuyển",
    "Chống AFK",
    "Vào lại server",
    "Tắt hub",
    "Giao diện",
    "Ngôn ngữ",
    "Tên cấu hình",
    "Lưu cấu hình",
    "Chọn cấu hình",
    "Tải cấu hình",
    "Làm mới danh sách cấu hình",
    "Hub tiện ích người chơi cho mọi game, tạo bằng FlurioreLib.",
    "Tạo bởi: **Zenx Teams** · Phiên bản: **2.1**",
    "Xem các hàm executor đang có",
    "Đang tải thông tin người chơi...",
    "Cập nhật thông tin nhân vật và người chơi",
    "Lưu WalkSpeed hiện tại và khôi phục khi tắt",
    "16 - 120 studs mỗi giây",
    "Nút riêng; lưu JumpPower, JumpHeight và UseJumpPower",
    "50 - 150; tạm dùng JumpPower khi bật",
    "Tắt va chạm các phần nhân vật; khôi phục khi tắt",
    "Nhảy thêm khi đang trên không",
    "Bay với tốc độ và chế độ bên dưới. Điện thoại: dùng joystick và chạm Jump để bay lên",
    "10 - 300 studs mỗi giây; áp dụng ngay khi đang bay",
    "Camera bay theo hướng nhìn; Horizontal giữ nguyên độ cao",
    "Nhân vật quay theo hướng camera khi bay",
    "Nhấn để bật/tắt bay",
    "Triệt tiêu vận tốc bất thường và giảm va chạm với người gần đó",
    "Hồi sinh nhân vật hiện tại",
    "Đổi trạng thái ngồi của nhân vật",
    "Mục tiêu để fling",
    "Xoay nhân vật lao qua người chơi đã chọn. Cần nhân vật đã tải",
    "Cập nhật danh sách người chơi",
    "Khóa camera hoặc chuột vào mục tiêu tốt nhất trong vòng FOV",
    "Giữ để ngắm khi bật Bắt buộc giữ phím ngắm",
    "Chỉ ngắm khi đang giữ phím ngắm",
    "Khóa camera hoặc di chuyển chuột tương đối",
    "Bộ phận cơ thể dùng làm điểm ngắm",
    "10 - 800 pixel quanh con trỏ",
    "1 = tức thì, số lớn thì chậm hơn",
    "50 - 3000 studs",
    "0 - 500 ms dự đoán vận tốc mục tiêu",
    "Bỏ qua người cùng đội",
    "Bỏ qua mục tiêu bị che bởi vật thể",
    "Bỏ qua nhân vật có máu bằng 0",
    "Giữ mục tiêu hiện tại khi còn hợp lệ",
    "Vẽ bán kính FOV quanh con trỏ",
    "Chuyển Hit và Target của chuột sang mục tiêu qua mouse hook",
    "Công tắc chính cho mọi hiển thị người chơi bên dưới",
    "Dựng lại hiển thị người chơi hiện tại",
    "Khung viền đầy đủ hoặc góc",
    "Tia bắt đầu từ đâu trên màn hình",
    "0 = đặc, 1 = trong suốt hoàn toàn",
    "0 = viền đặc, 1 = ẩn viền",
    "Màu người chơi đội khác",
    "Màu người chơi cùng đội",
    "Lưu và khôi phục thông số Lighting gốc",
    "Chọn người chơi để dịch chuyển đến gần",
    "Di chuyển đến cạnh nhân vật người chơi đã chọn",
    "Tự chạy khi nạp hub và khôi phục khi tắt. Các tùy chọn bên dưới điều khiển phần thay đổi",
    "Bỏ qua lệnh LocalPlayer:Kick từ script game",
    "Báo giá trị đã lưu cho script game khi đang tăng tốc",
    "Xử lý sự kiện idle của mình",
    "Kết nối lại server này",
    "Khôi phục giá trị đã đổi và gỡ UI",
    "Chọn bảng màu. Áp dụng ngay",
    "Ngôn ngữ giao diện. Đổi ngay lập tức",
    "Tên dùng khi lưu cài đặt hiện tại",
    "Lưu cài đặt hiện tại với tên ở trên",
    "Chọn cấu hình đã lưu để tải",
    "Áp dụng cấu hình đã chọn",
    "Tải lại danh sách cấu hình",
    "Nhân vật chưa sẵn sàng",
    "Chờ nhân vật tải xong rồi mới bật bay",
    "Đã chặn fling",
    "Đã triệt tiêu vận tốc bất thường",
    "Không hỗ trợ",
    "Không tìm thấy Drawing API. Đã tắt khung, góc, tia, thanh máu và xương",
    "Executor này không có mousemoverel, dùng chế độ camera",
    "Không cài được mouse hook trên executor này",
    "Không khả dụng",
    "Chọn người chơi đã tải nhân vật",
    "Thất bại",
    "Nhập tên cấu hình trước",
    "Chọn cấu hình trước",
    "Executor thiếu hàm metatable cần thiết. Đã tắt Bypass",
    "ZenX Universal",
    "FlurioreLib đã tải",
    "Các module hub đã sẵn sàng",
    "ngày",
    "Chưa hồi sinh",
    "Đang fling %s",
    "có",
    "không",
    "Đã lưu thành %s",
    "Đã tải %s",
    "Tên",
    "Tên hiển thị",
    "User ID",
    "Tuổi tài khoản",
    "Máu",
    "WalkSpeed",
    "Chế độ nhảy",
    "Vị trí",
    "FOV camera",
    "Đã lưu",
    "Đã tải",
    "Fling",
    "Đang chạy",
    "Đã dừng",
    "Dịch chuyển",
    "Metatable Bypass",
    "Khác",
    "Giao diện",
    "Cấu hình",
    "Chính",
    "Người chơi",
    "Troll",
    "Ngắm",
    "Esp",
    "Hiển thị",
    "Tiện ích",
    "Cài đặt",
    "Chào mừng",
    "Hệ thống",
    "Thông tin của bạn",
    "Di chuyển",
    "Bảo vệ",
    "Nhân vật",
    "Bộ lọc mục tiêu",
    "Kiểu",
    "Chams",
    "Nhãn",
    "Bộ lọc",
    "Màu sắc",
    "Thế giới",
    "Khung",
    "Vẽ khung theo kích thước thật của nhân vật trên màn hình",
    "Tia",
    "Tia từ mép màn hình tới từng người chơi",
    "Xương",
    "Đường nối giữa các khớp (Motor6D)",
    "Thanh máu",
    "Thanh máu dọc bên cạnh khung",
    "Tô sáng người chơi; ẩn sau tường khi bật kiểm tra tường",
    "Hiện tên người chơi phía trên nhân vật",
    "Khoảng cách",
    "Hiện khoảng cách bằng studs",
    "Số máu",
    "Hiện số máu phía trên nhân vật",
    "Ẩn người chơi cùng đội",
    "Chỉ hiện người chơi trong tầm nhìn",
    "Ẩn nhân vật có máu bằng 0",
    "Không fling được",
    "Chọn người chơi trong menu trước",
    "Mục tiêu không hợp lệ",
    "Người chơi đã chọn không còn trong server",
    "Tạm thời không khả dụng",
    "Nhân vật mục tiêu chưa tải hoặc đã chết",
    "Chờ nhân vật tải xong",
    "Bị giới hạn quyền",
    "Phần gốc nhân vật không do bạn sở hữu mạng trên server này",
    "Mục tiêu đã mất, rời server hoặc nhân vật đã bị xóa",
    "Ngắm: Aimbot có FOV, làm mượt, dự đoán, kiểm tra đội/tường và Ngắm im lặng.",
    "Esp: Chams, khung, khung góc, tia, xương, thanh máu, kiểm tra đội và tường.",
    "Người chơi · Troll · Ngắm · Esp · Hiển thị · Tiện ích",
    "Người chơi: Tốc độ, Nhảy, Xuyên tường, Nhảy vô hạn, Bay và Chống bị fling.",
    "Cài đặt: giao diện, ngôn ngữ và lưu/tải cấu hình.",
    "Troll: Fling người chơi bằng menu chọn mục tiêu.",
    "Tiện ích: Dịch chuyển, Metatable Bypass, Chống AFK và Vào lại server.",
    "Hiển thị: Sáng tối đa.",
    "Một script dùng được gần mọi map.",
    "Điện thoại: chạm Jump để bay lên",
    "Khóa FOV",
    "Tắt sương mù",
    "Tự chỉnh giờ",
    "Giờ",
    "Camera",
    "Tự chỉnh FOV",
    "Góc nhìn",
    "Theo dõi",
    "Theo dõi người đã chọn",
    "Đang theo dõi %s",
    "Máy chủ",
    "Thông tin máy chủ",
    "Sao chép Job ID",
    "Đã sao chép",
    "Đã sao chép Job ID",
    "Không sao chép được",
})

Locales.ru = buildLocale({
    "Ваш персонаж",
    "ZenX Universal Hub",
    "Авторы",
    "Функции",
    "Проверка API executor",
    "Проверить API снова",
    "Обновить данные",
    "Ускорение",
    "Скорость",
    "Прыжок",
    "Сила прыжка",
    "Ноклип",
    "Бесконечный прыжок",
    "Полёт",
    "Скорость полёта",
    "Режим полёта",
    "Поворот за камерой",
    "Клавиша полёта",
    "Анти-флинг",
    "Сброс персонажа",
    "Сесть / встать",
    "Выбрать цель",
    "Флинг игрока",
    "Обновить список",
    "Аимбот",
    "Клавиша прицела",
    "Нужна клавиша прицела",
    "Способ наведения",
    "Точка наведения",
    "Радиус FOV",
    "Плавность",
    "Макс. дистанция",
    "Упреждение",
    "Проверка команды",
    "Проверка стен",
    "Игнорировать мёртвых",
    "Липкая цель",
    "Показать круг FOV",
    "Тихий прицел",
    "ESP игроков",
    "Обновить ESP",
    "Стиль рамки",
    "Начало линий",
    "Прозрачность заливки",
    "Прозрачность контура",
    "Цвет врагов",
    "Цвет своей команды",
    "Полная яркость",
    "Выбрать игрока",
    "Телепорт к выбранному",
    "Статус",
    "Блок кика",
    "Подмена движения",
    "Анти-AFK",
    "Переподключение",
    "Выгрузить хаб",
    "Тема",
    "Язык",
    "Имя конфига",
    "Сохранить конфиг",
    "Выбрать конфиг",
    "Загрузить конфиг",
    "Обновить список конфигов",
    "Хаб для игроков на любой карте, сделан на FlurioreLib",
    "Автор: **Zenx Teams** · Версия: **2.1**",
    "Список доступных функций executor",
    "Загрузка данных игрока...",
    "Обновить данные персонажа и игрока",
    "Запоминает текущий WalkSpeed и возвращает его при выключении",
    "16 - 120 studs в секунду",
    "Отдельный переключатель; сохраняет JumpPower, JumpHeight и UseJumpPower",
    "50 - 150; временно использует JumpPower при включении",
    "Отключает коллизии частей персонажа; при выключении возвращает значения",
    "Прыжок в воздухе",
    "Полёт с выбранной скоростью и режимом. Телефон: джойстиком двигаться, тап по Jump — вверх",
    "10 - 300 studs в секунду; применяется сразу в полёте",
    "Camera летит по взгляду; Horizontal держит высоту",
    "Персонаж поворачивается туда же, куда смотрит камера, пока летите",
    "Нажмите, чтобы включить или выключить полёт",
    "Гасит аномальную скорость персонажа и смягчает столкновения с игроками рядом",
    "Возродить текущего персонажа",
    "Переключает состояние сидения персонажа",
    "Цель для флинга",
    "Раскрутить персонажа через выбранного игрока. Нужен загруженный персонаж",
    "Обновить список во всех меню",
    "Наводит камеру или мышь на лучшую цель в круге FOV",
    "Удерживайте для прицеливания, если включена клавиша прицела",
    "Прицел только при удержании клавиши",
    "Наведение камерой или относительное движение мыши",
    "Часть тела, куда наводиться",
    "10 - 800 пикселей от курсора",
    "1 = мгновенно, большие значения медленнее",
    "50 - 3000 studs",
    "0 - 500 мс упреждения скорости цели",
    "Пропускать игроков своей команды",
    "Пропускать цели за препятствиями",
    "Пропускать персонажей с нулевым HP",
    "Держать текущую цель, пока она подходит",
    "Рисовать радиус FOV вокруг курсора",
    "Подменять Hit и Target мыши на цель через mouse hook",
    "Главный переключатель всех визуалов игроков ниже",
    "Пересоздать текущие визуалы игроков",
    "Полная рамка или уголки",
    "Откуда начинаются линии на экране",
    "0 = сплошная, 1 = полностью прозрачная",
    "0 = сплошной контур, 1 = скрыт",
    "Цвет игроков других команд",
    "Цвет игроков своей команды",
    "Сохраняет и возвращает исходные настройки Lighting",
    "Выберите игрока, рядом с которым телепортироваться",
    "Встать рядом с персонажем выбранного игрока",
    "Включается сам при загрузке хаба и выключается при выгрузке. Опции ниже задают, что он меняет",
    "Игнорировать вызовы LocalPlayer:Kick из скриптов игры",
    "Показывать скриптам игры сохранённые значения, пока включены ускорения",
    "Обрабатывать событие простоя",
    "Вернуться на этот сервер",
    "Вернуть изменённые значения и убрать UI",
    "Выберите цветовую тему. Применяется сразу",
    "Язык интерфейса. Меняется сразу",
    "Имя для сохранения текущих настроек",
    "Сохранить текущие настройки под указанным именем",
    "Выберите сохранённый конфиг для загрузки",
    "Применить выбранный конфиг",
    "Перезагрузить список конфигов",
    "Персонаж не готов",
    "Дождитесь загрузки персонажа, потом включайте полёт",
    "Флинг заблокирован",
    "Аномальная скорость сброшена",
    "Не поддерживается",
    "Drawing API не найден. Рамки, уголки, линии, полоска HP и скелет отключены",
    "В этом executor нет mousemoverel. Используется режим камеры",
    "Не удалось установить mouse hook на этом executor",
    "Недоступно",
    "Выберите игрока с загруженным персонажем",
    "Ошибка",
    "Сначала введите имя конфига",
    "Сначала выберите конфиг",
    "Executor не даёт нужных функций metatable. Bypass отключён",
    "ZenX Universal",
    "FlurioreLib загружен",
    "Модули хаба готовы",
    "дн.",
    "Не появился",
    "Флинг: %s",
    "да",
    "нет",
    "Сохранено как %s",
    "Загружено %s",
    "Имя",
    "Отображаемое имя",
    "User ID",
    "Возраст аккаунта",
    "HP",
    "WalkSpeed",
    "Режим прыжка",
    "Позиция",
    "FOV камеры",
    "Сохранено",
    "Загружено",
    "Флинг",
    "Активно",
    "Остановлено",
    "Телепорт",
    "Metatable Bypass",
    "Разное",
    "Внешний вид",
    "Конфиг",
    "Главная",
    "Игроки",
    "Троллинг",
    "Аим",
    "Esp",
    "Визуал",
    "Утилиты",
    "Настройки",
    "Добро пожаловать",
    "Система",
    "Ваши данные",
    "Движение",
    "Защита",
    "Персонаж",
    "Фильтры цели",
    "Стили",
    "Chams",
    "Подписи",
    "Фильтры",
    "Цвета",
    "Мир",
    "Рамка",
    "Рамка по реальному размеру персонажа на экране",
    "Линия",
    "Линия от края экрана до каждого игрока",
    "Скелет",
    "Линии между суставами (Motor6D)",
    "Полоска HP",
    "Вертикальная полоска HP рядом с рамкой",
    "Подсветка игроков; скрыта за стенами, если включена проверка стен",
    "Показывать имя игрока над персонажем",
    "Дистанция",
    "Показывать дистанцию в studs",
    "Текст HP",
    "Показывать числовое HP над персонажем",
    "Скрывать игроков своей команды",
    "Показывать только тех, кто в прямой видимости",
    "Скрывать персонажей с нулевым HP",
    "Флинг недоступен",
    "Сначала выберите игрока в списке",
    "Неверная цель",
    "Выбранного игрока уже нет на сервере",
    "Временно недоступно",
    "Персонаж цели не загружен или умер",
    "Дождитесь загрузки персонажа",
    "Ограничение прав",
    "Корневая часть вашего персонажа не принадлежит вам по сети на этом сервере",
    "Цель сброшена, игрок вышел или персонаж удалён",
    "Аим: аимбот с FOV, плавностью, упреждением, проверкой команды/стен и тихий прицел.",
    "Esp: Chams, рамка, уголки, линии, скелет, полоска HP, проверка команды и стен.",
    "Игроки · Троллинг · Аим · Esp · Визуал · Утилиты",
    "Игроки: скорость, прыжок, ноклип, бесконечный прыжок, полёт и анти-флинг.",
    "Настройки: темы, язык и сохранение/загрузка конфигов.",
    "Троллинг: флинг игрока через выпадающий список целей.",
    "Утилиты: телепорт, Metatable Bypass, анти-AFK и переподключение.",
    "Визуал: полная яркость.",
    "Один скрипт для почти любой карты.",
    "Телефон: тап по Jump — вверх",
    "Фиксировать FOV",
    "Без тумана",
    "Своё время",
    "Час",
    "Камера",
    "Свой FOV",
    "Угол обзора",
    "Наблюдение",
    "Смотреть за выбранным",
    "Наблюдение: %s",
    "Сервер",
    "Инфо о сервере",
    "Скопировать Job ID",
    "Скопировано",
    "Job ID скопирован",
    "Буфер обмена недоступен",
})

Locales.es = buildLocale({
    "Tu personaje",
    "ZenX Universal Hub",
    "Créditos",
    "Funciones",
    "Revisar API del executor",
    "Revisar API de nuevo",
    "Actualizar info",
    "Velocidad",
    "Valor de velocidad",
    "Salto extra",
    "Potencia de salto",
    "Noclip",
    "Salto infinito",
    "Volar",
    "Velocidad de vuelo",
    "Modo de vuelo",
    "Mirar con la cámara",
    "Tecla de vuelo",
    "Anti Fling",
    "Reiniciar personaje",
    "Sentarse / Levantarse",
    "Elegir objetivo",
    "Flinguear jugador",
    "Actualizar lista",
    "Aimbot",
    "Tecla de apuntar",
    "Requerir tecla de apuntar",
    "Método de apuntado",
    "Hueso objetivo",
    "Radio FOV",
    "Suavizado",
    "Distancia máxima",
    "Predicción",
    "Revisar equipo",
    "Revisar paredes",
    "Ignorar muertos",
    "Objetivo fijo",
    "Mostrar círculo FOV",
    "Apuntado silencioso",
    "ESP de jugadores",
    "Actualizar ESP",
    "Estilo de caja",
    "Origen de líneas",
    "Transparencia de relleno",
    "Transparencia de borde",
    "Color enemigo",
    "Color de equipo",
    "Brillo total",
    "Elegir jugador",
    "Teletransportar al elegido",
    "Estado",
    "Bloquear kick",
    "Falsear movimiento",
    "Anti-AFK",
    "Reconectar",
    "Descargar hub",
    "Tema",
    "Idioma",
    "Nombre de config",
    "Guardar config",
    "Elegir config",
    "Cargar config",
    "Actualizar lista de configs",
    "Hub de utilidades para jugadores en cualquier mapa, hecho con FlurioreLib",
    "Creado por: **Zenx Teams** · Versión: **2.1**",
    "Ver las funciones del executor disponibles",
    "Cargando info del jugador...",
    "Actualizar datos de tu personaje y jugador",
    "Guarda el WalkSpeed actual y lo restaura al apagar",
    "16 - 120 studs por segundo",
    "Interruptor propio; guarda JumpPower, JumpHeight y UseJumpPower",
    "50 - 150; usa JumpPower temporalmente al activar",
    "Desactiva colisiones de partes del personaje; restaura al apagar",
    "Saltar otra vez en el aire",
    "Vuela con la velocidad y modo de abajo. Móvil: mueve con el joystick y toca Jump para subir",
    "10 - 300 studs por segundo; se aplica al instante mientras vuelas",
    "Camera vuela según la vista; Horizontal mantiene la altura",
    "El personaje gira hacia donde mira la cámara mientras vuelas",
    "Pulsa para activar o desactivar el vuelo",
    "Quita velocidad anormal y suaviza choques con jugadores cercanos",
    "Revivir tu personaje actual",
    "Cambia el estado de sentado del personaje",
    "Objetivo para el fling",
    "Gira tu personaje a través del jugador elegido. Necesita personaje cargado",
    "Actualizar la lista de todos los menús",
    "Mueve la cámara o el ratón hacia el mejor objetivo dentro del FOV",
    "Mantén para apuntar si está activo requerir tecla",
    "Apunta solo mientras mantienes la tecla",
    "Bloqueo con cámara o movimiento relativo del ratón",
    "Parte del cuerpo usada como punto de mira",
    "10 - 800 píxeles alrededor del cursor",
    "1 = instantáneo, valores altos son más lentos",
    "50 - 3000 studs",
    "0 - 500 ms de anticipación a la velocidad del objetivo",
    "Ignorar jugadores de tu equipo",
    "Ignorar objetivos ocultos tras objetos",
    "Ignorar personajes con vida 0",
    "Mantener el objetivo actual mientras siga válido",
    "Dibujar el radio FOV alrededor del cursor",
    "Cambia Hit y Target del ratón al objetivo con mouse hook",
    "Interruptor principal de todos los visuales de jugadores de abajo",
    "Reconstruir los visuales de jugadores actuales",
    "Contorno completo o esquinas",
    "Desde dónde salen las líneas en pantalla",
    "0 = sólido, 1 = totalmente transparente",
    "0 = contorno sólido, 1 = oculto",
    "Color de jugadores de otros equipos",
    "Color de jugadores de tu equipo",
    "Guarda y restaura las propiedades originales de Lighting",
    "Elige un jugador para teletransportarte cerca",
    "Ponte al lado del personaje del jugador elegido",
    "Se activa solo al cargar el hub y se restaura al descargar. Las opciones de abajo controlan qué cambia",
    "Ignorar llamadas LocalPlayer:Kick de scripts del juego",
    "Mostrar a los scripts del juego los valores guardados mientras hay boosts",
    "Manejar el evento de inactividad local",
    "Reconectar a esta instancia del juego",
    "Restaurar valores cambiados y quitar la interfaz",
    "Elige un tema de color. Se aplica al instante",
    "Idioma de la interfaz. Cambia al momento",
    "Nombre para guardar la configuración actual",
    "Guardar la configuración actual con el nombre de arriba",
    "Elige una configuración guardada para cargar",
    "Aplicar la configuración elegida",
    "Recargar la lista de configs guardadas",
    "Personaje no listo",
    "Espera a que cargue tu personaje antes de activar el vuelo",
    "Fling bloqueado",
    "Se eliminó la velocidad anormal",
    "No compatible",
    "No se encontró Drawing API. Caja, esquinas, líneas, barra de vida y esqueleto desactivados",
    "Este executor no tiene mousemoverel. Se usa el modo cámara",
    "No se pudo instalar el mouse hook en este executor",
    "No disponible",
    "Elige un jugador con personaje cargado",
    "Falló",
    "Escribe primero un nombre de config",
    "Elige primero una config",
    "El executor no expone las funciones metatable necesarias. Bypass desactivado",
    "ZenX Universal",
    "FlurioreLib cargado",
    "Módulos del hub listos",
    "días",
    "Sin aparecer",
    "Flingueando a %s",
    "sí",
    "no",
    "Guardado como %s",
    "Cargado %s",
    "Nombre",
    "Nombre visible",
    "User ID",
    "Antigüedad de cuenta",
    "Vida",
    "WalkSpeed",
    "Modo de salto",
    "Posición",
    "FOV de cámara",
    "Guardado",
    "Cargado",
    "Fling",
    "Activo",
    "Detenido",
    "Teletransporte",
    "Metatable Bypass",
    "Varios",
    "Apariencia",
    "Config",
    "Inicio",
    "Jugadores",
    "Trolls",
    "Aim",
    "Esp",
    "Visual",
    "Utilidades",
    "Ajustes",
    "Bienvenido",
    "Sistema",
    "Tu información",
    "Movimiento",
    "Protección",
    "Personaje",
    "Filtros de objetivo",
    "Estilos",
    "Chams",
    "Etiquetas",
    "Filtros",
    "Colores",
    "Mundo",
    "Caja",
    "Caja según el tamaño real del personaje en pantalla",
    "Línea",
    "Línea desde el borde de la pantalla a cada jugador",
    "Esqueleto",
    "Líneas entre articulaciones (Motor6D)",
    "Barra de vida",
    "Barra de vida vertical junto a la caja",
    "Resaltar jugadores; se oculta tras paredes si Revisar paredes está activo",
    "Muestra el nombre del jugador sobre el personaje",
    "Distancia",
    "Muestra la distancia en studs",
    "Texto de vida",
    "Muestra la vida numérica sobre el personaje",
    "Ocultar jugadores de tu equipo",
    "Mostrar solo jugadores con línea de visión",
    "Ocultar personajes con vida 0",
    "Fling no disponible",
    "Elige un jugador en el menú primero",
    "Objetivo inválido",
    "El jugador elegido ya no está en el servidor",
    "No disponible por ahora",
    "El personaje objetivo no está cargado o murió",
    "Espera a que cargue el personaje",
    "Permiso limitado",
    "La parte raíz de tu personaje no es tuya en la red en este servidor",
    "Objetivo perdido, salió del servidor o su personaje fue eliminado",
    "Aim: Aimbot con FOV, suavizado, predicción y revisión de equipo/paredes, además de Apuntado silencioso.",
    "Esp: Chams, caja, caja de esquinas, línea, esqueleto, barra de vida, revisión de equipo y paredes.",
    "Jugadores · Trolls · Aim · Esp · Visual · Utilidades",
    "Jugadores: Velocidad, Salto, Noclip, Salto infinito, Volar y Anti Fling.",
    "Ajustes: temas, idioma y guardar/cargar configs.",
    "Trolls: Flinguear jugador con menú de objetivo.",
    "Utilidades: Teletransporte, Metatable Bypass, Anti-AFK y Reconectar.",
    "Visual: Brillo total.",
    "Un script para casi cualquier mapa.",
    "Móvil: toca Jump para subir",
    "Fijar FOV",
    "Sin niebla",
    "Hora propia",
    "Hora",
    "Cámara",
    "FOV propio",
    "Campo de visión",
    "Espectar",
    "Espectar al elegido",
    "Espectando a %s",
    "Servidor",
    "Info del servidor",
    "Copiar Job ID",
    "Copiado",
    "Job ID copiado",
    "Portapapeles no disponible",
})

Locales.id = buildLocale({
    "Karakter kamu",
    "ZenX Universal Hub",
    "Kredit",
    "Fitur",
    "Cek API executor",
    "Cek API lagi",
    "Segarkan info",
    "Speed Boost",
    "Nilai Speed",
    "Jump Boost",
    "Jump Power",
    "Noclip",
    "Lompat Tak Terbatas",
    "Terbang",
    "Kecepatan Terbang",
    "Mode Terbang",
    "Hadap Kamera",
    "Tombol Terbang",
    "Anti Fling",
    "Reset Karakter",
    "Duduk / Berdiri",
    "Pilih Target",
    "Fling Pemain",
    "Segarkan Daftar",
    "Aimbot",
    "Tombol Bidik",
    "Wajib Tombol Bidik",
    "Metode Bidik",
    "Bagian Target",
    "Radius FOV",
    "Penghalusan",
    "Jarak Maks",
    "Prediksi",
    "Cek Tim",
    "Cek Tembok",
    "Abaikan Mati",
    "Target Lengket",
    "Tampilkan Lingkaran FOV",
    "Silent Aim",
    "ESP Pemain",
    "Segarkan ESP",
    "Gaya Kotak",
    "Asal Garis",
    "Transparansi Isi",
    "Transparansi Garis Tepi",
    "Warna Musuh",
    "Warna Tim",
    "Fullbright",
    "Pilih Pemain",
    "Teleport ke Terpilih",
    "Status",
    "Blokir Kick",
    "Palsukan Gerakan",
    "Anti-AFK",
    "Gabung Ulang Server",
    "Tutup Hub",
    "Tema",
    "Bahasa",
    "Nama Config",
    "Simpan Config",
    "Pilih Config",
    "Muat Config",
    "Segarkan Daftar Config",
    "Hub utilitas pemain untuk semua map, dibuat dengan FlurioreLib",
    "Dibuat oleh: **Zenx Teams** · Versi: **2.1**",
    "Lihat fungsi executor yang tersedia",
    "Memuat info pemain...",
    "Perbarui data karakter dan pemainmu",
    "Simpan WalkSpeed sekarang dan kembalikan saat dimatikan",
    "16 - 120 studs per detik",
    "Toggle terpisah; menyimpan JumpPower, JumpHeight, dan UseJumpPower",
    "50 - 150; sementara pakai JumpPower saat aktif",
    "Matikan tabrakan bagian karakter; kembalikan nilai asli saat mati",
    "Lompat lagi saat di udara",
    "Terbang dengan kecepatan dan mode di bawah. HP: gerakkan joystick, ketuk Jump untuk naik",
    "10 - 300 studs per detik; langsung berlaku saat terbang",
    "Camera mengikuti arah pandang; Horizontal menjaga ketinggian",
    "Karakter menghadap arah kamera saat terbang",
    "Tekan untuk mengaktifkan atau mematikan Terbang",
    "Netralkan kecepatan aneh dan kurangi tabrakan dengan pemain terdekat",
    "Respawn karakter sekarang",
    "Ubah status duduk karakter",
    "Target untuk fling",
    "Putar karakter melewati pemain terpilih. Butuh karakter sudah dimuat",
    "Perbarui semua dropdown pemain",
    "Kunci kamera atau mouse ke target terbaik di dalam FOV",
    "Tahan untuk membidik saat Wajib Tombol Bidik aktif",
    "Bidik hanya saat tombol bidik ditahan",
    "Kunci kamera atau gerakan mouse relatif",
    "Bagian tubuh sebagai titik bidik",
    "10 - 800 piksel dari kursor",
    "1 = instan, angka besar lebih lambat",
    "50 - 3000 studs",
    "0 - 500 ms prediksi kecepatan target",
    "Lewati pemain di timmu",
    "Lewati target yang tertutup benda",
    "Lewati karakter dengan HP nol",
    "Pertahankan target sekarang selama masih valid",
    "Gambar radius FOV di sekitar kursor",
    "Ubah Hit dan Target mouse ke target bidik lewat mouse hook",
    "Saklar utama untuk semua visual pemain di bawah",
    "Bangun ulang visual pemain sekarang",
    "Garis penuh atau sudut",
    "Garis mulai dari mana di layar",
    "0 = padat, 1 = tembus pandang penuh",
    "0 = garis tepi padat, 1 = disembunyikan",
    "Warna pemain tim lain",
    "Warna pemain di timmu",
    "Simpan dan kembalikan properti Lighting asli",
    "Pilih pemain untuk teleport ke dekatnya",
    "Pindah ke samping karakter pemain terpilih",
    "Otomatis jalan saat hub dimuat dan dikembalikan saat dibongkar. Opsi di bawah mengatur apa yang diubah",
    "Abaikan panggilan LocalPlayer:Kick dari script game",
    "Tampilkan nilai tersimpan ke script game saat boost aktif",
    "Tangani event idle lokal",
    "Sambung ulang ke instance game ini",
    "Kembalikan nilai yang diubah dan hapus UI",
    "Pilih tema warna. Langsung berlaku",
    "Bahasa antarmuka. Langsung berganti",
    "Nama untuk menyimpan pengaturan sekarang",
    "Simpan pengaturan sekarang dengan nama di atas",
    "Pilih config tersimpan untuk dimuat",
    "Terapkan config yang dipilih",
    "Muat ulang daftar config",
    "Karakter belum siap",
    "Tunggu karakter dimuat sebelum mengaktifkan Terbang",
    "Fling diblokir",
    "Kecepatan aneh dinetralkan",
    "Tidak didukung",
    "Drawing API tidak ditemukan. Kotak, sudut, garis, bar HP, dan kerangka dinonaktifkan",
    "Executor ini tidak punya mousemoverel. Pakai mode kamera",
    "Mouse hook tidak bisa dipasang di executor ini",
    "Tidak tersedia",
    "Pilih pemain yang karakternya sudah dimuat",
    "Gagal",
    "Isi nama config dulu",
    "Pilih config dulu",
    "Executor tidak menyediakan fungsi metatable yang dibutuhkan. Bypass dimatikan",
    "ZenX Universal",
    "FlurioreLib dimuat",
    "Modul hub siap",
    "hari",
    "Belum muncul",
    "Fling %s",
    "ya",
    "tidak",
    "Disimpan sebagai %s",
    "Dimuat %s",
    "Nama",
    "Nama tampilan",
    "User ID",
    "Umur akun",
    "HP",
    "WalkSpeed",
    "Mode lompat",
    "Posisi",
    "FOV kamera",
    "Tersimpan",
    "Dimuat",
    "Fling",
    "Aktif",
    "Berhenti",
    "Teleport",
    "Metatable Bypass",
    "Lainnya",
    "Tampilan",
    "Config",
    "Utama",
    "Pemain",
    "Troll",
    "Bidik",
    "Esp",
    "Visual",
    "Utilitas",
    "Pengaturan",
    "Selamat datang",
    "Sistem",
    "Info kamu",
    "Gerakan",
    "Proteksi",
    "Karakter",
    "Filter Target",
    "Gaya",
    "Chams",
    "Label",
    "Filter",
    "Warna",
    "Dunia",
    "Kotak",
    "Kotak sesuai ukuran asli karakter di layar",
    "Garis",
    "Garis dari tepi layar ke tiap pemain",
    "Kerangka",
    "Garis antar sendi (Motor6D)",
    "Bar HP",
    "Bar HP vertikal di samping kotak",
    "Sorot pemain; tersembunyi di balik tembok jika Cek Tembok aktif",
    "Tampilkan nama pemain di atas karakter",
    "Jarak",
    "Tampilkan jarak dalam studs",
    "Teks HP",
    "Tampilkan angka HP di atas karakter",
    "Sembunyikan pemain di timmu",
    "Tampilkan hanya pemain yang terlihat",
    "Sembunyikan karakter dengan HP nol",
    "Fling tidak tersedia",
    "Pilih pemain di menu dulu",
    "Target tidak valid",
    "Pemain terpilih sudah tidak ada di server",
    "Sementara tidak tersedia",
    "Karakter target belum dimuat atau sudah mati",
    "Tunggu karakter dimuat",
    "Izin terbatas",
    "Bagian root karakter tidak dimiliki jaringanmu di server ini",
    "Target hilang, keluar dari server, atau karakternya dihapus",
    "Bidik: Aimbot dengan FOV, penghalusan, prediksi dan cek tim/tembok, plus Silent Aim.",
    "Esp: Chams, kotak, kotak sudut, garis, kerangka, bar HP, cek tim dan tembok.",
    "Pemain · Troll · Bidik · Esp · Visual · Utilitas",
    "Pemain: Speed, Jump, Noclip, Lompat Tak Terbatas, Terbang dan Anti Fling.",
    "Pengaturan: tema, bahasa dan simpan/muat config.",
    "Troll: Fling Pemain dengan dropdown target.",
    "Utilitas: Teleport, Metatable Bypass, Anti-AFK dan Gabung Ulang.",
    "Visual: Fullbright.",
    "Satu script untuk hampir semua map.",
    "HP: ketuk Jump untuk naik",
    "Kunci FOV",
    "Tanpa kabut",
    "Waktu sendiri",
    "Jam",
    "Kamera",
    "FOV sendiri",
    "Sudut pandang",
    "Lihat pemain",
    "Lihat pemain terpilih",
    "Melihat %s",
    "Server",
    "Info server",
    "Salin Job ID",
    "Tersalin",
    "Job ID tersalin",
    "Clipboard tidak tersedia",
})

end
local function runtimeStatus()
    local checks = {
        "gethui", "setclipboard", "request", "http_request", "getrawmetatable",
        "newcclosure", "checkcaller", "clonefunction", "setreadonly", "getnamecallmethod",
        "isnetworkowner", "mousemoverel", "Drawing",
    }
    local environment = _G
    if type(getfenv) == "function" then
        local ok, result = pcall(getfenv, 0)
        if ok and type(result) == "table" then
            environment = result
        end
    end
    local available = {}
    for _, name in ipairs(checks) do
        local value = environment[name]
        if value == nil then
            value = _G[name]
        end
        table.insert(available, name .. ": " .. (value ~= nil and L("yes") or L("no")))
    end
    return table.concat(available, "\n")
end

local function gatedTrigger(build, handler)
    return function(...)
        if Unloaded or build ~= buildCount then
            return
        end
        handler(...)
    end
end

local function sanitizeConfigName(text)
    local cleaned = tostring(text or ""):gsub('[\\/:*?"<>|]', "")
    return cleaned:match("^%s*(.-)%s*$") or ""
end

local function refreshConfigList(source, selectName)
    if not (source and UI.ConfigDropdown) then
        return
    end
    local names = source:ListConfigs(CONFIG_FOLDER)
    table.sort(names)
    UI.ConfigDropdown:Refresh(names, selectName and {selectName} or {})
end

local function buildUI()
    buildCount = buildCount + 1
    local build = buildCount
    UI.Dropdowns = {}
    UI.ConfigName = UI.ConfigName or ""

    local window = FlurioreLib:MakeGui({
        NameHub = "Zenx",
        Description = "Beta",
        Color = COLOR_PINK,
        UIScale = 0.9,
        TextScale = 1,
        Theme = copyTable(ZenThemes["Neon Pink"]),
    })
    if not window then
        error("[ZenX] FlurioreLib did not create a window")
    end
    local ui = localized(window)

    do
        local TabMain = ui:CreateTab({Name = "Main", Icon = ""})
        local MainSection = TabMain:AddSection("Welcome")
        MainSection:AddParagraph({
            Title = "Zenx",
            Content = "",
        })
        MainSection:AddDiscord({
            Invite = "https://discord.gg/wKXdq8kNTx",
            Refresh = 120,
        })
        MainSection:AddParagraph({
            Title = "Credits",
            Content = "Created by: **Zenx Teams** · Version: **2.1**",
        })

        local RuntimeSection = TabMain:AddSection("Runtime")
        local runtimeParagraph = RuntimeSection:AddParagraph({
            Title = "Executor API Check",
            Content = runtimeStatus(),
        })
        RuntimeSection:AddButton({
            Title = "Refresh API Check",
            Content = "",
            Callback = function()
                runtimeParagraph:Set({Title = "Executor API Check", Content = runtimeStatus()})
            end,
        })
    end

    do
        local TabPlayers = ui:CreateTab({Name = "Players", Icon = ""})
        local InfoSection = TabPlayers:AddSection("Your Information")
        UI.PlayerInfo = InfoSection:AddParagraph({
            Title = "Local Player",
            Content = "Loading player information...",
        })
        InfoSection:AddButton({
            Title = "Refresh Information",
            Content = "",
            Callback = refreshPlayerInfo,
        })

        local MovementSection = TabPlayers:AddSection("Movement")
        MovementSection:AddToggle({
            Title = "Speed Boost",
            Content = "",
            Default = State.SpeedEnabled,
            Flag = "speedBoost",
            Callback = setSpeed,
        })
        MovementSection:AddSlider({
            Title = "Speed Value",
            Content = "",
            Min = 16,
            Max = 120,
            Default = State.SpeedValue,
            Increment = 1,
            Flag = "speedValue",
            Callback = updateSpeed,
        })
        MovementSection:AddToggle({
            Title = "Jump Boost",
            Content = "",
            Default = State.JumpEnabled,
            Flag = "jumpBoost",
            Callback = setJump,
        })
        MovementSection:AddSlider({
            Title = "Jump Power",
            Content = "",
            Min = 50,
            Max = 150,
            Default = State.JumpValue,
            Increment = 1,
            Flag = "jumpPower",
            Callback = updateJump,
        })
        MovementSection:AddToggle({
            Title = "Noclip",
            Content = "",
            Default = State.NoclipEnabled,
            Flag = "noclip",
            Callback = setNoclip,
        })
        MovementSection:AddToggle({
            Title = "Infinite Jump",
            Content = "",
            Default = State.InfiniteJumpEnabled,
            Flag = "infiniteJump",
            Callback = setInfiniteJump,
        })

        local FlySection = TabPlayers:AddSection("Fly")
        UI.FlyToggle = FlySection:AddToggle({
            Title = "Fly",
            Content = "",
            Default = State.FlyEnabled,
            Flag = "flyEnabled",
            Callback = setFly,
        })
        FlySection:AddSlider({
            Title = "Fly Speed",
            Content = "",
            Min = 10,
            Max = 300,
            Default = State.FlySpeed,
            Increment = 1,
            Flag = "flySpeed",
            Callback = setterNumber(State, "FlySpeed", 10, 300, 60),
        })
        FlySection:AddDropdown({
            Title = "Fly Mode",
            Content = "",
            Multi = false,
            Options = {"Camera", "Horizontal"},
            Default = {State.FlyMode},
            Flag = "flyMode",
            Callback = setFlyMode,
        })
        FlySection:AddToggle({
            Title = "Face Camera",
            Content = "",
            Default = State.FlyFaceCamera,
            Flag = "flyFaceCamera",
            Callback = setterFlag(State, "FlyFaceCamera"),
        })
        FlySection:AddKeybind({
            Title = "Fly Keybind",
            Content = "",
            Default = Enum.KeyCode.F,
            Mode = "Toggle",
            OnTrigger = gatedTrigger(build, function()
                setFly(not State.FlyEnabled)
                if UI.FlyToggle then
                    UI.FlyToggle:Set(State.FlyEnabled)
                end
            end),
        })

        local ProtectionSection = TabPlayers:AddSection("Protection")
        ProtectionSection:AddToggle({
            Title = "Anti Fling",
            Content = "",
            Default = State.AntiFlingEnabled,
            Flag = "antiFling",
            Callback = setAntiFling,
        })

        local CharacterSection = TabPlayers:AddSection("Character")
        CharacterSection:AddButton({
            Title = "Reset Character",
            Content = "",
            Callback = function()
                local humanoid = getHumanoid()
                if humanoid then
                    humanoid.Health = 0
                end
            end,
        })
        CharacterSection:AddButton({
            Title = "Sit / Unsit",
            Content = "",
            Callback = function()
                local humanoid = getHumanoid()
                if humanoid then
                    humanoid.Sit = not humanoid.Sit
                end
            end,
        })
    end

    do
        local TabTrolls = ui:CreateTab({Name = "Trolls", Icon = ""})
        local FlingSection = TabTrolls:AddSection("Fling Player")
        local flingDropdown = FlingSection:AddDropdown({
            Title = "Target Player",
            Content = "",
            Multi = false,
            Options = {},
            Default = {},
            Flag = "flingTarget",
            Callback = function(value)
                setFlingTarget(firstSelected(value))
            end,
        })
        table.insert(UI.Dropdowns, flingDropdown)
        UI.FlingToggle = FlingSection:AddToggle({
            Title = "Fling Player",
            Content = "",
            Default = false,
            Callback = setFling,
        })
        FlingSection:AddButton({
            Title = "Refresh Player List",
            Content = "",
            Callback = rebuildPlayerList,
        })
        local SpectateSection = TabTrolls:AddSection("Spectate")
        UI.SpectateToggle = SpectateSection:AddToggle({
            Title = "Spectate Player",
            Content = "",
            Default = false,
            Callback = setSpectate,
        })
    end


    do
        local TabAim = ui:CreateTab({Name = "Aim", Icon = ""})
        local AimbotSection = TabAim:AddSection("Aimbot")
        AimbotSection:AddToggle({
            Title = "Aimbot",
            Content = "",
            Default = State.AimEnabled,
            Flag = "aimEnabled",
            Callback = setAimbot,
        })
        AimbotSection:AddKeybind({
            Title = "Aim Key",
            Content = "",
            Default = Enum.KeyCode.Q,
            Mode = "Hold",
            OnTrigger = gatedTrigger(build, function(state)
                Runtime.AimKeyHeld = state and true or false
            end),
        })
        AimbotSection:AddToggle({
            Title = "Require Aim Key",
            Content = "",
            Default = State.AimRequireKey,
            Flag = "aimRequireKey",
            Callback = setterFlag(State, "AimRequireKey"),
        })
        AimbotSection:AddDropdown({
            Title = "Aim Method",
            Content = "Camera lock or relative mouse movement",
            Multi = false,
            Options = {"Camera", "Mouse"},
            Default = {State.AimMethod},
            Flag = "aimMethod",
            Callback = setAimMethod,
        })
        AimbotSection:AddDropdown({
            Title = "Target Bone",
            Content = "",
            Multi = false,
            Options = {"Head", "UpperTorso", "HumanoidRootPart", "Torso"},
            Default = {State.AimBone},
            Flag = "aimBone",
            Callback = setAimBone,
        })
        AimbotSection:AddSlider({
            Title = "FOV Radius",
            Content = "",
            Min = 10,
            Max = 800,
            Default = State.AimFOV,
            Increment = 1,
            Flag = "aimFOV",
            Callback = setterNumber(State, "AimFOV", 10, 800, 120),
        })
        AimbotSection:AddSlider({
            Title = "Smoothing",
            Content = "1 = instant, higher values are slower",
            Min = 1,
            Max = 20,
            Default = State.AimSmoothing,
            Increment = 1,
            Flag = "aimSmoothing",
            Callback = setterNumber(State, "AimSmoothing", 1, 20, 4),
        })
        AimbotSection:AddSlider({
            Title = "Max Distance",
            Content = "",
            Min = 50,
            Max = 3000,
            Default = State.AimMaxDistance,
            Increment = 10,
            Flag = "aimMaxDistance",
            Callback = setterNumber(State, "AimMaxDistance", 50, 3000, 1000),
        })
        AimbotSection:AddSlider({
            Title = "Prediction",
            Content = "0 - 500 ms of target velocity lead",
            Min = 0,
            Max = 500,
            Default = State.AimPrediction,
            Increment = 5,
            Flag = "aimPrediction",
            Callback = setterNumber(State, "AimPrediction", 0, 500, 100),
        })

        local FilterSection = TabAim:AddSection("Target Filters")
        FilterSection:AddToggle({
            Title = "Team Check",
            Content = "",
            Default = State.AimTeamCheck,
            Flag = "aimTeamCheck",
            Callback = setterFlag(State, "AimTeamCheck"),
        })
        FilterSection:AddToggle({
            Title = "Wall Check",
            Content = "",
            Default = State.AimWallCheck,
            Flag = "aimWallCheck",
            Callback = setterFlag(State, "AimWallCheck"),
        })
        FilterSection:AddToggle({
            Title = "Ignore Dead",
            Content = "",
            Default = State.AimIgnoreDead,
            Flag = "aimIgnoreDead",
            Callback = setterFlag(State, "AimIgnoreDead"),
        })
        FilterSection:AddToggle({
            Title = "Sticky Target",
            Content = "",
            Default = State.AimSticky,
            Flag = "aimSticky",
            Callback = setterFlag(State, "AimSticky"),
        })
        FilterSection:AddToggle({
            Title = "Lock FOV",
            Content = "",
            Default = State.AimLockFOV,
            Flag = "aimLockFOV",
            Callback = function(value)
                State.AimLockFOV = not not value
                updateFOVCircle()
            end,
        })
        FilterSection:AddToggle({
            Title = "Show FOV Circle",
            Content = "",
            Default = State.AimShowFOV,
            Flag = "aimShowFOV",
            Callback = setShowFOV,
        })

        local SilentSection = TabAim:AddSection("Silent Aim")
        UI.SilentToggle = SilentSection:AddToggle({
            Title = "Silent Aim",
            Content = "",
            Default = State.SilentAim,
            Flag = "silentAim",
            Callback = setSilentAim,
        })
    end

    do
        local TabEsp = ui:CreateTab({Name = "Esp", Icon = ""})

        local function espToggle(section, title, content, key)
            section:AddToggle({
                Title = title,
                Content = content,
                Default = State.ESP[key],
                Flag = "esp" .. key,
                Callback = setterFlag(State.ESP, key),
            })
        end

        local ESPSection = TabEsp:AddSection("Player ESP")
        ESPSection:AddToggle({
            Title = "Player ESP",
            Content = "",
            Default = State.ESPEnabled,
            Flag = "espEnabled",
            Callback = setESP,
        })
        ESPSection:AddButton({
            Title = "Refresh ESP",
            Content = "",
            Callback = function()
                if State.ESPEnabled then
                    clearESP()
                end
            end,
        })

        local StyleSection = TabEsp:AddSection("Styles")
        espToggle(StyleSection, "Chams", "Highlight players; hidden behind walls when Wall Check is on", "Chams")
        espToggle(StyleSection, "Box", "Box drawn from the projected bounding box", "Box")
        StyleSection:AddDropdown({
            Title = "Box Style",
            Content = "",
            Multi = false,
            Options = {"Full", "Corner"},
            Default = {State.ESP.BoxStyle},
            Flag = "espBoxStyle",
            Callback = choiceSetter(State.ESP, "BoxStyle", {Full = true, Corner = true}),
        })
        espToggle(StyleSection, "Tracer", "Line from the screen edge to each player", "Tracer")
        StyleSection:AddDropdown({
            Title = "Tracer Origin",
            Content = "",
            Multi = false,
            Options = {"Bottom", "Center", "Top"},
            Default = {State.ESP.TracerOrigin},
            Flag = "espTracerOrigin",
            Callback = choiceSetter(State.ESP, "TracerOrigin", {Bottom = true, Center = true, Top = true}),
        })
        espToggle(StyleSection, "Skeleton", "Lines between joints (Motor6D)", "Skeleton")
        espToggle(StyleSection, "Health Bar", "Vertical health bar beside the box", "HealthBar")

        local ChamsSection = TabEsp:AddSection("Chams")
        ChamsSection:AddSlider({
            Title = "Fill Transparency",
            Content = "0 = solid, 1 = fully see-through",
            Min = 0,
            Max = 1,
            Default = State.ESP.ChamsFill,
            Increment = 0.05,
            Flag = "espChamsFill",
            Callback = setterNumber(State.ESP, "ChamsFill", 0, 1, 0.55),
        })
        ChamsSection:AddSlider({
            Title = "Outline Transparency",
            Content = "0 = solid outline, 1 = hidden",
            Min = 0,
            Max = 1,
            Default = State.ESP.ChamsOutline,
            Increment = 0.05,
            Flag = "espChamsOutline",
            Callback = setterNumber(State.ESP, "ChamsOutline", 0, 1, 0),
        })

        local LabelSection = TabEsp:AddSection("Labels")
        espToggle(LabelSection, "Name", "Show the player name above the character", "Name")
        espToggle(LabelSection, "Distance", "Show distance in studs", "Distance")
        espToggle(LabelSection, "Health Text", "Show numeric health above the character", "Health")

        local FilterSection = TabEsp:AddSection("Filters")
        espToggle(FilterSection, "Team Check", "Hide players on your team", "TeamCheck")
        espToggle(FilterSection, "Wall Check", "Show only players in line of sight", "WallCheck")
        espToggle(FilterSection, "Ignore Dead", "Hide characters with zero health", "IgnoreDead")
        FilterSection:AddSlider({
            Title = "Max Distance",
            Content = "",
            Min = 50,
            Max = 3000,
            Default = State.ESP.MaxDistance,
            Increment = 10,
            Flag = "espMaxDistance",
            Callback = setterNumber(State.ESP, "MaxDistance", 50, 3000, 1000),
        })

        local ColorSection = TabEsp:AddSection("Colors")
        ColorSection:AddColorPicker({
            Title = "Enemy Color",
            Content = "",
            Default = ESPColors.Enemy,
            Flag = "espEnemyColor",
            Callback = function(color)
                ESPColors.Enemy = color
            end,
        })
        ColorSection:AddColorPicker({
            Title = "Team Color",
            Content = "",
            Default = ESPColors.Team,
            Flag = "espTeamColor",
            Callback = function(color)
                ESPColors.Team = color
            end,
        })
    end

    do
        local TabVisual = ui:CreateTab({Name = "Visual", Icon = ""})
        local WorldSection = TabVisual:AddSection("World")
        WorldSection:AddToggle({
            Title = "Fullbright",
            Content = "",
            Default = State.FullbrightEnabled,
            Flag = "fullbright",
            Callback = setFullbright,
        })
        WorldSection:AddToggle({
            Title = "No Fog",
            Content = "",
            Default = State.NoFogEnabled,
            Flag = "noFog",
            Callback = setNoFog,
        })
        WorldSection:AddToggle({
            Title = "Custom Time",
            Content = "",
            Default = State.CustomTimeEnabled,
            Flag = "customTime",
            Callback = setCustomTime,
        })
        WorldSection:AddSlider({
            Title = "Hour",
            Content = "",
            Min = 0,
            Max = 24,
            Default = State.TimeHour,
            Increment = 1,
            Flag = "timeHour",
            Callback = setTimeHour,
        })
        local CameraSection = TabVisual:AddSection("Camera")
        CameraSection:AddToggle({
            Title = "Custom FOV",
            Content = "",
            Default = State.CustomFOVEnabled,
            Flag = "customFOV",
            Callback = setCustomFOV,
        })
        CameraSection:AddSlider({
            Title = "Field of View",
            Content = "",
            Min = 30,
            Max = 120,
            Default = State.CameraFOV,
            Increment = 1,
            Flag = "cameraFOV",
            Callback = setCameraFOV,
        })
    end

    do
        local TabUtility = ui:CreateTab({Name = "Utility", Icon = ""})
        local TeleportSection = TabUtility:AddSection("Teleport")
        local teleportDropdown = TeleportSection:AddDropdown({
            Title = "Select Player",
            Content = "",
            Multi = false,
            Options = {},
            Default = {},
            Callback = function() end,
        })
        table.insert(UI.Dropdowns, teleportDropdown)
        TeleportSection:AddButton({
            Title = "Refresh Player List",
            Content = "",
            Callback = rebuildPlayerList,
        })
        TeleportSection:AddButton({
            Title = "Teleport Selected",
            Content = "",
            Callback = function()
                local name = firstSelected(teleportDropdown.Value)
                local target = name and Players:FindFirstChild(name)
                local targetRoot = target and getRoot(target.Character)
                local myRoot = getRoot()
                if targetRoot and myRoot then
                    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                else
                    notify("Teleport", "Unavailable", "Select a player with a loaded character", COLOR_RED)
                end
            end,
        })

        local ServerSection = TabUtility:AddSection("Server")
        ServerSection:AddParagraph({
            Title = "Server Info",
            Content = "Place " .. tostring(game.PlaceId) .. "\nJob " .. tostring(game.JobId) .. "\nPlayers " .. tostring(#Players:GetPlayers()),
        })
        ServerSection:AddButton({
            Title = "Copy Job ID",
            Content = "",
            Callback = function()
                if type(setclipboard) == "function" then
                    setclipboard(tostring(game.JobId))
                    notify("Server", "Copied", "Job ID copied", COLOR_GREEN)
                else
                    notify("Server", "Unavailable", "Clipboard unavailable", COLOR_YELLOW)
                end
            end,
        })

        local MiscSection = TabUtility:AddSection("Miscellaneous")
        MiscSection:AddToggle({
            Title = "Anti-AFK",
            Content = "",
            Default = State.AntiAFKEnabled,
            Flag = "antiAFK",
            Callback = setAntiAFK,
        })
        MiscSection:AddButton({
            Title = "Rejoin Server",
            Content = "",
            Callback = function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
            end,
        })
        MiscSection:AddButton({
            Title = "Unload Hub",
            Content = "",
            Callback = function()
                cleanup()
                pcall(function()
                    window:DestroyGui()
                end)
            end,
        })
    end

    do
        local TabSettings = ui:CreateTab({Name = "Settings", Icon = ""})

        local AppearanceSection = TabSettings:AddSection("Appearance")
        AppearanceSection:AddDropdown({
            Title = "Theme",
            Content = "",
            Multi = false,
            Options = ThemeOrder,
            Default = {ActiveTheme},
            Flag = "zenxTheme",
            Callback = function(value)
                local name = firstSelected(value)
                if not name then
                    return
                end
                ActiveTheme = name
                if ZenThemes[name] then
                    window:SetTheme(copyTable(ZenThemes[name]))
                else
                    window:SetThemePreset(name)
                end
            end,
        })

        local languageNames = {}
        for index, item in ipairs(LanguageList) do
            languageNames[index] = item.Name
        end
        AppearanceSection:AddDropdown({
            Title = "Language",
            Content = "",
            Multi = false,
            Options = languageNames,
            Default = {languageNameOf(Language)},
            Callback = function(value)
                local code = languageCodeOf(firstSelected(value))
                if not code or code == Language then
                    return
                end
                Language = code
                saveLanguage(code)
                task.defer(function()
                    rebuildWindow()
                end)
            end,
        })

        local ConfigSection = TabSettings:AddSection("Config")
        ConfigSection:AddInput({
            Title = "Config Name",
            Content = "",
            Callback = function(text)
                UI.ConfigName = text
            end,
        })
        ConfigSection:AddButton({
            Title = "Save Config",
            Content = "",
            Callback = function()
                local name = sanitizeConfigName(UI.ConfigName)
                if name == "" then
                    notify("Config", "Failed", "Enter a config name first", COLOR_RED)
                    return
                end
                local ok, result = Window:SaveConfig(CONFIG_FOLDER, name)
                if ok then
                    notify("Config", "Saved", string.format(L("Saved as %s"), name), COLOR_GREEN)
                    refreshConfigList(Window, name)
                else
                    notify("Config", "Failed", tostring(result), COLOR_RED)
                end
            end,
        })
        UI.ConfigDropdown = ConfigSection:AddDropdown({
            Title = "Select Config",
            Content = "",
            Multi = false,
            Options = {},
            Default = {},
            Callback = function() end,
        })
        ConfigSection:AddButton({
            Title = "Load Config",
            Content = "",
            Callback = function()
                local name = firstSelected(UI.ConfigDropdown.Value)
                if not name or name == "" then
                    notify("Config", "Failed", "Select a config first", COLOR_RED)
                    return
                end
                local ok, result = Window:LoadConfig(CONFIG_FOLDER, name)
                if ok then
                    notify("Config", "Loaded", string.format(L("Loaded %s"), name), COLOR_GREEN)
                else
                    notify("Config", "Failed", tostring(result), COLOR_RED)
                end
            end,
        })
        ConfigSection:AddButton({
            Title = "Refresh Config List",
            Content = "",
            Callback = function()
                refreshConfigList(Window)
            end,
        })
    end

    refreshConfigList(window)
    return window
end


addConnection(LP.CharacterAdded:Connect(function(character)
    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        if Unloaded then
            return
        end
        if humanoid then
            applyMovement(humanoid)
            refreshPlayerInfo()
        end
        if State.NoclipEnabled then
            task.wait(0.2)
            if Unloaded then
                return
            end
            for _, object in ipairs(character:GetDescendants()) do
                if object:IsA("BasePart") then
                    saveCollision(object)
                end
            end
        end
    end)
end))

local function scheduleRebuild()
    task.defer(function()
        if not Unloaded then
            rebuildPlayerList()
        end
    end)
end

addConnection(Players.PlayerAdded:Connect(scheduleRebuild))
addConnection(Players.PlayerRemoving:Connect(scheduleRebuild))

cleanup = function()
    if Unloaded then
        return
    end
    setFling(false)
    setFly(false)
    setAntiFling(false)
    setSpeed(false)
    setJump(false)
    setNoclip(false)
    setInfiniteJump(false)
    setESP(false)
    setSilentAim(false)
    setAimbot(false)
    State.BypassEnabled = false
    setFullbright(false)
    setNoFog(false)
    setCustomTime(false)
    setCustomFOV(false)
    setSpectate(false)
    setAntiAFK(false)
    Unloaded = true

    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(Connections)

    if Runtime.AimBound then
        pcall(function()
            RunService:UnbindFromRenderStep(AIM_STEP_NAME)
        end)
        Runtime.AimBound = false
    end
    destroyDrawing(Runtime.FOVCircle)
    Runtime.FOVCircle = nil

    for key, value in pairs(Runtime) do
        if typeof(value) == "RBXScriptConnection" then
            pcall(function()
                value:Disconnect()
            end)
        end
        Runtime[key] = nil
    end

    restoreHooks()
    restoreAntiFling()
    restoreSpeed()
    restoreJump()

    if ESPFolder and ESPFolder.Parent then
        ESPFolder:Destroy()
    end
end

rebuildWindow = function()
    if Unloaded then
        return
    end
    local snapshot = Window and Window:GetFlags() or {}
    if Window then
        pcall(function()
            Window:DestroyGui()
        end)
    end
    Window = buildUI()
    Window:SetFlags(snapshot)
    refreshPlayerInfo()
    rebuildPlayerList()
    refreshConfigList(Window)
end

Window = buildUI()

if canHook() and type(getnamecallmethod) == "function" and installGameHook() then
    State.BypassEnabled = true
else
    notify("Metatable Bypass", "Unsupported", "Executor does not expose the required metatable functions. Bypass is disabled", COLOR_YELLOW)
end

notify("ZenX Universal", "FlurioreLib loaded", "Hub modules initialized", COLOR_GREEN)
refreshPlayerInfo()
rebuildPlayerList()
print("[ZenX] Universal Hub loaded")

