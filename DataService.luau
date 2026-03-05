local DataService = {}
DataService.Profiles = {}

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DataStore = DataStoreService:GetDataStore("PlayerData")
local DataTemplate = require(script.Template)

--// FUNCTIONS
function DataService:IncrementData(Player, Key, Amount)
	local Profile = self.Profiles[Player]
	
	if not Profile then
		warn("Profile not found for: "..Player.Name)
		return
	end
	
	Profile.Data[Key] += Amount
	
	print(self.Profiles[Player])
end

function DataService:AddToInventory(Player, Category, Item, Amount, ExtraData)
	local Profile = self.Profiles[Player]
	
	if not Profile then
		warn("Profile not found for: "..Player.Name)
		return
	end
	
	local Inventory = Profile.Data.Inventory
	if not Inventory[Category] then
		Inventory[Category] = {}
	end
	
	local Category = Inventory[Category]
	if not Category[Item] then
		Category[Item] = {Amount = 0}
	end
	
	local Item = Category[Item]
	Item.Amount += Amount
	
	if typeof(ExtraData) == "table" then
		for Key, Value in ExtraData do
			if Item[Key] == nil then
				Item[Key] = Value
			end
		end
	end
	
	print(self.Profiles[Player])
end

function DataService:GetData(Player, Key)
	local Profile = self.Profiles[Player]
	
	if not Profile then
		warn("Profile not found for: "..Player.Name)
		return
	end
	
	return Profile.Data[Key]
end

--// INIT DATA

function DataService:Init()
	for _, Player in Players:GetPlayers() do
		task.spawn(function()
			local Profile = self:DataInit(Player)

			if not Profile then
				Player:Kick("Failed to load data")
			end
		end)
	end
	
	Players.PlayerAdded:Connect(function(Player)
		local Profile = self:DataInit(Player)
		
		if not Profile then
			Player:Kick("Failed to load data")
		end
	end)
	
	Players.PlayerRemoving:Connect(function(Player)
		self:RemoveProfile(Player)
	end)
	
	game:BindToClose(function()
		for Player in self.Profiles do
			self:SaveData(Player)
		end
	end)
end

function DataService:DataInit(Player)
	local UserId = Player.UserId
	local Data = nil
	
	local Success, Error = pcall(function()
		Data = DataStore:GetAsync(UserId)
	end)
	
	if not Success then
		warn("Failed to load data: "..Error)
		return
	end
	
	if not Data then
		Data = self:CopyTable(DataTemplate)
	end
	
	local Profile = {
		UserId = UserId,
		Data = Data,
	}
	
	self.Profiles[Player] = Profile
	
	return Profile
end

function DataService:SaveData(Player)
	local Profile = self.Profiles[Player]
	
	if not Profile then
		return
	end
	
	local UserId = Profile.UserId
	local Data = Profile.Data
	
	local Success, Error = pcall(function()
		DataStore:SetAsync(UserId, Data)
	end)
	
	if not Success then
		warn("Failed to save data: "..Error)
		return
	end
end

function DataService:RemoveProfile(Player)
	local Profile = self.Profiles[Player]
	
	if not Profile then
		return
	end
	
	self:SaveData(Player)
	self.Profiles[Player] = nil
end

function DataService:CopyTable(Table)
	local Copy = {}
	
	for Key, Value in Table do
		Copy[Key] = typeof(Value) == "table" and self:CopyTable(Value) or Value
	end
	
	return Copy
end

return DataService
