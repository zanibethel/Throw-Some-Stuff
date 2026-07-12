local GameConfig = {
	Game = {
		Title = "Throw Some Stuff",
		MaxPlayers = 6,
		StartingRoomId = "Room01",
	},
	Debug = {
		LoggingEnabled = true,
		StrictMissingInstances = false,
	},
	Interaction = {
		MaxDistance = 12,
		PromptHoldDurationSeconds = 0.15,
		RateLimitSeconds = 0.3,
	},
	Round = {
		ResetDelaySeconds = 5,
		RespawnDelaySeconds = 3,
	},
}

return table.freeze(GameConfig)
