local modules = game.ReplicatedStorage.Modules
local buildings = require(modules.Buildings)
local resourses = require(modules.RousursesData)

local function createHitbox(model, building,a)
	local x = 4
	local z = 4
	if not a then
		x = building["Xsize"] - 1.1
		z = building["Zsize"] - 1.1
	end
	local newHitbox = Instance.new("Part")
	if x < 0.55 then
		x = 0.55
	end
	if z < 0.55 then
		z = 0.55
	end
	newHitbox.CollisionGroup = "WorkerHitbox"
	newHitbox.Size = Vector3.new(x, 10, z)
	newHitbox.Parent = model
	newHitbox.Name = "BlockHitbox"
	newHitbox.Transparency = 1
	newHitbox.CanCollide = true
	newHitbox.Anchored = true
	newHitbox.Position = model.PrimaryPart.Position
	if model:FindFirstChild("AfkPart") then
		model:FindFirstChild("AfkPart").CanCollide = true
	end
end

for i,worker in ipairs(game.ReplicatedStorage.Workers:GetChildren()) do
	if worker:FindFirstChild("LeftFoot") then
		local newScript = game.ServerStorage.Setup.SetNetwork:Clone()
		newScript.Parent = worker
		newScript.Enabled = true
		
		worker.LeftFoot.CanCollide = true
		worker.RightFoot.CanCollide = true
	end
end

for i,building in pairs(buildings) do
	--[[for name, value in pairs(building) do
		if tonumber(value) then
			if game.ReplicatedStorage.Buildings:FindFirstChild(i) then
				local newValue = Instance.new("NumberValue", game.ReplicatedStorage.Buildings:FindFirstChild(i))
				newValue.Name = name
				newValue.Value = value
			else
				local newValue = Instance.new("NumberValue", game.ReplicatedStorage.Buildings.Upgrades:FindFirstChild(i))
				newValue.Name = name
				newValue.Value = value
			end
		else
			if game.ReplicatedStorage.Buildings:FindFirstChild(i) then
				local newValue = Instance.new("StringValue", game.ReplicatedStorage.Buildings:FindFirstChild(i))
				newValue.Name = name
				newValue.Value = value
			else
				local newValue = Instance.new("StringValue", game.ReplicatedStorage.Buildings.Upgrades:FindFirstChild(i))
				newValue.Name = name
				newValue.Value = value
			end
		end
	end]]
	local model
	if game.ReplicatedStorage.Buildings:FindFirstChild(i) then
		model = game.ReplicatedStorage.Buildings:FindFirstChild(i)
	else
		model = game.ReplicatedStorage.Buildings.Upgrades:FindFirstChild(i)
	end
	createHitbox(model,building)
end

for i,resourse in pairs(resourses) do
	for name, value in pairs(resourse) do
		if name ~= "Health" then
			if tonumber(value) then
				local newValue = Instance.new("NumberValue", game.ReplicatedStorage.Buildings:FindFirstChild(i))
				newValue.Name = name
				newValue.Value = value
			else
				local newValue = Instance.new("StringValue", game.ReplicatedStorage.Buildings:FindFirstChild(i))
				newValue.Name = name
				newValue.Value = value
			end
		end
	end
	local model = game.ReplicatedStorage.Buildings:FindFirstChild(i)
	createHitbox(model,resourse)
end

for i, seeds in ipairs(game.ReplicatedStorage.Seeds:GetChildren()) do
	createHitbox(seeds, nil, true)
end