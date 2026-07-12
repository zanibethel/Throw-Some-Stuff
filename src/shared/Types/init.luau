export type GamePhase = "Bootstrap" | "RoomReady" | "RoomActive" | "RoomResetting"

export type PlayerRuntimeState = {
	userId: number,
	isAlive: boolean,
	isHidden: boolean,
	currentRoomId: string?,
}

export type BootstrapContext = {
	Config: typeof(require(script.Parent.Parent.Config.GameConfig)),
	Janitor: any,
	Logger: any,
	RunContext: "Server" | "Client",
}

-- Describes a server-registered interactable object.
-- `getPrimaryPart` must return the part used for distance validation.
-- `validate` is called before `handle` and may reject the request with a reason.
-- `handle` performs the interaction and returns success plus an optional message.
export type InteractionDefinition = {
	displayName: string,
	actionName: string,
	maxDistance: number?,
	getPrimaryPart: () -> BasePart?,
	validate: ((player: Player, args: { [string]: any }?) -> (boolean, string?))?,
	handle: (player: Player, args: { [string]: any }?) -> (boolean, string?),
}

export type InteractionResult = {
	success: boolean,
	message: string?,
}

return nil
