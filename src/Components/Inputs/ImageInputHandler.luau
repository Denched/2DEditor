local CreateInputHandler = require(script.Parent.CreateInputHandler)
local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local ZIndexes = require(script.Parent.Parent.Parent.Constants.ZIndexes)

local function isPointInImage(worldPoint: vector, entity): boolean
	local pos = entity.position
	local halfSize = vector.create(entity.size.x / 2, entity.size.y / 2, 0)

	return worldPoint.x >= pos.x - halfSize.x
		and worldPoint.x <= pos.x + halfSize.x
		and worldPoint.y >= pos.y - halfSize.y
		and worldPoint.y <= pos.y + halfSize.y
end

return CreateInputHandler({
	name = "ImageInputHandler",
	zIndex = ZIndexes.HitboxOverlay + 12,
	usesHalfExtents = false,
	minSize = 10,

	canHandle = function(state)
		return state.selectedPhysicsObjectId() == nil and state.selectedSpawnPointId() == nil
	end,

	getSelectedObject = function(state)
		local entityId = state.selectedEntityId()
		if entityId then
			local entity = EditorState.getEntity(entityId)
			return entity, entityId, nil
		end
		return nil, nil, nil
	end,

	findObjectAtPoint = function(state, worldPoint)
		local entities = state.entities()
		for i = #entities, 1, -1 do
			local entity = entities[i]
			if isPointInImage(worldPoint, entity) then
				return entity.id, nil
			end
		end
		return nil, nil
	end,

	onSelect = function(entityId, _objectId)
		EditorState.selectEntity(entityId)
		EditorState.selectPhysicsObject(nil)
	end,

	onDeselect = function()
		EditorState.selectEntity(nil)
	end,

	updateObject = function(entityId, _objectId, updates)
		EditorState.updateEntity(entityId, updates)
	end,

	waypointMove = "Move Image",
	waypointResize = "Resize Image",
})
