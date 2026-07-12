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

return nil
