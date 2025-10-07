while not game.ReplicatedStorage:FindFirstChild("PlayerData") do
	wait(0.5)
end

local playerFolder = game.ReplicatedStorage.PlayerData
local events = game.ReplicatedStorage.NewEvents.Shop

local shopdata = require(game.ReplicatedStorage.Modules.StoreData)
local inventoryData = require(game.ReplicatedStorage.Modules.InventoryItems)
local collectionData = require(game.ReplicatedStorage.Modules.CollectionData)

events.Unlock.OnServerEvent:Connect(function(player,dane)
	if not playerFolder.UnlockedItems:FindFirstChild(dane[1]) then
		if playerFolder.RDolce.Value >= dane[3] then
			playerFolder.RDolce.Value -= dane[3]
			local newValue = Instance.new("NumberValue",playerFolder.UnlockedItems)
			newValue.Name = dane[1]
		end
	end
end)

local function unlockExpansion(name)
	local newValue = Instance.new("NumberValue", playerFolder.Expansions)
	newValue.Name = name
	newValue.Value = 0
	
	workspace.Expansions:FindFirstChild(name):Destroy()
	workspace.Block:FindFirstChild(name):Destroy()
end

events.Sell.OnServerEvent:Connect(function(player, item, quanity)
	local targetItem = playerFolder.Inventory:FindFirstChild(item)
	if targetItem then
		if targetItem.Value >= quanity then
			targetItem.Value -= quanity
			local price = inventoryData[item][1]
			playerFolder.Coins.Value += price * quanity
			if targetItem.Value == 0 then
				targetItem:Destroy()
			end
		end
	else
		warn("Can't find",item,"in inventory")
	end
end)

events.ExchangeCollection.OnServerEvent:Connect(function(plr, collection, ammount)
	local collectionFolder = playerFolder.Collections:FindFirstChild(collection)
	if collectionFolder then
		if #collectionFolder:GetChildren() == 5 then
			local min = nil
			for i, itemCollection in ipairs(collectionFolder:GetChildren()) do
				if not min then
					min = itemCollection.Value
				elseif min > itemCollection.Value then
					min = itemCollection.Value
				end
			end
			if min >= ammount then
				for i, itemCollection in ipairs(collectionFolder:GetChildren()) do
					itemCollection.Value -= ammount
					if itemCollection.Value == 0 then
						itemCollection:Destroy()
					end
				end
			end
			local reward = collectionData["Collections"][collection]["Reward"]
			local splittedReward = string.split(reward,"/")
			for i, rewardItems in pairs(splittedReward) do
				local rewardItem = string.split(rewardItems,"-")
				if playerFolder:FindFirstChild(rewardItem[2]) then
					playerFolder:FindFirstChild(rewardItem[2]).Value += rewardItem[1]  * ammount
				else
					if playerFolder.Inventory:FindFirstChild(rewardItem[2]) then
						playerFolder.Inventory:FindFirstChild(rewardItem[2]).Value += rewardItem[1]  * ammount
					else
						local newValue = Instance.new("NumberValue",playerFolder.Inventory)
						newValue.Name = rewardItem[2]
						newValue.Value = rewardItem[1] * ammount
					end
				end
			end
		end
	end
	events.Parent.ToLocal.RefreshDane:FireAllClients()
end)

events.UnlockExpansion.OnServerEvent:Connect(function(player, expansion,price)
	if expansion == "Mountain Top" and price == 70 and not playerFolder.Expansions:FindFirstChild("Mountain Top") then
		if playerFolder.RDolce.Value >= 70 then
			playerFolder.RDolce.Value -= 70
			unlockExpansion("Mountain Top")
			
			local newItem1 = game.ReplicatedStorage.Buildings.UpperTunnel:Clone()
			newItem1.Parent = workspace.Buildings
			newItem1:PivotTo(CFrame.new(Vector3.new(-84.5, 12.5, 87.5)))
			
			local newFolder = Instance.new("Folder",playerFolder.Buildings)
			newFolder.Name = newItem1.Name .. #playerFolder.Buildings:GetChildren()

			local primary = newItem1.PrimaryPart
			local pos = primary.Position

			local newValue2 = Instance.new("StringValue", newFolder)
			newValue2.Name = "buildingName"
			newValue2.Value = newItem1.Name

			local newValue = Instance.new("StringValue", newFolder)
			newValue.Name = "buildingPosition"
			newValue.Value = pos.X .. "x" .. pos.Y .. "x" .. pos.Z .. "x" .. primary.Orientation.Y
			
			local newItem2 = game.ReplicatedStorage.Buildings.LowerTunnel:Clone()
			newItem2.Parent = workspace.Buildings
			newItem2:PivotTo(CFrame.new(Vector3.new(-71.5, 1.5, 91)))

			local newFolder2 = Instance.new("Folder",playerFolder.Buildings)
			newFolder2.Name = newItem2.Name .. #playerFolder.Buildings:GetChildren()

			local primary2 = newItem2.PrimaryPart
			local pos2 = primary2.Position

			local newValue2a = Instance.new("StringValue", newFolder2)
			newValue2a.Name = "buildingName"
			newValue2a.Value = newItem2.Name

			local newValuea = Instance.new("StringValue", newFolder2)
			newValuea.Name = "buildingPosition"
			newValuea.Value = pos2.X .. "x" .. pos2.Y .. "x" .. pos2.Z .. "x" .. primary2.Orientation.Y
			
		end
	elseif expansion == "Behind The Fence" and price == 25 and not playerFolder.Expansions:FindFirstChild("Behind The Fence") then
		if playerFolder.RDolce.Value >= 25 then
			playerFolder.RDolce.Value -= 25
			unlockExpansion("Behind The Fence")
		end
	elseif expansion == "Behind The Fence" and price == 400000 and not playerFolder.Expansions:FindFirstChild("Behind The Fence") then
		if playerFolder.Coins.Value >= 400000 then
			playerFolder.Coins.Value -= 400000
			unlockExpansion("Behind The Fence")
		end
	end
end)

events.Craft.OnServerEvent:Connect(function(player, data)
	for i=1,2 do
		if data[(i-1) * 2 + 1] == "Coins" then
			playerFolder.Coins.Value -= data[i*2]
		else
			playerFolder.Inventory:FindFirstChild(data[(i-1) * 2 + 1]).Value -= data[i*2]
		end
	end
	if data[5] == "Coins" then
		playerFolder.Coins.Value += data[6]
	elseif data[5] == "RBucks" then
		playerFolder.RDolce.Value += data[6]
	else
		local itemInstance = playerFolder.Inventory:FindFirstChild(data[5])
		if not itemInstance then
			local newValue = Instance.new("NumberValue", playerFolder.Inventory)
			newValue.Value = data[6]
			newValue.Name = data[5]
		else
			itemInstance.Value += data[6]
		end
	end
end)

events.LevelUp.OnServerEvent:Connect(function(player)
	playerFolder.Level.Value += 1
end)

events.Delete.OnServerEvent:Connect(function(plr,item)
	if item:IsDescendantOf(game.ReplicatedStorage.PlayerData.Inventory) then
		item:Destroy()
	end
end)

events.BuyItems.OnServerEvent:Connect(function(player, item, number,bang,forCoins)
	local function add()
		local itemInstance = playerFolder.Inventory:FindFirstChild(item)
		if itemInstance then
			itemInstance.Value += number
		else
			local newValue = Instance.new("NumberValue", playerFolder.Inventory)
			newValue.Value = number
			newValue.Name = item
		end
	end
	local price
	if bang then
		price = bang
		if item == "Super" then
			item = "Super Shovel"
		elseif item == "Bangs" then
			item = "Bang"
		end
	else
		price = inventoryData[item][2] * number
	end
	if forCoins then
		if playerFolder.Coins.Value >= price then
			playerFolder.Coins.Value -= price
			add()
		end
	else
		if playerFolder.RDolce.Value >= price then
			playerFolder.RDolce.Value -= price
			add()
		end
	end
end)