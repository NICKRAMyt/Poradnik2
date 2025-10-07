local function restart()
	local dataName = "PresentsData"
	local DataStoreService = game:GetService("DataStoreService")

	--local DataStore = DataStoreService:GetGlobalDataStore(dataName)
	local DataStore = DataStoreService:GetDataStore(dataName)
	local data = DataStore:ListKeysAsync("",100,"",false)
	local topPage = data:GetCurrentPage()

	for i,dat in pairs(topPage) do
		DataStore:RemoveAsync(dat.KeyName)
	end
	print("removed")
end

--restart()