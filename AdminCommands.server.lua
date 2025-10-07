local players = game.Players

local admins = {"NICKRAM13"}

local items = require(game.ReplicatedStorage.Modules.InventoryItems)

local function addMaxItems()
	for item, x in pairs(items) do
		local targetItem = game.ReplicatedStorage.PlayerData.Inventory:FindFirstChild(item)
		if targetItem then
			targetItem.Value = 999
		else
			local target = Instance.new("NumberValue",game.ReplicatedStorage.PlayerData.Inventory)
			target.Name = item
			target.Value = 999
		end
	end
end

players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(s)
		--if table.find(admins,player.Name) then
			if s == "!max" then
				addMaxItems()
			elseif s == "!lvl" then
				if table.find(admins,player.Name) then
					game.ReplicatedStorage.PlayerData.Experience.Value = 6969431
					game.ReplicatedStorage.PlayerData.Level.Value = 67
					game.ReplicatedStorage.NewEvents.ToLocal.RefreshDane:FireAllClients()
				end
			end
		--end
	end)
end)