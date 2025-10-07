local starterData = require(game.ReplicatedStorage.Modules.StarterData)
local resourseData = require(game.ReplicatedStorage.Modules.RousursesData)
local workTime = require(game.ReplicatedStorage.Modules.WorkersTime)
local inventoryData = require(game.ReplicatedStorage.Modules.InventoryItems)
local buildingModule = require(game.ReplicatedStorage.Modules.Buildings)
local workersModule = require(game.ReplicatedStorage.Modules.Buildings.Workers)

local saveFriends = require(game.ServerStorage.Save.Friends)

local players = game.Players

local HttpService = game:GetService("HttpService")
local apiUrl = "https://u3l13.zse-e.edu.pl/projekty/Web/DataBase.html"

local function ConvertFolderToTable(folder)
	local data = {}

	for _, item in pairs(folder:GetChildren()) do
		if item:IsA("Folder") then
			data[item.Name] = ConvertFolderToTable(item)
		elseif item:IsA("ValueBase") then
			local key = tonumber(item.Name) or item.Name
			data[key] = item.Value
		end
	end

	return data
end

local function getData(data)
	local jsonData = HttpService:JSONEncode(data)
	local response = HttpService:PostAsync(apiUrl, jsonData, Enum.HttpContentType.ApplicationJson)

	if response == "no data" then
		return nil
	end
	
	local decodedData = HttpService:JSONDecode(response)
	
	return decodedData
end

local function save(player)
	local folder = game.ReplicatedStorage:FindFirstChild("PlayerData")
	
	local data = {
		id = player.UserId,
		username = player.Name,
		level = folder.Level.Value,
		coins = folder.Coins.Value,
		rdolce = folder.RDolce.Value,
		experience = folder.Experience.Value,
		talons = folder.Talons.Value,
		brains = ConvertFolderToTable(folder.Brains),
		['settings'] = ConvertFolderToTable(folder.Settings),
		buildings = ConvertFolderToTable(folder.Buildings),
		resourses = ConvertFolderToTable(folder.Resourses),
		quests = ConvertFolderToTable(folder.Quests),
		inventory = ConvertFolderToTable(folder.Inventory),
		unlockedItems = ConvertFolderToTable(folder.UnlockedItems),
		collections = ConvertFolderToTable(folder.Collections),
		expansions = ConvertFolderToTable(folder.Expansions),
		islands = ConvertFolderToTable(folder.Islands),
		loadedPlaces = ConvertFolderToTable(folder.LoadedPlaces),
		codes = ConvertFolderToTable(folder.Codes),
		lastActive = os.date("%Y-%m-%d %H:%M:%S"),
		sendedPresents = ConvertFolderToTable(folder.SendedGifts),
	}

	local jsonData = HttpService:JSONEncode(data)
	local response = HttpService:PostAsync(apiUrl, jsonData, Enum.HttpContentType.ApplicationJson)
	
	print(response)
end

game.ReplicatedStorage.NewEvents.Save.Event:Connect(function(plr)
	save(plr)
end)

function tableToInstance(parent, data)
	for key, value in pairs(data) do
		if key == "id" then
			local stringValue = Instance.new("StringValue")
			stringValue.Name = key
			stringValue.Value = tostring(value)
			stringValue.Parent = parent
		elseif type(value) == "string" then
			local stringValue = Instance.new("StringValue")
			stringValue.Name = key
			stringValue.Value = value
			stringValue.Parent = parent
		elseif type(value) == "number" then
			local numberValue = Instance.new("NumberValue")
			numberValue.Name = key
			numberValue.Value = value
			numberValue.Parent = parent
		elseif typeof(value) == "Vector3" then
			local vectorValue = Instance.new("Vector3Value")
			vectorValue.Name = key
			vectorValue.Value = value
			vectorValue.Parent = parent
		elseif type(value) == "table" then
			local folder = Instance.new("Folder")
			folder.Name = key
			folder.Parent = parent
			tableToInstance(folder, value)
		end
	end
end

local function create(buildingData, folder,IsAResourse,isFriend)
	local newBuilding
	if game.ReplicatedStorage.Buildings:FindFirstChild(buildingData["buildingName"]) then
		newBuilding = game.ReplicatedStorage.Buildings:FindFirstChild(buildingData["buildingName"]):Clone()
	else
		newBuilding = game.ReplicatedStorage.Buildings.Upgrades:FindFirstChild(buildingData["buildingName"]):Clone()
		newBuilding.Name = string.split(newBuilding.Name,"-")[1]
	end
	newBuilding.Parent = workspace.Buildings

	local splittedvalue = string.split(buildingData["buildingPosition"],"x")
	local pos = Vector3.new(splittedvalue[1], splittedvalue[2], splittedvalue[3])
	local cframe = CFrame.new(pos) * CFrame.Angles(0,math.rad(splittedvalue[4]), 0)
	
	local targetValue
	
	if not IsAResourse then
		targetValue = Instance.new("ObjectValue", newBuilding)
		targetValue.Name = "TargetFolder"
		if isFriend then
			targetValue.Value = game.ReplicatedStorage:FindFirstChild("FriendData").Buildings:FindFirstChild(folder)
		else
			targetValue.Value = game.ReplicatedStorage:FindFirstChild("PlayerData").Buildings:FindFirstChild(folder)
		end
	end
	
	local function createWorker()
		local newValue = Instance.new("ObjectValue", newBuilding)
		newValue.Name = "WorkerObject"

		local worker = newBuilding


		local target

		if not worker.TargetFolder.Value:FindFirstChild("id") then
			local idValue = Instance.new("StringValue", targetValue.Value)
			idValue.Name = "id"
			idValue.Value = ""

			local timerValue = Instance.new("NumberValue", targetValue.Value)
			timerValue.Name = "Timer"
			timerValue.Value = -1

			local items = Instance.new("NumberValue", targetValue.Value)
			items.Name = "Items"
			items.Value = 0

			local statusValue = Instance.new("StringValue", targetValue.Value)
			statusValue.Name = "Status"
			statusValue.Value = "None"
		end
		--do zmiany
		for i, targets in ipairs(workspace.Buildings:GetChildren()) do
			if targets:FindFirstChild("TargetFolder") then
				if targets.TargetFolder.Value then
					if targets.TargetFolder.Value:FindFirstChild("Health") then
						if targets.TargetFolder.Value.id.Value == worker.TargetFolder.Value.id.Value then
							target = targets
						end
					end
				end
			end
		end

		--print(target)
		if target then
			while buildingData["Timer"] < convertTime(os.time()) and worker.TargetFolder.Value.Items.Value < 3 and target.TargetFolder.Value.Health.Value > 0 do
				buildingData["Timer"] += workTime[newBuilding.Name]
				worker.TargetFolder.Value.Timer.Value = buildingData["Timer"]
				target.TargetFolder.Value.Health.Value -= 1
				worker.TargetFolder.Value.Items.Value += 1
			end
			if target.TargetFolder.Value.Health.Value == 0 then
				game.ReplicatedStorage.NewEvents.Workers.GenerateChest:Fire(target)
			end
		end
		if buildingModule[worker.Name]["Pile-Y"] then
			local pos = worker.PrimaryPart.Position.Y + buildingModule[worker.Name]["Pile-Y"]
			if worker.TargetFolder.Value.Items.Value >= 1 then
				worker.Pile.Pile3.Transparency = 0
				worker.Pile.Pile3.Position = Vector3.new(worker.Pile.Pile3.Position.X, pos,worker.Pile.Pile3.Position.Z)
				if worker.TargetFolder.Value.Items.Value >= 2 then
					worker.Pile.Pile2.Transparency = 0
					worker.Pile.Pile2.Position = Vector3.new(worker.Pile.Pile2.Position.X, pos,worker.Pile.Pile2.Position.Z)
					if worker.TargetFolder.Value.Items.Value >= 3 then
						worker.Pile.Pile1.Transparency = 0
						worker.Pile.Pile1.Position = Vector3.new(worker.Pile.Pile1.Position.X, pos,worker.Pile.Pile1.Position.Z)
					else
						worker.Pile.Pile1.Position = Vector3.new(worker.Pile.Pile3.Position.X, pos - 4,worker.Pile.Pile3.Position.Z)
						worker.Pile.Pile1.Transparency = 1
					end
				else
					worker.Pile.Pile2.Transparency = 1
					worker.Pile.Pile1.Transparency = 1
					worker.Pile.Pile1.Position = Vector3.new(worker.Pile.Pile3.Position.X, pos - 4,worker.Pile.Pile3.Position.Z)
					worker.Pile.Pile2.Position = Vector3.new(worker.Pile.Pile2.Position.X, pos - 4,worker.Pile.Pile2.Position.Z)
				end
			else
				worker.Pile.Pile3.Transparency = 1
				worker.Pile.Pile2.Transparency = 1
				worker.Pile.Pile1.Transparency = 1
				worker.Pile.Pile1.Position = Vector3.new(worker.Pile.Pile1.Position.X, pos - 4,worker.Pile.Pile1.Position.Z)
				worker.Pile.Pile2.Position = Vector3.new(worker.Pile.Pile2.Position.X, pos - 4,worker.Pile.Pile2.Position.Z)
				worker.Pile.Pile3.Position = Vector3.new(worker.Pile.Pile3.Position.X, pos - 4,worker.Pile.Pile3.Position.Z)
			end
		end
		if worker.TargetFolder.Value.id.Value ~= "" and worker.TargetFolder.Value.Items.Value < 3 and target then
			game.ReplicatedStorage.NewEvents.HumanoidMovement.RespawnWorker:Fire(worker)
		else
			if worker.TargetFolder.Value.Status.Value == "Working" or worker.TargetFolder.Value.Status.Value == "Afk" then
				game.ReplicatedStorage.NewEvents.HumanoidMovement.RespawnWorker:Fire(worker,true)
			end
		end
	end

	if game.ReplicatedStorage.Workers:FindFirstChild(buildingData["buildingName"]) then
		createWorker()
	elseif buildingData["buildingName"] == "Pot" then
		newBuilding:PivotTo(cframe)
		if not buildingData["Seed"] then
			local newValue3 = Instance.new("StringValue", targetValue.Value)
			newValue3.Name = "Seed"
			newValue3.Value = "None"

			local newValue4 = Instance.new("NumberValue", targetValue.Value)
			newValue4.Name = "SeedTime"
			newValue4.Value = -1

			local newValueSpecialnieDlaSwiatWgZombie = Instance.new("NumberValue", targetValue.Value)
			newValueSpecialnieDlaSwiatWgZombie.Name = "SeedStart"
			newValueSpecialnieDlaSwiatWgZombie.Value = -1
		else
			
		end
		if buildingData["Seed"] ~= "None" then
			game.ReplicatedStorage.NewEvents.Seeds.SeedPhase:Fire(newBuilding)
		end
	elseif workersModule[buildingData["buildingName"]] then
		if workersModule[buildingData["buildingName"]]["WorkerName"] then
			if game.ReplicatedStorage.Workers:FindFirstChild(workersModule[buildingData["buildingName"]]["WorkerName"]) then
				createWorker()
			end
		end
	end

	if IsAResourse then
		local targetValue = Instance.new("ObjectValue", newBuilding)
		targetValue.Name = "TargetFolder"
		targetValue.Value = game.ReplicatedStorage:FindFirstChild("PlayerData").Resourses:FindFirstChild(folder)
		
		if not buildingData["Health"] then
			local healthValue = Instance.new("NumberValue", targetValue.Value)
			healthValue.Name = "Health"
			healthValue.Value = resourseData[newBuilding.Name]["Health"]
		end
		
		if not buildingData["Status"] then
			local statusValue = Instance.new("StringValue", targetValue.Value)
			statusValue.Name = "Status"
			statusValue.Value = "None"
		end
		if not buildingData["id"] then
			local idValue = Instance.new("StringValue", targetValue.Value)
			idValue.Name = "id"
			idValue.Value = folder
		end
	elseif buildingData["buildingName"] == "Chest" then
		local targetValue = Instance.new("ObjectValue", newBuilding)
		targetValue.Name = "FolderObject"
		targetValue.Value = game.ReplicatedStorage:FindFirstChild("PlayerData").Buildings:FindFirstChild(folder)
	end
	newBuilding:PivotTo(cframe)
end

local function loadBuildings(data,isFriend)
	local i = 0
	for building, buildingData in pairs(data["Resourses"]) do
		create(buildingData,building,true,isFriend)
		i += 1
		if i == 10 then
			wait(0.05)
			i = 0
		end
	end
	for building, buildingData in pairs(data["Buildings"]) do
		create(buildingData, building,nil,isFriend)
		i += 1
		if i == 10 then
			wait(0.05)
			i = 0
		end
	end
end

local function loadExpansions(data)
	for i,expan in pairs(data["Expansions"]) do
		workspace.Expansions:FindFirstChild(i):Destroy()
		workspace.Block:FindFirstChild(i):Destroy()
	end
end

local function loadPresents(player,data)
	print("missing Code - G")
	-- if not game.ReplicatedStorage:FindFirstChild("PresentsData") then
	-- 	local newFolder = Instance.new("Folder",game.ReplicatedStorage)
	-- 	newFolder.Name = "PresentsData"
	-- end
	-- for i, folders in ipairs(game.ReplicatedStorage.PresentsData:GetChildren()) do
	-- 	folders:Destroy()
	-- end
	-- player = {["UserId"] = tostring(player.UserId)}
	-- local fullData
	-- if data then
	-- 	fullData = data
	-- else
	-- 	fullData = presentsBase:GetAsync("Presents") or {}
	-- end
	-- local playerData = fullData[player.UserId] or {["Limit"] = 10000, ["Presents"] = {},["Want"] = {}}
	-- for i, data in pairs(fullData) do
	-- 	if game.ReplicatedStorage.Friends:FindFirstChild(i) then
	-- 		newFolder = Instance.new("Folder", game.ReplicatedStorage.PresentsData)
	-- 		newFolder.Name = id
	-- 		tableToInstance(newFolder,data)
	-- 	end
	-- end
	-- createData(playerData,player.UserId)
end

game.ReplicatedStorage.NewEvents.Friends.AddFriend.OnServerEvent:Connect(function(plr, id)
	saveFriends.addFriend(plr,id)
end)

game.ReplicatedStorage.NewEvents.RequireData.OnServerInvoke = function(id)
	print("missing Code - E")
	-- if dataBase:GetAsync(id) then
	-- 	return true
	-- end
end

local resoursesData = require(game.ReplicatedStorage.Modules.ResoursesOnTheMapData)

local function checkResourses(data,tData)
	for name, value in pairs(resoursesData) do
		if not data["LoadedPlaces"][name] then
			print("Added newPlace: ".. name)
			data["LoadedPlaces"][name] = 1
			for i,x in pairs(value) do
				data[tData][i] = x
			end
		end
	end
	return data
end

local buildingOnTheMapData = require(game.ReplicatedStorage.Modules.BuildingsOnTheMap)

local function checkBuildings(data,tData)
	for name, value in pairs(buildingOnTheMapData) do
		if not data["LoadedPlaces"][name] then
			print("Added newPlace: ".. name)
			data["LoadedPlaces"][name] = 1
			for i,x in pairs(value) do
				data[tData][i] = x
			end
		end
	end
	return data
end

local function checkIfSomethingMissing(data)
	for dataName, i in pairs(starterData) do
		if not data[dataName] then
			data[dataName] = i
			print("Something New: ",dataName)
		end
	end
	return data
end

local function restart()
	warn("Restarting Data")
	return nil
end

local function formatDate(currentDate)
	for i, value in pairs(currentDate) do
		currentDate[i] = tonumber(value)
	end
	if currentDate.month < 10 then
		currentDate.month = "0" .. currentDate.month
	end
	if currentDate.day < 10 then
		currentDate.day = "0" .. currentDate.day
	end
	if currentDate.hour < 10 then
		currentDate.hour = "0" .. currentDate.hour
	end
	if currentDate.min < 10 then
		currentDate.min = "0" .. currentDate.min
	end

	local value = currentDate.year .. currentDate.month .. currentDate.day .. currentDate.hour .. currentDate.min
	return tonumber(value)
end

local function getCurrentDateFormat()
	local currentTime = os.time()
	local currentDate = os.date("!*t",currentTime)
	
	return formatDate(currentDate)
end

local dailyTime = {
	["Hour"] = 6, --+2 polska
	["Minute"] = 0,
}

local function restoreShovelsAndGifts(plr)
	print("missing Code - D")
	-- local playerFolder = game.ReplicatedStorage.PlayerData
	-- if not playerFolder:FindFirstChild("Friends") then
	-- 	return
	-- end
	-- for i, friends in ipairs(playerFolder.Friends:GetChildren()) do
	-- 	friends.Value = 5
	-- end
	-- local todayDate = os.date("!*t",os.time())
	-- todayDate.min = dailyTime["Minute"] + 1
	-- todayDate.hour = dailyTime["Hour"]
	-- playerFolder.LastEnter.Value = formatDate(todayDate)
	-- local fullData = presentsBase:GetAsync("Presents") or {}
	-- if not fullData[tostring(plr.UserId)] then
	-- 	fullData[tostring(plr.UserId)] = {["Limit"] = 10000, ["Presents"] = {},["Want"] = {}}
	-- else
	-- 	fullData[tostring(plr.UserId)]["Limit"] = 10000
	-- end
	-- for i, sendedPresents in ipairs(playerFolder.SendedGifts:GetChildren()) do
	-- 	sendedPresents:Destroy()
	-- end
	-- presentsBase:SetAsync("Presents",fullData)
end

local function checkIfCanRestoreShovelsAndGifts(plr)
	print("missing code - J")
	-- local playerFolder = game.ReplicatedStorage.PlayerData
	-- if playerFolder.LastEnter.Value ~= 0 then
	-- 	local todayDate = os.date("!*t",os.time())
	-- 	todayDate.min = dailyTime["Minute"]
	-- 	todayDate.hour = dailyTime["Hour"]
	-- 	if formatDate(todayDate) >= playerFolder.LastEnter.Value then
	-- 		restoreShovelsAndGifts(plr)
	-- 	end
	-- 	if getCurrentDateFormat() > playerFolder.LastEnter.Value then
	-- 		playerFolder.LastEnter.Value = getCurrentDateFormat()
	-- 	end
	-- else
	-- 	playerFolder.LastEnter.Value = getCurrentDateFormat()
	-- 	restoreShovelsAndGifts(plr)
	-- end
end

local function saveWanting(plr)
	print("missing code - C")
	-- plr = {["UserId"] = tostring(plr.UserId)}
	-- local wanting = {}
	-- for i, items in ipairs(game.ReplicatedStorage.PresentsData.PlayerData.Want:GetChildren()) do
	-- 	wanting[items.Name] = items.Value
	-- end
	-- local data = presentsBase:GetAsync("Presents") or {}
	-- local playerData = data[plr.UserId] or {["Limit"] = 10000, ["Presents"] = {},["Want"] = {}}
	-- playerData["Want"] = wanting
	-- data[plr.UserId] = playerData
	-- presentsBase:SetAsync("Presents",data)
end

game.ReplicatedStorage.NewEvents.Friends.DeleteFromWanting.OnServerEvent:Connect(function(plr,slot,item)
	game.ReplicatedStorage.PresentsData.PlayerData.Want:FindFirstChild(slot):Destroy()
	saveWanting(plr)
end)

game.ReplicatedStorage.NewEvents.Friends.RefreshGifts.OnServerEvent:Connect(function(plr)
	loadPresents(plr)
end)

game.ReplicatedStorage.NewEvents.Friends.AddToWanting.OnServerEvent:Connect(function(plr,slot,item)
	for i, items in ipairs(game.ReplicatedStorage.PresentsData.PlayerData.Want:GetChildren()) do
		if items.Value == item then
			items:Destroy()
		end
	end 
	local newValue = Instance.new("StringValue", game.ReplicatedStorage.PresentsData.PlayerData.Want)
	newValue.Value = item
	newValue.Name = slot
	saveWanting(plr)
end)

game.ReplicatedStorage.NewEvents.Friends.AcceptGift.OnServerEvent:Connect(function(plr,present,sold)
	print("missing code - B")
	-- present = {["Name"] = tonumber(present.Name)}
	-- local fullData = presentsBase:GetAsync("Presents")
	-- if sold then
	-- 	if fullData[tostring(plr.UserId)]["Presents"][present.Name] then
	-- 		local price = inventoryData[fullData[tostring(plr.UserId)]["Presents"][present.Name]["Item"]][1]
	-- 		game.ReplicatedStorage.PlayerData.Coins.Value += price * fullData[tostring(plr.UserId)]["Presents"][present.Name]["Quanity"]
	-- 	end
	-- else
	-- 	if fullData[tostring(plr.UserId)]["Presents"][present.Name] then
	-- 		local itemName = fullData[tostring(plr.UserId)]["Presents"][present.Name]["Item"]
	-- 		local item = game.ReplicatedStorage.PlayerData.Inventory:FindFirstChild(itemName)
	-- 		if item then
	-- 			item.Value += fullData[tostring(plr.UserId)]["Presents"][present.Name]["Quanity"]
	-- 		else
	-- 			local newValue = Instance.new("NumberValue",game.ReplicatedStorage.PlayerData.Inventory)
	-- 			newValue.Name = itemName
	-- 			newValue.Value = item
	-- 		end
	-- 	end
	-- end
	-- if fullData[tostring(plr.UserId)]["Presents"][present.Name] then
	-- 	fullData[tostring(plr.UserId)]["Presents"][present.Name] = nil
	-- end
	-- game.ReplicatedStorage.NewEvents.ToLocal.RefreshDane:FireAllClients()
	-- loadPresents(plr,fullData)
	-- presentsBase:SetAsync("Presents",fullData)
end)

game.ReplicatedStorage.NewEvents.Friends.SendGifts.OnServerEvent:Connect(function(plr,values,isFree)
	print("missing code - A")
	-- local fullData = presentsBase:GetAsync("Presents") or {}
	-- for friendId, value in pairs(values) do
	-- 	if value["Message"] == "Write Message" then
	-- 		value["Message"] = ""
	-- 	end
	-- 	if not fullData[friendId] then
	-- 		fullData[friendId] = {["Limit"] = 10000, ["Presents"] = {},["Want"] = {}}
	-- 	end
	-- 	if isFree then
	-- 		if game.ReplicatedStorage.PlayerData.SendedGifts:FindFirstChild(friendId) then
	-- 			print("Can't send - 2")
	-- 		else
	-- 			table.insert(fullData[friendId]["Presents"],value)
	-- 			local newValue = Instance.new("NumberValue", game.ReplicatedStorage.PlayerData.SendedGifts)
	-- 			newValue.Name = friendId
	-- 			newValue.Value = 1
	-- 		end
	-- 	else
	-- 		if inventoryData[value["Item"]] then
	-- 			if fullData[friendId]["Limit"] < inventoryData[value["Item"]][1] * value["Quanity"] then
	-- 				print("Can't send - 1")
	-- 			else
	-- 				fullData[friendId]["Limit"] = fullData[friendId]["Limit"] - inventoryData[value["Item"]][1] * value["Quanity"]
	-- 				table.insert(fullData[friendId]["Presents"],value)
	-- 				local newValue = Instance.new("NumberValue", game.ReplicatedStorage.PlayerData.SendedGifts)
	-- 				game.ReplicatedStorage.PlayerData.Inventory:FindFirstChild(value["Item"]).Value -= value["Quanity"]
	-- 			end
	-- 		end
	-- 	end
	-- end
	-- loadPresents(plr,fullData)
	-- presentsBase:SetAsync("Presents",fullData)
end)

local function randomTresureGenerator()
	if workspace.IsFriend.Value > 0 then
		local total = #workspace.Buildings:GetChildren()
		local draws = math.ceil(total / 15)
		local winning = {}
		for i=1, draws do
			local random = -1
			while random < 0 or winning[random] do
				random = math.random(1,total)
			end
			winning[random] = 0
		end
		for i,building in ipairs(workspace.Buildings:GetChildren()) do
			if winning[i] then
				local newValue = Instance.new("IntValue",building)
				newValue.Name = "TreasurePot"
				newValue.Value = math.random(4,6)
			end
		end
	end
end

local function checkBrains()
	local requiredBrains = require(game.ReplicatedStorage.Modules.WorkersTime.WorkersBrains)
	local maxBrains = #game.ReplicatedStorage.PlayerData.Brains:GetChildren()
	local brains = 0
	for i, buildings in ipairs(workspace.Buildings:GetChildren()) do
		if buildings:FindFirstChild("TargetFolder") and buildingModule[buildings.Name] then
			local status = buildings.TargetFolder.Value:FindFirstChild("Status") 
			if status and buildingModule[buildings.Name]["Worker"] then
				if status.Value == "Afk" or status.Value == "Active" then
					if brains + requiredBrains[buildings.Name]["Brains"] <= maxBrains then
						print("good", buildings)
						brains += requiredBrains[buildings.Name]["Brains"]
					else
						print("need to reset status and reset target status")
					end
				end
			end
		end
	end
	workspace.UsingBrains.Value = brains
	game.ReplicatedStorage.NewEvents.ToLocal.RefreshDane:FireAllClients()
end

local function load(player,breakk)
	local key = player.UserId
	local data = getData({method = "getData",id = player.UserId,})

	if not data then
		print("New Data")
		data = starterData
	end
	data = checkResourses(data,"Resourses")
	data = checkBuildings(data,"Buildings")
	data = checkIfSomethingMissing(data)
	--dataBase:SetAsync(key,data)
	
	local folder = Instance.new("Folder",game.ReplicatedStorage)
	if breakk then
		folder.Name = "FriendData"
	else
		folder.Name = "PlayerData"
	end
	tableToInstance(folder,data)
	
	if not breakk then
		saveFriends.loadAddedFriends(player)
		coroutine.wrap(saveFriends.loadFriends)(player)
		wait(1)
		checkIfCanRestoreShovelsAndGifts(player)
		loadExpansions(data)
	end
	wait(0.5)
	if workspace.IsFriend.Value == 0 or breakk then
		loadBuildings(data,breakk)
		checkBrains()
		randomTresureGenerator()
	else
		print("Loading Friend Data: ", workspace.IsFriend.Value)
		local playerFolder = game.ReplicatedStorage.PlayerData
		if not playerFolder.Friends:FindFirstChild(workspace.IsFriend.Value) then
			local newFolder = Instance.new("NumberValue", playerFolder.Friends)
			newFolder.Value = 5
			newFolder.Name = workspace.IsFriend.Value
		else
			workspace.Shovels.Value = playerFolder.Friends:FindFirstChild(workspace.IsFriend.Value).Value
		end
		load({["UserId"] = workspace.IsFriend.Value},true)
	end
end

game.ReplicatedStorage.NewEvents.Settings.OnServerEvent:Connect(function(plr,what)
	local folder = game.ReplicatedStorage:FindFirstChild("PlayerData").Settings
	if what == "ZoomOut" then
		if folder.Zoom.Value < 1.25 then
			folder.Zoom.Value += 0.05
		end
	elseif what == "ZoomIn" then
		if folder.Zoom.Value > 1 then
			folder.Zoom.Value -= 0.05
		end
	elseif what == "ClearQueue" then
		game.ReplicatedStorage.NewEvents.Workers.ClearQueue:Fire()
	else
		if folder[what].Value == 1 then
			folder[what].Value = 0
		else
			folder[what].Value = 1
		end
	end
end)

players.PlayerAdded:Connect(function(player)
	load(player)
end)

players.PlayerRemoving:Connect(function(player)
	save(player)
end)

while true do
	wait(30)
	for i,player in ipairs(players:GetChildren()) do
		if player then
			save(player)
		end
	end
end