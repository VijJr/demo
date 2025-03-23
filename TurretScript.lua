local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BulletFiredEvent = ReplicatedStorage:FindFirstChild("BulletFired")

if not BulletFiredEvent then
	warn("BulletFired event not found in ReplicatedStorage")
	return
end

local function CreateBullet(bulletPosition, shootDirection, BULLET_SPEED, BULLET_CLEAN_TIMER)
	local bullet = Instance.new("Part")
	bullet.Size = Vector3.new(0.2, 0.2, 0.2)
	bullet.Shape = Enum.PartType.Block
	bullet.Material = Enum.Material.Neon
	bullet.BrickColor = BrickColor.new("Bright yellow")
	bullet.CanCollide = false
	bullet.Anchored = false
	bullet.Massless = true
	bullet.Name = "SPHVPISZNN"
	bullet.Position = bulletPosition

	-- Create attachment and velocity constraint
	local attachment = Instance.new("Attachment", bullet)
	local velocityConstraint = Instance.new("LinearVelocity")
	velocityConstraint.Attachment0 = attachment
	velocityConstraint.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocityConstraint.VectorVelocity = shootDirection * BULLET_SPEED
	velocityConstraint.Parent = bullet

	-- Ensure bullet storage folder exists
	local bulletStorage = workspace:FindFirstChild("bullet_storage")
	if not bulletStorage then
		bulletStorage = Instance.new("Folder", workspace)
		bulletStorage.Name = "bullet_storage"
	end
	bullet.Parent = bulletStorage

	-- Handle bullet collision
	local bulletTouched = nil
	bulletTouched = bullet.Touched:Connect(function(hit)
		if bullet and hit ~= bullet and hit.Name ~= "Baseplate" then
			bulletTouched:Disconnect()
			bullet:Destroy()
			local success, err = pcall(function()
				BulletFiredEvent:FireServer(hit)
			end)
			if not success then
				warn("Failed to fire bullet event:", err)
			end
		end
	end)

	-- Clean up bullet after timer
	task.delay(BULLET_CLEAN_TIMER, function()
		if bullet then
			bullet:Destroy()
			bulletTouched:Disconnect()
		end
	end)
end

-- Connect the event
BulletFiredEvent.OnClientEvent:Connect(CreateBullet)