local Turret = require(game.ServerStorage.TurretModule) 
local turrets = {}

-- Not optimized, just here for demo purposes only

local params = {
	{
		BULLET_SPEED = 100,
		FIRE_RATE = 50,
		NUM_BULLETS_IN_SPREAD = 2,
		SPREAD = 1
		
	},
	{
		BULLET_SPEED = 50,
		FIRE_RATE = 20,
		NUM_BULLETS_IN_SPREAD = 5,
		SPREAD = 10

	},
	{
		BULLET_SPEED = 30,
		FIRE_RATE = 20,
		NUM_BULLETS_IN_SPREAD = 1,
		SPREAD = 1

	},
	{
		BULLET_SPEED = 30,
		FIRE_RATE = 30,
		NUM_BULLETS_IN_SPREAD = 3,
		SPREAD = 4

	},
	{
		BULLET_SPEED = 70,
		FIRE_RATE = 10,
		NUM_BULLETS_IN_SPREAD = 3,
		SPREAD = 4

	},
	
	
}


for i, turretModel in ipairs(workspace.Turrets:GetChildren()) do
	if turretModel:FindFirstChild("gun") then
		local turret = Turret.new(turretModel.gun, params[i])
		table.insert(turrets, turret)
			
	end
end

wait(4)
local player = game:GetService("Players"):GetPlayers()[1]
for _, turret in ipairs(turrets) do
	turret:lockOn(player)
	turret:StartShooting()
end


local humanoid = player.Character:WaitForChild("Humanoid")
humanoid.Died:Connect(function()
	wait(6)
	local player = game:GetService("Players"):GetPlayers()[1]
	for _, turret in ipairs(turrets) do
		turret:lockOn(player)
	end

end)

local function OnCharacterAdded(character, callback)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(callback)
end

player.CharacterAdded:Connect(function(character)
	OnCharacterAdded(character, function()
		wait(5)
		local player = game:GetService("Players"):GetPlayers()[1]
		for _, turret in ipairs(turrets) do
			turret:lockOn(player)
		end			
	end)
end)


game:BindToClose(function()
	for _, turret in ipairs(turrets) do
		turret:Destroy()
	end
end)
