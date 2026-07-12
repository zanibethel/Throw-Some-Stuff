if script:GetAttribute("Initialized") then
	return
end

script:SetAttribute("Initialized", true)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getChild(parent: Instance, childName: string): Instance?
	return parent:FindFirstChild(childName) or parent:WaitForChild(childName, 5)
end

local sharedFolder = getChild(ReplicatedStorage, "Shared")
if sharedFolder == nil then
	warn("[ThrowSomeStuff] Shared folder missing; server bootstrap aborted")
	return
end

local configFolder = getChild(sharedFolder, "Config")
local utilFolder = getChild(sharedFolder, "Util")
local gameConfigModule = configFolder and getChild(configFolder, "GameConfig")
local loggerModule = utilFolder and getChild(utilFolder, "Logger")
local janitorModule = utilFolder and getChild(utilFolder, "Janitor")
local moduleBootstrapModule = utilFolder and getChild(utilFolder, "ModuleBootstrap")
local servicesFolder = script:FindFirstChild("Services") or script:WaitForChild("Services", 5)

if not configFolder or not utilFolder or not gameConfigModule or not loggerModule or not janitorModule or not moduleBootstrapModule then
	warn("[ThrowSomeStuff] Shared bootstrap dependencies are incomplete; server bootstrap aborted")
	return
end

local GameConfig = require(gameConfigModule)
local Logger = require(loggerModule)
local Janitor = require(janitorModule)
local ModuleBootstrap = require(moduleBootstrapModule)

Logger.configure(GameConfig.Debug.LoggingEnabled)

local runtimeJanitor = Janitor.new()
local context = {
	Config = GameConfig,
	Janitor = runtimeJanitor,
	Logger = Logger,
	RunContext = "Server",
}

runtimeJanitor:Add(ModuleBootstrap.run({
	root = servicesFolder,
	key = "ServerServices",
	context = context,
}))

game:BindToClose(function()
	runtimeJanitor:Cleanup()
end)

Logger.info("Server bootstrap finished")
