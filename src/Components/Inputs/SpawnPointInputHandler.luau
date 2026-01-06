local CreateInputHandler = require(script.Parent.CreateInputHandler)
local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local ZIndexes = require(script.Parent.Parent.Parent.Constants.ZIndexes)

local SPAWN_WORLD_SIZE = 24

local function isPointInSpawn(worldPoint: vector, spawn: EditorState.SpawnPoint): boolean
	local pos = spawn.position
	local half = SPAWN_WORLD_SIZE / 2

	return worldPoint.x >= pos.x - half
		and worldPoint.x <= pos.x + half
		and worldPoint.y >= pos.y - half
		and worldPoint.y <= pos.y + half
end

return CreateInputHandler({
	name = "SpawnPointInputHandler",
	zIndex = ZIndexes.HitboxOverlay + 15,
	usesHalfExtents = false,
	minSize = 10,
	disableResize = true,

	canHandle = function(state)
		return state.selectedPhysicsObjectId() == nil
	end,

	getSelectedObject = function(state)
		local spawnId = state.selectedSpawnPointId()
		if spawnId then
			local spawn = EditorState.getSelectedSpawnPoint()
			if spawn then
				return {
					position = spawn.position,
					size = vector.create(SPAWN_WORLD_SIZE, SPAWN_WORLD_SIZE, 0),
					id = spawn.id,
				},
					spawn.id,
					nil
			end
		end
		return nil, nil, nil
	end,

	findObjectAtPoint = function(state, worldPoint)
		local spawns = state.spawnPoints()
		for i = #spawns, 1, -1 do
			local spawn = spawns[i]
			if isPointInSpawn(worldPoint, spawn) then
				return spawn.id, nil
			end
		end
		return nil, nil
	end,

	onSelect = function(spawnId, _objectId)
		EditorState.selectSpawnPoint(spawnId)
	end,

	onDeselect = function()
		EditorState.selectSpawnPoint(nil)
	end,

	updateObject = function(spawnId, _objectId, updates)
		if spawnId and updates.position then
			EditorState.updateSpawnPoint(spawnId, { position = updates.position })
		end
	end,

	waypointMove = "Move Spawn Point",
	waypointResize = "Resize Spawn Point",
})
