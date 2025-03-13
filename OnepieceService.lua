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
		-- Random distance away
		local dist = math.random(10, 20)
		
		-- Create square debris item at a random location away from user and a random distance away 
		local vec = (pos * CFrame.Angles(math.rad(math.random(360)),math.rad(math.random(360)), math.rad(math.random(360)))).LookVector
		local part = Instance.new("Part")
		part.Size = Vector3.new(0.5,0.5,0.5)
		part.Material = Enum.Material.SmoothPlastic
		part.Color = Color3.new(0,255,0)
		part.Anchored = true
		part.CanCollide = false
		part.Parent= character
		part.CFrame =pos +  vec*dist
		
		-- Tween to rise 7 higher in 1 second
		local Goal = {Position = part.Position + Vector3.new(0, 7, 0) }
		local Tween = TweenService:Create(part, Info, Goal)
		Tween:Play()
		
		-- Used to have some scripts here so didn't use debris functionality. Task spawn to cleanup parts asynch
		task.delay(1, function()
			part:Destroy()
		end)
	end
	
	

	wait(1)
	-- Flies towards enemy
	StartFlight(player, serverData, enemy, serverData.asura.duration-1)
	
	
end

-- Flies towards enemy, this is an aux method for clean purposes. Duration is how long the flight lasts before target is reached
function StartFlight(player, data, enemy, duration)
	local character = player.Character
	GeneralFunctions.makeSound("rbxassetid://137463716",player.Character )
	
	
	-- Generate hitbox and weld onto player since player is moving
	local hitbox = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura.hitbox2:Clone()
	hitbox.CFrame = character.HumanoidRootPart.CFrame + character.HumanoidRootPart.CFrame.LookVector*4
	hitbox.Parent = character
	debris:AddItem(hitbox, duration)

	local weld = Instance.new("WeldConstraint")
	weld.Parent = character
	weld.Part0 = character.HumanoidRootPart
	weld.Part1 = hitbox
	debris:AddItem(weld, duration)
	
	-- Create beam and add one attachement to starting location, the other on the players root so it moves w/ player
	local beam = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura.Beam:Clone()
	beam.Parent = character
	beam.Start.CFrame = character.HumanoidRootPart.CFrame
	debris:AddItem(beam, duration)

	
	local att = beam.End.Attachment1
	local b = beam.End.beam2
	att.Parent = character.HumanoidRootPart
	b.Parent= character.HumanoidRootPart
	debris:AddItem(att, duration)
	debris:AddItem(b, duration)
	
	-- Flashy fx added to the player 
	local expl = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura.Explosion.Hit:Clone()
	expl.Parent = character.HumanoidRootPart
	debris:AddItem(expl, duration)
	
	
	-- Move the character towards the enemy 
	local align = Instance.new("AlignPosition")
	align.Parent = character
	align.RigidityEnabled = true
	align.Attachment0 = character.HumanoidRootPart.RootRigAttachment
	align.Attachment1 = enemy.RootRigAttachment
	debris:AddItem(align, duration)
	
	
	-- Once character reaches enemy, fire move 
	local connect
	connect = hitbox.Touched:Connect(function(hit)
		if(hit.Parent:FindFirstChild("HumanoidRootPart")) then
			if(hit.Parent == character) then return end
			
			-- Fires hitframe on client with a black/white frame
			OnepieceService.Client.hitframe:Fire(player, hit.Parent, character)
			
			-- Fires hitframe on enemy client with a black/white frame
			if(game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)) then
				OnepieceService.Client.hitframe:Fire(game:GetService("Players"):GetPlayerFromCharacter(hit.Parent), hit.Parent, character)

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
				-- Validate enemy is close (prevent cheating)
				if((hit.Parent.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude > 100) then return end
				hit.Parent.Humanoid:TakeDamage(serverData.asura.damage)
				-- Damage GUI handle on the local 
				OnepieceService.Client.damage:Fire(player, hit.Parent, serverData.asura.damage)
				
				GeneralFunctions.makeSound("rbxassetid://7118966167", hit.Parent)

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
	if(character:FindFirstChild("mouth")) then
		character:FindFirstChild("mouth"):Destroy()
	end
	if(character:FindFirstChild("right")) then
		character:FindFirstChild("right"):Destroy()
	end
	if(character:FindFirstChild("left")) then
		character:FindFirstChild("left"):Destroy()
	end
	if(character.Head:FindFirstChild("eye")) then
		character.Head:FindFirstChild("eye"):Destroy()
	end
end

-- This is fired on local if there are no enemies in hitbox. Functions like a teleport move 
function OnepieceService.Client:HandleAsuraTeleport(player, data)
	local character = player.Character
	
	-- Give the cosmetics
	local acc = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura["Three-Sword Style"].mouth:Clone()
	character.Humanoid:AddAccessory(acc)
	local acc2 = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura["Three-Sword Style"].right:Clone()
	character.Humanoid:AddAccessory(acc2)

	local acc3 = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura["Three-Sword Style"].left:Clone()
	character.Humanoid:AddAccessory(acc3)

	local eye = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura.eye.eye:Clone()
	eye.Parent = character.Head

	GeneralFunctions.makeSound("rbxassetid://858508159",player.Character )

	local pos = character.HumanoidRootPart.CFrame
	debris:AddItem(acc2, 2)
	debris:AddItem(acc, 2)
	debris:AddItem(acc3,2)
	debris:AddItem(eye, 2)


	-- Provide the same fx from earlier
	for i = 1,3 do
		local vec = (pos * CFrame.Angles(0,math.rad(120*i), 0)).LookVector
		local dist = math.random(10, 20)
		local lightning = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura["A - ELECTRICITY 01"]:Clone()
		lightning.Parent= character
		lightning.CFrame =pos +  vec*dist
		task.delay(1, function()
			lightning:Destroy()
		end)

	end

	for i = 1,7 do
		local dist = math.random(10, 20)

		local vec = (pos * CFrame.Angles(math.rad(math.random(360)),math.rad(math.random(360)), math.rad(math.random(360)))).LookVector
		local part = Instance.new("Part")
		part.Size = Vector3.new(0.5,0.5,0.5)
		part.Material = Enum.Material.SmoothPlastic
		part.Color = Color3.new(0,255,0)
		part.Anchored = true
		part.CanCollide = false
		part.Parent= character
		part.CFrame =pos +  vec*dist

		local Info = TweenInfo.new(1)
		local Goal = {Position = part.Position + Vector3.new(0, 7, 0) }
		local Tween = TweenService:Create(part, Info, Goal)
		Tween:Play()

		task.delay(1, function()
			part:Destroy()
		end)
	end





end

-- Once the animation sequence for the plain teleport is over, actually teleport the character forward
function OnepieceService.Client:doTeleport(player, data)
	GeneralFunctions.makeSound("rbxassetid://1231327271",player.Character )
	local character = player.Character
	-- Same beam from earlier
	local beam = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.Asura.Beam:Clone()
	beam.Parent = character
	beam.Start.CFrame = character.HumanoidRootPart.CFrame
	debris:AddItem(beam, 1)


	local att = beam.End.Attachment1
	local b = beam.End.beam2
	att.Parent = character.HumanoidRootPart
	b.Parent= character.HumanoidRootPart
	debris:AddItem(att, 1)
	debris:AddItem(b, 1)
	
	-- Move the character forward based on the data provided (modifyable in serverData easily)
	character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame + character.HumanoidRootPart.CFrame.LookVector*serverData.asura.distance
end


-- Creates cosmetics for the snake move in the one piece moveset, as done in the anime
function OnepieceService.Client:HandleSnake(player, data)
	
	local character = player.Character
	character.RightHand.Transparency = 1
	character.RightLowerArm.Transparency = 1
	character.LeftHand.Transparency = 1
	character.LeftLowerArm.Transparency = 1
	character.RightFoot.Transparency = 1
	character.LeftFoot.Transparency = 1
	character.RightLowerLeg.Transparency = 1
	character.LeftLowerLeg.Transparency = 1
	
	local fx1 = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.snake.fx1:Clone()
	local fx2 = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.snake.fx2:Clone()
	fx1.Parent = character.RightUpperLeg
	fx2.Parent = character.LeftUpperLeg
	
	fx1 = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.snake.fx1:Clone()
	fx2 = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.snake.fx2:Clone()
	fx2.Parent = character.RightUpperLeg
	fx1.Parent = character.LeftUpperLeg
	
	
	local f3 = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.snake.f3:Clone()
	local f4 = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.snake.f4:Clone()
	local f5 = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.snake.f5:Clone()
	
	f3.Parent = character.HumanoidRootPart.RootRigAttachment
	f4.Parent = character.HumanoidRootPart.RootRigAttachment
	f5.Parent = character.HumanoidRootPart.RootRigAttachment
	




	

end


-- Generates the snake arms, fired in local
function OnepieceService.Client:GenSnake(player, enemy, rootAttachment, data)
	
	
	-- Create a joint to attach on to based on provided joint characteristics
	local character = player.Character
	local joint = rootAttachment:Clone()
	joint.Parent = rootAttachment.Parent
	joint.Name= rootAttachment.Name .. "1"




	
	-- Defines some stuff like the angle variance, wait time (t) between arm generation, tween, size of arm segments, etc
	local character = player.Character
	local t = 0.3
	local Info = TweenInfo.new(t, Enum.EasingStyle.Linear)
	local newSize =Vector3.new(50, 1,1)
	local angleVar = 10
	local scaleFactorFromOriginal = (newSize)/Vector3.new(1, 1,1)
	GeneralFunctions.makeSound("rbxassetid://876800936",player.Character )
	GeneralFunctions.makeSound("rbxassetid://650898624",player.Character, 0, 0,false, 1 )
	GeneralFunctions.makeSound("rbxassetid://979751563",player.Character )

	

	
	-- Creates the first arm segments angled forward and at a slight angle 
	local fake = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.snake.fake:Clone()
	fake.Parent = character.HumanoidRootPart
	local constraint = Instance.new("RigidConstraint")
	constraint.Parent = fake
	constraint.Attachment0 = joint
	constraint.Attachment1 = fake.Attachment1
	joint.WorldCFrame = CFrame.new(joint.WorldCFrame.Position, enemy.Position) *CFrame.Angles(0,0,math.rad(-90))
	
	
	-- Tween the attachement so they seem to grow 
	local init = fake.Attachment1.Position
	local Goal = {Position =init*scaleFactorFromOriginal }
	local Tween = TweenService:Create(fake.Attachment1, Info, Goal)
	Tween:Play()


	local init = fake.Attachment2.Position
	local Goal = {Position =init*scaleFactorFromOriginal }
	local Tween = TweenService:Create(fake.Attachment2, Info, Goal)
	Tween:Play()
	

	local Goal = {Size = newSize }
	local Tween = TweenService:Create(fake, Info, Goal)
	Tween:Play()
	
	local dontStop = true
	local prevRoot = fake.Attachment2
	
	-- Build a kill switch for when the move is ended, fired in the local. Ended by time limit or by player releasing key 
	self.stopSnake:Connect(function()
		dontStop = false
		joint:Destroy()
	end)
	
	-- db is debounce 
	local db = false
	wait(t)
	
	-- Iteratively build arms growing towards enemy
	while dontStop do
		-- Attach a hitbox to the enemy so if the arm gets within range it counts as a hit
		local hit = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.snake.hit:Clone()
		hit.Parent = enemy
		hit.CFrame = enemy.CFrame
		local weld = Instance.new("Weld")
		weld.Parent = enemy
		weld.Part0 = enemy
		weld.Part1 = hit
		

		-- Basically just ends the sequence before it starts, could break as well
		if(not dontStop) then continue end
		
		-- Based on previous arm change the Cframe so when new arm is attached to an end it takes that direction
		-- First align with enemy
		prevRoot.WorldCFrame = CFrame.new(prevRoot.WorldCFrame.Position, enemy.Position)
		-- Due to the way the CFrame is treated need to do a 90 degree rotation
		prevRoot.CFrame *= CFrame.Angles(0,math.rad(90),0)
		-- Create random variations in the arm moving in the general direction of enemy
		prevRoot.WorldCFrame *= CFrame.Angles(math.rad(math.random(-angleVar, angleVar)),math.rad(math.random(-angleVar,angleVar)),math.rad(math.random(-angleVar,angleVar)))

		-- Create new arm 
		fake = game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.snake.fake:Clone()
		fake.Parent = character.HumanoidRootPart
		constraint = Instance.new("RigidConstraint")
		constraint.Parent = fake
		constraint.Attachment0 = prevRoot
		constraint.Attachment1 = fake.Attachment1

		GeneralFunctions.makeSound("rbxassetid://9116939168",fake, 0, true,false, 100 )
		GeneralFunctions.makeSound("rbxassetid://18351315070",fake, 0, true,false, 0.3 )

		
		-- Tween each new arm
		init = fake.Attachment1.Position
		Goal = {Position =init*scaleFactorFromOriginal }
		Tween = TweenService:Create(fake.Attachment1, Info, Goal)
		Tween:Play()


		init = fake.Attachment2.Position
		Goal = {Position =init*scaleFactorFromOriginal }
		Tween = TweenService:Create(fake.Attachment2, Info, Goal)
		Tween:Play()


		Goal = {Size = newSize }
		Tween = TweenService:Create(fake, Info, Goal)
		Tween:Play()
		
		if((fake.Position - character.HumanoidRootPart.Position).Magnitude > serverData.snake.maxDist) then
			self.stopSnake2:Fire(player)
		end
		
		
		-- debounce 
		db = false
		prevRoot = fake.Attachment2
		wait(t)
		for _,x in pairs(game.Workspace:GetPartsInPart(fake)) do
			if(db) then continue end
			-- Check if arm entered hitbox 
			if(x.Name == "hit") then
				GeneralFunctions.makeSound("rbxassetid://9119594928",enemy.Parent )
				-- Check to make sure enemy didn't get to far away, then do damage
				if((enemy.Parent.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude > serverData.snake.maxDist+100) then return end
				enemy.Parent.Humanoid:TakeDamage(serverData.snake.damage)
				
				-- Show damage GUI
				self.damage:Fire(player, enemy.Parent, serverData.snake.damage)
				
				-- Give KB in direction of arm 
				doKb(enemy.Parent, prevRoot.WorldCFrame.LookVector, serverData.snake.kb)

				db = true
				-- Add fx to hit and clean up 
				for _,x in pairs(game:GetService("ReplicatedStorage").Moveset_Resources.onepiece_resources.snake.fx:GetChildren()) do
					local h = x:Clone()
					h.Parent = enemy
					debris:AddItem(h, 0.4)
				end


			end
		end
		weld:Destroy()
		hit:Destroy()
	end
	

	

	
end


-- Ends the cosmetics and cleans the snake arms, fired in local  
function OnepieceService.Client:EndSnake(player, data)
	local character = player.Character
	character.RightHand.Transparency = 0
	character.RightLowerArm.Transparency = 0
	character.LeftHand.Transparency = 0
	character.LeftLowerArm.Transparency = 0
	character.RightFoot.Transparency = 0
	character.LeftFoot.Transparency = 0
	character.RightLowerLeg.Transparency = 0
	character.LeftLowerLeg.Transparency = 0
	
	character.LeftUpperLeg.fx2:Destroy()
	character.RightUpperLeg.fx1:Destroy()
	character.LeftUpperLeg.fx1:Destroy()
	character.RightUpperLeg.fx2:Destroy()
	
	character.HumanoidRootPart.RootRigAttachment.f3:Destroy()
	character.HumanoidRootPart.RootRigAttachment.f4:Destroy()
	character.HumanoidRootPart.RootRigAttachment.f5:Destroy()
	
	for _,x in pairs(character.HumanoidRootPart:GetChildren()) do
		if(x.Name == "fake") then
			x:Destroy()
		end
	end



end



return OnepieceService
