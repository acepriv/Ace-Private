getgenv().hvh = {
    Main = {
        Type = "FOV",
        TargetAim = false,
        Part = "Head",
        Keybinds = "C",
        Predictions = 0;
        Resolver = false;
        RemoveFireRate = false;
        View = false;
        Aimbot = false;
        AimbotPred = 0.12;
        AimbotParts = "HumanoidRootPart";
        Smoothness = 1;
        AimbotKeybind = "C";
        LookAt = false;
        Aug = true;
    };

    Visuals = {
        Circle = false;
        CircleColor = Color3.fromRGB(255, 255, 255);
        Tracer = false;
        TracerColor = Color3.fromRGB(255, 255, 255);
    };

    HitDetections = {
        Info = false;
    };

    CustomSounds = {
        Method = "Damage"; -- Damage, Ammo
        Enabled = false;
        Type = "Neverlose";
        Volume = 100;
    };

    World = {};

    HitChams = {
        Method = "BasePart"; --// Clone
        Enabled = false;
        Rainbow = false;
        Duration = 5;
        Color = Color3.fromRGB(111, 111, 111);
    };

    Desyncs = {};

    Player = {
        Speed = { Enabled = false, Value = 16 };
        Jump = { Enabled = false, Value = 50 };
        Flight = { Enabled = false, Value = 5 };
    };

    Esp = {
        Enabled = false;
        ShowBox = false;
        ShowName = false;
        ShowHealth = false;
        ShowArmor = false;
        ShowDistance = false;
        ShowTool = false;
        SelfEsp = false;
    };

    Checks = {
        AntiStomp = false;
        AntiStompKeybind = "Z";
        AntiStompDelay = 2

    };
};

if (not LPH_OBFUSCATED) then
    LPH_NO_VIRTUALIZE = function(...) return (...) end;
    LPH_JIT_MAX = function(...) return (...) end;
    LPH_JIT_ULTRA = function(...) return (...) end;
end

setfpscap(25000)


local HeartbeatConn

local PreSimulationConn

local PostSimulationConn

local cloneref = getgenv().cloneref or function(...) return ... end

local Game = cloneref(Game)

local Players = Game:GetService("Players");

local Camera = Game:GetService("Workspace").CurrentCamera;

local UserInputService = Game:GetService("UserInputService");

local LocalPlayer = Players.LocalPlayer;

local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();

local LocalHumanoid = LocalCharacter:FindFirstChildOfClass("Humanoid") or LocalCharacter:WaitForChild("Humanoid", 1e9);

local LocalRootPart = LocalHumanoid and LocalHumanoid.RootPart or LocalCharacter:WaitForChild("HumanoidRootPart", 1e9);

local Mouse = LocalPlayer:GetMouse();

local r_s = Game:GetService("RunService");

local Workspace = Game:GetService("Workspace")

local renderStepped = r_s.RenderStepped;

local vector3 = Vector3;

local vector2 = Vector2;

local defaults = {
    WalkSpeed = 16,
    JumpPower = 50,
    JumpHeight = 7.2,
}

if LocalHumanoid then
    defaults.WalkSpeed = LocalHumanoid.WalkSpeed
    defaults.JumpPower = LocalHumanoid.JumpPower
    pcall(function()
        defaults.JumpHeight = LocalHumanoid.JumpHeight
    end)
end

LocalPlayer.CharacterAdded:Connect(function(Character)
    LocalCharacter = Character
    LocalHumanoid = LocalCharacter:FindFirstChildOfClass("Humanoid") or LocalCharacter:WaitForChild("Humanoid", 1e9)
    LocalRootPart = LocalHumanoid and LocalHumanoid.RootPart or LocalCharacter:WaitForChild("HumanoidRootPart", 1e9)
    if LocalHumanoid then
        defaults.WalkSpeed = LocalHumanoid.WalkSpeed
        defaults.JumpPower = LocalHumanoid.JumpPower
        pcall(function()
            defaults.JumpHeight = LocalHumanoid.JumpHeight
        end)
    end
end)

Utility = {
    Aimbot = nil;
    Target = nil;
    func = {};
    connect = {};
    draw = {};
    connections={};
    prevammo = {};
    prevhealth = {};
    MaxDistances = {};
    SpeedKeybindhandling = false;
    AntiStomp = false;
    firing = false;
};


local blunt = Drawing.new("Circle")
blunt.Radius = 500
blunt.Transparency = 1
blunt.Thickness = 0.2
blunt.Visible =true
blunt.Color = Color3.new(1.000000, 1.000000, 1.000000)
blunt.ZIndex = 999999
blunt.Filled = false

Utility.func.Movement = function()
    if not LocalCharacter or not LocalHumanoid or not LocalRootPart then return end

    local player = getgenv().hvh.Player

    if player.Speed.Enabled then
        LocalHumanoid.WalkSpeed = player.Speed.Value
    else
        LocalHumanoid.WalkSpeed = defaults.WalkSpeed
    end

    if player.Jump.Enabled then
        LocalHumanoid.JumpPower = player.Jump.Value
        pcall(function()
            LocalHumanoid.JumpHeight = player.Jump.Value
        end)
    else
        LocalHumanoid.JumpPower = defaults.JumpPower
        pcall(function()
            LocalHumanoid.JumpHeight = defaults.JumpHeight
        end)
    end

    if player.Flight.Enabled then
        local direction = vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction = direction + vector3.new(0, -1, 0)
        end
        if direction.Magnitude > 0 then
            direction = direction.Unit
        end
        LocalRootPart.CFrame = LocalRootPart.CFrame + (direction * player.Flight.Value)
        LocalRootPart.Velocity = direction * player.Flight.Value
    end
end

Utility.activation = function(tool)
    tool:Activate()
end

UserInputService.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        local tool = LocalCharacter:FindFirstChildWhichIsA("Tool") 
        if getgenv().hvh.Main.Aug and tool and not Utility.firing then
            Utility.firing = true

            while Utility.firing do
                Utility.activation(tool)
                task.wait(0)
            end
        end
    end
end)


UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        Utility.firing = false
    end
end)


Utility.func.AntiStomp = function()
    if not LocalCharacter or not LocalHumanoid or not LocalRootPart then return end
    if getgenv().hvh.Checks.AntiStomp then
        for _, retard in pairs(LocalCharacter:GetDescendants()) do
            if retard:IsA("BasePart") then
                task.delay(getgenv().hvh.Checks.AntiStompDelay, function()
                    retard:Destroy()
                end)
            end
        end
    end
end


Utility.func.get_closest = LPH_NO_VIRTUALIZE(function()
    local Target
    local Closest = math.huge
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            local PartPos, OnScreen = Camera:WorldToViewportPoint(Player.Character.HumanoidRootPart.Position)
            local MouseLocation = UserInputService:GetMouseLocation()
            local Magnitude = (Vector2.new(PartPos.X, PartPos.Y) - MouseLocation).Magnitude
            if Magnitude < Closest and Magnitude <= blunt.Radius and OnScreen then
                Target = Player
                Closest = Magnitude
            end
        end
    end
    return Target
end)

Utility.func.Future = function()
    local Target

    if getgenv().hvh.Main.Type == "FOV" then
        Target = Utility.func.get_closest()
    elseif getgenv().hvh.Main.Type == "Target" then
        Target = Utility.Target
    end

    if getgenv().hvh.Main.TargetAim and Target and Target.Character then
        local character = Target.Character
        local bodyEffects = character:FindFirstChild("BodyEffects")
        local KOd = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
        local humanoid = character:FindFirstChild("Humanoid")
        
        if humanoid then
            local Part = tostring(getgenv().hvh.Main.Part)
            local TargetPart = Target.Character:FindFirstChild(Part)
            local Prediction = tonumber(getgenv().hvh.Main.Predictions)

            if Part and TargetPart and TargetPart.Position and TargetPart.Velocity and Prediction then
                return TargetPart.Position + TargetPart.Velocity * Prediction
            end
        end
    end
end




do
    Utility.func.ViewTarget = function()
        if getgenv().hvh.Main.View and Utility.Target and Utility.Target.Character then
            Camera.CameraSubject = Utility.Target.Character.Humanoid
        else
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end

    Utility.func.lookat = function()
        local Target

        if getgenv().hvh.Main.Type == "FOV" then
            Target = Utility.func.get_closest()
        elseif getgenv().hvh.Main.Type == "Target" then
            Target = Utility.Target
        end

        if Target and Target.Character then
            if getgenv().hvh.Main.LookAt then
                LocalRootPart.CFrame = CFrame.new(
                    LocalRootPart.CFrame.Position,
                    Vector3.new(
                        Target.Character.HumanoidRootPart.Position.X,
                        LocalRootPart.CFrame.Position.Y,
                        Target.Character.HumanoidRootPart.Position.Z
                    )
                )
                LocalHumanoid.AutoRotate = false
            else
                LocalRootPart.CFrame = LocalRootPart.CFrame
                LocalHumanoid.AutoRotate = true
            end
        end
    end
end


Utility.draw.c = Drawing.new("Circle");
Utility.draw.c.Thickness = 2;
Utility.draw.c.NumSides = 100000;
Utility.draw.c.Radius = 50;
Utility.draw.c.Filled = false;
Utility.draw.c.Color = Color3.fromRGB(1,1,1);
Utility.draw.c.Visible = false;

Utility.draw.t = Drawing.new("Line");
Utility.draw.t.Thickness = 2;
Utility.draw.t.Color = Color3.fromRGB(1,1,1);
Utility.draw.t.Visible = false;
Utility.draw.t.Transparency = 1



Utility.func.AimBotFormula = function()
    if Utility.Aimbot and Utility.Aimbot.Character then
        local a = getgenv().hvh.Main.AimbotParts
        local mainparts = Utility.Aimbot.Character:FindFirstChild(a)

        if getgenv().hvh.Main.Aimbot and mainparts then
            local endpoint = mainparts.Position + mainparts.Velocity * getgenv().hvh.Main.AimbotPred

            local stuff = CFrame.new(Camera.CFrame.Position, endpoint)
            Camera.CFrame = Camera.CFrame:Lerp(stuff, getgenv().hvh.Main.Smoothness, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut) 
        end
    end
end

Utility.func.lerp = function(v1, v2, alpha)
    return v1 + (v2 - v1) * alpha;
end;


if game.PlaceId == 9825515356 then
    r_s.PostSimulation:Connect(function()
        local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
        local framework = playerGui:WaitForChild("Framework", math.huge)
        
        if framework then
            local env = getsenv(framework)
            if env and env._G then
                local BIGNIGGER = Utility.func.Future()
                if BIGNIGGER then
                    env._G.MOUSE_POSITION = BIGNIGGER
                end
            end
        end
    end)
end


if game.PlaceId ~= 9825515356 and not string.find(identifyexecutor(), "Solara") and not string.find(identifyexecutor(), "Wave") and not string.find(identifyexecutor(), "Xeno") and not string.find(identifyexecutor(), "Synapse Z") then
    local grm = getrawmetatable(game)
    local MousePosChanger2 = nil
    setreadonly(grm, false)
    MousePosChanger2 = grm.__index
    grm.__index = function(self, Index)
        if not checkcaller() and self == Mouse then
            if Index == "Hit" then
                local EndPoint = Utility.func.Future()
                if EndPoint then
                    return CFrame.new(EndPoint)
                end
            elseif Index == "Target" and game.PlaceId == 2788229376 then
                local EndPoint = Utility.func.Future()
                if EndPoint then
                    return CFrame.new(EndPoint)
                end
            end
        end
        return MousePosChanger2(self, Index)
    end
end




local hitsounds = {
    ["RIFK7"] = "rbxassetid://9102080552",
    ["Bubble"] = "rbxassetid://9102092728",
    ["Minecraft"] = "rbxassetid://5869422451",
    ["Cod"] = "rbxassetid://160432334",
    ["Bameware"] = "rbxassetid://6565367558",
    ["Neverlose"] = "rbxassetid://6565370984",
    ["Gamesense"] = "rbxassetid://4817809188",
    ["Rust"] = "rbxassetid://6565371338",
    ["UWU"] = "rbxassetid://8323804973",
    ["Bat"] = "rbxassetid://4529474217",
    ["Lazer"] = "rbxassetid://1624609598"
}

Utility.func.Sounds = function()
    local soundId = hitsounds[getgenv().hvh.CustomSounds.Type]
    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = getgenv().hvh.CustomSounds.Volume
        sound.Parent = Workspace
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
end

Utility.func.TrackPlayersAmmo = function()
    local Player = game.Players.LocalPlayer
    
    local Guns = Player.Character and Player.Character:FindFirstChildWhichIsA("Tool")
    if Guns and Guns:FindFirstChild("Ammo") then
        Utility.prevammo[Guns.Name] = Utility.prevammo[Guns.Name] or Guns.Ammo.Value

        local newammo = Guns.Ammo.Value
        local prevammo = Utility.prevammo[Guns.Name]

        if newammo < prevammo then
            if getgenv().hvh.CustomSounds.Enabled and getgenv().hvh.CustomSounds.Method == "Ammo" then
                Utility.func.Sounds()
            end

            Utility.prevammo[Guns.Name] = newammo
        end
    end
end


function Utility:GAYFLAG()
local tick = tick()
return Color3.fromHSV((tick % 1), 1, 1)
end

function Utility:Hitchams(Player)
    for _, Index in pairs(Player.Character:GetChildren()) do
        if Index.Name ~= "HumanoidRootPart" and Index:IsA("BasePart") then
            local Part = Instance.new("Part")
            Part.Name = Index.Name .. "Grah"
            Part.Parent = Workspace
            Part.Material = Enum.Material.Neon
            Part.Transparency = 0
            Part.Anchored = true
            Part.Size = Index.Size
            Part.CFrame = Index.CFrame
            Part.CanCollide = false
            
            if getgenv().hvh.HitChams.Enabled then
                if getgenv().hvh.HitChams.Rainbow then
                    Part.Color = Utility:GAYFLAG()
                else
                    Part.Color = getgenv().hvh.HitChams.Color
                end
            end
            
            task.delay(getgenv().hvh.HitChams.Duration, function()
                Part:Destroy()
            end)
        end
    end
end

function Utility:Clone(player)
    player.Character.Archivable = true
    local latest_character = player.Character:Clone()
    latest_character.Parent = Workspace
    player.Character.Archivable = false

    for _, Parts in pairs(latest_character:GetChildren()) do
        if Parts:IsA("MeshPart") then
            Parts.Anchored = true
            Parts.CanCollide = false
            Parts.Transparency = 0
            Parts.Material = Enum.Material.Neon

            if getgenv().hvh.HitChams.Rainbow then
                Parts.Color = Utility:GAYFLAG()
            else
                Parts.Color = getgenv().hvh.HitChams.Color
            end
        else
            if Parts.Name ~= "HumanoidRootPart" then
                Parts:Destroy()
            end
        end

        if Parts.Name == "Head" then
            local faces = Parts:FindFirstChild("face")
            if faces then
                faces:Destroy()
            end
        end
    end

    task.delay(getgenv().hvh.HitChams.Duration, function()
        if latest_character and latest_character.Parent then
            latest_character:Destroy()
        end
    end)
end


Utility.autostomp = function()
Game:GetService("ReplicatedStorage").MainEvent:FireServer("Stomp")
end

local HitText = Drawing.new("Text")
HitText.Visible = false
HitText.Center = true
HitText.Outline = true
HitText.Size = 20
HitText.Color = Color3.new(1, 1, 1)
HitText.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 230)
HitText.Font = 1

Utility.func.TrackPlayerHealth = LPH_NO_VIRTUALIZE(function()
    local Target = nil

    if getgenv().hvh.Main.Type == "FOV" then
        Target = Utility.func.get_closest()
    elseif getgenv().hvh.Main.Type == "Target" then
        Target = Utility.Target
    end

    if Target and Target.Character then
        local humanoid = Target.Character:FindFirstChild("Humanoid")
        local distance = (Target.Character.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude

        if humanoid and distance <= 150 then
            local currentHealth = humanoid.Health

            if not Utility.prevhealth[Target.Name] then
                Utility.prevhealth[Target.Name] = currentHealth
            end

            local prevHealth = Utility.prevhealth[Target.Name]

            if currentHealth < prevHealth then
                if getgenv().hvh.HitChams.Enabled then
                    if getgenv().hvh.HitChams.Method == "Clone" then
                        Utility:Clone(Target)
                    elseif getgenv().hvh.HitChams.Method == "BasePart" then
                        Utility:Hitchams(Target)
                    end
                end

                if getgenv().hvh.CustomSounds.Enabled and getgenv().hvh.CustomSounds.Method == "Damage" then
                    Utility.func.Sounds()
                end

                if getgenv().hvh.HitDetections.Info then
                    local dmg = prevHealth - currentHealth
                    HitText.Text = "[Index] (Hit Detected) > " .. tostring(dmg)
                    HitText.Transparency = 1
                    HitText.Visible = true

                    task.spawn(function()
                        wait(0.5)
                        for i = 1, 10 do
                            HitText.Transparency = HitText.Transparency - 0.1
                            wait(0.05)
                        end
                        HitText.Visible = false
                    end)
                end
            end

            Utility.prevhealth[Target.Name] = currentHealth
        end
    end
end)


Utility.autoreload = function()
    if LocalCharacter and LocalRootPart and LocalHumanoid then
        local tool = LocalCharacter:FindFirstChildWhichIsA("Tool")
        if tool then
            local ammo = tool:FindFirstChild("Ammo")
            if ammo and ammo:IsA("IntValue") and ammo.Value <= 0 then
                Game:GetService("ReplicatedStorage").MainEvent:FireServer("Reload", tool)
            end
        end
    end
end

Utility.func.RemoveFireRate = LPH_NO_VIRTUALIZE(function()
    if game.PlaceId == 2788229376 and getgenv().hvh.Main.RemoveFireRate and LocalCharacter and LocalCharacter:FindFirstChildOfClass("Tool") and LocalCharacter:FindFirstChildOfClass("Tool"):FindFirstChild("GunScript") then
        for _, v in ipairs(getconnections(LocalCharacter:FindFirstChildOfClass("Tool").Activated)) do
            if v.Function and type(v.Function) == "function" then
                local funcinfo = debug.getinfo(v.Function)
                if funcinfo then
                    for i = 1, funcinfo.nups do
                        local c, n = debug.getupvalue(v.Function, i)
                        if type(c) == "number" then
                            debug.setupvalue(v.Function, i, 0)
                        end
                    end
                end
            end
        end
    elseif getgenv().hvh.Main.RemoveFireRate and game.PlaceId == 9825515356 and LocalCharacter and LocalHumanoid and LocalRootPart then
        local Gun = LocalCharacter:FindFirstChildOfClass("Tool")
        if Gun and Gun:FindFirstChild("GunData") then
            local Module = require(Gun:FindFirstChild("GunData"))
            Module["slowdown_time"] = 0
            Module["cooldown"] = 0
        end
    end
end)

local cache = {}
local Esp = {
    BoxOutlineColor = Color3.new(0, 0, 0),
    BoxColor = Color3.new(1, 1, 1),
    HealthOutlineColor = Color3.new(0, 0, 0),
    HealthHighColor = Color3.new(0, 1, 0),
    ArmorOutlineColor = Color3.new(0, 0, 0),
    ArmorColor = Color3.new(0, 0, 1),
    CharSize = Vector2.new(4, 6),
}

Utility.func.create = function(class, properties)
    local drawing = Drawing.new(class)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    return drawing
end

Utility.func.createEsp = LPH_NO_VIRTUALIZE(function(player)
    local esp = {
        boxOutline = Utility.func.create("Square", {Color = Esp.BoxOutlineColor, Thickness = 3, Filled = false}),
        box = Utility.func.create("Square", {Color = Esp.BoxColor, Thickness = 1, Filled = false}),
        healthOutline = Utility.func.create("Square", {Thickness = 1, Color = Esp.HealthOutlineColor, Filled = true}),
        health = Utility.func.create("Square", {Thickness = 1, Color = Esp.HealthHighColor, Filled = true}),
        armorOutline = Utility.func.create("Square", {Thickness = 1, Color = Esp.ArmorOutlineColor, Filled = true}),
        armor = Utility.func.create("Square", {Thickness = 1, Color = Esp.ArmorColor, Filled = true}),
        healthText = Utility.func.create("Text", {Color = Color3.new(0, 1, 0), Size = 12, Center = true, Font = 3}),
        armorText = Utility.func.create("Text", {Color = Color3.new(0, 0, 1), Size = 12, Center = true, Font = 3}),
        nameText = Utility.func.create("Text", {Color = Color3.new(1, 1, 1), Size = 12, Center = true, Font = 3}),
        distanceText = Utility.func.create("Text", {Color = Color3.new(1, 1, 1), Size = 12, Center = true, Font = 3}),
        toolText = Utility.func.create("Text", {Color = Color3.new(1, 1, 1), Size = 12, Center = true, Font = 3})
    }
    cache[player] = esp
end)

Utility.func.removeEsp = function(player)
    local esp = cache[player]
    if not esp then return end
    for _, drawing in pairs(esp) do
        drawing:Remove()
    end
    cache[player] = nil
end

Utility.func.updateEsp = LPH_NO_VIRTUALIZE(function()
    for player, esp in pairs(cache) do
        local character = player.Character
        if character then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")
            local humanoid = character:FindFirstChild("Humanoid")
            local bodyEffects = character:FindFirstChild("BodyEffects")
            local armor = bodyEffects and bodyEffects:FindFirstChild("Armor")
            local backpack = player:FindFirstChildOfClass("Backpack")
            local tool = character:FindFirstChildWhichIsA('Tool')

            if rootPart and head and humanoid and getgenv().hvh.Esp.Enabled then
                local position, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                if onScreen then
                    local hrp2D = Camera:WorldToViewportPoint(rootPart.Position)
                    local charSize = (Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 1, 0)).Y - Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0)).Y) / 2
                    local boxSize = Vector2.new(math.floor(charSize * 2.2), math.floor(charSize * 3.5)) 
                    local boxPosition = Vector2.new(math.floor(hrp2D.X - charSize * 2.2 / 2), math.floor(hrp2D.Y - charSize * 3.5 / 2))

                    if getgenv().hvh.Esp.ShowBox then
                        esp.boxOutline.Size = boxSize
                        esp.boxOutline.Position = boxPosition
                        esp.boxOutline.Visible = true

                        esp.box.Size = boxSize
                        esp.box.Position = boxPosition
                        esp.box.Visible = true
                    else
                        esp.box.Visible = false
                        esp.boxOutline.Visible = false
                    end

                    if getgenv().hvh.Esp.ShowHealth then
                        local healthPercentage = humanoid.Health / humanoid.MaxHealth
                        local healthBarHeight = boxSize.Y * healthPercentage
                        local healthBarPosition = Vector2.new(boxPosition.X - 4, boxPosition.Y + boxSize.Y - healthBarHeight)

                        esp.healthOutline.Size = Vector2.new(4, boxSize.Y)
                        esp.healthOutline.Position = Vector2.new(boxPosition.X - 4, boxPosition.Y)
                        esp.healthOutline.Visible = true

                        esp.health.Size = Vector2.new(2, healthBarHeight)
                        esp.health.Position = healthBarPosition
                        esp.health.Visible = true

                        esp.healthText.Visible = true
                        esp.healthText.Outline = true
                        esp.healthText.Position = Vector2.new(boxPosition.X - 30, boxPosition.Y - 5)
                        esp.healthText.Text = math.floor(humanoid.Health)
                    else
                        esp.healthOutline.Visible = false
                        esp.health.Visible = false
                        esp.healthText.Visible = false
                    end

                    if getgenv().hvh.Esp.ShowArmor and armor then
                        local armorPercentage = armor.Value / 130
                        local armorBarHeight = boxSize.Y * armorPercentage
                        local armorBarPosition = Vector2.new(boxPosition.X - 10, boxPosition.Y + boxSize.Y - armorBarHeight)

                        esp.armorOutline.Size = Vector2.new(4, boxSize.Y)
                        esp.armorOutline.Position = Vector2.new(boxPosition.X - 10, boxPosition.Y)
                        esp.armorOutline.Visible = true

                        esp.armor.Size = Vector2.new(2, armorBarHeight)
                        esp.armor.Position = armorBarPosition
                        esp.armor.Visible = true

                        esp.armorText.Visible = true
                        esp.armorText.Outline = true
                        esp.armorText.Text = math.floor(armor.Value)
                        esp.armorText.Position = Vector2.new(boxPosition.X - 30, boxPosition.Y + 5)
                    else
                        esp.armorOutline.Visible = false
                        esp.armor.Visible = false
                        esp.armorText.Visible = false
                    end

                    if getgenv().hvh.Esp.ShowName then
                        esp.nameText.Visible = true
                        esp.nameText.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y - 15)
                        esp.nameText.Text = player.DisplayName
                        esp.nameText.Outline = true
                    else
                        esp.nameText.Visible = false
                    end

                    if getgenv().hvh.Esp.ShowDistance then
                        local distance = math.floor((LocalRootPart.Position - rootPart.Position).Magnitude)
                        esp.distanceText.Visible = true
                        esp.distanceText.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y + boxSize.Y + 1)
                        esp.distanceText.Text = "[ " .. distance .. " M ]"
                        esp.distanceText.Outline = true
                    else
                        esp.distanceText.Visible = false
                    end

                    if getgenv().hvh.Esp.ShowTool then
                        esp.toolText.Visible = true
                        esp.toolText.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y + boxSize.Y + 10)
                        esp.toolText.Text = tool and tool.Name or "none"
                        esp.toolText.Outline = true
                    else
                        esp.toolText.Visible = false
                    end
                else
                    for _, drawing in pairs(esp) do
                        drawing.Visible = false
                    end
                end
            else
                for _, drawing in pairs(esp) do
                    drawing.Visible = false
                end
            end
        else
            for _, drawing in pairs(esp) do
                drawing.Visible = false
            end
        end
    end
end)


for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        Utility.func.createEsp(player)
    end
end


Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        Utility.func.createEsp(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    Utility.func.removeEsp(player)
end)

local tvis = true
local cvis = true
VisualsRendering = LPH_NO_VIRTUALIZE(function()
    blunt.Position = UserInputService:GetMouseLocation()
    
    local Target

    if getgenv().hvh.Main.Type == "FOV" then
        Target = Utility.func.get_closest()
    elseif getgenv().hvh.Main.Type == "Target" then
        Target = Utility.Target
    end

    if Target and Target.Character then
        local endpoint = Utility.func.Future(Target) 
        if endpoint then
            local pos, onscreen = Camera:WorldToViewportPoint(endpoint)
            local MousePos = UserInputService:GetMouseLocation()

            Utility.draw.c.Position = Utility.func.lerp(Utility.draw.c.Position, Vector2.new(pos.X, pos.Y), 0.3)
            Utility.draw.c.Visible = cvis

            Utility.draw.t.From = Utility.func.lerp(Utility.draw.t.From, MousePos, 0.3)
            Utility.draw.t.To = Utility.func.lerp(Utility.draw.t.To, Vector2.new(pos.X, pos.Y), 0.3)
            Utility.draw.t.Visible = tvis
        else
            Utility.draw.c.Visible = false
            Utility.draw.t.Visible = false
        end
    else
        Utility.draw.c.Visible = false
        Utility.draw.t.Visible = false
    end
end)


HeartbeatConn = r_s.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
    Utility.func.ViewTarget()
    Utility.func.Movement()
    Utility.func.lookat()
    Utility.func.AimBotFormula()
    Utility.func.RemoveFireRate()
    Utility.autoreload()
end))

PreSimulationConn = r_s.PreSimulation:Connect(LPH_NO_VIRTUALIZE(function()
    Utility.func.TrackPlayersAmmo()
    Utility.func.TrackPlayerHealth()
    Utility.autostomp()
end))

PostSimulationConn = r_s.PostSimulation:Connect(function()
    Utility.func.updateEsp()
    VisualsRendering()
end)

-- New example script written by wally
-- You can suggest changes with a pull request or something

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local gameName = "Unknown"
pcall(function()
	gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end)

local Window = Library:CreateWindow({
    Title = "Ace | " .. gameName, 
    TitleAlign = Enum.TextXAlignment.Center, 
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.1
})

-- CALLBACK NOTE:
-- Passing in callback functions via the initial element parameters (i.e. Callback = function(Value)...) works
-- HOWEVER, using Toggles/Options.INDEX:OnChanged(function(Value) ... ) is the RECOMMENDED way to do this.
-- I strongly recommend decoupling UI code from logic code. i.e. Create your UI elements FIRST, and THEN setup :OnChanged functions later.

-- You do not have to set your tabs & groups up this way, just a prefrence.
local Tabs = {
    -- Creates a new tab titled Main
    Main = Window:AddTab('Main'),
    Visual = Window:AddTab('Visuals'),
    Players = Window:AddTab('Players'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local function bindToggle(toggle, id, label)
    toggle:AddKeyPicker(id, {
        Default = 'None',
        Text = label,
        Mode = 'Toggle',
        SyncToggleState = true,
        NoUI = true,
    })
end


local Left = Tabs.Main:AddLeftGroupbox('Silent')
local Exploit = Tabs.Main:AddLeftGroupbox('Exploit')
local Right = Tabs.Main:AddRightGroupbox('Aimbot')
local Esp = Tabs.Visual:AddLeftGroupbox('Esp')
local hd = Tabs.Visual:AddLeftGroupbox('Hit Detection')
local Indicator = Tabs.Visual:AddRightGroupbox('Indicator')
local plr = Tabs.Players:AddLeftGroupbox('Movement')

local function playerFeature(box, id, label, tip, field, sliderDefault, sliderMin, sliderMax)
    local toggle = box:AddToggle(id .. 'Toggle', {
        Text = label,
        Default = false,
        Tooltip = tip,
        Callback = function(Value)
            getgenv().hvh.Player[field].Enabled = Value
        end,
    })
    bindToggle(toggle, id .. 'Key', label .. ' keybind')
    box:AddSlider(id .. 'Slider', {
        Text = label .. ' amount',
        Default = sliderDefault,
        Min = sliderMin,
        Max = sliderMax,
        Rounding = 1,
        Compact = false,
        Tooltip = 'Value used while ' .. string.lower(label) .. ' is enabled.',
        Callback = function(Value)
            getgenv().hvh.Player[field].Value = Value
        end,
    })
end

playerFeature(plr, 'Speed', 'Speed', 'Increases walk speed.', 'Speed', 16, 16, 500)
playerFeature(plr, 'Jump', 'Jump Power', 'Increases jump height.', 'Jump', 50, 50, 500)
playerFeature(plr, 'Flight', 'Flight', 'Fly with WASD, Space, and Ctrl.', 'Flight', 5, 1, 100)

hd:AddToggle('MyToggle', {
    Text = 'Indicators',
    Default = false, 
    Tooltip = 'Shows on-screen text with damage dealt when you hit someone.',

    Callback = function(Value)
        getgenv().hvh.HitDetections.Info = Value
    end
})

hd:AddToggle('MyToggle', {
    Text = 'CustomSounds',
    Default = false, 
    Tooltip = 'Plays a custom sound on hit or when ammo drops.',

    Callback = function(Value)
        getgenv().hvh.CustomSounds.Enabled = Value
    end
})

hd:AddSlider('MySlider', {
    Text = 'Sounds Volume',
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Compact = false,
    Tooltip = 'How loud hit sounds play (0–100).',

    Callback = function(Value)
        getgenv().hvh.CustomSounds.Volume = Value
    end
})

hd:AddDropdown('Type', {
     Values = { 
        'RIFK7', 'Bubble', 'Minecraft', 'Cod', 'Bameware', 'Neverlose', 
        'Gamesense', 'Rust', 'UWU', 'Bat', 'Lazer' 
    },
    Default = 1, 
    Multi = false, 

    Text = 'Sounds Name',
    Tooltip = 'Pick which hit sound effect to use.',

    Callback = function(Value)
        getgenv().hvh.CustomSounds.Type = Value
    end
})

hd:AddToggle('MyToggle', {
    Text = 'Hit Chams',
    Default = false, 
    Tooltip = 'Spawns glowing copies of the enemy when you damage them.',

    Callback = function(Value)
        getgenv().hvh.HitChams.Enabled = Value
    end
})
hd:AddToggle('MyToggle', {
    Text = 'Rainbow Color',
    Default = false, 
    Tooltip = 'Cycles hit chams through rainbow colors.',

    Callback = function(Value)
        getgenv().hvh.HitChams.Rainbow = Value
    end
})
hd:AddDropdown('Type', {
    Values = { 'BasePart', 'Clone'},
    Default = 1, 
    Multi = false, 

    Text = 'hithchams method',
    Tooltip = 'BasePart = neon parts. Clone = full character copy.',

    Callback = function(Value)
        getgenv().hvh.HitChams.Method = Value
    end
})
hd:AddSlider('MySlider', {
    Text = 'HitChams Duration',
    Default = 0,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Tooltip = 'How long hit chams stay visible (seconds).',

    Callback = function(Value)
        getgenv().hvh.HitChams.Duration = Value
    end
})
hd:AddLabel('Color'):AddColorPicker('HitChamsColorPicker', {
    Default = Color3.new(1, 1, 1),
    Title = 'Hit chams color',
    Callback = function(Value)
        getgenv().hvh.HitChams.Color = Value
    end,
})
Left:AddDropdown('Type', {
    Values = { 'Target', 'FOV'},
    Default = 2, 
    Multi = false, 

    Text = 'silent aim type',
    Tooltip = 'FOV = closest player in circle. Target = player you lock with keybind.',

    Callback = function(Value)
        getgenv().hvh.Main.Type = Value
    end
})
Left:AddDropdown('Parts', {
    Values = { 
        "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"
    },
    Default = 1, 
    Multi = false, 

    Text = 'BodyParts',
    Tooltip = 'Body part silent aim will redirect your shots to.',

    Callback = function(Value)
        getgenv().hvh.Main.Part = Value
    end
})
local aimbotToggle = Right:AddToggle('AimbotToggle', {
    Text = 'AimBot',
    Default = false, 
    Tooltip = 'Smoothly moves your camera onto the closest enemy.',

    Callback = function(Value)
        getgenv().hvh.Main.Aimbot = Value
    end
})
bindToggle(aimbotToggle, 'AimbotKey', 'Aimbot keybind')

Indicator:AddToggle('MyToggle', {
    Text = 'ShowTracer',
    Default = false, 
    Tooltip = 'Draws a line from your mouse to the current target.',

    Callback = function(Value)
        tvis = Value
    end
})
Indicator:AddSlider('MySlider', {
    Text = 'Tracer Thickness',
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Compact = false,
    Tooltip = 'How thick the target tracer line is.',

    Callback = function(Value)
        Utility.draw.t.Thickness = Value
    end
})

Indicator:AddSlider('MySlider', {
    Text = 'Tracer Transparency',
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Compact = false,
    Tooltip = 'How see-through the tracer line is.',

    Callback = function(Value)
        Utility.draw.t.Transparency = Value
    end
})
Indicator:AddLabel('Color'):AddColorPicker('TracerColorPicker', {
    Default = Color3.new(1, 1, 1),
    Title = 'Tracer color',
    Callback = function(Value)
        getgenv().hvh.Visuals.TracerColor = Value
        Utility.draw.t.Color = Value
    end,
})
Indicator:AddToggle('MyToggle', {
    Text = 'Show Circle',
    Default = false, 
    Tooltip = 'Shows a circle on screen over the silent aim target point.',

    Callback = function(Value)
        cvis= Value
    end
})
Indicator:AddSlider('MySlider', {
    Text = 'Circle radius',
    Default = 0,
    Min = 0,
    Max = 50,
    Rounding = 1,
    Compact = false,
    Tooltip = 'Size of the on-screen target circle.',

    Callback = function(Value)
        Utility.draw.c.Radius = Value
    end
})

Indicator:AddSlider('MySlider', {
    Text = 'Circle Thickness',
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Compact = false,
    Tooltip = 'Outline thickness of the target circle.',

    Callback = function(Value)
         Utility.draw.c.Thickness = Value
    end
})

Indicator:AddSlider('MySlider', {
    Text = 'Circle Transparency',
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Compact = false,
    Tooltip = 'How see-through the target circle is.',

    Callback = function(Value)
         Utility.draw.c.Transparency = Value
    end
})
Indicator:AddLabel('Color'):AddColorPicker('CircleColorPicker', {
    Default = Color3.new(1, 1, 1),
    Title = 'Target circle color',
    Callback = function(Value)
        getgenv().hvh.Visuals.CircleColor = Value
        Utility.draw.c.Color = Value
    end,
})

Right:AddDropdown('Parts', {
    Values = { 
        "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"
    },
    Default = 1, 
    Multi = false, 

    Text = 'BodyParts',
    Tooltip = 'Body part the aimbot will track and look at.',

    Callback = function(Value)
        getgenv().hvh.Main.AimbotParts = Value
    end
})
Right:AddLabel('Lock target'):AddKeyPicker('AimbotLockKey', {
    Default = 'None',
    NoUI = true,
    Text = 'Aimbot lock',
    Mode = 'Press',
    Callback = function()
        if not getgenv().hvh.Main.Aimbot then
            return
        end
        if Utility.Aimbot then
            Utility.Aimbot = nil
        else
            local Target = Utility.func.get_closest()
            if Target then
                Utility.Aimbot = Target
            end
        end
    end,
})
Right:AddInput('MyTextbox', {
    Default = 'Predictions',
    Numeric = false, -- true / false, only allows numbers
    Finished = false, -- true / false, only calls callback when you press enter

    Text = 'Pred',
    Tooltip = 'How far ahead to aim based on target movement.',

    Placeholder = 'pred', -- placeholder text when the box is empty
    
    Callback = function(Value)
        getgenv().hvh.Main.AimbotPred = Value
    end
})
Right:AddInput('MyTextbox', {
    Default = 'Smoothness',
    Numeric = false, -- true / false, only allows numbers
    Finished = false, -- true / false, only calls callback when you press enter

    Text = 'smoothing',
    Tooltip = 'Camera follow speed. Higher = smoother/slower aim.',

    Placeholder = 'smooth', -- placeholder text when the box is empty
    
    Callback = function(Value)
        getgenv().hvh.Main.Smoothness = Value
    end
})
local function espToggle(name, text, tip, field)
    local t = Esp:AddToggle(name, {
        Text = text,
        Default = false,
        Tooltip = tip,
        Callback = function(Value)
            getgenv().hvh.Esp[field] = Value
        end,
    })
    bindToggle(t, name .. 'Key', text .. ' keybind')
end

espToggle('EspMaster', 'Show Esp', 'Master switch for player ESP overlays.', 'Enabled')
espToggle('EspBox', 'Show Box', 'Draws a box around enemy players.', 'ShowBox')
espToggle('EspName', 'Show Name', 'Shows player display names above ESP boxes.', 'ShowName')
espToggle('EspHealth', 'Show Health', 'Shows a health bar next to each player.', 'ShowHealth')
espToggle('EspArmor', 'Show Armor', 'Shows armor bar (Da Hood BodyEffects armor).', 'ShowArmor')
espToggle('EspDistance', 'Show Distance', 'Shows how many meters away each player is.', 'ShowDistance')
espToggle('EspTool', 'Show Tool', 'Shows the tool/weapon each player is holding.', 'ShowTool')


local silentAimToggle = Left:AddToggle('SilentAimToggle', {
    Text = 'Silent aim',
    Default = false, 
    Tooltip = 'Redirects bullets to targets without moving your camera.',

    Callback = function(Value)
        getgenv().hvh.Main.TargetAim = Value
    end
})
bindToggle(silentAimToggle, 'SilentAimKey', 'Silent aim keybind')

Left:AddLabel('Lock target'):AddKeyPicker('SilentAimLockKey', {
    Default = 'None',
    NoUI = true,
    Text = 'Silent aim lock',
    Mode = 'Press',
    Callback = function()
        if Utility.Target then
            Utility.Target = nil
        else
            local Target = Utility.func.get_closest()
            if Target then
                Utility.Target = Target
            end
        end
    end,
})
Left:AddInput('MyTextbox', {
    Default = 'Predidctions',
    Numeric = false, -- true / false, only allows numbers
    Finished = false, -- true / false, only calls callback when you press enter

    Text = 'Prediction',
    Tooltip = 'Lead multiplier for moving targets (velocity × value).',

    Placeholder = 'Pred', -- placeholder text when the box is empty
    
    Callback = function(Value)
        getgenv().hvh.Main.Predictions = Value
    end
})
local showFovToggle = Left:AddToggle('ShowFovToggle', {
    Text = 'Show Fov ',
    Default = false, 
    Tooltip = 'Shows the circle around your mouse for target selection.',

    Callback = function(Value)
        blunt.Visible = Value
    end
})
bindToggle(showFovToggle, 'ShowFovKey', 'Show FOV keybind')

local filledFovToggle = Left:AddToggle('FilledFovToggle', {
    Text = 'Filled Fov ',
    Default = false, 
    Tooltip = 'Fills the FOV circle instead of showing outline only.',

    Callback = function(Value)
        blunt.Filled = Value
    end
})
bindToggle(filledFovToggle, 'FilledFovKey', 'Filled FOV keybind')
Left:AddSlider('MySlider', {
    Text = 'Radius',
    Default = 0,
    Min = 0,
    Max = 1000,
    Rounding = 1,
    Compact = false,
    Tooltip = 'How big the silent aim FOV circle is (pixels).',

    Callback = function(Value)
        blunt.Radius = Value
    end
})

Left:AddSlider('MySlider', {
    Text = 'Thickness',
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Compact = false,
    Tooltip = 'Line thickness of the FOV circle.',

    Callback = function(Value)
        blunt.Thickness = Value
    end
})

Left:AddSlider('MySlider', {
    Text = 'Transparency',
    Default = 0,
    Min = 0.1,
    Max = 1,
    Rounding = 1,
    Compact = false,
    Tooltip = 'How see-through the FOV circle is.',

    Callback = function(Value)
     blunt.Transparency = Value
    end
})
Left:AddLabel('Color'):AddColorPicker('FovColorPicker', {
    Default = Color3.new(1, 1, 1),
    Title = 'FOV circle color',
    Callback = function(Value)
        blunt.Color = Value
    end,
})









local removeFireToggle = Exploit:AddToggle('RemoveFireToggle', {
    Text = 'Remove Fire Rate',
    Default = false, 
    Tooltip = 'Removes gun fire cooldown on supported games.',

    Callback = function(Value)
        getgenv().hvh.Main.RemoveFireRate = Value
    end
})
bindToggle(removeFireToggle, 'RemoveFireKey', 'Remove fire rate keybind')

local spectateToggle = Exploit:AddToggle('SpectateToggle', {
    Text = 'Spectate Target',
    Default = false, 
    Tooltip = 'Moves your camera to follow the locked target.',

    Callback = function(Value)
        getgenv().hvh.Main.View= Value
    end
})
bindToggle(spectateToggle, 'SpectateKey', 'Spectate keybind')

local lookAtToggle = Exploit:AddToggle('LookAtToggle', {
    Text = 'Look At Target',
    Default = false, 
    Tooltip = 'Rotates your character to face the locked target.',

    Callback = function(Value)
        getgenv().hvh.Main.LookAt= Value
    end
})
bindToggle(lookAtToggle, 'LookAtKey', 'Look at target keybind')

local augToggle = Exploit:AddToggle('AugToggle', {
    Text = 'Aug rapid fire',
    Default = false, 
    Tooltip = 'Auto-fires while holding click. Can cause lag or kicks.',

    Callback = function(Value)
        getgenv().hvh.Main.Aug= Value
    end
})
bindToggle(augToggle, 'AugKey', 'Aug rapid fire keybind')
Library:SetWatermarkVisibility(true)


local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local localPlayerName = game.Players.LocalPlayer.DisplayName

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end

    Library:SetWatermark(('Game: %s | Player: %s | #RR | ver:Gui | Index | .GG/TRACED | %s fps | %s ms'):format(
        gameName,
        localPlayerName,
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ))
end)


Library.KeybindFrame.Visible = false; -- todo: add a function for this

Library:OnUnload(function()
    WatermarkConnection:Disconnect()

    print('Unloaded!')
    Library.Unloaded = true
end)

-- UI Settings
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

-- I set NoUI so it does not show up in the keybinds menu
MenuGroup:AddButton({
    Text = 'Unload',
    Tooltip = 'Fully unloads the script and closes the menu.',
    Func = function() Library:Unload() end
})
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'RightShift', NoUI = true, Text = 'Menu keybind', Tooltip = 'Show or hide this menu (RightShift).' })

Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu

-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- ThemeManager (Allows you to have a menu theme system)

-- Hand the library over to our managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- Adds our MenuKeybind to the ignore list
-- (do you want each config to have a different menu key? probably not.)
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')

SaveManager:BuildConfigSection(Tabs['UI Settings'])


ThemeManager:ApplyToTab(Tabs['UI Settings'])


SaveManager:LoadAutoloadConfig()