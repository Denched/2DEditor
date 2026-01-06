local CreateInputHandler = require(script.Parent.CreateInputHandler)
local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local ZIndexes = require(script.Parent.Parent.Parent.Constants.ZIndexes)

local function isPointInPhysicsObject(worldPoint: vector, physicsObject): boolean
	local pos = physicsObject.position
	local half = physicsObject.halfExtents

	return worldPoint.x >= pos.x - half.x
		and worldPoint.x <= pos.x + half.x
		and worldPoint.y >= pos.y - half.y
		and worldPoint.y <= pos.y + half.y
end

return CreateInputHandler({
	name = "PhysicsObjectInputHandler",
	zIndex = ZIndexes.HitboxOverlay + 10,
	usesHalfExtents = true,
	minSize = 5,

	canHandle = function(_state)
		return true
	end,

	getSelectedObject = function(state)
		local entityId = state.selectedEntityId()
		local physicsObjectId = state.selectedPhysicsObjectId()
		if entityId and physicsObjectId then
			local physicsObject = EditorState.getPhysicsObject(entityId, physicsObjectId)
			return physicsObject, entityId, physicsObjectId
		end
		return nil, nil, nil
	end,

	findObjectAtPoint = function(state, worldPoint)
		local entities = state.entities()
		for i = #entities, 1, -1 do
			local entity = entities[i]
			for j = #entity.physicsObjects, 1, -1 do
				local physicsObject = entity.physicsObjects[j]
				if isPointInPhysicsObject(worldPoint, physicsObject) then
					return entity.id, physicsObject.id
				end
			end
		end
		return nil, nil
	end,

	onSelect = function(entityId, objectId)
		EditorState.selectEntity(entityId)
		EditorState.selectPhysicsObject(objectId)
	end,

	onDeselect = function()
		EditorState.selectPhysicsObject(nil)
	end,

	updateObject = function(entityId, objectId, updates)
		EditorState.updatePhysicsObject(entityId, objectId, updates)
	end,

	waypointMove = "Move PhysicsObject",
	waypointResize = "Resize PhysicsObject",
})
