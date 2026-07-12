-- InteractionController
-- Client-side controller that watches for Interactable-tagged instances, creates
-- ProximityPrompts, and fires interaction requests to the server.
--
-- Interactable instances must have:
--   Attribute "InteractableId"     (string)  — matches a server-registered definition
--   Attribute "InteractableAction" (string)  — action name sent to the server
--   Attribute "InteractableDisplay"(string?) — optional prompt ObjectText override

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local INTERACTABLE_TAG = "Interactable"

local controller = {
	Name = "InteractionController",
}

local initialized = false
local started = false
local controllerJanitor = nil

local function getAttachPart(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance :: BasePart
	elseif instance:IsA("Model") then
		return (instance :: Model).PrimaryPart
	end
	return nil
end

function controller.Init(context)
	if initialized then
		context.Logger.warn("%s already initialized", controller.Name)
		return
	end

	initialized = true

	local Janitor = require(ReplicatedStorage.Shared.Util.Janitor)
	controllerJanitor = Janitor.new()
	context.Janitor:Add(controllerJanitor)
end

function controller.Start(context)
	if started then
		context.Logger.warn("%s already started", controller.Name)
		return
	end

	if controllerJanitor == nil then
		error(string.format("%s cannot start because its janitor is missing", controller.Name))
	end

	local Janitor = require(ReplicatedStorage.Shared.Util.Janitor)
	local requestRemote = Remotes.get(Remotes.Names.InteractionRequest)
	local stateChangedRemote = Remotes.get(Remotes.Names.InteractionStateChanged)

	-- Per-instance janitors so each interactable cleans up independently
	local instanceJanitors: { [Instance]: any } = {}

	local function setupInstance(instance: Instance)
		if instanceJanitors[instance] ~= nil then
			return
		end

		local interactableId = instance:GetAttribute("InteractableId")
		if type(interactableId) ~= "string" or interactableId == "" then
			context.Logger.warn(
				"%s: skipping %s — missing InteractableId attribute",
				controller.Name,
				instance:GetFullName()
			)
			return
		end

		local attachPart = getAttachPart(instance)
		if attachPart == nil then
			context.Logger.warn(
				"%s: skipping %s — no BasePart or PrimaryPart to attach prompt to",
				controller.Name,
				instance:GetFullName()
			)
			return
		end

		local instanceJanitor = Janitor.new()
		instanceJanitors[instance] = instanceJanitor

		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = tostring(instance:GetAttribute("InteractableDisplay") or instance.Name)
		prompt.ActionText = tostring(instance:GetAttribute("InteractableAction") or "Interact")
		prompt.MaxActivationDistance = context.Config.Interaction.MaxDistance
		prompt.HoldDuration = context.Config.Interaction.PromptHoldDurationSeconds
		prompt.RequiresLineOfSight = false
		prompt.Parent = attachPart
		instanceJanitor:Add(prompt)

		local action = tostring(instance:GetAttribute("InteractableAction") or "interact")

		instanceJanitor:Add(prompt.Triggered:Connect(function(_localPlayer: Player)
			local ok, success, message = pcall(function()
				return requestRemote:InvokeServer(interactableId, action, nil)
			end)

			if not ok then
				context.Logger.warn(
					"%s: remote call failed for %s: %s",
					controller.Name,
					interactableId,
					tostring(success)
				)
				return
			end

			if not success then
				context.Logger.warn(
					"%s: interaction rejected for %s: %s",
					controller.Name,
					interactableId,
					tostring(message)
				)
			else
				context.Logger.info("%s: interaction succeeded for %s", controller.Name, interactableId)
			end
		end))
	end

	local function teardownInstance(instance: Instance)
		local instanceJanitor = instanceJanitors[instance]
		if instanceJanitor ~= nil then
			instanceJanitor:Cleanup()
			instanceJanitors[instance] = nil
		end
	end

	-- Watch all currently-tagged instances
	for _, instance in CollectionService:GetTagged(INTERACTABLE_TAG) do
		setupInstance(instance)
	end

	-- Watch future additions and removals
	controllerJanitor:Add(CollectionService:GetInstanceAddedSignal(INTERACTABLE_TAG):Connect(function(instance)
		setupInstance(instance)
	end))

	controllerJanitor:Add(CollectionService:GetInstanceRemovedSignal(INTERACTABLE_TAG):Connect(function(instance)
		teardownInstance(instance)
	end))

	-- Log interactable state changes broadcast from the server
	controllerJanitor:Add(stateChangedRemote.OnClientEvent:Connect(function(interactableId, newState)
		context.Logger.info(
			"%s: interactable %s state changed to %s",
			controller.Name,
			tostring(interactableId),
			tostring(newState)
		)
	end))

	-- Clean up all instance janitors when the controller stops
	controllerJanitor:Add(function()
		for _, instanceJanitor in pairs(instanceJanitors) do
			instanceJanitor:Cleanup()
		end
	end)

	started = true
	context.Logger.info("%s started", controller.Name)
end

function controller.Stop(context)
	if controllerJanitor ~= nil then
		controllerJanitor:Cleanup()
		controllerJanitor = nil
	end

	started = false
	initialized = false
	context.Logger.info("%s stopped", controller.Name)
end

return controller
