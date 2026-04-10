local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local playersService = game:GetService("Players")
local runService = game:GetService("RunService")
local localPlayer = playersService.LocalPlayer

local Window = Fluent:CreateWindow({
    Title = "Bite by Night",
    SubTitle = "by xin",
    Search = false,
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 380),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})

local Tabs = {
    Esp = Window:AddTab({ Title = "Tap Esp", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

local Options = Fluent.Options
local espObjects = {}
local highlightObjects = {}

local SURVIVOR_COLOR = Color3.fromRGB(0, 255, 80)
local KILLER_COLOR = Color3.fromRGB(255, 50, 50)

local function getTeamColor(team)
    if team == "Survivor" then return SURVIVOR_COLOR end
    if team == "Killer" then return KILLER_COLOR end
    return nil
end

local function getPlayerCharacter(player)
    local team = player:GetAttribute("TEAM")

    if team == "Killer" then
        local success, result = pcall(function()
            return workspace.PLAYERS.KILLER[player.Name]
        end)
        if success and result then return result end
    end

    if team == "Survivor" then
        local success, result = pcall(function()
            return workspace.PLAYERS.ALIVE[player.Name]
        end)
        if success and result then return result end
    end

    local successAlive, resultAlive = pcall(function()
        return workspace.PLAYERS.ALIVE[player.Name]
    end)
    if successAlive and resultAlive then return resultAlive end

    local successKiller, resultKiller = pcall(function()
        return workspace.PLAYERS.KILLER[player.Name]
    end)
    if successKiller and resultKiller then return resultKiller end

    return nil
end

local function getPlayerTeam(player)
    local success, result = pcall(function()
        return player:GetAttribute("TEAM")
    end)
    if success then return result end
    return nil
end

local function addHighlight(player, character, teamColor)
    if highlightObjects[player] then
        pcall(function() highlightObjects[player]:Destroy() end)
        highlightObjects[player] = nil
    end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = teamColor
    highlight.OutlineColor = teamColor
    highlight.FillTransparency = 0.55
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = character
    highlightObjects[player] = highlight
end

local function removeHighlight(player)
    if highlightObjects[player] then
        pcall(function() highlightObjects[player]:Destroy() end)
        highlightObjects[player] = nil
    end
end

local function createEspDrawings(player)
    espObjects[player] = {
        name       = Drawing.new("Text"),
        distance   = Drawing.new("Text"),
        tracer     = Drawing.new("Line"),
        healthBar  = Drawing.new("Square"),
        healthFill = Drawing.new("Square"),
        teamLabel  = Drawing.new("Text"),
    }

    local d = espObjects[player]

    d.name.Visible = false
    d.name.Size = 13
    d.name.Center = true
    d.name.Outline = true
    d.name.OutlineColor = Color3.fromRGB(0, 0, 0)

    d.distance.Visible = false
    d.distance.Size = 11
    d.distance.Center = true
    d.distance.Outline = true
    d.distance.Color = Color3.fromRGB(200, 200, 200)
    d.distance.OutlineColor = Color3.fromRGB(0, 0, 0)

    d.tracer.Visible = false
    d.tracer.Thickness = 1

    d.healthBar.Visible = false
    d.healthBar.Thickness = 1
    d.healthBar.Filled = true
    d.healthBar.Color = Color3.fromRGB(30, 30, 30)

    d.healthFill.Visible = false
    d.healthFill.Thickness = 1
    d.healthFill.Filled = true

    d.teamLabel.Visible = false
    d.teamLabel.Size = 11
    d.teamLabel.Center = true
    d.teamLabel.Outline = true
    d.teamLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
end

local function removeEspForPlayer(player)
    if espObjects[player] then
        for _, drawingObject in pairs(espObjects[player]) do
            pcall(function() drawingObject:Remove() end)
        end
        espObjects[player] = nil
    end
    removeHighlight(player)
end

local function hideEsp(player)
    local d = espObjects[player]
    if not d then return end
    for _, drawingObject in pairs(d) do
        drawingObject.Visible = false
    end
end

local function applyColor(player, teamColor)
    local d = espObjects[player]
    if not d then return end
    d.name.Color = teamColor
    d.tracer.Color = teamColor
    d.teamLabel.Color = teamColor
end

local function updateEsp()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local espOn = Options.EspToggle and Options.EspToggle.Value

    local localCharacter = getPlayerCharacter(localPlayer) or localPlayer.Character
    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

    local activePlayers = {}

    for _, player in pairs(playersService:GetPlayers()) do
        activePlayers[player] = true

        if player == localPlayer then continue end

        if not espObjects[player] then
            createEspDrawings(player)
        end

        local team = getPlayerTeam(player)
        local teamColor = getTeamColor(team)
        local isValidTeam = team == "Survivor" or team == "Killer"

        if not espOn or not isValidTeam or not teamColor then
            hideEsp(player)
            removeHighlight(player)
            continue
        end

        local character = getPlayerCharacter(player)
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if not character or not rootPart then
            hideEsp(player)
            removeHighlight(player)
            continue
        end

        if humanoid and humanoid.Health <= 0 then
            hideEsp(player)
            removeHighlight(player)
            continue
        end

        local currentHighlight = highlightObjects[player]
        if not currentHighlight or not currentHighlight.Parent then
            addHighlight(player, character, teamColor)
        else
            currentHighlight.FillColor = teamColor
            currentHighlight.OutlineColor = teamColor
        end

        local rootPosition = rootPart.Position
        local screenCenter, onScreen = camera:WorldToViewportPoint(rootPosition)

        if not onScreen or screenCenter.Z <= 0 then
            hideEsp(player)
            continue
        end

        applyColor(player, teamColor)

        local d = espObjects[player]
        local distanceValue = localRoot and math.floor((localRoot.Position - rootPosition).Magnitude) or 0

        d.name.Visible = true
        d.name.Text = player.DisplayName
        d.name.Position = Vector2.new(screenCenter.X, screenCenter.Y - 28)

        d.teamLabel.Visible = true
        d.teamLabel.Text = "[" .. team .. "]"
        d.teamLabel.Position = Vector2.new(screenCenter.X, screenCenter.Y - 16)

        d.distance.Visible = true
        d.distance.Text = distanceValue .. "m"
        d.distance.Position = Vector2.new(screenCenter.X, screenCenter.Y + 4)

        d.tracer.Visible = true
        d.tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
        d.tracer.To = Vector2.new(screenCenter.X, screenCenter.Y)

        local scaleFactor = 1 / screenCenter.Z * 100
        local barH = scaleFactor * 4.5
        local barW = 4
        local barX = screenCenter.X - 30
        local barY = screenCenter.Y - barH / 2

        local maxHp = humanoid and humanoid.MaxHealth or 100
        local currentHp = humanoid and humanoid.Health or 100
        local hpRatio = math.clamp(currentHp / math.max(maxHp, 1), 0, 1)

        d.healthBar.Visible = true
        d.healthBar.Position = Vector2.new(barX, barY)
        d.healthBar.Size = Vector2.new(barW, barH)

        d.healthFill.Visible = true
        d.healthFill.Position = Vector2.new(barX, barY + barH * (1 - hpRatio))
        d.healthFill.Size = Vector2.new(barW, barH * hpRatio)
        d.healthFill.Color = Color3.fromRGB(
            math.floor(255 * (1 - hpRatio)),
            math.floor(200 * hpRatio + 55),
            0
        )
    end

    for player, _ in pairs(espObjects) do
        if not activePlayers[player] then
            removeEspForPlayer(player)
        end
    end
end

Tabs.Esp:AddToggle("EspToggle", {
    Title = "ESP",
    Description = "",
    Default = false,
})

Options.EspToggle:OnChanged(function()
    if not Options.EspToggle.Value then
        for _, player in pairs(playersService:GetPlayers()) do
            hideEsp(player)
            removeHighlight(player)
        end
    end
end)

playersService.PlayerAdded:Connect(function(player)
    task.wait(2)
    if not espObjects[player] then
        createEspDrawings(player)
    end
end)

playersService.PlayerRemoving:Connect(function(player)
    removeEspForPlayer(player)
end)

for _, player in pairs(playersService:GetPlayers()) do
    if player ~= localPlayer then
        createEspDrawings(player)
    end
end

runService.RenderStepped:Connect(updateEsp)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("BiteByNight")
SaveManager:SetFolder("BiteByNight/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Bite by Night",
    Content = "Script loaded — ESP ready.",
    Duration = 5,
})

SaveManager:LoadAutoloadConfig()
