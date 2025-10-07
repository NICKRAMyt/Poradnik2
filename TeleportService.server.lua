local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local placeId = game.PlaceId
local teleportDataKey = "teleported"

local function teleportPlayer(player,target)
	local joinData = player:GetJoinData()
	local teleportPreData = joinData and joinData.TeleportData

	local teleportData = {}
	
	if target then
		teleportData[teleportDataKey] = target
	else
		teleportData[teleportDataKey] = "Home"
	end

	game.ReplicatedStorage.NewEvents.Save:Fire(player)
	wait(1)
	TeleportService:Teleport(placeId, player, teleportData)
end

local function disableGui(player,argument)
	if argument == false then
		player.PlayerGui:WaitForChild("NewGameGui"):Destroy()
		player.PlayerGui.FriendsGui.LocalScriptFriend.Enabled = true
		for i, guis in ipairs(player.PlayerGui.FriendsGui:GetChildren()) do
			guis.Enabled = true
		end
	else
		player.PlayerGui:WaitForChild("FriendsGui"):Destroy()
		player.PlayerGui.NewGameGui.LocalScriptGame.Enabled = true
		for i, guis in ipairs(player.PlayerGui.NewGameGui:GetChildren()) do
			guis.Enabled = true
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData

	if (teleportData and teleportData[teleportDataKey]) or workspace.IsFriend.Value > 0 then
		if workspace.IsFriend.Value > 0 then
			disableGui(player,false)
		elseif teleportData[teleportDataKey] == "Home" then
			disableGui(player,true)
		else
			workspace.IsFriend.Value = teleportData[teleportDataKey]
			disableGui(player,false)
		end
	else
		disableGui(player,true)
	end
end)

game.ReplicatedStorage.NewEvents.ToLocal.GoToFriend.OnServerEvent:Connect(function(plr,target)
	teleportPlayer(plr,target)
end)