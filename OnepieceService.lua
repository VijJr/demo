--[[ 

NOTE: 

This library uses the Knit library for convenience, and there is a corresponding controller (local script)
This works specifically for r15 rigs, it was not build for r6
In the demo every move is implemented but this is only code for the F skill

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
	-- If character or humanoid root part is nil terminate to avoid errors
	if not char or not char:FindFirstChild("HumanoidRootPart") then
	    return
	end

	-- Calculate the total mass by looping over the direct children that are baseparts, and summing the mass 
	local mass = 0
	for _, y in pairs(char:GetChildren()) do
		if(y:IsA("BasePart")) then
			mass += y:GetMass()
		end
	end

	-- Generate force vectors by using the lookvector direction and scaling by mass + mult factor so it translates the same 
	-- In case custom mult is nil choose 1 to prevent errors
        local mult = customMult or 1
        local forceX = lookvector.x * kbAmount * mass
        local forceZ = lookvector.z * kbAmount * mass
	-- In terms of y direction no need for a look vector since the upward direction stays constant 
        local impulseForce = Vector3.new(forceX, mass * mult, forceZ)

	-- Apply an impulse force to the character 
        char.HumanoidRootPart:ApplyImpulse(impulseForce)

end

-- Helper function to generate rising debris for asura skill 
local function createRisingPart(position)
	-- Create a part, set its size, material, color, and other generic properties 
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.new(0, 255, 0)
	part.Anchored = true
	part.CanCollide = false
	part.Parent = character
	part.CFrame = position

	-- Create a tween that lasts for 1 second, take its current position and move it up 7 studs on the y axis
	local tweenInfo = TweenInfo.new(1)
	local goal = {Position = part.Position + Vector3.new(0, 7, 0)}
	-- Create and play the tween 
	local tween = TweenService:Create(part, tweenInfo, goal)
	tween:Play()

	-- Delay by 1 second and destroy the part for asynchronous cleanup
	task.delay(1, function() part:Destroy() end)
end

-- This is a helper function to apply the fx lightning and rising debris, referencing the above method 
local function asuraFX(character, pos)
	-- Setting aside this replicated storage variable for ease of use, accessing the file tree for the asura skill
	local repStorage = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura

	-- Generate three lightning 
	for i = 1,3 do
		-- Take the current pos of the character, based on the current i multiply by 120 to get rotating angles in intervals of 120 degrees
		-- Then take the look vector of that new cframe to know which direction to place the part in 
		local vec = (pos * CFrame.Angles(0, math.rad(120 * i), 0)).LookVector
		-- Create a random number from 10-20
		local dist = math.random(10, 20)
		-- Clone the lightning from rep storage
		local lightning = repStorage["A - ELECTRICITY 01"]:Clone()
		lightning.Parent = character
		-- Set the lightning pos by appending the lookvectoro scaled by the random distance to the position of the character
		lightning.CFrame = pos + vec * dist
		-- Auto cleanup
		task.delay(1, function() lightning:Destroy() end)
	end


	-- Generate 7 rising debris 
	for i = 1,7 do
		-- Random distance calc (same as above)
		local dist = math.random(10, 20)
		-- Similar logic as above but now the angles are truly randomized since 7 parts gives enough to evenly distribute
		-- Logic: Gen 3 random angles, apply the rotation to the current position and take that lookvector to get a random vector away from char
		local vec = (pos * CFrame.Angles(math.rad(math.random(360)), math.rad(math.random(360)), math.rad(math.random(360)))).LookVector
		-- Apply the position on the part using the above method, by using the same logic as seen in the lightning skill 
		createRisingPart(pos + vec * dist, character)
	end

end

-- Asura move server-side method as called in local controller. local generates hitbox and feeds the enemy as input along with data about 
-- the move like execution time, distance of hitbox, damage, etc
function OnepieceService.Client:HandleAsura(player, data, enemy)
	-- Validate character and necessary parts
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Head") then
		return
	end

	-- Cache commonly used services and assets
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local MovesetResources = ReplicatedStorage.Moveset_Resources.onepiece_resources.Asura
	local Humanoid = character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end

	-- Clone accessories and attach them to the player
	local accessories = {
		MovesetResources["Three-Sword Style"].mouth:Clone(),
		MovesetResources["Three-Sword Style"].right:Clone(),
		MovesetResources["Three-Sword Style"].left:Clone()
	}

	for _, acc in ipairs(accessories) do
		Humanoid:AddAccessory(acc)
		task.delay(serverData.asura.duration + 1, function()
			acc:Destroy()
		end)
	end

	local eye = MovesetResources.eye.eye:Clone()
	eye.Parent = character.Head
	task.delay(serverData.asura.duration + 1, function()
		eye:Destroy()
	end)

	-- Apply FX to nearby players
	local players = game:GetService("Players"):GetPlayers()
	local rootPos = character.HumanoidRootPart.Position

	for _, x in ipairs(players) do
		local xRoot = x.Character and x.Character:FindFirstChild("HumanoidRootPart")
		if xRoot and (xRoot.Position - rootPos).Magnitude < 300 then
			self.applyFx:Fire(x)
		end
	end


	local pos = character.HumanoidRootPart.CFrame
	asuraFX(character, pos)


	-- Wait and initiate flight
	task.wait(1)
	StartFlight(player, serverData, enemy, serverData.asura.duration - 1)
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
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	local accessories = {"mouth", "right", "left", "eye"}
	for _, accessory in ipairs(accessories) do
		local part = (accessory == "eye" and character.Head or character):FindFirstChild(accessory)
		if part then part:Destroy() end
	end
end

-- This is fired on local if there are no enemies in hitbox. Functions like a teleport move 
function OnepieceService.Client:HandleAsuraTeleport(player, data)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Head") then
		return
	end

	-- Cache commonly used services and assets
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local MovesetResources = ReplicatedStorage.Moveset_Resources.onepiece_resources.Asura
	local Humanoid = character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end

	-- Clone accessories and attach them to the player
	local accessories = {
		MovesetResources["Three-Sword Style"].mouth:Clone(),
		MovesetResources["Three-Sword Style"].right:Clone(),
		MovesetResources["Three-Sword Style"].left:Clone()
	}
	for _, acc in ipairs(accessories) do
		Humanoid:AddAccessory(acc)
		print(serverData.asura.duration)

		task.delay(2 , function()
			print("moog")
			acc:Destroy()
		end)
	end

	local eye = MovesetResources.eye.eye:Clone()
	eye.Parent = character.Head
	task.delay(2, function()
		eye:Destroy()
	end)


	GeneralFunctions.makeSound("rbxassetid://858508159",player.Character )

	local pos = character.HumanoidRootPart.CFrame
	asuraFX(character, pos)

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
