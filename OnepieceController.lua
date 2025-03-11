local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)


local OnepieceService = nil
local GeneralFunctions = require(game.ReplicatedStorage.general_resources.General)
local CameraShaker = require(game.ReplicatedStorage.general_resources.CameraShaker)
local TweenService = game:GetService("TweenService")

local debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local DataService = nil
local data = nil

local OnepieceController = Knit.CreateController { Name = "OnepieceController" }

-- modify externally
OnepieceController.level = 0



local AsuraAnim = nil
function OnepieceController:KnitInit()
	OnepieceService =  Knit.GetService("OnepieceService")
	DataService =  Knit.GetService("DataService")
	DataService.getOPData():andThen(function(d)
		data = d
	end)

	
	OnepieceService.changeLevel:Connect(function(level)
		self.level = level
	end)
	
	OnepieceService.damage:Connect(function(enemy, dmg)
		GeneralFunctions.damage(dmg, player, enemy)
	end)
	OnepieceService.endAsura:Connect(function(enemy)

		if(AsuraAnim) then
			AsuraAnim:Stop()
		end

		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://18325482355"
		local animTrack = player.Character.Humanoid.Animator:LoadAnimation(anim)
		animTrack.Priority = Enum.AnimationPriority.Action
		animTrack.Looped = false
		animTrack:Play()
		debris:AddItem(anim, 1)
		
		wait(1)
		OnepieceService:CleanAsura()

	end)
	OnepieceService.hitframe:Connect(function(char, char2)
		local correction = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura.ColorCorrection:Clone()
		correction.Parent = game:GetService("Lighting")
		debris:AddItem(correction, 0.3)
		
		local highlight = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura.Highlight:Clone()
		local highlight2 = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura.Highlight:Clone()
		highlight.Parent = char
		highlight2.Parent = char2
		debris:AddItem(highlight, 0.3)
		debris:AddItem(highlight2, 0.3)

		
	end)
	OnepieceService.applyFx:Connect(function()
		local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
			local camera = game.Workspace.Camera
			camera.CFrame = camera.CFrame * shakeCFrame
		end)
		camShake:Start()
		camShake:Shake(CameraShaker.Presets.asura)
	end)


end





function tweenCountdown(vers, timing)
	local GUI = player.PlayerGui.Move_GUI
	local tweenInfo = TweenInfo.new(timing,Enum.EasingStyle.Linear)
	local goal = {TextTransparency  = 0.7}
	local Tween
	if(vers == 1) then
		GUI.MoveSetHolder.S1.S1.TextLabel2.TextTransparency = 0
		Tween = TweenService:Create(GUI.MoveSetHolder.S1.S1.TextLabel2, tweenInfo, goal)
	
	elseif(vers == 2) then
		GUI.MoveSetHolder.S2.S2.TextLabel2.TextTransparency = 0
		Tween = TweenService:Create(GUI.MoveSetHolder.S2.S2.TextLabel2, tweenInfo, goal)
	
	elseif(vers == 3) then
		GUI.MoveSetHolder.S3.S3.TextLabel2.TextTransparency = 0
		Tween = TweenService:Create(GUI.MoveSetHolder.S3.S3.TextLabel2, tweenInfo, goal)
	elseif(vers == 4) then
		GUI.MoveSetHolder.S4.S4.TextLabel2.TextTransparency = 0
		Tween = TweenService:Create(GUI.MoveSetHolder.S4.S4.TextLabel2, tweenInfo, goal)
	else
		GUI.MoveSetHolder.S5.S5.TextLabel2.TextTransparency = 0
		Tween = TweenService:Create(GUI.MoveSetHolder.S5.S5.TextLabel2, tweenInfo, goal)
		
	end

	Tween:Play()
end

local cache
local connection
function LookAtMouse(t, lookUp)
	if(cache) then
		task.cancel(cache)
		connection:Disconnect()
	end
	local root = player.Character.HumanoidRootPart
	local Mouse = player:GetMouse()
	connection = RunService.RenderStepped:Connect(function()
		if(player.Character:GetAttribute("SkillCast") == true) then return end
		local RootPos, MousePos = root.Position, Mouse.Hit.Position
		root.CFrame = CFrame.new(RootPos, Vector3.new(MousePos.X, RootPos.Y, MousePos.Z))
		if(lookUp) then
			root.CFrame = CFrame.new(RootPos, Vector3.new(MousePos.X, MousePos.Y, MousePos.Z))

		end
	end)
	cache = task.delay(t, function()
		connection:Disconnect()
		cache = nil
	end)
end




local pistol = false
function OnepieceController:FirePistol()
	if(self.level < 1) then return end
	local character = player.Character
	if(pistol) then return end
	pistol = true
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://18310883833"
	local animTrack = player.Character.Humanoid.Animator:LoadAnimation(anim)
	animTrack.Priority = Enum.AnimationPriority.Action
	animTrack.Looped = false
	animTrack:Play()
	debris:AddItem(anim, 1)
	LookAtMouse(1)
	

	animTrack:GetMarkerReachedSignal("start"):Connect(function(paramString)
		OnepieceService:HandlePistol(data, character.HumanoidRootPart.CFrame.LookVector)
		
	end)

	animTrack:GetMarkerReachedSignal("end"):Connect(function(paramString)
		OnepieceService:EndPistol(data)

	end)
	
	
	
	
	tweenCountdown(1, data.pistol.cooldown+1)
	GeneralFunctions.countdown(data.pistol.cooldown+1.4,1,true, function(count_up)
		if(count_up == -1) then
			player.PlayerGui.Move_GUI.MoveSetHolder.S1.S1.TextLabel2.TextTransparency = 1

			pistol = false
			return
		end

	end)

end

local mirror = false
function OnepieceController:FireMirror()
	if(self.level < 2) then return end
	local character = player.Character
	if(mirror) then return end
	mirror = true
	
	local hitbox = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.mirror.hitbox:Clone()
	hitbox.Parent = character
	hitbox.CFrame = character.HumanoidRootPart.CFrame
	
	local enemies = {}
	for _,x in pairs(game.Workspace:GetPartsInPart(hitbox)) do
		if(x.Name == "HumanoidRootPart") then
			if(x.Parent == character) then continue end
			table.insert(enemies, x.Parent)
		end
	end
	hitbox:Destroy()
	
	OnepieceService:HandleMirror(data, enemies)



	tweenCountdown(2, data.mirror.cooldown+1)
	GeneralFunctions.countdown(data.mirror.cooldown+1.4,1,true, function(count_up)
		if(count_up == -1) then
			player.PlayerGui.Move_GUI.MoveSetHolder.S2.S2.TextLabel2.TextTransparency = 1

			mirror = false
			return
		end

	end)

end

local quake = false
function OnepieceController:FireQuake()
	if(self.level < 3) then return end
	local character = player.Character
	if(quake) then return end
	quake = true
	
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://18313979213"
	local animTrack = player.Character.Humanoid.Animator:LoadAnimation(anim)
	animTrack.Priority = Enum.AnimationPriority.Action
	animTrack.Looped = false
	animTrack:Play()
	debris:AddItem(anim, 1)


	animTrack:GetMarkerReachedSignal("fire"):Connect(function(paramString)
		local hitbox = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.quake.hitbox:Clone()
		hitbox.Parent = character
		hitbox.Position = character.HumanoidRootPart.Position

		local enemies = {}
		for _,x in pairs(game.Workspace:GetPartsInPart(hitbox)) do
			if(x.Name == "HumanoidRootPart") then
				if(x.Parent == character) then continue end
				table.insert(enemies, x.Parent)
				GeneralFunctions.damage(data.quake.damage, player, x.Parent)
			end
		end
		hitbox:Destroy()

		OnepieceService:HandleQuake(data, player.Character.HumanoidRootPart.Position, enemies)

	end)
	
	





	tweenCountdown(3, data.quake.cooldown+1)
	GeneralFunctions.countdown(data.quake.cooldown+1.4,1,true, function(count_up)
		if(count_up == -1) then
			player.PlayerGui.Move_GUI.MoveSetHolder.S3.S3.TextLabel2.TextTransparency = 1

			quake = false
			return
		end

	end)

end

local asura = false
function OnepieceController:FireAsura()
	if(self.level < 4) then return end
	local character = player.Character
	if(asura) then return end
	asura = true

	LookAtMouse(1, true)
	wait()
	local enemies =  GeneralFunctions.createHitbox(20, 24.3, data.asura.distance, character.HumanoidRootPart.CFrame +character.HumanoidRootPart.CFrame.LookVector*data.asura.distance/2, character)

	if(#enemies == 0) then

		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://18324894242"
		local animTrack = player.Character.Humanoid.Animator:LoadAnimation(anim)
		animTrack.Priority = Enum.AnimationPriority.Action
		animTrack.Looped = false
		animTrack:Play()
		debris:AddItem(anim, 1)
		OnepieceService:HandleAsuraTeleport(data)
		animTrack:GetMarkerReachedSignal("start"):Connect(function(paramString)
			OnepieceService:doTeleport(data)
		end)

	else
		character:SetAttribute("SkillCast", true)
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://18324894242"
		local animTrack = player.Character.Humanoid.Animator:LoadAnimation(anim)
		animTrack.Priority = Enum.AnimationPriority.Action
		animTrack.Looped = false
		animTrack:Play()
		debris:AddItem(anim, 1)


		OnepieceService:HandleAsura(data, enemies[1])
		wait(0.4)

		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://18324927240"
		AsuraAnim = player.Character.Humanoid.Animator:LoadAnimation(anim)
		AsuraAnim.Priority = Enum.AnimationPriority.Action
		AsuraAnim.Looped = true
		AsuraAnim:Play()
		debris:AddItem(anim, 1)

		wait(2)

		task.delay(data.asura.duration, function()
			AsuraAnim:Stop()

		end)
		
	end

	character:SetAttribute("SkillCast", false)

	tweenCountdown(4, data.asura.cooldown+1)
	GeneralFunctions.countdown(data.asura.cooldown+1.4,1,true, function(count_up)
		if(count_up == -1) then
			player.PlayerGui.Move_GUI.MoveSetHolder.S4.S4.TextLabel2.TextTransparency = 1

			asura = false
			return
		end

	end)

end

local snake = false
local animT = nil
local cache = nil
local startedMove = false
function OnepieceController:FireSnake()
	if(self.level < 5) then return end
	local character = player.Character
	if(snake) then return end
	startedMove = true
	snake = true
	LookAtMouse(0.1, true)
	wait()
	
	local enemies =  GeneralFunctions.createHitbox(21, 21, data.snake.distance, character.HumanoidRootPart.CFrame +character.HumanoidRootPart.CFrame.LookVector*data.snake.distance/2, character)
	
	if(#enemies == 0) then
		showEnemyPanel()
		startedMove = false
		snake = false
		return

		--tweenCountdown(5, self.data.snake.cooldown+1)
		--GeneralFunctions.countdown(self.data.snake.cooldown+1.4,1,true, function(count_up)
		--	if(count_up == -1) then
		--		player.PlayerGui.Move_GUI.MoveSetHolder.S5.S5.TextLabel2.TextTransparency = 1
		--		snake = false
		--		return
		--	end

		--end)
	end
	showGUI()
	
	

	OnepieceService:GenSnake(enemies[1], character.RightUpperArm.RightElbowRigAttachment, data)
	OnepieceService:GenSnake(enemies[1], character.LeftUpperArm.LeftElbowRigAttachment,data)

	
	OnepieceService.stopSnake2:Connect(function()
		self:StopSnake()

	end)

	
	
	cache = task.delay(data.snake.duration, function()
		cache = nil
		self:StopSnake()
	end)
	
	character:SetAttribute("isStunned", true)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://18335081086"
	animT = player.Character.Humanoid.Animator:LoadAnimation(anim)
	animT.Priority = Enum.AnimationPriority.Action
	animT.Looped = true
	animT:Play()
	debris:AddItem(anim, 1)
	
	OnepieceService:HandleSnake(data)





end

function OnepieceController:StopSnake()
	if(self.level < 5) then return end
	local character = player.Character
	if(not startedMove) then return end
	startedMove = false
	if(cache) then
		task.cancel(cache)
	end
	OnepieceService.stopSnake:Fire()
	OnepieceService:EndSnake(data)
	if(animT) then
		animT:Stop()

	end
	

	
	wait(0.3)
	endGUI()
	character:SetAttribute("isStunned", false)

	tweenCountdown(5, data.snake.cooldown+1)
	GeneralFunctions.countdown(data.snake.cooldown+1.4,1,true, function(count_up)
		if(count_up == -1) then
			player.PlayerGui.Move_GUI.MoveSetHolder.S5.S5.TextLabel2.TextTransparency = 1
			snake = false
			return
		end

	end)
end

local db = false
function showEnemyPanel()
	if(db) then return end

	local panel = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.snake.panel:Clone()
	panel.Parent = player.PlayerGui

	
	panel.Frame.Size = UDim2.new(0, 0, 0, 0)
	panel.Frame.Position = UDim2.new(0.506, 0, 0.759, 0)
	local goal = {Size = UDim2.new(0.15, 0, 0.08, 0), Position = UDim2.new(0.43, 0, 0.738, 0)}
	local Info = TweenInfo.new(0.2)
	local Tween = TweenService:Create(panel.Frame, Info, goal)
	Tween:Play()
	debris:AddItem(panel, 1)
	db = true
	task.delay(1, function()
		db = false
	end)
end

function showGUI()
	local panel = game:GetService("ReplicatedStorage").Moveset_Resources.panel:Clone()
	panel.Parent = player.PlayerGui
	panel.Frame.Size = UDim2.new(0, 0, 0, 0)
	panel.Frame.Position = UDim2.new(0.506, 0, 0.759, 0)
	local goal = {Size = UDim2.new(0.115, 0, 0.08, 0), Position = UDim2.new(0.444, 0, 0.738, 0)}
	local Info = TweenInfo.new(0.2)
	local Tween = TweenService:Create(panel.Frame, Info, goal)
	Tween:Play()
end

function endGUI()
	if(player.PlayerGui:FindFirstChild("panel"))  then
		player.PlayerGui.panel:Destroy()
	end
end


return OnepieceController
