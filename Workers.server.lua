while not game.ReplicatedStorage:FindFirstChild("PlayerData") do
	wait(0.5)
end

local playerFolder = game.ReplicatedStorage.PlayerData

local events = game.ReplicatedStorage.NewEvents.Workers
local runService = game["Run Service"]
local humanoidEvents = game.ReplicatedStorage.NewEvents.HumanoidMovement
local tweenService = game.TweenService
local workerScripts = game.ServerStorage.Workers

local function convertTime(times)
	return times - 1715514260
end

local humanoidStatus = {}

local workTime = require(game.ReplicatedStorage.Modules.WorkersTime)

local storeData = require(game.ReplicatedStorage.Modules.StoreData)
local buildingModule = require(game.ReplicatedStorage.Modules.Buildings)
local workersData = require(game.ReplicatedStorage.Modules.WorkersTime.WorkersBrains)
local walkToModule = require(workerScripts.WalkTo)
local lauchObjectModule = require(workerScripts.LauchObjects)
local collectModule = require(workerScripts.CollectModule)
local collectFriendModule = require(workerScripts.CollectFriendModule)
local changeVisulationModule = require(workerScripts.ChangeVisulation)
local collectionData = require(game.ReplicatedStorage.Modules.CollectionData)

humanoidEvents.AddToQueue.OnServerEvent:Connect(function(player,object,isLocal,special)
	collectModule.AddToQueue(player,object,isLocal,special)
end)

local function stoneMiner(worker,newWorker,afk)
	if afk then
		newWorker.AfkItem.Afk1.Transparency = 0
		worker.BigKon.Transparency = 1
	else
		newWorker.AfkItem.Afk1.Transparency = 1
		worker.BigKon.Transparency = 0
	end
end

local function disableAnimations(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		local tracks = animator:GetPlayingAnimationTracks()
		for _, track in ipairs(tracks) do
			track:Stop()
		end
	end
end

local function showOrHide(parent, tryb)
	if tryb == true then
		for i, parts in ipairs(parent:GetChildren()) do
			parts.Transparency = 1
		end
	else
		for i, parts in ipairs(parent:GetChildren()) do
			parts.Transparency = 0
		end
	end
end

humanoidEvents.PlayerMovement.OnServerEvent:Connect(function(player, pos)
	if workspace.IsFriend.Value == 0 then
		collectModule.goToCursor(pos)
	else
		collectFriendModule.goToCursor(pos)
	end
end)

local function restartingPosition(worker,newWorker)
	while true do
		newWorker:PivotTo(worker.AfkPos.CFrame)
		wait(5)
		if worker and newWorker then
			if worker.TargetFolder.Value.Status.Value ~= "Afk" then
				return
			end
		else
			return
		end
	end
end

local function afk(worker, newWorker)
	if worker.Name == "Stoneminer" then
		stoneMiner(worker,newWorker,true)
	end
	worker.Particle.Part.Transparency = 0
	worker.Particle.Beam.Beam.Enabled = true
	changeVisulationModule.changeVisulation(worker)
	worker.TargetFolder.Value.Status.Value = "Afk"
	coroutine.wrap(restartingPosition)(worker,newWorker)
	for i, items in ipairs(newWorker.AfkItem:GetDescendants()) do
		if items:IsA("UnionOperation") or items:IsA("Part") or items:IsA("Decal") then
			items.Transparency = 0
		end
	end
	local anim = newWorker.Humanoid:LoadAnimation(game.ReplicatedStorage.Animations[buildingModule[worker.Name]["Animation"] .. "-Afk"])
	anim:Play()
	wait(0.5)
	changeVisulationModule.changeVisulation(worker)
	newWorker:PivotTo(worker.AfkPos.CFrame)
end

events.Sleep.OnServerEvent:Connect(function(player, worker)
	worker.WorkerObject.Value.HumanoidRootPart.Sound:Stop()
	if worker.TargetFolder.Value.Status.Value == "Afk" then
		walkToModule.walkTo(worker.Respawn.Position, worker.WorkerObject.Value)
	else
		walkToModule.walkTo(worker.Target.Position, worker.WorkerObject.Value)
		walkToModule.walkTo(worker.Respawn.Position, worker.WorkerObject.Value)
	end
	if worker.TargetFolder.Value.id.Value ~= "" then
		print("code missing: ID-03")
		--[[
		local target = findTarget(worker.TargetFolder.Value.id.Value)
		if target then
			target.TargetFolder.Value.Status.Value = "None"
		end]]
	end
	worker.WorkerObject.Value:Destroy()
	worker.WorkerObject.Value = nil
	worker.TargetFolder.Value.Status.Value = "None"
	worker.TargetFolder.Value.id.Value = "None"
	worker.Particle.Part.Transparency = 1
	worker.Particle.Beam.Beam.Enabled = false
	print("need to add brains")
end)

events.GenerateChest.Event:Connect(function(building)
	local playerFolder = game.ReplicatedStorage:WaitForChild("PlayerData")
	local newChest = game.ReplicatedStorage.Buildings.Chest:Clone()
	newChest:PivotTo(building.PrimaryPart.CFrame)
	newChest.Parent = workspace.Buildings
	
	
	local newFolder = Instance.new("Folder",playerFolder.Buildings)
	newFolder.Name = #playerFolder.Buildings:GetChildren()
	
	local targetFolder = Instance.new("ObjectValue",newChest)
	targetFolder.Name = "FolderObject"
	targetFolder.Value = newFolder

	local primary = newChest.PrimaryPart
	local pos = primary.Position

	local newValue2 = Instance.new("StringValue", newFolder)
	newValue2.Name = "buildingName"
	newValue2.Value = newChest.Name

	local newValue = Instance.new("StringValue", newFolder)
	newValue.Name = "buildingPosition"
	newValue.Value = pos.X .. "x" .. pos.Y .. "x" .. pos.Z .. "x" .. primary.Orientation.Y
	
	building.TargetFolder.Value:Destroy()
	building:Destroy()
end)

workspace.Buildings.ChildAdded:Connect(function(item)
	if game.ReplicatedStorage.Workers:FindFirstChild(item.Name) then
		local worker = item
		worker:WaitForChild("TargetFolder").Value:WaitForChild("Items").Changed:Connect(function(change)
			if change == 2 and worker.TargetFolder.Value.Status.Value == "Afk" then
				local newWorker = worker.WorkerObject.Value
				wait(0.1)
				disableAnimations(newWorker.Humanoid)
				wait(0.1)
				newWorker:PivotTo(worker.AfkPos.CFrame)
				workerScripts.Work:Fire(worker,newWorker)
			end
		end)
	end
end)

local function work(worker, newWorker,target)
	for i, items in ipairs(newWorker.AfkItem:GetDescendants()) do -- zmiana przedmiotu
		if items:IsA("UnionOperator") or items:IsA("Part") or items:IsA("Decal") then
			items.Transparency = 1
		end
	end
	if worker.Name == "Stoneminer" then
		stoneMiner(worker,newWorker)
	end
	showOrHide(newWorker.LeftItem, false)
	showOrHide(newWorker.RightItem, true)
	
	
	if not target then
		print("code missing: ID-02")
		--[[target = findTarget(worker.TargetFolder.Value.id.Value)
		if not target then
			afk(worker,newWorker)
			return
		end]]
	end
	if newWorker then
		if target then
			walkToModule.walkTo(target.Target.Position,newWorker, target.PrimaryPart.Position)
		else
			afk(worker,newWorker)
			return
		end
	else
		return
	end
	
	showOrHide(newWorker.LeftItem, true)
	showOrHide(newWorker.RightItem, false)
	
	local anim = newWorker.Humanoid:LoadAnimation(game.ReplicatedStorage.Animations[worker.Name .. "-Chop"]) -- do zmiany
	newWorker.HumanoidRootPart.Sound:Play()
	anim:Play()
	newWorker.HumanoidRootPart.Anchored = true
	wait(5)
	newWorker.HumanoidRootPart.Anchored = false
	newWorker.HumanoidRootPart.Sound:Stop()
	disableAnimations(newWorker.Humanoid)
	if newWorker then
		if target then
			walkToModule.walkTo(target.Target.Position,newWorker, target.PrimaryPart.Position)
		else
			afk(worker,newWorker)
			return
		end
	else
		return
	end
	
	showOrHide(newWorker.LeftItem, false)
	showOrHide(newWorker.RightItem, true)
	
	if newWorker then
		if target then	
			walkToModule.walkTo(worker.Target.Position,newWorker)
		else
			afk(worker,newWorker)
			return
		end
	else
		return
	end
	if worker.TargetFolder.Value.Status.Value == "None" or worker.TargetFolder.Value.Items.Value == 3 then
		walkToModule.walkTo(worker.AfkPos.Position, newWorker)
		afk(worker,newWorker)
	else
		if worker.TargetFolder.Value.Timer.Value <= convertTime(os.time()) then
			worker.TargetFolder.Value.Items.Value += 1
			target.TargetFolder.Value.Health.Value -= 1
			changeVisulationModule.changeVisulation(worker)
			if worker.TargetFolder.Value.Items.Value == 3 or target.TargetFolder.Value.Health.Value == 0 then
				if target.TargetFolder.Value.Health.Value == 0 then
					worker.TargetFolder.Value.id.Value = "None"
				end
				coroutine.wrap(afk)(worker,newWorker)
			else
				worker.TargetFolder.Value.Timer.Value = workTime[worker.Name] + convertTime(os.time())
				work(worker,newWorker,target)
			end
			if target:FindFirstChild("TargetFolder") then
				if target.TargetFolder.Value.Health.Value == 0 then
					events.GenerateChest:Fire(target)
				end
			end
		else
			work(worker,newWorker,target)
		end
	end
end

workerScripts.Work.Event:Connect(function(worker, newWorker)
	worker.TargetFolder.Value.Status.Value = "Working"
	worker.TargetFolder.Value.Timer.Value = convertTime(os.time()) + workTime[worker.Name]
	walkToModule.walkTo(worker.Target.Position,newWorker)
	work(worker,newWorker)
end)

local function awake(worker, newWorker,target)
	if target then
		changeVisulationModule.changeVisulation(worker)
		worker.TargetFolder.Value.Status.Value = "Working"
		target.TargetFolder.Value.Status.Value = "Active"
		worker.Particle.Part.Transparency = 0
		worker.Particle.Beam.Beam.Enabled = true
		worker.TargetFolder.Value.id.Value = target.TargetFolder.Value.id.Value
		wait(1)
		--tutaj bedzie animacja respawnu kiedys
		walkToModule.walkToWithoutPathFinding(worker.Target.Position,newWorker)
		work(worker,newWorker,target)
	else
		print("can't find target, going to none")
		worker.TargetFolder.Value.Status.Value = "None"
		afk(worker,newWorker)
	end
end

local offsetOfTasks = require(workerScripts.Offset)

local function createNewWorker(worker,target)
	local newWorker = game.ReplicatedStorage.Workers:FindFirstChild(worker.Name):Clone()
	newWorker.Name = #workspace.Workers:GetChildren() + 1
	newWorker.Parent = workspace.Workers
	newWorker:PivotTo(worker.Respawn.CFrame)
	for i, parts in ipairs(newWorker:GetDescendants()) do
		if parts:IsA("BasePart") then
			parts.CollisionGroup = "Worker"
		end
	end

	worker.WorkerObject.Value = newWorker

	return newWorker
end

local conversionWorkerTypeToScript = {
	["Brigade"] = "Special",
	["Airplane"] = "Special",
	["Fisherman"] = "Random",
	["Treasure"] = "Random",
	["Cook"] = "Cooking",
}

events.Awake.OnServerEvent:Connect(function(player, worker,target)
	local converted = conversionWorkerTypeToScript[buildingModule[worker.Name]["Worker"]]
	if converted then
		if script.WorkersScripts:FindFirstChild(converted) then
			require(script.WorkersScripts:FindFirstChild(converted)).StartWorking(worker)
		end
	else
		if table.find(string.split(worker.Name," "),"Pair") then
			print("Found script by pair")
		else
			print("Found script by normal")
		end
	end
	--[[if target then
		if workspace.UsingBrains.Value <= #game.ReplicatedStorage.PlayerData.Brains:GetChildren() then
			worker.TargetFolder.Value.id.Value = target.TargetFolder.Value.id.Value
			if worker.WorkerObject.Value then -- gdy ma afk
				worker.TargetFolder.Value.Timer.Value = workTime[worker.Name] + convertTime(os.time())
				worker.TargetFolder.Value.Status.Value = "Working"
				local newWorker = worker.WorkerObject.Value
				disableAnimations(newWorker.Humanoid)
				work(worker,newWorker,target)
			else 
				worker.TargetFolder.Value.Timer.Value = workTime[worker.Name] + convertTime(os.time())
				local newWorker = createNewWorker(worker,target)
				awake(worker,newWorker,target)
			end
		else
			print("can't because don't have enought brains")
		end
	end]]
end)

humanoidEvents.AddToQueueFriend.OnServerEvent:Connect(function(plr, object)
	collectFriendModule.AddToQueue(plr,object)
end)

humanoidEvents.RespawnWorker.Event:Connect(function(worker,afkf)
	if afkf then
		local newWorker = createNewWorker(worker)
		afk(worker,newWorker)
	else
		wait(1)
		print("code missing: ID-01")
		--[[local target = findTarget(worker.TargetFolder.Value.id.Value)
		local newWorker = createNewWorker(worker,target)
		awake(worker,newWorker,target)]]
	end
end)

events.ClearQueue.Event:Connect(function()
	collectModule.ClearQueue()
	collectFriendModule.ClearQueue()
end)

workspace.CameraPart.ChangePosition.OnServerEvent:Connect(function(p,pos,rotation)
	workspace.CopiedCamera.CFrame = CFrame.new(pos + Vector3.new(0,10,0)) * CFrame.Angles(math.rad(rotation.X),math.rad(rotation.Y),math.rad(rotation.Z))
end)