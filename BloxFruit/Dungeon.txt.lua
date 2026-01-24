loadstring(game:HttpGet("https://raw.githubusercontent.com/AnhDzaiScript/Setting/refs/heads/main/FastMax.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Testgameak/RYNtraxHub/refs/heads/main/fast%20attack%20new%20by%20trieu.txt"))()
if game.PlaceId == 73902483975735 then

    -- // CARREGAMENTO DA UI NIGHT MYSTIC // --
    local I = (loadstring(game:HttpGet("https://raw.githubusercontent.com/vitorffpro888/VITOR-HUB-V1-lua/refs/heads/main/Hshdh.lua")))();
    local Window = I:NewWindow();

    -- // ABAS E SEÇÕES // --
    local DungeonTab = Window:T("Dungeon");
    local SettingsTab = Window:T("Settings");

    local MainSection = DungeonTab:AddSection("Main Farm");
    local WeaponSection = SettingsTab:AddSection("Weapon Config");
    local MiscSection = SettingsTab:AddSection("Misc Config");

    -- // SERVIÇOS E VARIÁVEIS // --
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local LocalPlayer = Players.LocalPlayer

    -- Variáveis de Controle
    local CurrentTween = nil
    local WaitingForSpawn = false
    local MustTouchTeleport = true

    -- LISTA DE MOBS PARA IGNORAR
    local IgnoreMobs = {
        "DungeonAlly", "AllyMob", "SupportMob", "FriendlyMob", 
        "GuardianMob", "ProtectorMob", "HelperMob", "EscortMob", 
        "DefenderMob", "AssistMob", "Little_Boy's", "Friendo", "Shadow"
    }

    -- Inicialização de variáveis globais
    _G.AutoFarm_DungeonFix = false
    _G.AutoSelectCard = false 
    _G.FastAttack_Dungeon = true
    _G.AutoBuso_Dungeon = true
    _G.AutoRaceV3_Dungeon = false
    _G.AutoRaceV4_Dungeon = false
    _G.WeaponType_Dungeon = "Melee"

    local Distance = 15       
    local TweenSpeed = 300    

    -- // PREPARAÇÃO DO FAST ATTACK // --
    local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
    local RegisterHit = Net:WaitForChild("RE/RegisterHit")
    local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
    local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
    local HIT_FUNCTION = nil

    task.defer(function()
        local LocalScript = PlayerScripts:FindFirstChildOfClass("LocalScript")
        while not LocalScript do
            PlayerScripts.ChildAdded:Wait()
            LocalScript = PlayerScripts:FindFirstChildOfClass("LocalScript")
        end
        if getsenv then
            local Success, ScriptEnv = pcall(getsenv, LocalScript)
            if Success and ScriptEnv then
                HIT_FUNCTION = ScriptEnv._G.SendHitsToServer
            end
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        MustTouchTeleport = true
        WaitingForSpawn = false
    end)

    -- // FUNÇÕES AUXILIARES DE MOVIMENTAÇÃO // --

    local function IsIgnored(target)
        local nameToCheck = target.Name:lower()
        local displayName = ""
        if target:FindFirstChild("Humanoid") then
            displayName = target.Humanoid.DisplayName:lower()
        end

        for _, ignoreName in pairs(IgnoreMobs) do
            local lowerIgnore = ignoreName:lower()
            if nameToCheck:find(lowerIgnore) or displayName:find(lowerIgnore) then
                return true
            end
        end
        return false
    end

    local function StopTween()
        if CurrentTween then
            CurrentTween:Cancel()
            CurrentTween = nil
        end
    end

    local function MoveToPosition(targetCFrame)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local dist = (hrp.Position - targetCFrame.Position).Magnitude
        if dist <= 5 then
            StopTween()
            hrp.CFrame = targetCFrame
            return
        end

        local info = TweenInfo.new(dist / TweenSpeed, Enum.EasingStyle.Linear)
        if not CurrentTween or (CurrentTween.PlaybackState == Enum.PlaybackState.Completed) then
            StopTween()
            CurrentTween = TweenService:Create(hrp, info, {CFrame = targetCFrame})
            CurrentTween:Play()
        end
    end

    local function GetNearestMob()
        local target = nil
        local distance = math.huge
        local Folder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Characters")
        
        if Folder then  
            for _, v in pairs(Folder:GetChildren()) do  
                if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then  
                    if v ~= LocalPlayer.Character and not IsIgnored(v) then  
                        local mag = (LocalPlayer.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude  
                        if mag < distance then 
                            distance = mag 
                            target = v 
                        end  
                    end  
                end  
            end  
        end  
        return target
    end

    local function GetExitTeleporter()
        local Map = workspace:FindFirstChild("Map")
        local Dungeon = Map and Map:FindFirstChild("Dungeon")
        if not Dungeon then return nil end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        
        local nearestExit, minDistance = nil, math.huge
        for _, room in pairs(Dungeon:GetChildren()) do
            local exit = room:FindFirstChild("ExitTeleporter")
            if exit and exit:FindFirstChild("Root") then
                local dist = (hrp.Position - exit.Root.Position).Magnitude
                if dist < minDistance then 
                    minDistance = dist 
                    nearestExit = exit.Root.CFrame * CFrame.new(0, 5, 0) 
                end
            end
        end
        return nearestExit
    end

    local function EquipWeapon()
        local char = LocalPlayer.Character
        if not char then return end
        local currentTool = char:FindFirstChildOfClass("Tool")
        if currentTool and currentTool.ToolTip == _G.WeaponType_Dungeon then return end
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == _G.WeaponType_Dungeon then
                char.Humanoid:EquipTool(tool)
                break
            end
        end
    end

    -- // SISTEMA DE CLIQUE NOS CARDS // --
    local function AutoClickCards()
        if not _G.AutoSelectCard then return end
        
        pcall(function()
            local pg = LocalPlayer:WaitForChild("PlayerGui")
            local BuffGui = pg:FindFirstChild("BuffSelectorMenu") or pg:FindFirstChild("Interface") or pg:FindFirstChild("DungeonUI")
            
            if BuffGui and BuffGui.Enabled then
                for _, obj in pairs(BuffGui:GetDescendants()) do
                    if obj:IsA("GuiObject") and obj.Visible and obj.AbsoluteSize.Y > 50 then
                        local name = obj.Name:lower()
                        if name:find("card") or name:find("buff") or name:find("select") then
                            local x = obj.AbsolutePosition.X + (obj.AbsoluteSize.X / 2)
                            local y = obj.AbsolutePosition.Y + (obj.AbsoluteSize.Y / 2) + 58
                            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                            task.wait(0.05)
                            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
                        end
                    end
                end
                
                local viewport = workspace.CurrentCamera.ViewportSize
                local positions = {
                    Vector2.new(viewport.X * 0.3, viewport.Y * 0.5),
                    Vector2.new(viewport.X * 0.5, viewport.Y * 0.5),
                    Vector2.new(viewport.X * 0.7, viewport.Y * 0.5)
                }
                for _, pos in pairs(positions) do
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                end
            end
        end)
    end

    -- // ELEMENTOS DA UI // --
    MainSection:AddToggle({
        Title = "Auto Farm Dungeon",
        Default = false,
        Callback = function(v)
            _G.AutoFarm_DungeonFix = v
            WaitingForSpawn = false
            MustTouchTeleport = true
            if not v then StopTween() end
        end
    })

    MainSection:AddToggle({
        Title = "Auto Select Card Buff",
        Default = false,
        Callback = function(v)
            _G.AutoSelectCard = v
        end
    })

    WeaponSection:AddDropdown({
        Title = "Select Weapon",
        Values = {"Melee", "Sword", "Blox Fruit", "Gun"},
        Default = "Melee",
        Multi = false,
        Callback = function(v) _G.WeaponType_Dungeon = v end
    })

    MiscSection:AddToggle({Title = "Auto Attack", Default = true, Callback = function(v) _G.FastAttack_Dungeon = v end})
    MiscSection:AddToggle({Title = "Auto Buso (Haki)", Default = true, Callback = function(v) _G.AutoBuso_Dungeon = v end})
    MiscSection:AddToggle({Title = "Auto Active V3", Default = false, Callback = function(v) _G.AutoRaceV3_Dungeon = v end})
    MiscSection:AddToggle({Title = "Auto Active V4", Default = false, Callback = function(v) _G.AutoRaceV4_Dungeon = v end})

    -- // LOOPS DE EXECUÇÃO // --

    RunService.Stepped:Connect(function()
        if _G.AutoFarm_DungeonFix then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            for _, part in pairs(char:GetChildren()) do 
                if part:IsA("BasePart") then part.CanCollide = false end 
            end
            hrp.Velocity = Vector3.new(0, 0, 0)
            
            local targetMob = GetNearestMob()
            local exitFrame = GetExitTeleporter()

            if MustTouchTeleport and exitFrame then
                MoveToPosition(exitFrame)
                if (hrp.Position - exitFrame.Position).Magnitude < 8 then
                    StopTween()
                    MustTouchTeleport = false 
                end
                return 
            end

            if targetMob then
                WaitingForSpawn = false
                EquipWeapon()
                local targetPos = targetMob.HumanoidRootPart.CFrame * CFrame.new(0, Distance, 0)
                if (hrp.Position - targetPos.Position).Magnitude > 10 then
                    MoveToPosition(targetPos)
                else
                    StopTween()
                    hrp.CFrame = targetPos
                    hrp.CFrame = CFrame.new(hrp.Position, targetMob.HumanoidRootPart.Position)
                end
            elseif not targetMob and not WaitingForSpawn then
                if exitFrame then
                    MoveToPosition(exitFrame)
                    if (hrp.Position - exitFrame.Position).Magnitude < 8 then
                        StopTween()
                        WaitingForSpawn = true
                    end
                end
            end  
        end
    end)

    task.spawn(function()
        while task.wait() do
            if _G.FastAttack_Dungeon and _G.AutoFarm_DungeonFix and not WaitingForSpawn and not MustTouchTeleport then
                pcall(function()
                    local Enemies = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Characters")
                    if not Enemies then return end
                    for _, enemy in ipairs(Enemies:GetChildren()) do
                        if not IsIgnored(enemy) then
                            local hum = enemy:FindFirstChild("Humanoid")
                            local root = enemy:FindFirstChild("HumanoidRootPart")
                            if hum and hum.Health > 0 and root and (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 60 then
                                if HIT_FUNCTION then 
                                    HIT_FUNCTION(root, {{[1] = enemy, [2] = root}}) 
                                else 
                                    RegisterHit:FireServer(root, {{[1] = enemy, [2] = root}}) 
                                end
                                RegisterAttack:FireServer(0)
                            end
                        end
                    end
                end)
            end
        end
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if _G.AutoSelectCard then AutoClickCards() end
            pcall(function()
                if _G.AutoBuso_Dungeon and LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("HasBuso") then
                    game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Buso")
                end
                if _G.AutoRaceV3_Dungeon then game:GetService("ReplicatedStorage").Remotes.CommE:FireServer("ActivateAbility") end
                if _G.AutoRaceV4_Dungeon then
                    local raceEnergy = LocalPlayer.Character:FindFirstChild("RaceEnergy")
                    if raceEnergy and raceEnergy.Value >= 1 then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Y, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Y, false, game)
                    end
                end
            end)
        end
    end)

else
    warn("Script não carregado: PlaceId incorreto.")
end
