local ToolController = {}
ToolController.Modules = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local JanitorModule = require(Packages.Janitor)

local Player = Players.LocalPlayer

local PlayerScripts = Player:WaitForChild("PlayerScripts")
local Controllers = PlayerScripts.Controllers
local ToolModules = Controllers.Tools

function ToolController:Init()
    self:CacheToolModules()

    Player.CharacterAdded:Connect(function(Character)
        local Janitor = JanitorModule.new()

        Character.ChildAdded:Connect(function(Tool)
            self:RegisterTool(Tool, Janitor)
        end)
    end)
end

function ToolController:RegisterTool(Tool, Janitor)
	if Tool:IsA("Tool") then
		local ToolModule = self:GetToolModule(Tool.Name)

        if not ToolModule then
            return
        end

		if ToolModule.OnEquip then
			Janitor:Add(Tool.Equipped:Connect(function()
				ToolModule:OnEquip(Tool)
			end))
		end

		if ToolModule.OnActivate then
			Janitor:Add(Tool.Activated:Connect(function()
				ToolModule:OnActivate(Tool)
			end))
		end

        if ToolModule.OnDeactivate then
            Janitor:Add(Tool.Deactivated:Connect(function()
                ToolModule:OnDeactivate(Tool)
            end))
        end

		if ToolModule.OnUnequip then
			Janitor:Add(Tool.Unequipped:Connect(function()
				ToolModule:OnUnequip(Tool)

				Janitor:Cleanup()
			end))
		end
	end
end

function ToolController:GetToolModule(ToolName)
    if self.Modules[ToolName] then
        return self.Modules[ToolName]
    end

    warn("Tool module for '" .. ToolName .. "' not found.")
    return nil
end

function ToolController:CacheToolModules()
    for _, ToolModule in ToolModules:GetChildren() do
        if not ToolModule:IsA("ModuleScript") then
            continue
        end

        self.Modules[ToolModule.Name] = require(ToolModule)
    end
end

return ToolController
