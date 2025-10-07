while not game.ReplicatedStorage:FindFirstChild("PlayerData") do
	wait(0.5)
end

local playerFolder = game.ReplicatedStorage.PlayerData
local events = game.ReplicatedStorage.NewEvents
local tweenService = game.TweenService

local upgradeData = require(game.ReplicatedStorage.Modules.Upgrades)
local buildingData = require(game.ReplicatedStorage.Modules.Buildings)
local craftingData = require(game.ReplicatedStorage.Modules.CraftingData)
local shopData = require(game.ReplicatedStorage.Modules.StoreData)

local function findBuildingCost(building)
	for i, category in pairs(shopData) do
		for buildingName, value in pairs(category) do
			if value[1] == building.Name then
				return value[2]
			end
		end
	end
end

local function check(object)
	local hitbox = object:FindFirstChild("Hitbox")
	if hitbox then
		local hites = hitbox:GetTouchingParts()
		for i,hit in pairs(hites) do
			return nil
		end
		return true
	end
end

local function checkBang(object)
	local hitbox = object:FindFirstChild("Hitbox")
	if hitbox then
		local hites = hitbox:GetTouchingParts()
		for i,hit in pairs(hites) do
			if hit:IsDescendantOf(workspace.Block) then
				return nil
			end
		end
	end
	return true
end

local function createFolderValue(newBuilding)
	local newFolder = Instance.new("Folder",playerFolder.Buildings)
	newFolder.Name = #playerFolder.Buildings:GetChildren() .. newBuilding.Name .. math.random(1,100)

	local primary = newBuilding.PrimaryPart
	local pos = primary.Position

	local newValue2 = Instance.new("StringValue", newFolder)
	newValue2.Name = "buildingName"
	newValue2.Value = newBuilding.Name

	local newValue = Instance.new("StringValue", newFolder)
	newValue.Name = "buildingPosition"
	newValue.Value = pos.X .. "x" .. pos.Y .. "x" .. pos.Z .. "x" .. primary.Orientation.Y
	
	local targetValue = Instance.new("ObjectValue", newBuilding)
	targetValue.Name = "TargetFolder"
	targetValue.Value = newFolder
	
	if newBuilding:FindFirstChild("Worker") then
		local newValue3 = Instance.new("NumberValue", newFolder)
		newValue3.Name = "Items"
		newValue3.Value = 0

		local newValue4 = Instance.new("NumberValue", newFolder)
		newValue4.Name = "Timer"
		newValue4.Value = -1

		local newValue5 = Instance.new("StringValue", newFolder)
		newValue5.Name = "id"
		newValue5.Value = -1

		local newValue5a = Instance.new("StringValue", newFolder)
		newValue5a.Name = "Status"
		newValue5a.Value = "None"

		local newValue7 = Instance.new("ObjectValue", newBuilding)
		newValue7.Name = "WorkerObject"
	elseif newBuilding.Name == "Pot" then
		local newValue3 = Instance.new("StringValue", newFolder)
		newValue3.Name = "Seed"
		newValue3.Value = "None"
		
		local newValue4 = Instance.new("NumberValue", newFolder)
		newValue4.Name = "SeedTime"
		newValue4.Value = -1
		
		local newValueSpecialnieDlaSwiatWgZombie = Instance.new("NumberValue", newFolder)
		newValueSpecialnieDlaSwiatWgZombie.Name = "SeedStart"
		newValueSpecialnieDlaSwiatWgZombie.Value = -1
	end
	return newFolder
end

local function effect(pos, value, exp,typeo)
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
			value = tonumber(string.sub(value, 1, -2))
			newEffect.BillboardGui.Cost.Text = "-" .. value .. " RBucks"
			playerFolder.RDolce.Value -= value
		end
	end
	events.ToLocal.RefreshDane:FireAllClients()
	local tween = tweenService:Create(newEffect, TweenInfo.new(3,Enum.EasingStyle.Linear),{Position = Vector3.new(pos.X - 1, pos.Y + 4, pos.Z - 1)}):Play()
	wait(3)
	newEffect:Destroy()
end

events.Placement.ToStorage.OnServerEvent:Connect(function(player,building)
	if building then
		building.TargetFolder.Value:Destroy()
		if playerFolder.Inventory:FindFirstChild(building.Name) then
			playerFolder.Inventory:FindFirstChild(building.Name).Value += 1
		else
			local newValue = Instance.new("NumberValue", playerFolder.Inventory)
			newValue.Name = building.Name
			newValue.Value = 1
		end
		building:Destroy()
	end
end)

events.Placement.Modernization.OnServerEvent:Connect(function(player, building)
	if craftingData[building.Name]["Modernization"] then
		local neededItems = craftingData[building.Name]["Modernization"]
		local check = true
		for i=1,3 do
			local item = neededItems[(i - 1) * 2 + 1]
			local quanity = neededItems[i*2]
			local targetItem = playerFolder.Inventory:FindFirstChild(item)
			if targetItem then
				if targetItem.Value >= quanity then
					targetItem.Value -= quanity
				else
					check = false
				end
			else
				check = false
			end
		end
		if check == true then
			local newBuilding = game.ReplicatedStorage.Buildings.Upgrades:FindFirstChild(building.Name .. "-Upgrade"):Clone()
			newBuilding.Parent = workspace.Buildings
			newBuilding:PivotTo(building.PrimaryPart.CFrame)
			local targetFolder = building.TargetFolder.Value
			targetFolder:Destroy()
			building:Destroy()
			local folder = createFolderValue(newBuilding)
			
			local timerValue = Instance.new("NumberValue",folder)
			timerValue.Name = "Timer"
			timerValue.Value = -1
			
			effect(newBuilding.PrimaryPart.Position, nil,buildingData[newBuilding.Name]["Exp"])
		else
			warn("Something went wrong with modernization!")
		end
	else
		warn("Can't find a modernization for this building: ", building.Name)
	end
end)

local function bangAnimationAndExplosion(building)
	local targetBuilding = playerFolder.Inventory:FindFirstChild(building.Name)
	targetBuilding.Value -= 1
	local range = buildingData[building.Name]["Range"]
	local effectPos = building.Effect.Position
	building.Effect.BillboardGui.Enabled = true
	tweenService:Create(building.Effect, TweenInfo.new(1.5,Enum.EasingStyle.Linear),{Position = Vector3.new(effectPos.X,effectPos.Y + 3,effectPos.Z)}):Play()
	wait(1.5)
	building.Effect.BillboardGui.Timer.Text = "2"
	building.Effect.Position = effectPos
	tweenService:Create(building.Effect, TweenInfo.new(1.5,Enum.EasingStyle.Linear),{Position = Vector3.new(effectPos.X,effectPos.Y + 3,effectPos.Z)}):Play()
	wait(1.5)
	building.Effect.BillboardGui.Timer.Text = "1"
	building.Effect.Position = effectPos
	tweenService:Create(building.Effect, TweenInfo.new(1.5,Enum.EasingStyle.Linear),{Position = Vector3.new(effectPos.X,effectPos.Y + 3,effectPos.Z)}):Play()
	wait(1.5)
	for i, resourse in ipairs(workspace.Buildings:GetChildren()) do
		if resourse:FindFirstChild("TargetFolder") then
			if resourse.TargetFolder.Value:FindFirstChild("Health") then
				local targetRange = (resourse.PrimaryPart.Position - building.PrimaryPart.Position).Magnitude
				if targetRange <= range then
					if checkBang(resourse) then
						resourse.TargetFolder.Value.Health.Value -= 50
						if resourse.TargetFolder.Value.Health.Value <= 0 then
							events.Workers.GenerateChest:Fire(resourse)
						end
					end
				end
			end
		end
	end
	building:Destroy()
end

events.Placement.PlaceFromInventory.OnServerEvent:Connect(function(player, pos, building)
	local targetBuilding = playerFolder.Inventory:FindFirstChild(building)
	if targetBuilding then
		local object = game.ReplicatedStorage.Buildings:FindFirstChild(building)
		if building == "Bang" then
			local newObejct = object:Clone()
			newObejct.Parent = workspace.Buildings
			newObejct:PivotTo(pos)
			bangAnimationAndExplosion(newObejct)
		else
			targetBuilding.Value -= 1
			local newObejct = object:Clone()
			newObejct.Parent = workspace.Buildings
			newObejct:PivotTo(pos)
			createFolderValue(newObejct)
		end
	end
end)

events.Placement.Spin.OnServerEvent:Connect(function(player, building, item,quanity)
	if playerFolder:FindFirstChild(item) then
		playerFolder:FindFirstChild(item).Value += quanity
	else
		if playerFolder.Inventory:FindFirstChild(item) then
			playerFolder.Inventory:FindFirstChild(item).Value += quanity
		else
			local newValue = Instance.new("NumberValue", playerFolder.Inventory)
			newValue.Name = item
			newValue.Value = quanity
		end
	end
	building.TargetFolder.Value.Timer.Value = convertTime(os.time()) + 86400
	events.ToLocal.RefreshDane:FireAllClients()
end)

events.Placement.PlaceServer.Event:Connect(function(object)
	local price = buildingData[object.Name]["Cost"]
	if playerFolder.Coins.Value >= price then
		local newObejct = object:Clone()
		newObejct.Parent = workspace.Buildings
		newObejct:PivotTo(object.PrimaryPart.CFrame)
		newObejct.Union.Transparency = 0
		object:Destroy()
		createFolderValue(newObejct)
		effect(newObejct.PrimaryPart.Position, price,nil,"Coins")
	else
		object:Destroy()
	end
end)

events.Placement.Delete.OnServerEvent:Connect(function(p, building, price)
	building.TargetFolder.Value:Destroy()
	building:Destroy()
	playerFolder.Coins.Value += price
end)

events.Placement.Place.OnServerEvent:Connect(function(player, pos, building)
	local newBuilding = game.ReplicatedStorage.Buildings:FindFirstChild(building):Clone()
	newBuilding.Parent = workspace.Buildings
	newBuilding:PivotTo(pos)

	local typeo
	local value = findBuildingCost(newBuilding)
	if tonumber(value) then
		typeo = "Coins"
	else
		typeo = "RBucks"
	end
	local exp
	if buildingData[newBuilding.Name]["Exp"] then
		exp = buildingData[newBuilding.Name]["Exp"]
	end

	createFolderValue(newBuilding)

	effect(newBuilding.PrimaryPart.Position,value, exp, typeo)
end)

local function payment(building, level)
	local data = upgradeData[building.Name][level]
	for i, value in pairs(data) do
		if i % 2 == 0 then
			local item = data[i - 1]
			local number = value
			if item == "Coins" then
				playerFolder.Coins.Value -= number
			else
				playerFolder.Inventory:FindFirstChild(item).Value -= number
			end
		end
	end
end

events.Placement.Move.OnServerEvent:Connect(function(p, building, pos)
	building:PivotTo(pos)
	if building:FindFirstChild("TargetFolder") then
		if building.TargetFolder.Value:FindFirstChild("Status") then
			if building.TargetFolder.Value.Status.Value == "Afk" then
				building.WorkerObject.Value:PivotTo(building.AfkPos.CFrame)
			end
		end
	end
	pos = building.PrimaryPart.Position
	building.TargetFolder.Value.buildingPosition.Value = pos.X .. "x" .. pos.Y .. "x" .. pos.Z .. "x" .. building.PrimaryPart.Orientation.Y
end)

events.Placement.Upgrade.OnServerEvent:Connect(function(player, building, level)
	local fullName = building.Name .. "-" .. level
	local newBuilding = game.ReplicatedStorage.Buildings.Upgrades:FindFirstChild(fullName):Clone()
	if newBuilding then
		local primary = building.PrimaryPart
		local pos = primary.Position

		local targetValue = pos.X .. "x" .. pos.Y .. "x" .. pos.Z .. "x" .. primary.Orientation.Y

		local exp = buildingData[building.TargetFolder.Value.buildingName.Value]["Exp"]

		building.TargetFolder.Value:Destroy()

		payment(building,level)

		newBuilding.Parent = workspace.Buildings
		newBuilding:PivotTo(building.PrimaryPart.CFrame)
		building:Destroy()
		
		createFolderValue(newBuilding)
		
		newBuilding.Name = string.split(fullName,"-")[1]
		
		effect(pos,nil,exp,nil)
	else
		print("can find: " .. fullName)
	end
end)