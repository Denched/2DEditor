local HttpService = game:GetService("HttpService")
local EditorState = require(script.Parent.Parent.State.EditorState)

local StageExporter = {}

function StageExporter.exportToJSON(stageName: string?): string
	local state = EditorState.get()
	local entities = state.entities()
	local spawnPoints = state.spawnPoints()

	local spawnsData = {}
	for _, spawn in spawnPoints do
		table.insert(spawnsData, {
			x = spawn.position.x,
			y = spawn.position.y,
			z = 0,
		})
	end

	local stageData = {
		version = "2.0",
		name = stageName or "Stage1",
		metadata = {
			exportDate = os.date("%Y-%m-%d %H:%M:%S"),
			entityCount = #entities,
			spawnCount = #spawnPoints,
		},
		screenGui = {
			ignoreGuiInset = true,
			displayOrder = 0,
		},
		spawns = {
			respawn = spawnsData,
		},
		elements = {},
	}

	for _, entity in entities do
		local element = {
			type = "ImageLabel",
			id = entity.id,
			name = entity.name,

			position = {
				scale = { x = entity.position.x, y = entity.position.y },
				offset = { x = 0, y = 0 },
			},
			size = {
				scale = { x = 0, y = 0 },
				offset = { x = entity.size.x, y = entity.size.y },
			},
			anchorPoint = { x = 0.5, y = 0.5 },
			rotation = entity.rotation or 0,

			image = "rbxassetid://" .. entity.textureId,
			imageColor3 = { 255, 255, 255 },
			imageTransparency = 0,
			scaleType = "Fit",
			resampleMode = "Pixelated",
			backgroundTransparency = 1,
			borderSizePixel = 0,

			imageRectOffset = entity.imageRectOffset and {
				x = entity.imageRectOffset.X,
				y = entity.imageRectOffset.Y,
			} or { x = 0, y = 0 },
			imageRectSize = entity.imageRectSize and {
				x = entity.imageRectSize.X,
				y = entity.imageRectSize.Y,
			} or { x = 0, y = 0 },

			zIndex = entity.zIndex or 1,
			layoutOrder = entity.layoutOrder or 0,
			visible = true,

			physics = {},
		}

		for _, po in entity.physicsObjects do
			local physicsData = {
				id = po.id,
				name = po.name,
				offset = {
					x = po.position.x - entity.position.x,
					y = po.position.y - entity.position.y,
				},
				halfExtents = {
					x = po.halfExtents.x,
					y = po.halfExtents.y,
				},
				rotation = po.rotation,
				isTrigger = false,
				layer = "Static",
			}
			table.insert(element.physics, physicsData)
		end

		table.insert(stageData.elements, element)
	end

	return HttpService:JSONEncode(stageData)
end

function StageExporter.exportToLuaModule(stageName: string?): string
	local state = EditorState.get()
	local entities = state.entities()
	local spawnPoints = state.spawnPoints()

	local lines = {

		"-- " .. os.date("%Y-%m-%d %H:%M:%S"),
		"",
		"return {",
		string.format('\tname = "%s",', stageName or "Stage1"),
		"\tscreenGui = {",
		"\t\tignoreGuiInset = true,",
		"\t\tdisplayOrder = 0,",
		"\t},",
		"\tspawns = {",
		"\t\trespawn = {",
	}

	for i, spawn in spawnPoints do
		local comma = if i < #spawnPoints then "," else ""
		table.insert(
			lines,
			string.format("\t\t\tvector.create(%.0f, %.0f, 0)%s", spawn.position.x, spawn.position.y, comma)
		)
	end

	table.insert(lines, "\t\t},")
	table.insert(lines, "\t},")
	table.insert(lines, "\telements = {")

	for i, entity in entities do
		table.insert(lines, "\t\t{")
		table.insert(lines, '\t\t\ttype = "ImageLabel",')
		table.insert(lines, string.format('\t\t\tid = "%s",', entity.id))
		table.insert(lines, string.format('\t\t\tname = "%s",', entity.name))
		table.insert(lines, "")

		table.insert(
			lines,
			string.format("\t\t\tposition = UDim2.new(%.2f, 0, %.2f, 0),", entity.position.x, entity.position.y)
		)
		table.insert(lines, "\t\t\tsize = UDim2.fromOffset(" .. entity.size.x .. ", " .. entity.size.y .. "),")
		table.insert(lines, "\t\t\tanchorPoint = Vector2.new(0.5, 0.5),")
		table.insert(lines, string.format("\t\t\trotation = %d,", entity.rotation or 0))
		table.insert(lines, "")

		table.insert(lines, string.format('\t\t\timage = "rbxassetid://%s",', entity.textureId))
		table.insert(lines, "\t\t\timageColor3 = Color3.fromRGB(255, 255, 255),")
		table.insert(lines, "\t\t\timageTransparency = 0,")
		table.insert(lines, "\t\t\tscaleType = Enum.ScaleType.Fit,")
		table.insert(lines, "\t\t\tresampleMode = Enum.ResamplerMode.Pixelated,")
		table.insert(lines, "\t\t\tbackgroundTransparency = 1,")
		table.insert(lines, "\t\t\tborderSizePixel = 0,")

		if entity.imageRectOffset and entity.imageRectSize then
			table.insert(
				lines,
				string.format(
					"\t\t\timageRectOffset = Vector2.new(%d, %d),",
					entity.imageRectOffset.x,
					entity.imageRectOffset.y
				)
			)
			table.insert(
				lines,
				string.format(
					"\t\t\timageRectSize = Vector2.new(%d, %d),",
					entity.imageRectSize.x,
					entity.imageRectSize.y
				)
			)
		end

		table.insert(lines, "")
		table.insert(lines, string.format("\t\t\tzIndex = %d,", entity.zIndex or 1))
		table.insert(lines, "\t\t\tvisible = true,")

		if #entity.physicsObjects > 0 then
			table.insert(lines, "")
			table.insert(lines, "\t\t\tphysics = {")

			for j, po in entity.physicsObjects do
				table.insert(lines, "\t\t\t\t{")
				table.insert(lines, string.format('\t\t\t\t\tname = "%s",', po.name))
				table.insert(
					lines,
					string.format(
						"\t\t\t\t\toffset = vector.create(%.2f, %.2f, 0),",
						po.position.x - entity.position.x,
						po.position.y - entity.position.y
					)
				)
				table.insert(
					lines,
					string.format(
						"\t\t\t\t\thalfExtents = vector.create(%.2f, %.2f, 0),",
						po.halfExtents.x,
						po.halfExtents.y
					)
				)
				table.insert(lines, "\t\t\t\t\tisTrigger = false,")
				table.insert(lines, "\t\t\t\t\tlayer = 0x02,")
				table.insert(lines, string.format("\t\t\t\t}%s", j < #entity.physicsObjects and "," or ""))
			end

			table.insert(lines, "\t\t\t},")
		else
			table.insert(lines, "\t\t\tphysics = {},")
		end

		table.insert(lines, string.format("\t\t}%s", i < #entities and "," or ""))
	end

	table.insert(lines, "\t},")
	table.insert(lines, "}")

	return table.concat(lines, "\n")
end

function StageExporter.importFromJSON(jsonString: string)
	local success, data = pcall(function()
		return HttpService:JSONDecode(jsonString)
	end)

	if not success then
		warn("Failed to parse stage JSON:", data)
		return false
	end

	if not data.elements then
		warn("Invalid stage format: missing elements")
		return false
	end

	local state = EditorState.get()
	local existingEntities = state.entities()
	for _, entity in existingEntities do
		EditorState.removeEntity(entity.id)
	end

	for _, element in data.elements do
		if element.type == "ImageLabel" then
			local entity = {
				id = element.id or HttpService:GenerateGUID(false),
				name = element.name,
				textureId = element.image:gsub("rbxassetid://", ""),
				position = vector.create(element.position.offset.x, element.position.offset.y, 0),
				size = vector.create(element.size.offset.x, element.size.offset.y, 0),
				rotation = element.rotation or 0,
				zIndex = element.zIndex or 1,
				physicsObjects = {},
			}

			if element.imageRectOffset then
				entity.imageRectOffset = vector.create(element.imageRectOffset.x, element.imageRectOffset.y, 0)
			end

			if element.imageRectSize and (element.imageRectSize.x > 0 or element.imageRectSize.y > 0) then
				entity.imageRectSize = vector.create(element.imageRectSize.x, element.imageRectSize.y, 0)
			end

			if element.physics then
				for _, physicsData in element.physics do
					local po: EditorState.PhysicsObject = {
						id = physicsData.id or HttpService:GenerateGUID(false),
						name = physicsData.name,
						position = vector.create(
							entity.position.x + physicsData.offset.x,
							entity.position.y + physicsData.offset.y,
							0
						),
						halfExtents = vector.create(physicsData.halfExtents.x, physicsData.halfExtents.y, 0),
						rotation = physicsData.rotation or 0,
						color = Color3.fromRGB(255, 0, 0), -- Default red for visibility
					}
					table.insert(entity.physicsObjects, po)
				end
			end

			EditorState.addEntity(entity)
		end
	end

	print("Successfully imported stage:", data.name, "with", #data.elements, "elements")
	return true
end

return StageExporter
