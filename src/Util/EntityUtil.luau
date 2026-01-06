local HttpService = game:GetService("HttpService")
local EditorState = require(script.Parent.Parent.State.EditorState)

local EntityUtil = {}

function EntityUtil.createImage()
	local id = HttpService:GenerateGUID(false)
	local entity = {
		id = id,
		name = "Image" .. id:sub(1, 4),
		textureId = "0",
		position = vector.create(320, 180, 0),
		size = vector.create(200, 200, 0),
		imageRectOffset = Vector2.new(0, 0),
		imageRectSize = Vector2.new(0, 0),
		physicsObjects = {},
	}
	EditorState.addEntity(entity)
	EditorState.selectEntity(id)
end

return EntityUtil
