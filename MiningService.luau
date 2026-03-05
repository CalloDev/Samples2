local MiningService = {}
MiningService.ActiveMining = {}
MiningService.NodeStates = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ServerScriptService.Services
local NodeService = require(Services.NodeService)
local OreService = require(Services.OreService)
local DataService = require(Services.DataService)

local Remotes = ReplicatedStorage.Remotes
local Notification = Remotes.Notification
local MiningRemotes = Remotes.Mining
local UpdateMiningRemote = MiningRemotes.UpdateMining
local UpdateProgressUI = MiningRemotes.UpdateProgressUI

local NodesFolder = workspace.Nodes

local TICK_RATE = 0.2

function MiningService:Init()
	UpdateMiningRemote.OnServerEvent:Connect(function(Player, Action, Node)
		if Action == "Start" then
			self:StartMining(Player, Node)
		elseif Action == "Stop" then
			self:StopMining(Player)
		end
	end)

	task.spawn(function()
		while true do
			self:UpdateMining()
			task.wait(TICK_RATE)
		end
	end)
end

function MiningService:StartMining(Player, Node)
	if not self:CanMine(Node) then
		return
	end

	if self.ActiveMining[Player.UserId] then
		return
	end

	local NodeState = self:GetNodeState(Node)
	NodeState.ActiveMiner = Player.UserId

	self.ActiveMining[Player.UserId] = {
		Player = Player,
		Node = Node,
		Speed = 1,
	}
end

function MiningService:StopMining(Player)
	local MiningData = self.ActiveMining[Player.UserId]

	if not MiningData then
		return
	end

	local NodeState = self:GetNodeState(MiningData.Node)

	if NodeState and NodeState.ActiveMiner == Player.UserId then
		NodeState.ActiveMiner = nil
	end

	self.ActiveMining[Player.UserId] = nil
end

function MiningService:UpdateMining()
	for UserId, MiningData in self.ActiveMining do
		local Player = MiningData.Player
		local Node = MiningData.Node

		local NodeState = self:GetNodeState(Node)

		if not NodeState or NodeState.Mined or NodeState.ActiveMiner ~= Player.UserId  then
			self:StopMining(Player)
			continue
		end

		local NodeData = NodeService:GetNodeData(Node)

		local Hardness = NodeData.Hardness
		local Yield = NodeState.TotalYield

		NodeState.Progress += MiningData.Speed * TICK_RATE

		local Progress = NodeState.Progress / Hardness
		UpdateProgressUI:FireClient(Player, Progress, Node)

		local YieldPerProgress = Yield / Hardness
		local ExpectedYield = math.floor(NodeState.Progress * YieldPerProgress)
		local YieldToGive = ExpectedYield - NodeState.YieldGiven

		--// GIVE PLAYER ORE
		if YieldToGive > 0 then
			NodeState.YieldGiven += YieldToGive
			
			local RolledOre = OreService:RollOre(Player, 1)
			print(RolledOre)
			DataService:AddToInventory(Player, "Ores", RolledOre, YieldToGive)
			Notification:FireClient(Player, "Ore", {OreName = RolledOre})
		end
		--\\

		if NodeState.Progress >= Hardness then
			NodeState.Mined = true
			NodeState.ActiveMiner = nil
			self.ActiveMining[UserId] = nil

			NodeService:RegenerateNode(Node, NodeState)
		end
	end
end

function MiningService:GetNodeState(Node)
	self.NodeStates[Node] = self.NodeStates[Node] or {
		Progress = 0,
		TotalYield = NodeService:CalculateYield(Node),
		YieldGiven = 0,
		ActiveMiner = nil,
		Mined = false,
	}
	
	return self.NodeStates[Node]
end

function MiningService:CanMine(Node)
	if not Node or not Node:IsDescendantOf(NodesFolder) then
		return false
	end

	local NodeState = self.NodeStates[Node]

	if NodeState then
		if NodeState.Mined then
			return false
		end

		if NodeState.ActiveMiner then
			return false
		end
	end

	return true
end

return MiningService
