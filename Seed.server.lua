local events = game.ReplicatedStorage.NewEvents

local storeData = require(game.ReplicatedStorage.Modules.StoreData)
local tweenService = game.TweenService

local function effect(pos, value, exp,typeo)
	local playerFolder = game.ReplicatedStorage:WaitForChild("PlayerData")
	local newEffect = game.ReplicatedStorage.Effect:Clone()
	newEffect.Parent = workspace
	newEffect.Position = pos
	if exp then
		newEffect.BillboardGui.Exp.Text = "+" .. exp .. " Experience"
		playerFolder.Experience.Value += exp 
	else
		newEffect.BillboardGui.Exp.Text = ""
	end
	newEffect.BillboardGui.Cost.Text = ""
	if value then
		if typeo == "Coins" then
			newEffect.BillboardGui.Cost.Text = "-" .. value .. " Coins"
			playerFolder.Coins.Value -= value
		else
			newEffect.BillboardGui.Cost.Text = "-" .. value .. " RBucks"
			playerFolder.RDolce.Value -= value
		end
	end
	events.ToLocal.RefreshDane:FireAllClients()
	local tween = tweenService:Create(newEffect, TweenInfo.new(3,Enum.EasingStyle.Linear),{Position = Vector3.new(pos.X - 1, pos.Y + 4, pos.Z - 1)}):Play()
	wait(3)
	newEffect:Destroy()
end

local function convertTime(times)
	return times - 1715514260
end

local function createSeed(tasks, new)
	local seed = game.ReplicatedStorage.Seeds:FindFirstChild(tasks.Parent.TemporarySeed.Value):Clone()
	seed.Parent = workspace.Buildings
	seed:PivotTo(tasks.Parent.PrimaryPart.CFrame)
	local targetFolderValue = Instance.new("ObjectValue", seed)
	targetFolderValue.Value = tasks.Parent.TargetFolder.Value
	targetFolderValue.Name = "TargetFolder"
	if new then
		seed.TargetFolder.Value.Seed.Value = seed.Name
		seed.TargetFolder.Value.SeedStart.Value = convertTime(os.time())
		local seedtime
		local price
		for i, seeds in pairs(storeData["Seeds"]) do
			if seeds[1] == seed.Name then
				seedtime = seeds[4]
				price = seeds[2]
			end
		end
		seed.TargetFolder.Value.SeedTime.Value = convertTime(os.time()) + seedtime
		effect(seed.PrimaryPart.Position,price,nil,"Coins")
	end
	tasks.Parent:Destroy()
	seed.Name = "Pot"
end

local function SeedPhase(seed, timeT, new)
	local phase = ""
	
	local startT = seed.TargetFolder.Value.SeedStart.Value
	local endT = seed.TargetFolder.Value.SeedTime.Value
	if startT > 0 then
		if not seed:FindFirstChild("Phase") then
			local newPhase = Instance.new("StringValue",seed)
			newPhase.Name = "Phase"
			newPhase.Value = "New"
		end
		local phaseSplit = (endT - startT) / 4
		if startT + phaseSplit < timeT then
			phase = ""
		end
		if startT + phaseSplit * 2 < timeT then
			phase = 2
		end
		if startT + phaseSplit * 3 < timeT then
			phase = 3
		end
		if endT <= timeT then
			phase = 4
		end
		if tonumber(seed.Phase.Value) or new then
			if tonumber(seed.Phase.Value) ~= phase or new then
				local temporarySeedType = Instance.new("StringValue",seed)
				temporarySeedType.Name = "TemporarySeed"
				if phase ~= "" then
					temporarySeedType.Value = seed.TargetFolder.Value.Seed.Value .. "-" .. phase
					createSeed(seed.PrimaryPart)
				else
					temporarySeedType.Value = seed.TargetFolder.Value.Seed.Value
					createSeed(seed.PrimaryPart)
				end
			end
		end
		if seed and seed:FindFirstChild("Phase") then
			seed.Phase.Value = phase
		end
	end
end

events.Seeds.Plow.Event:Connect(function(tasks)
	local newPole = game.ReplicatedStorage.Buildings.Pot:Clone()
	newPole.Parent = workspace.Buildings
	newPole:PivotTo(tasks.Parent.PrimaryPart.CFrame)
	tasks.Parent.TargetFolder.Parent = newPole
	newPole.TargetFolder.Value.buildingName.Value = "Pot"
	effect(newPole.PrimaryPart.Position,nil,1,nil)
	tasks.Parent:Destroy()
end)

events.Seeds.Collect.Event:Connect(function(tasks)
	local playerFolder = game.ReplicatedStorage:WaitForChild("PlayerData")
	local seed = tasks.Parent.TargetFolder.Value.Seed.Value
	if playerFolder.Inventory:FindFirstChild(seed) then
		playerFolder.Inventory:FindFirstChild(seed).Value += 1
	else
		local newValue = Instance.new("NumberValue", playerFolder.Inventory)
		newValue.Name = seed
		newValue.Value = 1
	end
	local newPlowedField = game.ReplicatedStorage.Buildings.Plow:Clone()
	newPlowedField.Parent = workspace.Buildings
	newPlowedField:PivotTo(tasks.Parent.PrimaryPart.CFrame)
	tasks.Parent.TargetFolder.Parent = newPlowedField
	newPlowedField.TargetFolder.Value.buildingName.Value = "Plow"
	newPlowedField.TargetFolder.Value.SeedStart.Value = -1
	newPlowedField.TargetFolder.Value.SeedTime.Value = -1
	local targetExp
	for i, seeds in pairs(storeData["Seeds"]) do
		if seeds[1] == newPlowedField.TargetFolder.Value.Seed.Value then
			targetExp = seeds[5]
		end
	end
	newPlowedField.TargetFolder.Value.Seed.Value = "None"
	if targetExp > 0 then
		coroutine.wrap(effect)(tasks.Parent.PrimaryPart.Position,nil,targetExp,nil)
	end
	tasks.Parent:Destroy()
end)

events.Seeds.CreateSeed.Event:Connect(function(tasks)
	createSeed(tasks,true)
end)

events.Seeds.SeedPhase.Event:Connect(function(seed)
	SeedPhase(seed,convertTime(os.time()),true)
end)

while true do
	local timeT = convertTime(os.time())
	for i, seeds in ipairs(workspace.Buildings:GetChildren()) do
		if seeds:FindFirstChild("TargetFolder") then
			if seeds.TargetFolder.Value then
				if seeds.TargetFolder.Value:FindFirstChild("Seed") then
					SeedPhase(seeds,timeT)
				end
			end
		end
	end
	wait(1)
end