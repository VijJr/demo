--[[ 

NOTE: 

This library uses the Knit library for convenience, and there is a corresponding controller (local script)
This works specifically for r15 rigs, it was not build for r6
This code only looks at Asura and Snake man move in the roblox game

--]]


-- Global variables declared at the top for convenience including Knit required modules, Rock module for debris, 
-- debris service for managed cleanup, tweens, etc
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local GeneralFunctions = require(game.ReplicatedStorage.general_resources.General)
local RockModule = require(game.ReplicatedStorage.general_resources.RockModule)
local debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- These two vars hold data objects which are injected OnInit using Knit from an external service. Omitted for brevity
local serverData = nil
local dataService = nil


-- Creates events that are used in the file according to the Knit guidelines 
local OnepieceService = Knit.CreateService { Name = "OnepieceService", Client = {
	changeLevel = Knit.CreateSignal(),
	damage = Knit.CreateSignal(),
	endAsura = Knit.CreateSignal(),
	hitframe = Knit.CreateSignal(),
	applyFx = Knit.CreateSignal(),
	stopSnake = Knit.CreateSignal(),
	stopSnake2 = Knit.CreateSignal()
} }


-- Knockback function with tuned parameters that work best for this move
function doKb(char, lookvector, kbAmount, customMult)
	if not char or not char:FindFirstChild("HumanoidRootPart") then
	    return
	end
	
	local mass = 0
	for _, y in pairs(char:GetChildren()) do
		if(y:IsA("BasePart")) then
			mass += y:GetMass()
		end
	end


        local mult = customMult or 1
        local forceX = lookvector.x * kbAmount * mass
        local forceZ = lookvector.z * kbAmount * mass
        local impulseForce = Vector3.new(forceX, mass * mult, forceZ)

        char.HumanoidRootPart:ApplyImpulse(impulseForce)

end


-- Asura move server-side method as called in local controller. local generates hitbox and feeds the enemy as input along with data about 
-- the move like execution time, distance of hitbox, damage, etc
function OnepieceService.Client:HandleAsura(player, data, enemy)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Head") then
		return
	end
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local MovesetResources = ReplicatedStorage.Moveset_Resources.onepiece_resources.Asura
	
	
	local accessories = {
		MovesetResources["Three-Sword Style"].mouth:Clone(),
		MovesetResources["Three-Sword Style"].right:Clone(),
		MovesetResources["Three-Sword Style"].left:Clone()
	}
	for _, acc in ipairs(accessories) do
		Humanoid:AddAccessory(acc)
		task.delay(serverData.asura.duration, function()
			acc:Destroy()
		end)
	end
	
	local eye = MovesetResources.eye.eye:Clone()
	eye.Parent = character.Head
	task.delay(serverData.asura.duration, function()
		eye:Destroy()
	end)
	
	-- General functions is a service of my own methods I reference for convenience and reuse. This makes a sound and cleans automatically
	GeneralFunctions.makeSound("rbxassetid://858508159",player.Character )
	
	local pos = character.HumanoidRootPart.CFrame
	local players = game:GetService("Players"):GetPlayers()
	local rootPos = character.HumanoidRootPart.Position

	-- Apply fx is a method listening in the local controller. For nearby playersr within 300 make screenshake with custom library
	for _,x in pairs(players) do
		local xRoot = x.Character and x.Character:FindFirstChild("HumanoidRootPart")
		if xRoot and (xRoot.Position - rootPos).Magnitude < 300 then
		self.applyFx:Fire(x)
	end


	-- Add three lightning fx around the player for visuals calculated with 120 degree intervals around player and randomized distance away
	for i = 1,3 do
		local vec = (pos * CFrame.Angles(0,math.rad(120*i), 0)).LookVector
		local dist = math.random(10, 20)
		local lightning = MovesetResources["A - ELECTRICITY 01"]:Clone()
		lightning.Parent = character
		lightning.CFrame = pos +  vec * dist
		task.delay(1, function()
			lightning:Destroy()
		end)
		
	end

	local Info = TweenInfo.new(1)

	-- Add 7 squares that rise, looks like debris under pressure. Uses same idea as previous lightining fx
	for i = 1,7 do
		local dist = math.random(10, 20)
		local vec = (pos * CFrame.Angles(math.rad(math.random(360)), math.rad(math.random(360)), math.rad(math.random(360)))).LookVector
		createRisingPart(pos + vec * dist)
	end
	
	

	task.wait(1)
	-- Flies towards enemy
	StartFlight(player, serverData, enemy, serverData.asura.duration-1)
	
	
end

-- Flies towards enemy, this is an aux method for clean purposes. Duration is how long the flight lasts before target is reached
function StartFlight(player, data, enemy, duration)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	GeneralFunctions.makeSound("rbxassetid://137463716",player.Character )
	
	
	-- Generate hitbox and weld onto player since player is moving
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local MovesetResources = ReplicatedStorage.Moveset_Resources.onepiece_resources.Asura
	
	local hitbox = MovesetResources.hitbox2:Clone()
	hitbox.CFrame = character.HumanoidRootPart.CFrame + character.HumanoidRootPart.CFrame.LookVector * 4
	hitbox.Parent = character
	
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = character.HumanoidRootPart
	weld.Part1 = hitbox
	weld.Parent = hitbox
	
	task.delay(duration, function()
		hitbox:Destroy()
		weld:Destroy()
	end)
		
	-- Create beam and add one attachement to starting location, the other on the players root so it moves w/ player
	local beam = MovesetResources.Beam:Clone()
	beam.Parent = character
	beam.Start.CFrame = character.HumanoidRootPart.CFrame
	
	local att = beam.End.Attachment1
	local b = beam.End.beam2
	att.Parent, b.Parent = character.HumanoidRootPart, character.HumanoidRootPart
	
	task.delay(duration, function()
		beam:Destroy()
		att:Destroy()
		b:Destroy()
	end)
	
	-- Flashy fx added to the player 
	local expl = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura.Explosion.Hit:Clone()
	expl.Parent = character.HumanoidRootPart
	task.delay(duration, function()
		expl:Destroy()
	end)	
		
	-- Move the character towards the enemy 

	if not enemy or not enemy:FindFirstChild("RootRigAttachment") then
		return
	end
		
	local align = Instance.new("AlignPosition")
	align.Parent = character
	align.RigidityEnabled = true
	align.Attachment0 = character.HumanoidRootPart.RootRigAttachment
	align.Attachment1 = enemy.RootRigAttachment
	task.delay(duration, function()
		align:Destroy()
	end)	
		
	-- Once character reaches enemy, fire move 
	local players = game:GetService("Players")

	local connect
	connect = hitbox.Touched:Connect(function(hit)
		if(hit.Parent:FindFirstChild("HumanoidRootPart")) then
			local hitParent = hit.Parent
			local hitRoot = hitParent and hitParent:FindFirstChild("HumanoidRootPart")
			
			if hitParent == character or not hitRoot then return end
			
			OnepieceService.Client.hitframe:Fire(player, hitParent, character)
		
			local hitPlayer = players:GetPlayerFromCharacter(hitParent)
			if hitPlayer then
				OnepieceService.Client.hitframe:Fire(hitPlayer, hitParent, character)
			end

			GeneralFunctions.makeSound("rbxassetid://5989945551",player.Character )
			GeneralFunctions.makeSound("rbxassetid://7390331288",player.Character )
			align:Destroy()
			
			-- Creates a debris field with 16 radius, and 7 size, 1 second until despawn and don't fly around (false)
			GeneralFunctions.Create(16, hit.Position, 7, 1, false)
			
			-- Fx slash  
			local fx = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura.CUTS:Clone()
			fx.Parent = hit
			debris:AddItem(fx, 1)
			
			-- For every 0.1 seconds to a fixed amount of damage and fire sound so it feels like multiple slashes
			GeneralFunctions.countdown(1, 0.1, false, function()
				local hitHumanoid = hitParent:FindFirstChildOfClass("Humanoid")
				if not hitHumanoid then return end
			
				if (hitRoot.Position - character.HumanoidRootPart.Position).Magnitude > 100 then return end
			
				hitHumanoid:TakeDamage(serverData.asura.damage)
				OnepieceService.Client.damage:Fire(player, hitParent, serverData.asura.damage)
				GeneralFunctions.makeSound("rbxassetid://7118966167", hitParent)
			end)
			
			-- Clean extra stuff
			expl:Destroy()
			b:Destroy()
			att:Destroy()
			beam:Destroy()
			weld:Destroy()
			hitbox:Destroy()
			for i,v in pairs(player.Character.Humanoid:GetPlayingAnimationTracks()) do
				v:Stop()
			end

			-- Clean local elements, stop anim, and clean other cosmetics 
			OnepieceService.Client.endAsura:Fire(player, hit.Parent )
			connect:Disconnect()
		end

	end)

end

-- Cleans the swords and cosmetics from the asura move when called in controller from anim sequence track markers (in case debris is slow)
function OnepieceService.Client:CleanAsura(player)
	local accessories = {"mouth", "right", "left", "eye"}
	for _, accessory in ipairs(accessories) do
		local part = (accessory == "eye" and character.Head or character):FindFirstChild(accessory)
		if part then part:Destroy() end
	end
end

-- This is fired on local if there are no enemies in hitbox. Functions like a teleport move 
function OnepieceService.Client:HandleAsuraTeleport(player, data)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	-- Give the cosmetics
	local accessories = {"mouth", "right", "left", "eye"}
	for _, accessory in ipairs(accessories) do
		local part = (accessory == "eye" and character.Head or character):FindFirstChild(accessory)
		if part then
			local accClone = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura["Three-Sword Style"][accessory]:Clone()
			if accessory == "eye" then
				accClone.Parent = character.Head
			else
				character.Humanoid:AddAccessory(accClone)
			end
			task.delay(2, function()
				accClone:Destroy()
			end)	
		end
	end


	GeneralFunctions.makeSound("rbxassetid://858508159",player.Character )

	local pos = character.HumanoidRootPart.CFrame


	-- Provide the same fx from earlier
	for i = 1,3 do
		local vec = (pos * CFrame.Angles(0, math.rad(120 * i), 0)).LookVector
		local dist = math.random(10, 20)
		local lightning = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura["A - ELECTRICITY 01"]:Clone()
		lightning.Parent = character
		lightning.CFrame = pos + vec * dist
		task.delay(1, function() lightning:Destroy() end)
	end


	
	for i = 1,7 do
		local dist = math.random(10, 20)
		local vec = (pos * CFrame.Angles(math.rad(math.random(360)), math.rad(math.random(360)), math.rad(math.random(360)))).LookVector
		createRisingPart(pos + vec * dist)
	end

end

	
local function createRisingPart(position)
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.new(0, 255, 0)
	part.Anchored = true
	part.CanCollide = false
	part.Parent = character
	part.CFrame = position
	
	local tweenInfo = TweenInfo.new(1)
	local goal = {Position = part.Position + Vector3.new(0, 7, 0)}
	local tween = TweenService:Create(part, tweenInfo, goal)
	tween:Play()
	
	task.delay(1, function() part:Destroy() end)
end
	
-- Once the animation sequence for the plain teleport is over, actually teleport the character forward
function OnepieceService.Client:doTeleport(player, data)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	GeneralFunctions.makeSound("rbxassetid://1231327271",player.Character )
		
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local MovesetResources = ReplicatedStorage.Moveset_Resources.onepiece_resources.Asura

		
	-- Same beam from earlier
	local beam = MovesetResources.Beam:Clone()
	beam.Parent = character
	beam.Start.CFrame = character.HumanoidRootPart.CFrame
	
	local att = beam.End.Attachment1
	local b = beam.End.beam2
	att.Parent, b.Parent = character.HumanoidRootPart, character.HumanoidRootPart
	
	task.delay(1, function()
		beam:Destroy()
		att:Destroy()
		b:Destroy()
	end)
	
	-- Move the character forward based on the data provided (modifyable in serverData easily)
	local moveDirection = character.HumanoidRootPart.CFrame.LookVector * serverData.asura.distance
	character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame + moveDirection
end



return OnepieceService
