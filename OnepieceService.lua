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
function doKb(char: Model, lookvector: Vector3, kbAmount: number, customMult: number)
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
local function createRisingPart(position: CFrame)
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
local function asuraFX(character: Model, pos: CFrame, Humanoid: Humanoid )
	-- Setting aside this replicated storage variable for ease of use, accessing the file tree for the asura skill
	local repStorage = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura

	-- List accessories that need to be applied to player by cloning from rep storage
	local accessories = {
		repStorage["Three-Sword Style"].mouth:Clone(),
		repStorage["Three-Sword Style"].right:Clone(),
		repStorage["Three-Sword Style"].left:Clone()
	}

	-- For each accessory listed, apply to humanoid and set an asynch timer for automatic cleanup based on the desired duration
	-- as specified in the serverData module 
	for _, acc in ipairs(accessories) do
		Humanoid:AddAccessory(acc)
		task.delay(serverData.asura.duration, function()
			acc:Destroy()
		end)
	end

	-- Do the same for the eye part 
	local eye = repStorage.eye.eye:Clone()
	eye.Parent = character.Head
	task.delay(serverData.asura.duration, function()
		eye:Destroy()
	end)

	

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
function OnepieceService.Client:HandleAsura(player: Player, data, enemy: Part)
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

	
	-- Apply the external effects defined above 
	local pos = character.HumanoidRootPart.CFrame
	asuraFX(character, pos, Humanoid)

	--  Get current position of player and all players in game with the player service
	local players = game:GetService("Players"):GetPlayers()
	local rootPos = character.HumanoidRootPart.Position

	-- Check each player, and make sure they have a rootpart with ternary operator for error checking
	for _, x in ipairs(players) do
		local xRoot = x.Character and x.Character:FindFirstChild("HumanoidRootPart")
		-- If the player exists (including the current character), subtract positions and take the magnitude distance
		-- If the player is within 300 studs of the current character, apply shake effect which happens on local script 
		if xRoot and (xRoot.Position - rootPos).Magnitude < 300 then
			self.applyFx:Fire(x) -- Pass in the desired player to create a local screenshake effect
		end
	end




	-- Wait 1 second and initiate flight
	task.wait(1)
	-- Subtract one since 1 second has passed 
	StartFlight(player, serverData, enemy, serverData.asura.duration - 1)
end


-- Flies towards enemy, this is an aux method for clean purposes. Duration is how long the flight lasts before target is reached
function StartFlight(player, data, enemy, duration)
	-- Validate character again after the 1 second delay
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	-- General functions is a moduel with helpful functions, this syntax plays sound at the player.character location on server
	GeneralFunctions.makeSound("rbxassetid://137463716",player.Character )
	
	
	-- Create helpful variables for moveset resources 
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local MovesetResources = ReplicatedStorage.Moveset_Resources.onepiece_resources.Asura

	-- Clone hitbox from moveset resources, apply position as 4 studs in front of the character by scaling the lookvector and adding it on 
	-- This is done because the hitbox part is centered in the middle and we want to attach on one end (it is 8 studs wide)
	local hitbox = MovesetResources.hitbox2:Clone()
	hitbox.CFrame = character.HumanoidRootPart.CFrame + character.HumanoidRootPart.CFrame.LookVector * 4
	hitbox.Parent = character

	-- Create a weld and attach the hotbox to the character rootpart so while in motion the hitbox stays 
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = character.HumanoidRootPart
	weld.Part1 = hitbox
	weld.Parent = hitbox

	-- Asynch cleanup 
	task.delay(duration, function()
		hitbox:Destroy()
		weld:Destroy()
	end)
		
	-- Create beam and add one attachement to starting location, the other on the players root so it moves w/ player. Adds appropriate parents
	-- Beam is a folder containing the beam and attachements. Attachement start is set to the current character position 
	local beam = MovesetResources.Beam:Clone()
	beam.Parent = character
	beam.Start.CFrame = character.HumanoidRootPart.CFrame
	
	-- Attachement end is set into the humanoid root part. Also there are two beams for color variation so the same thing happens there 
	local att = beam.End.Attachment1
	local b = beam.End.beam2
	att.Parent, b.Parent = character.HumanoidRootPart, character.HumanoidRootPart

	-- Async cleanup 
	task.delay(duration, function()
		beam:Destroy()
		att:Destroy()
		b:Destroy()
	end)
	
	-- Get the flashy vfx from storage that are applied to the character for the duration of the move 
	local expl = MovesetResources.Explosion.Hit:Clone()
	expl.Parent = character.HumanoidRootPart
	task.delay(duration, function()
		expl:Destroy()
	end)	
		
	-- Validate the enemy exists to prevent errors
	if not enemy or not enemy:FindFirstChild("RootRigAttachment") then
		return
	end

	-- Create new align position to pull the character towards the enemy location regardless of how either character moves 
	local align = Instance.new("AlignPosition")
	align.Parent = character
	-- Set to true for a smooth motion 
	align.RigidityEnabled = true
	-- Set attachments to the relevant root attachements of both characters
	align.Attachment0 = character.HumanoidRootPart.RootRigAttachment
	align.Attachment1 = enemy.RootRigAttachment
	-- Async cleanup 
	task.delay(duration, function()
		align:Destroy()
	end)	
		
	-- Player service 
	local players = game:GetService("Players")

	-- Create  a connection to the hitbox touched event,
	local connect
	connect = hitbox.Touched:Connect(function(hit)
		-- Make sure the hit character is a humanoid with a root part (npc or player doesnt matter)
		if(hit.Parent:FindFirstChild("HumanoidRootPart")) then
			-- Get the rootpart if it is not nill 
			local hitParent = hit.Parent
			local hitRoot = hitParent and hitParent:FindFirstChild("HumanoidRootPart")
			-- Validate not nil 
			if hitParent == character or not hitRoot then return end

			-- Local listener to create the hitframe white/black sequence for the character 
			OnepieceService.Client.hitframe:Fire(player, hitParent, character)

			-- Get the player from enemy character, and generate hitframe for that local too. 
			local hitPlayer = players:GetPlayerFromCharacter(hitParent)
			-- Validate not nil in case hit character is a NPC 
			if hitPlayer then
				OnepieceService.Client.hitframe:Fire(hitPlayer, hitParent, character)
			end

			-- Generate sound fx
			GeneralFunctions.makeSound("rbxassetid://5989945551",player.Character )
			GeneralFunctions.makeSound("rbxassetid://7390331288",player.Character )
			-- Destroy align once the two characters reach if the enemy hasn't managed to get away / timout the skill 
			align:Destroy()
			
			-- Creates a debris field with 16 radius, and 7 size, 1 second until despawn and don't fly around (false)
			GeneralFunctions.Create(16, hit.Position, 7, 1, false)
			
			-- Get the slash vfx and apply it to the enemy character
			local fx = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura.CUTS:Clone()
			fx.Parent = hit

			-- Async cleanup
			task.delay(1, function()
				fx:Destroy()
			end)	
				
			-- Custom countdown function that runs the code block every 0.1 seconds until 1 minute has passed
			GeneralFunctions.countdown(1, 0.1, false, function()
				-- Get the humanoid and validate it 
				local hitHumanoid = hitParent:FindFirstChildOfClass("Humanoid")
				if not hitHumanoid then return end

				-- Check the magnitude difference between character and enemy is not more than 100 studs
				-- To prevent exploitation from a distance 
				if (hitRoot.Position - character.HumanoidRootPart.Position).Magnitude > 100 then return end

				-- Do damage to enemy humanoid, and fire the damage local method so the character can see the GUI popup for 
				-- damage on the local side screen + make sound 
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
			-- Stop all anim tracks if they haven't been stopped already
			for i,v in pairs(player.Character.Humanoid:GetPlayingAnimationTracks()) do
				v:Stop()
			end

			-- Clean local elements, stop anim, and clean other cosmetics 
			OnepieceService.Client.endAsura:Fire(player, hit.Parent )
				
			-- Disconnect connection to prevent memory usage 
			connect:Disconnect()
		end

	end)

end

-- Cleans the swords and cosmetics from the asura move when called in controller from anim sequence track markers (in case debris is slow)
function OnepieceService.Client:CleanAsura(player)
	-- Get and validate character
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	-- Create a list of accessories to grab, iterate over the accessories
	local accessories = {"mouth", "right", "left", "eye"}
	for _, accessory in ipairs(accessories) do
		-- If the accessory is eye, get from head otherwise get from character. Then find first child 
		local part = (accessory == "eye" and character.Head or character):FindFirstChild(accessory)
		-- If the part is not nil/ validated, destroy the part 
		if part then part:Destroy() end
	end
end

-- This is fired on local if there are no enemies in hitbox. Functions like a teleport move 
function OnepieceService.Client:HandleAsuraTeleport(player, data)
	-- Once again get and validate the character
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Head") then
		return
	end

	-- Cache commonly used services and assets
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local MovesetResources = ReplicatedStorage.Moveset_Resources.onepiece_resources.Asura
	local Humanoid = character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end
	
	-- Make the lightning and debris rising as defined in the above method 
	local pos = character.HumanoidRootPart.CFrame
	asuraFX(character, pos)

	-- Make sound
	GeneralFunctions.makeSound("rbxassetid://858508159",player.Character )



end

	

	
-- Once the animation sequence for the plain teleport is over, actually teleport the character forward
function OnepieceService.Client:doTeleport(player, data)
	-- Validate character and get it 
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	GeneralFunctions.makeSound("rbxassetid://1231327271",player.Character )

	-- Store moveset resources 
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local MovesetResources = ReplicatedStorage.Moveset_Resources.onepiece_resources.Asura

		
	-- Same beam from earlier, same logic 
	local beam = MovesetResources.Beam:Clone()
	beam.Parent = character
	beam.Start.CFrame = character.HumanoidRootPart.CFrame
	
	local att = beam.End.Attachment1
	local b = beam.End.beam2
	att.Parent, b.Parent = character.HumanoidRootPart, character.HumanoidRootPart

	-- Auto cleanup 
	task.delay(1, function()
		beam:Destroy()
		att:Destroy()
		b:Destroy()
	end)
	
	-- Move the character forward based on the data provided (modifyable in serverData easily)
	-- Calculated by getting the look vector and scaling the distance by the distance in server data 
	-- Then applying that distance vector3 to the cframe current position so the character gets jumped ahead in the direction they were looking 
	-- Note we take the rootpart cframe so it wouldn't be looking up or down unless they glitched the character
	-- In this case it is possible to set the y-component to 0 in the lookvector to prevent glitching under the map, but it wasn't a concern
	local moveDirection = character.HumanoidRootPart.CFrame.LookVector * serverData.asura.distance
	character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame + moveDirection
end



return OnepieceService
