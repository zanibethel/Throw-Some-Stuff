local Janitor = require(script.Parent.Janitor)
local Logger = require(script.Parent.Logger)

export type BootstrapModule = {
	Init: ((context: any) -> ())?,
	Start: ((context: any) -> ())?,
	Stop: ((context: any) -> ())?,
	Destroy: ((context: any) -> ())?,
	Cleanup: ((context: any) -> ())?,
}

export type BootstrapOptions = {
	root: Instance?,
	key: string,
	context: any,
}

local initializedKeys: { [string]: boolean } = {}

local ModuleBootstrap = {}

local function getModules(root: Instance): { { instance: ModuleScript, module: BootstrapModule } }
	local resolvedModules = {}
	local children = root:GetChildren()

	table.sort(children, function(left, right)
		return left.Name < right.Name
	end)

	for _, child in children do
		if child:IsA("ModuleScript") then
			local ok, loadedModule = pcall(require, child)
			if not ok then
				Logger.warn("Failed to require %s: %s", child:GetFullName(), tostring(loadedModule))
			elseif type(loadedModule) == "table" then
				table.insert(resolvedModules, {
					instance = child,
					module = loadedModule :: BootstrapModule,
				})
			else
				Logger.warn("Ignoring %s because it did not return a table", child:GetFullName())
			end
		end
	end

	return resolvedModules
end

function ModuleBootstrap.run(options: BootstrapOptions)
	local janitor = Janitor.new()

	if initializedKeys[options.key] then
		Logger.warn("Skipped duplicate bootstrap for %s", options.key)
		return janitor
	end

	initializedKeys[options.key] = true
	janitor:Add(function()
		initializedKeys[options.key] = nil
	end)

	if options.root == nil then
		Logger.warn("Skipping bootstrap for %s because the root instance is missing", options.key)
		return janitor
	end

	local modules = getModules(options.root)

	for _, definition in modules do
		local init = definition.module.Init
		if init ~= nil then
			local ok, err = pcall(init, options.context)
			if not ok then
				Logger.warn("Init failed for %s: %s", definition.instance:GetFullName(), tostring(err))
			end
		end
	end

	for _, definition in modules do
		local start = definition.module.Start
		if start ~= nil then
			local ok, err = pcall(start, options.context)
			if not ok then
				Logger.warn("Start failed for %s: %s", definition.instance:GetFullName(), tostring(err))
			end
		end
	end

	janitor:Add(function()
		for index = #modules, 1, -1 do
			local definition = modules[index]
			local stop = definition.module.Stop or definition.module.Destroy or definition.module.Cleanup
			if stop ~= nil then
				local ok, err = pcall(stop, options.context)
				if not ok then
					Logger.warn("Cleanup failed for %s: %s", definition.instance:GetFullName(), tostring(err))
				end
			end
		end
	end)

	return janitor
end

return table.freeze(ModuleBootstrap)
