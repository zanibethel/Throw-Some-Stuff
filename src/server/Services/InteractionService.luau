-- InteractionService
-- Server-side service that creates interaction remotes, validates requests, and
-- dispatches to registered interactable handlers.
--
-- Public API (callable by other server modules):
--   InteractionService.register(id, definition)   -- declare an interactable
--   InteractionService.unregister(id)              -- remove an interactable
--   InteractionService.broadcastState(id, state, player?)  -- notify clients of state changes

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local service = {
	Name = "InteractionService",
}

local initialized = false
local started = false
local serviceJanitor = nil
local gameConfig = nil

-- Registry: interactableId -> definition table
local registry: { [string]: any } = {}

-- Per-player rate limit: userId -> os.clock() of last accepted request
local lastRequestTime: { [number]: number } = {}

local function handleRequest(player: Player, interactableId: any, action: any, args: any): (boolean, string?)
	-- Validate client-supplied argument types before touching any state
	if type(interactableId) ~= "string" or interactableId == "" then
		return false, "Invalid interactable ID"
	end
	if type(action) ~= "string" or action == "" then
		return false, "Invalid action"
	end
	if args ~= nil and type(args) ~= "table" then
		return false, "Invalid arguments"
	end

	-- Rate limit
	local userId = player.UserId
	local now = os.clock()
	local rateLimitSeconds = if gameConfig ~= nil then gameConfig.Interaction.RateLimitSeconds else 0.3
	local last = lastRequestTime[userId]
	if last ~= nil and (now - last) < rateLimitSeconds then
		return false, "Request rate limit exceeded"
	end
	lastRequestTime[userId] = now

	-- Character must exist with a root part for distance checks
	local character = player.Character
	if character == nil then
		return false, "Character not found"
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart == nil then
		return false, "HumanoidRootPart not found"
	end

	-- Registry lookup
	local definition = registry[interactableId]
	if definition == nil then
		return false, "Interactable not registered"
	end

	-- Action must match the registered definition
	if definition.actionName ~= action then
		return false, "Invalid action for interactable"
	end

	-- Distance check against the interactable's primary part
	local primaryPart = definition.getPrimaryPart()
	if primaryPart ~= nil then
		local maxDistance = definition.maxDistance
		if maxDistance == nil then
			maxDistance = if gameConfig ~= nil then gameConfig.Interaction.MaxDistance else 12
		end
		local distance = (rootPart.Position - primaryPart.Position).Magnitude
		if distance > maxDistance then
			return false, "Too far from interactable"
		end
	end

	-- Optional custom validation from the registrant
	if definition.validate ~= nil then
		local valid, reason = definition.validate(player, args)
		if not valid then
			return false, reason or "Validation failed"
		end
	end

	-- Dispatch to the registrant's handler
	local success, message = definition.handle(player, args)
	return success, message
end

function service.Init(context)
	if initialized then
		context.Logger.warn("%s already initialized", service.Name)
		return
	end

	initialized = true
	gameConfig = context.Config

	Remotes.setup()

	local Janitor = require(ReplicatedStorage.Shared.Util.Janitor)
	serviceJanitor = Janitor.new()
	context.Janitor:Add(serviceJanitor)
end

function service.Start(context)
	if started then
		context.Logger.warn("%s already started", service.Name)
		return
	end

	if serviceJanitor == nil then
		error(string.format("%s cannot start because its janitor is missing", service.Name))
	end

	local requestRemote = Remotes.get(Remotes.Names.InteractionRequest)

	requestRemote.OnServerInvoke = function(player, interactableId, action, args)
		local success, message = handleRequest(player, interactableId, action, args)
		return success, message
	end

	serviceJanitor:Add(function()
		requestRemote.OnServerInvoke = nil
	end)

	serviceJanitor:Add(Players.PlayerRemoving:Connect(function(player)
		lastRequestTime[player.UserId] = nil
	end))

	started = true
	context.Logger.info("%s started", service.Name)
end

function service.Stop(context)
	registry = {}
	lastRequestTime = {}
	gameConfig = nil

	if serviceJanitor ~= nil then
		serviceJanitor:Cleanup()
		serviceJanitor = nil
	end

	started = false
	initialized = false
	context.Logger.info("%s stopped", service.Name)
end

-- Registers an interactable. Must be called after Init.
-- definition fields: displayName, actionName, getPrimaryPart, handle, and optional maxDistance/validate.
function service.register(interactableId: string, definition: any)
	assert(type(interactableId) == "string" and interactableId ~= "", "interactableId must be a non-empty string")
	assert(type(definition) == "table", "definition must be a table")
	assert(type(definition.displayName) == "string", "definition.displayName must be a string")
	assert(type(definition.actionName) == "string", "definition.actionName must be a string")
	assert(type(definition.getPrimaryPart) == "function", "definition.getPrimaryPart must be a function")
	assert(type(definition.handle) == "function", "definition.handle must be a function")
	registry[interactableId] = definition
end

-- Removes a registered interactable, preventing future interactions.
function service.unregister(interactableId: string)
	registry[interactableId] = nil
end

-- Fires InteractionStateChanged to one player or all clients.
-- Use this to update client-side prompt availability when interactable state changes.
function service.broadcastState(interactableId: string, newState: string, player: Player?)
	local stateRemote = Remotes.get(Remotes.Names.InteractionStateChanged)
	if player ~= nil then
		stateRemote:FireClient(player, interactableId, newState)
	else
		stateRemote:FireAllClients(interactableId, newState)
	end
end

return service
