local ServerScriptService = game:GetService("ServerScriptService")
local Services = ServerScriptService:WaitForChild("Services")
local ServicesCache = {}

for _, Service in Services:GetChildren() do
    if not Service:IsA("ModuleScript") then
        continue
    end

    ServicesCache[Service.Name] = require(Service)
end

for _, Service in ServicesCache do
    if not Service.Init then
        continue
    end

    Service:Init()
end

-- Same for client just using PlayerScripts.Controllers
