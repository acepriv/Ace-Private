-- Ace Arsenal | Aimbot, ESP, gun mods, and melee wired

getgenv().hvh = {
	Combat = {
		Aimbot = false,
		HitPart = "Head",
		Prediction = 0.12,
		Smoothness = 0.35,
		ShowFOV = false,
		FOVFilled = false,
		FOVRadius = 500,
		ShowTracer = false,
		ShowTargetCircle = false,
		TargetCircleRadius = 50,
		FOVColor = Color3.fromRGB(255, 255, 255),
		TracerColor = Color3.fromRGB(255, 255, 255),
		TargetCircleColor = Color3.fromRGB(255, 255, 255),
	},
	Guns = {
		RapidFire = false,
		InfiniteAmmo = false,
		NoRecoil = false,
		InstantReload = false,
		FireRate = 1,
	},
	Melee = {
		KillAura = false,
		Range = 15,
		Rage = false,
		AutoSwing = false,
		SwingSpeed = 1,
	},
	Esp = {
		Enabled = false,
		ShowBox = false,
		ShowName = false,
		ShowHealth = false,
		ShowDistance = false,
		ShowWeapon = false,
		ShowSkeleton = false,
	},
	Player = {
		Speed = { Enabled = false, Value = 16 },
		Jump = { Enabled = false, Value = 50 },
		Flight = { Enabled = false, Value = 5 },
		Bhop = { Enabled = false },
	},
	Misc = {
		AntiVoteKick = false,
		UnlockAll = false,
		ThirdPerson = false,
	},
	Skins = {
		UnlockSkins = false,
		UnlockKillEffects = false,
		UnlockEmotes = false,
	},
}

if not LPH_OBFUSCATED then
	LPH_NO_VIRTUALIZE = function(...)
		return (...)
	end
end

local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
	Title = "Ace | Arsenal",
	TitleAlign = Enum.TextXAlignment.Center,
	Center = true,
	AutoShow = true,
	TabPadding = 8,
	MenuFadeTime = 0.1,
})

local Tabs = {
	Main = Window:AddTab("Main"),
	Visual = Window:AddTab("Visuals"),
	Players = Window:AddTab("Players"),
	Misc = Window:AddTab("Misc"),
	["UI Settings"] = Window:AddTab("UI Settings"),
}

task.defer(function()
local Game = game
local Players = Game:GetService("Players")
local Camera = workspace.CurrentCamera
local r_s = Game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character
local LocalHumanoid = LocalCharacter and LocalCharacter:FindFirstChildOfClass("Humanoid")
local LocalRootPart = LocalHumanoid and LocalHumanoid.RootPart

local function refreshCharacter(character)
	LocalCharacter = character
	LocalHumanoid = character and (character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10))
	LocalRootPart = LocalHumanoid and LocalHumanoid.RootPart
		or (character and (character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 10)))
	if character and not LocalRootPart then
		LocalRootPart = character:FindFirstChild("Hitbox") or character:FindFirstChild("HeadHB")
	end
end

refreshCharacter(LocalCharacter)
LocalPlayer.CharacterAdded:Connect(refreshCharacter)

task.spawn(function()
	local gui = LocalPlayer:WaitForChild("PlayerGui", 20)
	if not gui then
		return
	end
	gui:WaitForChild("Menew", 20)
	gui:WaitForChild("GUI", 20)
end)

if not LocalCharacter then
	task.spawn(function()
		refreshCharacter(LocalPlayer.CharacterAdded:Wait())
	end)
end

local UserInputService = Game:GetService("UserInputService")

Utility = { func = {}, draw = {}, espReady = false, Aimbot = nil, HoldingRMB = false, MeleeTarget = nil, arsenal = {}, unlock = { coreEnv = nil, viewItems = nil, loadout = nil, hooked = false, lastNotify = 0, lastMsg = nil } }

local ReplicatedStorage = Game:GetService("ReplicatedStorage")
local gunDefaults = {}
local lastMeleeSwing = 0

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = workspace.CurrentCamera
end)

local aimCache = { target = nil, point = nil, part = nil, frame = 0 }
local cacheFrame = 0

r_s.RenderStepped:Connect(function()
	cacheFrame += 1

	local combat = getgenv().hvh.Combat
	if combat.Aimbot or combat.ShowFOV or combat.ShowTracer or combat.ShowTargetCircle then
		Utility.func.refreshAimCache()
	end
	if combat.ShowFOV then
		Utility.func.updateFovCircle()
	elseif fovCircle then
		fovCircle.Visible = false
	end
	if combat.ShowTracer or combat.ShowTargetCircle then
		Utility.func.updateTargetIndicator()
	elseif Utility.draw.c and Utility.draw.t then
		Utility.draw.c.Visible = false
		Utility.draw.t.Visible = false
	end
end)

local fovCircle
if Drawing then
	fovCircle = Drawing.new("Circle")
	fovCircle.Radius = getgenv().hvh.Combat.FOVRadius
	fovCircle.Thickness = 1
	fovCircle.Transparency = 1
	fovCircle.Filled = getgenv().hvh.Combat.FOVFilled
	fovCircle.Color = getgenv().hvh.Combat.FOVColor
	fovCircle.Visible = false
	fovCircle.NumSides = 64
	fovCircle.ZIndex = 999999

	Utility.draw.c = Drawing.new("Circle")
	Utility.draw.c.Thickness = 2
	Utility.draw.c.NumSides = 64
	Utility.draw.c.Radius = getgenv().hvh.Combat.TargetCircleRadius
	Utility.draw.c.Filled = false
	Utility.draw.c.Color = getgenv().hvh.Combat.TargetCircleColor
	Utility.draw.c.Transparency = 1
	Utility.draw.c.Visible = false
	Utility.draw.c.ZIndex = 999998

	Utility.draw.t = Drawing.new("Line")
	Utility.draw.t.Thickness = 2
	Utility.draw.t.Color = getgenv().hvh.Combat.TracerColor
	Utility.draw.t.Transparency = 1
	Utility.draw.t.Visible = false
	Utility.draw.t.ZIndex = 999998
else
	task.defer(function()
		Library:Notify("Drawing API unavailable — FOV and ESP visuals will not render.", 6)
	end)
end

Utility.func.lerp = function(v1, v2, alpha)
	return v1 + (v2 - v1) * alpha
end

Utility.func.isTeammate = function(player)
	if player == LocalPlayer then
		return true
	end
	local myTeam = LocalPlayer.Team
	local theirTeam = player.Team
	if not myTeam or not theirTeam then
		return false
	end
	return myTeam == theirTeam
end

Utility.func.isEnemy = function(player)
	return player ~= LocalPlayer and not Utility.func.isTeammate(player)
end

Utility.func.isArsenalAlive = function(player)
	local nrpbs = player:FindFirstChild("NRPBS")
	if nrpbs then
		local health = nrpbs:FindFirstChild("Health")
		if health then
			return health.Value > 0
		end
	end
	local character = player.Character
	if not character then
		return false
	end
	local hum = character:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
end

Utility.func.getCamera = function()
	return workspace.CurrentCamera or Camera
end

Utility.func.getMousePosition = function()
	return UserInputService:GetMouseLocation()
end

Utility.func.getHitPart = function(character)
	local chosen = getgenv().hvh.Combat.HitPart
	return character:FindFirstChild(chosen)
		or (chosen == "Head" and character:FindFirstChild("HeadHB"))
		or character:FindFirstChild("HeadHB")
		or character:FindFirstChild("Hitbox")
		or character:FindFirstChild("Head")
		or character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("Torso")
end

Utility.func.getPredictedPosition = function(part)
	local pred = tonumber(getgenv().hvh.Combat.Prediction) or 0.12
	local velocity = part.AssemblyLinearVelocity
	if velocity.Magnitude <= 0 then
		velocity = part.Velocity
	end
	return part.Position + velocity * pred
end

Utility.func.getArsenalEvents = function()
	if Utility.arsenal.events and Utility.arsenal.events.Parent then
		return Utility.arsenal.events
	end
	Utility.arsenal.events = ReplicatedStorage:FindFirstChild("Events")
	return Utility.arsenal.events
end

Utility.func.getArsenalWeapons = function()
	if Utility.arsenal.weapons and Utility.arsenal.weapons.Parent then
		return Utility.arsenal.weapons
	end
	Utility.arsenal.weapons = ReplicatedStorage:FindFirstChild("Weapons")
	return Utility.arsenal.weapons
end

Utility.func.getClientScript = function()
	local gui = LocalPlayer:FindFirstChild("PlayerGui")
	local client = gui and gui:FindFirstChild("GUI") and gui.GUI:FindFirstChild("Client")
	if not client then
		return nil
	end
	return client:FindFirstChildWhichIsA("LocalScript") or client
end

Utility.func.getClientEnv = function()
	if typeof(getsenv) ~= "function" then
		return nil
	end
	local scriptObj = Utility.func.getClientScript()
	if not scriptObj then
		return nil
	end
	local ok, env = pcall(getsenv, scriptObj)
	if ok and typeof(env) == "table" then
		Utility.arsenal.clientEnv = env
		return env
	end
	return Utility.arsenal.clientEnv
end

Utility.func.getClientVariables = function()
	local gui = LocalPlayer:FindFirstChild("PlayerGui")
	local client = gui and gui:FindFirstChild("GUI") and gui.GUI:FindFirstChild("Client")
	return client and client:FindFirstChild("Variables")
end

Utility.func.getCurrentWeaponName = function()
	local env = Utility.func.getClientEnv()
	if env then
		for _, key in { "curweapon", "currentweapon", "CurrentWeapon", "weapon", "WeaponName", "toolname", "ToolName" } do
			local value = env[key]
			if typeof(value) == "string" and value ~= "" then
				return value
			end
		end
	end

	local vars = Utility.func.getClientVariables()
	if vars then
		for _, name in { "currentweapon", "CurrentWeapon", "weapon", "Weapon", "curgun", "Gun", "tool", "Tool" } do
			local valueObject = vars:FindFirstChild(name)
			if valueObject then
				local value = valueObject.Value
				if typeof(value) == "string" and value ~= "" then
					return value
				elseif typeof(value) == "Instance" then
					return value.Name
				end
			end
		end
		for _, child in vars:GetChildren() do
			if child:IsA("StringValue") or child:IsA("ObjectValue") then
				local value = child.Value
				local weaponName = typeof(value) == "string" and value or (typeof(value) == "Instance" and value.Name)
				if weaponName and (Utility.func.getWeaponData(weaponName) or Utility.func.isMeleeWeapon(weaponName)) then
					return weaponName
				end
			end
		end
	end

	if LocalCharacter then
		local tool = LocalCharacter:FindFirstChildWhichIsA("Tool")
		if tool then
			return tool.Name
		end
	end

	local status = LocalPlayer:FindFirstChild("Status")
	if status then
		for _, name in { "Weapon", "Equipped", "CurrentWeapon", "Tool" } do
			local valueObject = status:FindFirstChild(name)
			if valueObject and (valueObject:IsA("StringValue") or valueObject:IsA("ObjectValue")) then
				local value = valueObject.Value
				if typeof(value) == "string" and value ~= "" then
					return value
				elseif typeof(value) == "Instance" then
					return value.Name
				end
			end
		end
	end

	return nil
end

Utility.func.getWeaponData = function(weaponName)
	if not weaponName then
		return nil
	end
	local weapons = Utility.func.getArsenalWeapons()
	return weapons and weapons:FindFirstChild(weaponName)
end

Utility.func.isMeleeWeapon = function(weaponName)
	if not weaponName then
		return false
	end

	local itemData = ReplicatedStorage:FindFirstChild("ItemData")
	if itemData then
		local melees = itemData:FindFirstChild("Melees")
			or (itemData:FindFirstChild("Images") and itemData.Images:FindFirstChild("Melees"))
		if melees and melees:FindFirstChild(weaponName) then
			return true
		end
	end

	local data = Utility.func.getWeaponData(weaponName)
	if not data then
		return false
	end

	if data:FindFirstChild("Backstab") or data:FindFirstChild("BackstabMultiplier") then
		return true
	end

	if data:FindFirstChild("Ammo") or data:FindFirstChild("StoredAmmo") or data:FindFirstChild("Projectile") or data:FindFirstChild("Bullets") then
		return false
	end

	return true
end

Utility.func.isGunWeapon = function(weaponName)
	return weaponName and not Utility.func.isMeleeWeapon(weaponName)
end

Utility.func.storeGunDefault = function(valueObject)
	local key = tostring(valueObject)
	if gunDefaults[key] == nil then
		gunDefaults[key] = valueObject.Value
	end
end

Utility.func.setWeaponValue = function(valueObject, enabled, newValue)
	if not enabled or not valueObject then
		return
	end
	if valueObject:IsA("NumberValue") or valueObject:IsA("IntValue") or valueObject:IsA("BoolValue") then
		Utility.func.storeGunDefault(valueObject)
		valueObject.Value = newValue
	end
end

Utility.func.applyGunMods = LPH_NO_VIRTUALIZE(function()
	local cfg = getgenv().hvh.Guns
	local active = cfg.RapidFire or cfg.InfiniteAmmo or cfg.NoRecoil or cfg.InstantReload or cfg.FireRate > 1
	if not active then
		return
	end

	local weapons = Utility.func.getArsenalWeapons()
	if not weapons then
		return
	end

	local rateMult = cfg.RapidFire and math.max(cfg.FireRate, 5) or math.max(cfg.FireRate, 1)
	local currentWeapon = Utility.func.getCurrentWeaponName()

	local function patchWeaponFolder(weaponFolder)
		if cfg.RapidFire or cfg.FireRate > 1 then
			for _, name in { "FireRate", "BFireRate" } do
				local valueObject = weaponFolder:FindFirstChild(name, true)
				if valueObject and (valueObject:IsA("NumberValue") or valueObject:IsA("IntValue")) then
					Utility.func.storeGunDefault(valueObject)
					valueObject.Value = math.max(gunDefaults[tostring(valueObject)] / rateMult, 0.02)
				end
			end
		end

		if cfg.InstantReload then
			for _, name in { "ReloadTime", "EReloadTime" } do
				local valueObject = weaponFolder:FindFirstChild(name, true)
				Utility.func.setWeaponValue(valueObject, true, 0.01)
			end
		end

		if cfg.NoRecoil then
			for _, desc in weaponFolder:GetDescendants() do
				if desc:IsA("NumberValue") or desc:IsA("IntValue") then
					local lower = desc.Name:lower()
					if lower:find("recoil") or desc.Name == "Spread" or desc.Name == "MaxSpread" or desc.Name == "SpreadControl" then
						Utility.func.setWeaponValue(desc, true, 0)
					end
				end
			end
		end

		if cfg.RapidFire then
			for _, desc in weaponFolder:GetDescendants() do
				if desc:IsA("BoolValue") then
					local lower = desc.Name:lower()
					if lower:find("auto") then
						Utility.func.setWeaponValue(desc, true, true)
					end
				end
			end
		end
	end

	if currentWeapon and (cfg.RapidFire or cfg.FireRate > 1 or cfg.NoRecoil or cfg.InstantReload) then
		local currentData = Utility.func.getWeaponData(currentWeapon)
		if currentData then
			patchWeaponFolder(currentData)
		end
	end

	if cfg.RapidFire or cfg.NoRecoil or cfg.InstantReload or cfg.FireRate > 1 then
		for _, weaponFolder in weapons:GetChildren() do
			patchWeaponFolder(weaponFolder)
		end
	end

	if cfg.InfiniteAmmo then
		pcall(function()
			local wkspc = ReplicatedStorage:FindFirstChild("wkspc")
			local curse = wkspc and wkspc:FindFirstChild("CurrentCurse")
			if curse then
				curse.Value = "Infinite Ammo"
			end
		end)

		local vars = Utility.func.getClientVariables()
		if vars then
			for _, name in { "ammocount", "ammocount2", "ammocount3", "ammocount4" } do
				local valueObject = vars:FindFirstChild(name)
				if valueObject and (valueObject:IsA("IntValue") or valueObject:IsA("NumberValue")) then
					valueObject.Value = 99
				end
			end
		end

		local env = Utility.func.getClientEnv()
		if env then
			env.getammo = function()
				return 999
			end
			for index = 1, 4 do
				local key = index == 1 and "ammocount" or ("ammocount" .. index)
				if env[key] ~= nil then
					env[key] = 999
				end
			end
		end
	end

	if cfg.NoRecoil then
		local env = Utility.func.getClientEnv()
		if env then
			env.ShakeCam = function() end
		end
	end
end)

Utility.func.getCharacterRoot = function(character)
	return Utility.func.getEspRoot(character)
end

Utility.func.getClosestEnemy = function(maxRange)
	local closestPlayer, closestDistance = nil, maxRange or math.huge
	if not LocalRootPart then
		return nil
	end

	for _, player in Players:GetPlayers() do
		if not Utility.func.isEnemy(player) or not Utility.func.isArsenalAlive(player) then
			continue
		end
		local character = player.Character
		local root = character and Utility.func.getCharacterRoot(character)
		if not root then
			continue
		end
		local distance = (LocalRootPart.Position - root.Position).Magnitude
		if distance <= closestDistance then
			closestDistance = distance
			closestPlayer = player
		end
	end

	return closestPlayer
end

Utility.func.teleportBehindPlayer = function(player)
	local character = player and player.Character
	local root = character and Utility.func.getCharacterRoot(character)
	if not root or not LocalRootPart then
		return false
	end

	local behind = root.Position + root.CFrame.LookVector * 3
	LocalRootPart.CFrame = CFrame.new(behind, root.Position)
	LocalRootPart.AssemblyLinearVelocity = Vector3.zero
	LocalRootPart.AssemblyAngularVelocity = Vector3.zero
	return true
end

Utility.func.swingMelee = function(targetPlayer)
	if not targetPlayer then
		return
	end

	local events = Utility.func.getArsenalEvents()
	if events then
		local meleeEvent = events:FindFirstChild("meleeEvent") or events:FindFirstChild("MeleeEvent")
		if meleeEvent and meleeEvent:IsA("RemoteEvent") then
			pcall(function()
				for _ = 1, 3 do
					meleeEvent:FireServer(targetPlayer)
				end
			end)
		end

		local hitPart = events:FindFirstChild("HitPart")
		local character = targetPlayer.Character
		local part = character and Utility.func.getHitPart(character)
		if hitPart and hitPart:IsA("RemoteEvent") and part then
			pcall(function()
				hitPart:FireServer(part, part.Position, Vector3.zero, Utility.func.getCurrentWeaponName() or "Knife")
			end)
		end
	end

	if LocalCharacter then
		local tool = LocalCharacter:FindFirstChildWhichIsA("Tool")
		if tool then
			pcall(function()
				tool:Activate()
			end)
		end
	end

	if typeof(VirtualInputManager) == "userdata" or typeof(VirtualInputManager) == "Instance" then
		pcall(function()
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
			task.defer(function()
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
			end)
		end)
	end
end

Utility.func.runMelee = LPH_NO_VIRTUALIZE(function()
	local cfg = getgenv().hvh.Melee
	if not (cfg.Rage or cfg.KillAura or cfg.AutoSwing) then
		Utility.MeleeTarget = nil
		return
	end

	local weaponName = Utility.func.getCurrentWeaponName()
	if not weaponName or not Utility.func.isMeleeWeapon(weaponName) then
		Utility.MeleeTarget = nil
		return
	end

	if not LocalRootPart then
		return
	end

	local now = tick()
	local swingDelay = 1 / math.max(cfg.SwingSpeed or 1, 0.1)
	local canSwing = now - lastMeleeSwing >= swingDelay

	if cfg.Rage then
		if not Utility.MeleeTarget or not Utility.func.isEnemy(Utility.MeleeTarget) or not Utility.func.isArsenalAlive(Utility.MeleeTarget) then
			Utility.MeleeTarget = Utility.func.getClosestEnemy()
		end

		local target = Utility.MeleeTarget
		if target and target.Character then
			Utility.func.teleportBehindPlayer(target)
			if canSwing then
				Utility.func.swingMelee(target)
				lastMeleeSwing = now
			end
		end
		return
	end

	Utility.MeleeTarget = nil
	local target = Utility.func.getClosestEnemy(cfg.Range)
	if not target then
		return
	end

	if cfg.KillAura or cfg.AutoSwing then
		if canSwing then
			Utility.func.swingMelee(target)
			lastMeleeSwing = now
		end
	end
end)

Utility.func.getArsenalTargetPart = LPH_NO_VIRTUALIZE(function()
	local combat = getgenv().hvh.Combat
	local cam = Utility.func.getCamera()
	local closestDistance = combat.FOVRadius
	local closestPart, closestPlayer = nil, nil
	local mousePos = Utility.func.getMousePosition()

	for _, player in Players:GetPlayers() do
		if not Utility.func.isEnemy(player) or not player.Character then
			continue
		end
		if not Utility.func.isArsenalAlive(player) then
			continue
		end

		local hitPart = player.Character:FindFirstChild(combat.HitPart) or Utility.func.getHitPart(player.Character)
		if not hitPart then
			continue
		end

		local screenPos, onScreen = cam:WorldToViewportPoint(hitPart.Position)
		if not onScreen or screenPos.Z < 0 then
			continue
		end

		local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
		if distance < closestDistance then
			closestDistance = distance
			closestPart = hitPart
			closestPlayer = player
		end
	end

	return closestPart, closestPlayer
end)

Utility.func.refreshAimCache = LPH_NO_VIRTUALIZE(function()
	if aimCache.frame == cacheFrame then
		return
	end

	local combat = getgenv().hvh.Combat
	if not (combat.Aimbot or combat.ShowFOV or combat.ShowTracer or combat.ShowTargetCircle) then
		aimCache.target, aimCache.point, aimCache.part = nil, nil, nil
		aimCache.frame = cacheFrame
		return
	end

	local part, player = Utility.func.getArsenalTargetPart()
	aimCache.part = part
	aimCache.target = player
	aimCache.point = part and Utility.func.getPredictedPosition(part) or nil
	aimCache.frame = cacheFrame
end)

Utility.func.getTargetPlayer = function()
	if Utility.HoldingRMB and Utility.Aimbot and Utility.func.isArsenalAlive(Utility.Aimbot) then
		return Utility.Aimbot
	end
	return aimCache.target
end

Utility.func.getAimPoint = function(target)
	if not target or not target.Character then
		return nil
	end
	if target == Utility.Aimbot and Utility.HoldingRMB then
		local part = Utility.func.getHitPart(target.Character)
		return part and Utility.func.getPredictedPosition(part) or nil
	end
	if target == aimCache.target and aimCache.point then
		return aimCache.point
	end
	local part = Utility.func.getHitPart(target.Character)
	return part and Utility.func.getPredictedPosition(part) or nil
end

Utility.func.tryAimbotLock = function()
	if not getgenv().hvh.Combat.Aimbot or not Utility.HoldingRMB then
		return
	end
	if Utility.Aimbot and Utility.func.isArsenalAlive(Utility.Aimbot) then
		return
	end
	Utility.Aimbot = nil
	local _, target = Utility.func.getArsenalTargetPart()
	if target then
		Utility.Aimbot = target
	end
end

Utility.func.AimBotFormula = function()
	local combat = getgenv().hvh.Combat
	if not combat.Aimbot then
		return
	end
	if not Utility.HoldingRMB or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		Utility.HoldingRMB = false
		Utility.Aimbot = nil
		return
	end

	local target = Utility.Aimbot
	if not target or not Utility.func.isArsenalAlive(target) then
		Utility.Aimbot = nil
		return
	end

	local part = Utility.func.getHitPart(target.Character)
	if not part then
		return
	end

	local cam = Utility.func.getCamera()
	local endpoint = Utility.func.getPredictedPosition(part)
	local smooth = tonumber(combat.Smoothness) or 0.35
	local goal = CFrame.new(cam.CFrame.Position, endpoint)
	cam.CFrame = cam.CFrame:Lerp(goal, smooth)
end

Utility.func.getFunctionName = function(fn)
	if typeof(fn) ~= "function" then
		return nil
	end
	if debug and debug.info then
		return debug.info(fn, "n")
	end
	if debug and debug.getinfo then
		local info = debug.getinfo(fn)
		return info and info.name
	end
	return nil
end

Utility.func.clearUnlockCache = function()
	Utility.unlock.coreEnv = nil
	Utility.unlock.viewItems = nil
	Utility.unlock.loadout = nil
end

Utility.func.notifyUnlock = function(message, duration)
	local now = tick()
	if Utility.unlock.lastMsg == message and now - (Utility.unlock.lastNotify or 0) < 3 then
		return
	end
	Utility.unlock.lastNotify = now
	Utility.unlock.lastMsg = message
	Library:Notify(message, duration)
end

Utility.func.getMenewScript = function()
	local gui = LocalPlayer:FindFirstChild("PlayerGui")
	if not gui then
		return nil
	end

	for _, menuName in { "Menew", "Menu" } do
		local menew = gui:FindFirstChild(menuName)
		if menew then
			local direct = menew:FindFirstChild("LocalScript", true)
				or menew:FindFirstChild("Client", true)
			if direct and direct:IsA("LocalScript") then
				return direct
			end
			for _, desc in menew:GetDescendants() do
				if desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
					return desc
				end
			end
		end
	end

	if typeof(getrunningscripts) == "function" then
		for _, scr in getrunningscripts() do
			if scr:IsA("LocalScript") and scr:IsDescendantOf(gui) then
				local ancestor = scr.Parent
				while ancestor and ancestor ~= gui do
					if ancestor.Name == "Menew" or ancestor.Name == "Menu" then
						return scr
					end
					ancestor = ancestor.Parent
				end
			end
		end
	end

	return nil
end

Utility.func.getMenewEnv = function()
	if Utility.unlock.coreEnv then
		return Utility.unlock.coreEnv
	end
	if typeof(getsenv) ~= "function" then
		return nil
	end
	local scriptObj = Utility.func.getMenewScript()
	if not scriptObj then
		return nil
	end
	local ok, env = pcall(getsenv, scriptObj)
	if ok and typeof(env) == "table" then
		Utility.unlock.coreEnv = env
		if typeof(env.ViewItems) == "function" then
			Utility.unlock.viewItems = env.ViewItems
		end
		return env
	end
	return nil
end

Utility.func.findViewItems = function()
	if Utility.unlock.viewItems then
		return Utility.unlock.viewItems
	end

	Utility.func.getMenewEnv()
	if typeof(Utility.unlock.viewItems) == "function" then
		return Utility.unlock.viewItems
	end

	if typeof(getrunningscripts) == "function" and typeof(getsenv) == "function" then
		for _, scr in getrunningscripts() do
			if scr:IsDescendantOf(LocalPlayer) or scr:IsDescendantOf(game:GetService("PlayerGui")) then
				local ok, env = pcall(getsenv, scr)
				if ok and typeof(env) == "table" and typeof(env.ViewItems) == "function" then
					Utility.unlock.coreEnv = env
					Utility.unlock.viewItems = env.ViewItems
					return env.ViewItems
				end
			end
		end
	end

	if typeof(getgc) ~= "function" or typeof(getupvalues) ~= "function" then
		return nil
	end

	for _, obj in getgc(true) do
		if typeof(obj) == "function" and Utility.func.getFunctionName(obj) == "ViewItems" then
			local ok, upvalues = pcall(getupvalues, obj)
			if ok then
				for _, value in pairs(upvalues) do
					if typeof(value) == "table" and (value.Skins or value.Melees) then
						Utility.unlock.viewItems = obj
						Utility.unlock.loadout = value
						return obj
					end
				end
			end
		end
	end

	return nil
end

Utility.func.looksLikeLoadout = function(value)
	return typeof(value) == "table"
		and typeof(value.Skins) == "table"
		and (typeof(value.Melees) == "table" or typeof(value.Emotes) == "table")
end

Utility.func.getLoadoutTable = function()
	if Utility.unlock.loadout then
		return Utility.unlock.loadout
	end

	local viewItems = Utility.func.findViewItems()
	if not viewItems or typeof(getupvalues) ~= "function" then
		return nil
	end

	local ok, upvalues = pcall(getupvalues, viewItems)
	if not ok or typeof(upvalues) ~= "table" then
		return nil
	end

	for _, value in pairs(upvalues) do
		if Utility.func.looksLikeLoadout(value) or (typeof(value) == "table" and (value.Skins or value.Melees)) then
			Utility.unlock.loadout = value
			Utility.unlock.viewItems = viewItems
			return value
		end
	end

	if typeof(getgc) == "function" then
		for _, obj in getgc(true) do
			if Utility.func.looksLikeLoadout(obj) then
				Utility.unlock.loadout = obj
				return obj
			end
		end
	end

	return nil
end

Utility.func.ensureUnlockState = function(maxWait)
	maxWait = maxWait or 4
	local deadline = tick() + maxWait
	while tick() < deadline do
		local loadout = Utility.func.getLoadoutTable()
		if loadout then
			return loadout
		end
		Utility.func.clearUnlockCache()
		task.wait(0.15)
	end
	return Utility.func.getLoadoutTable()
end

Utility.func.addToLoadoutList = function(list, name)
	if typeof(list) ~= "table" or typeof(name) ~= "string" or name == "" then
		return
	end
	if not table.find(list, name) then
		table.insert(list, name)
	end
end

Utility.func.syncLoadoutUpvalue = function()
	local loadout = Utility.unlock.loadout
	local viewItems = Utility.unlock.viewItems
	if loadout and viewItems and setupvalue then
		pcall(setupvalue, viewItems, 1, loadout)
	end
end

Utility.func.installUnlockAllHook = function()
	if Utility.unlock.hooked or not Utility.unlock.loadout then
		return
	end

	local function patchGetInventory(self, oldFn, ...)
		if typeof(self) == "Instance" and (self.Name == "GetInventory" or self.Name == "UpdateInventory") then
			if getgenv().hvh.Misc.UnlockAll
				or getgenv().hvh.Skins.UnlockSkins
				or getgenv().hvh.Skins.UnlockEmotes
				or getgenv().hvh.Skins.UnlockKillEffects
			then
				Utility.func.syncLoadoutUpvalue()
			end
		end
		return oldFn(self, ...)
	end

	if hookmetamethod and typeof(hookmetamethod) == "function" then
		local ok = pcall(function()
			local oldNamecall
			oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
				if typeof(checkcaller) == "function" and checkcaller() then
					return oldNamecall(self, ...)
				end
				return patchGetInventory(self, oldNamecall, ...)
			end)
			Utility.unlock.hooked = ok
		end)
		if ok then
			return
		end
	end

	local okMeta, mt = pcall(getrawmetatable, game)
	if okMeta and mt and typeof(mt.__namecall) == "function" then
		pcall(function()
			if setreadonly then
				setreadonly(mt, false)
			end
		end)
		local oldNamecall = mt.__namecall
		mt.__namecall = function(self, ...)
			return patchGetInventory(self, oldNamecall, ...)
		end
		pcall(function()
			if setreadonly then
				setreadonly(mt, true)
			end
		end)
		Utility.unlock.hooked = true
	end
end

Utility.func.applyUnlockAll = function(options)
	options = options or { all = true }

	local loadout = Utility.func.ensureUnlockState(4)
	if not loadout then
		return false, "Locker not ready — open the Arsenal menu, wait a moment, then toggle Unlock All again."
	end

	local itemData = ReplicatedStorage:FindFirstChild("ItemData")
	local images = itemData and itemData:FindFirstChild("Images")
	if images then
		for _, category in images:GetChildren() do
			local shouldUnlock = options.all
				or options[category.Name]
				or (options.Skins and category.Name == "Skins")
				or (options.Emotes and category.Name == "Emotes")
				or (options.KillEffects and (category.Name == "KillEffects" or category.Name == "KillEffects2"))

			if shouldUnlock and typeof(loadout[category.Name]) == "table" then
				for _, item in category:GetChildren() do
					Utility.func.addToLoadoutList(loadout[category.Name], item.Name)
				end
			end
		end
	end

	if options.all or options.Weapons or options.Skins then
		local weapons = Utility.func.getArsenalWeapons()
		if weapons and typeof(loadout.Skins) == "table" then
			for _, weapon in weapons:GetChildren() do
				Utility.func.addToLoadoutList(loadout.Skins, weapon.Name)
			end
		end
	end

	Utility.func.syncLoadoutUpvalue()
	Utility.func.installUnlockAllHook()
	return true
end

Utility.func.tryAutoUnlock = function()
	local h = getgenv().hvh
	if h.Misc.UnlockAll then
		return Utility.func.applyUnlockAll({ all = true })
	end
	local opts = {}
	if h.Skins.UnlockSkins then
		opts.Skins = true
		opts.Weapons = true
	end
	if h.Skins.UnlockEmotes then
		opts.Emotes = true
	end
	if h.Skins.UnlockKillEffects then
		opts.KillEffects = true
	end
	if next(opts) then
		return Utility.func.applyUnlockAll(opts)
	end
	return false
end

LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
	if child.Name ~= "Menew" and child.Name ~= "Menu" then
		return
	end
	task.spawn(function()
		for _ = 1, 25 do
			task.wait(0.15)
			Utility.func.clearUnlockCache()
			local ok, err = Utility.func.tryAutoUnlock()
			if ok then
				Utility.func.notifyUnlock("Locker unlocked — items should appear in your locker.", 4)
				return
			end
			if err and _ == 25 then
				Utility.func.notifyUnlock(err, 5)
			end
		end
	end)
end)

if LocalPlayer.PlayerGui:FindFirstChild("Menew") or LocalPlayer.PlayerGui:FindFirstChild("Menu") then
	task.defer(function()
		if Utility.func.tryAutoUnlock() then
			Utility.func.notifyUnlock("Locker unlocked — items should appear in your locker.", 4)
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		Utility.HoldingRMB = true
		Utility.func.tryAimbotLock()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		Utility.HoldingRMB = false
		Utility.Aimbot = nil
	end
end)

Utility.func.updateFovCircle = function()
	if not fovCircle then
		return
	end
	local combat = getgenv().hvh.Combat
	fovCircle.Position = Utility.func.getMousePosition()
	fovCircle.Radius = combat.FOVRadius
	fovCircle.Filled = combat.FOVFilled
	fovCircle.Color = combat.FOVColor
	fovCircle.Visible = combat.ShowFOV
end

Utility.func.updateTargetIndicator = LPH_NO_VIRTUALIZE(function()
	if not Utility.draw.c or not Utility.draw.t then
		return
	end

	local combat = getgenv().hvh.Combat
	local target = Utility.func.getTargetPlayer()
	local point = target and Utility.func.getAimPoint(target)
	if not point then
		Utility.draw.c.Visible = false
		Utility.draw.t.Visible = false
		return
	end

	local screenPos, onScreen = Utility.func.getCamera():WorldToViewportPoint(point)
	if not onScreen then
		Utility.draw.c.Visible = false
		Utility.draw.t.Visible = false
		return
	end

	local mousePos = Utility.func.getMousePosition()
	local targetScreen = Vector2.new(screenPos.X, screenPos.Y)

	if combat.ShowTargetCircle then
		Utility.draw.c.Radius = combat.TargetCircleRadius
		Utility.draw.c.Color = combat.TargetCircleColor
		Utility.draw.c.Position = targetScreen
		Utility.draw.c.Visible = true
	else
		Utility.draw.c.Visible = false
	end

	if combat.ShowTracer then
		Utility.draw.t.Color = combat.TracerColor
		Utility.draw.t.From = mousePos
		Utility.draw.t.To = targetScreen
		Utility.draw.t.Visible = true
	else
		Utility.draw.t.Visible = false
	end
end)

local SkeletonConnections = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" },
}

local SkeletonConnectionsR6 = {
	{ "Head", "Torso" },
	{ "Torso", "Left Arm" },
	{ "Torso", "Right Arm" },
	{ "Torso", "Left Leg" },
	{ "Torso", "Right Leg" },
}

Utility.func.getEspRoot = function(character)
	return character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("Hitbox")
		or character:FindFirstChild("HeadHB")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("Head")
end

Utility.func.getPlayerHealth = function(player, character)
	local nrpbs = player:FindFirstChild("NRPBS")
	if nrpbs then
		local health = nrpbs:FindFirstChild("Health")
		if health then
			local maxHealth = nrpbs:FindFirstChild("MaxHealth")
			local max = maxHealth and maxHealth.Value or 100
			if max <= 0 then
				max = 100
			end
			return health.Value, max
		end
	end
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if hum then
		return hum.Health, hum.MaxHealth
	end
	return 0, 100
end

Utility.func.getPlayerWeapon = function(player, character)
	if character then
		local tool = character:FindFirstChildWhichIsA("Tool")
		if tool then
			return tool.Name
		end
		for _, child in character:GetChildren() do
			if child:IsA("Tool") or (child:IsA("Model") and child:FindFirstChild("Handle")) then
				return child.Name
			end
		end
	end
	local nrpbs = player:FindFirstChild("NRPBS")
	if nrpbs then
		for _, child in nrpbs:GetChildren() do
			if child.Name:lower():find("weapon") and (child:IsA("StringValue") or child:IsA("ObjectValue")) then
				local value = child.Value
				if typeof(value) == "Instance" then
					return value.Name
				elseif value ~= nil then
					return tostring(value)
				end
			end
		end
	end
	return "none"
end

Utility.func.isEspTarget = function(player)
	if not Utility.func.isEnemy(player) then
		return false
	end
	if not player.Character or not Utility.func.getEspRoot(player.Character) then
		return false
	end
	local health = select(1, Utility.func.getPlayerHealth(player, player.Character))
	return health > 0
end

local cache = {}
local EspTheme = {
	BoxOutlineColor = Color3.new(0, 0, 0),
	BoxColor = Color3.new(1, 1, 1),
	HealthOutlineColor = Color3.new(0, 0, 0),
	HealthHighColor = Color3.new(0, 1, 0),
}

Utility.func.create = function(class, properties)
	if not Drawing then
		return nil
	end
	local ok, drawing = pcall(Drawing.new, class)
	if not ok or not drawing then
		return nil
	end
	for property, value in pairs(properties) do
		drawing[property] = value
	end
	return drawing
end

Utility.func.createEsp = LPH_NO_VIRTUALIZE(function(player)
	if cache[player] then
		return
	end
	local boxOutline = Utility.func.create("Square", { Color = EspTheme.BoxOutlineColor, Thickness = 3, Filled = false })
	if not boxOutline then
		return
	end
	cache[player] = {
		boxOutline = boxOutline,
		box = Utility.func.create("Square", { Color = EspTheme.BoxColor, Thickness = 1, Filled = false }),
		healthOutline = Utility.func.create("Square", { Thickness = 1, Color = EspTheme.HealthOutlineColor, Filled = true }),
		health = Utility.func.create("Square", { Thickness = 1, Color = EspTheme.HealthHighColor, Filled = true }),
		healthText = Utility.func.create("Text", { Color = Color3.new(0, 1, 0), Size = 12, Center = true, Font = 3 }),
		nameText = Utility.func.create("Text", { Color = Color3.new(1, 1, 1), Size = 12, Center = true, Font = 3 }),
		distanceText = Utility.func.create("Text", { Color = Color3.new(1, 1, 1), Size = 12, Center = true, Font = 3 }),
		weaponText = Utility.func.create("Text", { Color = Color3.new(1, 1, 1), Size = 12, Center = true, Font = 3 }),
		skeletonLines = {},
	}

	for _ = 1, #SkeletonConnections do
		table.insert(
			cache[player].skeletonLines,
			Utility.func.create("Line", { Color = Color3.new(1, 1, 1), Thickness = 1, Visible = false })
		)
	end
end)

Utility.func.removeEsp = function(player)
	local esp = cache[player]
	if not esp then
		return
	end
	for key, drawing in pairs(esp) do
		if key == "skeletonLines" then
			for _, line in ipairs(drawing) do
				line:Remove()
			end
		else
			drawing:Remove()
		end
	end
	cache[player] = nil
end

Utility.func.hideEsp = function(esp)
	for key, drawing in pairs(esp) do
		if key == "skeletonLines" then
			for _, line in ipairs(drawing) do
				line.Visible = false
			end
		else
			drawing.Visible = false
		end
	end
end

Utility.func.updateEsp = LPH_NO_VIRTUALIZE(function()
	if not getgenv().hvh.Esp.Enabled then
		for _, esp in pairs(cache) do
			Utility.func.hideEsp(esp)
		end
		return
	end

	local cam = Utility.func.getCamera()

	for player, esp in pairs(cache) do
		if not Utility.func.isEspTarget(player) then
			Utility.func.hideEsp(esp)
			continue
		end

		local character = player.Character
		local rootPart = Utility.func.getEspRoot(character)
		if not rootPart then
			Utility.func.hideEsp(esp)
			continue
		end

		local hrp2D, onScreen = cam:WorldToViewportPoint(rootPart.Position)
		if not onScreen then
			Utility.func.hideEsp(esp)
			continue
		end

		local top = cam:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 2.5, 0))
		local bottom = cam:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 2.5, 0))
		local charHeight = math.abs(bottom.Y - top.Y)
		local charWidth = charHeight * 0.55
		local boxSize = Vector2.new(math.floor(charWidth), math.floor(charHeight))
		local boxPosition = Vector2.new(
			math.floor(hrp2D.X - charWidth / 2),
			math.floor(hrp2D.Y - charHeight / 2)
		)

		local showBox = getgenv().hvh.Esp.ShowBox
		esp.boxOutline.Visible = showBox
		esp.box.Visible = showBox
		if showBox then
			esp.boxOutline.Size = boxSize
			esp.boxOutline.Position = boxPosition
			esp.box.Size = boxSize
			esp.box.Position = boxPosition
		end

		if getgenv().hvh.Esp.ShowHealth then
			local health, maxHealth = Utility.func.getPlayerHealth(player, character)
			local healthPct = math.clamp(health / maxHealth, 0, 1)
			local healthH = boxSize.Y * healthPct
			esp.healthOutline.Visible = true
			esp.health.Visible = true
			esp.healthText.Visible = true
			esp.healthOutline.Size = Vector2.new(4, boxSize.Y)
			esp.healthOutline.Position = Vector2.new(boxPosition.X - 4, boxPosition.Y)
			esp.health.Size = Vector2.new(2, healthH)
			esp.health.Position = Vector2.new(boxPosition.X - 3, boxPosition.Y + boxSize.Y - healthH)
			esp.healthText.Position = Vector2.new(boxPosition.X - 30, boxPosition.Y - 5)
			esp.healthText.Text = tostring(math.floor(health))
			esp.healthText.Outline = true
		else
			esp.healthOutline.Visible = false
			esp.health.Visible = false
			esp.healthText.Visible = false
		end

		if getgenv().hvh.Esp.ShowName then
			esp.nameText.Visible = true
			esp.nameText.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y - 15)
			esp.nameText.Text = player.DisplayName
			esp.nameText.Outline = true
		else
			esp.nameText.Visible = false
		end

		if getgenv().hvh.Esp.ShowDistance and LocalRootPart then
			esp.distanceText.Visible = true
			esp.distanceText.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y + boxSize.Y + 1)
			esp.distanceText.Text = "[ " .. math.floor((LocalRootPart.Position - rootPart.Position).Magnitude) .. " M ]"
			esp.distanceText.Outline = true
		else
			esp.distanceText.Visible = false
		end

		if getgenv().hvh.Esp.ShowWeapon then
			esp.weaponText.Visible = true
			esp.weaponText.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y + boxSize.Y + 10)
			esp.weaponText.Text = Utility.func.getPlayerWeapon(player, character)
			esp.weaponText.Outline = true
		else
			esp.weaponText.Visible = false
		end

		if getgenv().hvh.Esp.ShowSkeleton then
			local connections = character:FindFirstChild("UpperTorso") and SkeletonConnections or SkeletonConnectionsR6
			for index, pair in ipairs(connections) do
				local line = esp.skeletonLines[index]
				local partA = character:FindFirstChild(pair[1])
				local partB = character:FindFirstChild(pair[2])
				if line and partA and partB then
					local a, aOn = cam:WorldToViewportPoint(partA.Position)
					local b, bOn = cam:WorldToViewportPoint(partB.Position)
					if aOn and bOn then
						line.From = Vector2.new(a.X, a.Y)
						line.To = Vector2.new(b.X, b.Y)
						line.Visible = true
					else
						line.Visible = false
					end
				elseif line then
					line.Visible = false
				end
			end
			for index = #connections + 1, #esp.skeletonLines do
				esp.skeletonLines[index].Visible = false
			end
		else
			for _, line in ipairs(esp.skeletonLines) do
				line.Visible = false
			end
		end
	end
end)

Utility.func.hideAllEsp = function()
	for _, esp in pairs(cache) do
		Utility.func.hideEsp(esp)
	end
end

Utility.func.ensureEspPlayers = function()
	if not Drawing then
		return
	end
	Utility.espReady = true
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			Utility.func.createEsp(player)
		end
	end
end

if Drawing then
	Utility.func.ensureEspPlayers()
end

Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer then
		Utility.func.createEsp(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	Utility.func.removeEsp(player)
end)

r_s.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
	if Utility.HoldingRMB then
		Utility.func.tryAimbotLock()
	end
	Utility.func.AimBotFormula()
	Utility.func.applyGunMods()
	Utility.func.runMelee()
end))

r_s.RenderStepped:Connect(function()
	if getgenv().hvh.Esp.Enabled then
		Utility.func.updateEsp()
	end
end)
end)

local function bindToggle(toggle, id, label)
	toggle:AddKeyPicker(id, {
		Default = "None",
		Text = label,
		Mode = "Toggle",
		SyncToggleState = true,
		NoUI = true,
	})
end

local function combatToggle(box, id, label, tip, field)
	local t = box:AddToggle(id, {
		Text = label,
		Default = false,
		Tooltip = tip,
		Callback = function(v)
			getgenv().hvh.Combat[field] = v
		end,
	})
	bindToggle(t, id .. "Key", label .. " keybind")
end

local function gunToggle(box, id, label, tip, field)
	local t = box:AddToggle(id, {
		Text = label,
		Default = false,
		Tooltip = tip,
		Callback = function(v)
			getgenv().hvh.Guns[field] = v
		end,
	})
	bindToggle(t, id .. "Key", label .. " keybind")
end

local function espToggle(box, id, label, tip, field)
	local t = box:AddToggle(id, {
		Text = label,
		Default = false,
		Tooltip = tip,
		Callback = function(v)
			getgenv().hvh.Esp[field] = v
			if field == "Enabled" and Utility and Utility.func then
				if v then
					Utility.func.ensureEspPlayers()
				else
					Utility.func.hideAllEsp()
				end
			elseif field ~= "Enabled" and v and not getgenv().hvh.Esp.Enabled then
				getgenv().hvh.Esp.Enabled = true
				Utility.func.ensureEspPlayers()
			end
		end,
	})
	bindToggle(t, id .. "Key", label .. " keybind")
end

local function playerFeature(box, id, label, tip, field, sliderDefault, sliderMin, sliderMax)
	local toggle = box:AddToggle(id .. "Toggle", {
		Text = label,
		Default = false,
		Tooltip = tip,
		Callback = function(v)
			getgenv().hvh.Player[field].Enabled = v
		end,
	})
	bindToggle(toggle, id .. "Key", label .. " keybind")
	box:AddSlider(id .. "Slider", {
		Text = label .. " amount",
		Default = sliderDefault,
		Min = sliderMin,
		Max = sliderMax,
		Rounding = 1,
		Tooltip = "Value for " .. string.lower(label) .. " (not wired yet).",
		Callback = function(v)
			getgenv().hvh.Player[field].Value = v
		end,
	})
end

local AimbotBox = Tabs.Main:AddLeftGroupbox("Aimbot")
local aimbotToggle = AimbotBox:AddToggle("Aimbot", {
	Text = "Aimbot",
	Default = false,
	Tooltip = "Smooth camera aim while holding right mouse button. Team check is always on.",
	Callback = function(v)
		getgenv().hvh.Combat.Aimbot = v
		if not v then
			Utility.Aimbot = nil
			Utility.HoldingRMB = false
		end
	end,
})
bindToggle(aimbotToggle, "AimbotKey", "Aimbot keybind")

AimbotBox:AddLabel("Hold RMB — locks closest enemy in FOV")

AimbotBox:AddDropdown("HitPart", {
	Values = { "Head", "Hitbox", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
	Default = 1,
	Text = "Hit part",
	Tooltip = "Body part the aimbot tracks.",
	Callback = function(v)
		getgenv().hvh.Combat.HitPart = v
	end,
})

AimbotBox:AddSlider("Prediction", {
	Text = "Prediction",
	Default = 12,
	Min = 0,
	Max = 50,
	Rounding = 1,
	Tooltip = "Lead amount for moving targets.",
	Callback = function(v)
		getgenv().hvh.Combat.Prediction = v / 100
	end,
})

AimbotBox:AddSlider("AimbotSmooth", {
	Text = "Smoothness",
	Default = 35,
	Min = 1,
	Max = 100,
	Rounding = 1,
	Tooltip = "Lower = snappier, higher = smoother.",
	Callback = function(v)
		getgenv().hvh.Combat.Smoothness = v / 100
	end,
})

AimbotBox:AddLabel("FOV")
combatToggle(AimbotBox, "ShowFOV", "Show FOV", "Draw aim FOV circle on mouse.", "ShowFOV")
combatToggle(AimbotBox, "FilledFOV", "Filled FOV", "Fill the FOV circle.", "FOVFilled")

AimbotBox:AddSlider("FOVRadius", {
	Text = "FOV Size",
	Default = 500,
	Min = 50,
	Max = 1000,
	Rounding = 1,
	Tooltip = "Target search radius from mouse (pixels).",
	Callback = function(v)
		getgenv().hvh.Combat.FOVRadius = v
	end,
})

AimbotBox:AddLabel("Target Indicator")
combatToggle(AimbotBox, "ShowTracer", "Show Tracer", "Line from mouse to target.", "ShowTracer")
combatToggle(AimbotBox, "ShowTargetCircle", "Show Circle", "Circle on aim point.", "ShowTargetCircle")

AimbotBox:AddSlider("TargetCircleRadius", {
	Text = "Circle Radius",
	Default = 50,
	Min = 0,
	Max = 50,
	Rounding = 1,
	Tooltip = "On-screen target circle size.",
	Callback = function(v)
		getgenv().hvh.Combat.TargetCircleRadius = v
	end,
})

local Guns = Tabs.Main:AddRightGroupbox("Gun Mods")
gunToggle(Guns, "RapidFire", "Rapid Fire", "Much faster shooting.", "RapidFire")
gunToggle(Guns, "InfiniteAmmo", "Infinite Ammo", "Never run out of ammo.", "InfiniteAmmo")
gunToggle(Guns, "NoRecoil", "No Recoil", "Remove weapon kick and spread.", "NoRecoil")
gunToggle(Guns, "InstantReload", "Instant Reload", "Skip reload time.", "InstantReload")

Guns:AddSlider("FireRate", {
	Text = "Fire Rate",
	Default = 1,
	Min = 1,
	Max = 20,
	Rounding = 1,
	Tooltip = "Fire rate multiplier.",
	Callback = function(v)
		getgenv().hvh.Guns.FireRate = v
	end,
})

local function meleeToggle(box, id, label, tip, field)
	local t = box:AddToggle(id, {
		Text = label,
		Default = false,
		Tooltip = tip,
		Callback = function(v)
			getgenv().hvh.Melee[field] = v
		end,
	})
	bindToggle(t, id .. "Key", label .. " keybind")
end

local Melee = Tabs.Main:AddRightGroupbox("Melee")

Melee:AddLabel("Rage")
meleeToggle(Melee, "MeleeRage", "Rage", "While holding melee, teleport behind enemies and auto swing. Team check is always on.", "Rage")
meleeToggle(Melee, "AutoSwing", "Auto Swing", "Automatically swings melee at nearby enemies.", "AutoSwing")

Melee:AddSlider("SwingSpeed", {
	Text = "Swing Speed",
	Default = 1,
	Min = 1,
	Max = 10,
	Rounding = 1,
	Tooltip = "Melee swing speed multiplier.",
	Callback = function(v)
		getgenv().hvh.Melee.SwingSpeed = v
	end,
})

Melee:AddLabel("Kill Aura")
local killAuraToggle = Melee:AddToggle("KillAura", {
	Text = "Kill Aura",
	Default = false,
	Tooltip = "Auto melee nearby enemies within range. Team check is always on.",
	Callback = function(v)
		getgenv().hvh.Melee.KillAura = v
	end,
})
bindToggle(killAuraToggle, "KillAuraKey", "Kill aura keybind")

Melee:AddSlider("MeleeRange", {
	Text = "Melee Range",
	Default = 15,
	Min = 5,
	Max = 50,
	Rounding = 1,
	Tooltip = "Kill aura reach.",
	Callback = function(v)
		getgenv().hvh.Melee.Range = v
	end,
})

local EspBox = Tabs.Visual:AddLeftGroupbox("ESP")
espToggle(EspBox, "EspMaster", "Show ESP", "Master ESP switch. Team check is always on.", "Enabled")
espToggle(EspBox, "EspBox", "Show Box", "Box around players.", "ShowBox")
espToggle(EspBox, "EspName", "Show Name", "Player names.", "ShowName")
espToggle(EspBox, "EspHealth", "Show Health", "Health bar.", "ShowHealth")
espToggle(EspBox, "EspDistance", "Show Distance", "Distance in studs.", "ShowDistance")
espToggle(EspBox, "EspWeapon", "Show Weapon", "Equipped gun name.", "ShowWeapon")
espToggle(EspBox, "EspSkeleton", "Show Skeleton", "Bone lines.", "ShowSkeleton")

local PlayerBox = Tabs.Players:AddLeftGroupbox("Movement")
playerFeature(PlayerBox, "Speed", "Speed", "Walk speed.", "Speed", 16, 16, 500)
playerFeature(PlayerBox, "Jump", "Jump Power", "Jump height.", "Jump", 50, 50, 500)
playerFeature(PlayerBox, "Flight", "Flight", "Fly with WASD.", "Flight", 5, 1, 100)

local bhopToggle = PlayerBox:AddToggle("BhopToggle", {
	Text = "Bhop",
	Default = false,
	Tooltip = "Auto jump while holding space.",
	Callback = function(v)
		getgenv().hvh.Player.Bhop.Enabled = v
	end,
})
bindToggle(bhopToggle, "BhopKey", "Bhop keybind")

local function runUnlock(options)
	local ok, err = Utility.func.applyUnlockAll(options)
	if ok then
		Utility.func.notifyUnlock("Locker unlocked — items should appear in your locker.", 4)
	else
		Utility.func.notifyUnlock(err or "Unlock failed.", 5)
	end
	return ok
end

local MiscBox = Tabs.Misc:AddLeftGroupbox("Misc")
local function miscToggle(id, label, tip, field)
	local t = MiscBox:AddToggle(id, {
		Text = label,
		Default = false,
		Tooltip = tip,
		Callback = function(v)
			getgenv().hvh.Misc[field] = v
		end,
	})
	bindToggle(t, id .. "Key", label .. " keybind")
end

local unlockAllToggle = MiscBox:AddToggle("UnlockAll", {
	Text = "Unlock All",
	Default = false,
	Tooltip = "Unlocks all skins, melees, emotes, and kill effects in your locker. Team check N/A.",
	Callback = function(v)
		getgenv().hvh.Misc.UnlockAll = v
		if v then
			runUnlock({ all = true })
		end
	end,
})
bindToggle(unlockAllToggle, "UnlockAllKey", "Unlock all keybind")
miscToggle("AntiVoteKick", "Anti Vote Kick", "Blocks vote kick attempts.", "AntiVoteKick")
miscToggle("ThirdPerson", "Third Person", "Third person camera.", "ThirdPerson")

local SkinsBox = Tabs.Misc:AddRightGroupbox("Skins")
local skinUnlockOptions = {
	UnlockSkins = { Skins = true, Weapons = true },
	UnlockEmotes = { Emotes = true },
	UnlockKillEffects = { KillEffects = true },
}
local function skinToggle(id, label, tip, field)
	local t = SkinsBox:AddToggle(id, {
		Text = label,
		Default = false,
		Tooltip = tip,
		Callback = function(v)
			getgenv().hvh.Skins[field] = v
			if v then
				runUnlock(skinUnlockOptions[field] or { all = true })
			end
		end,
	})
	bindToggle(t, id .. "Key", label .. " keybind")
end

skinToggle("UnlockSkins", "Unlock Skins", "All weapon skins and guns.", "UnlockSkins")
skinToggle("UnlockKillEffects", "Unlock Kill Effects", "All kill effects.", "UnlockKillEffects")
skinToggle("UnlockEmotes", "Unlock Emotes", "All emotes.", "UnlockEmotes")

Library:SetWatermarkVisibility(true)

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60
local localPlayerName = game.Players.LocalPlayer.DisplayName

local WatermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
	FrameCounter += 1
	if tick() - FrameTimer >= 1 then
		FPS = FrameCounter
		FrameTimer = tick()
		FrameCounter = 0
	end
	Library:SetWatermark(
		("Ace | Arsenal | Player: %s | %s fps | %s ms"):format(
			localPlayerName,
			math.floor(FPS),
			math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
		)
	)
end)

Library.KeybindFrame.Visible = false

Library:OnUnload(function()
	WatermarkConnection:Disconnect()
	print("Ace Arsenal unloaded!")
	Library.Unloaded = true
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddButton({
	Text = "Unload",
	Tooltip = "Fully unloads the script.",
	Func = function()
		Library:Unload()
	end,
})
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
	Tooltip = "Show or hide this menu (RightShift).",
})
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("AceArsenal")
SaveManager:SetFolder("AceArsenal/settings")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

Library:Notify("Ace Arsenal loaded — Aimbot, gun mods, and melee ready. RightShift for menu.", 5)
