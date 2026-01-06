--# selene: allow(mixed_table)

local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create
local source = vide.source

local ITEM_HEIGHT = 22
local INDENT_SIZE = 14
local ICON_SIZE = 14

local function createTreeItem(props: {
	text: string,
	indent: number,
	isSelected: boolean,
	isEntity: boolean,
	hasChildren: boolean,
	isExpanded: boolean?,
	onClick: () -> (),
	onToggleExpand: (() -> ())?,
}): Frame
	local indentOffset = props.indent * INDENT_SIZE
	local arrowWidth = if props.hasChildren then ICON_SIZE else 0

	return create("Frame")({
		Size = UDim2.new(1, -6, 0, ITEM_HEIGHT),
		BackgroundColor3 = if props.isSelected then Color3.fromRGB(68, 137, 255) else Color3.fromRGB(37, 37, 37),
		BackgroundTransparency = if props.isSelected then 0.7 else 1,
		BorderSizePixel = 0,

		create("TextButton")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			MouseButton1Click = props.onClick,
		}),

		if props.hasChildren
			then create("TextButton")({
				Position = UDim2.fromOffset(indentOffset + 2, 0),
				Size = UDim2.fromOffset(ICON_SIZE, ITEM_HEIGHT),
				BackgroundTransparency = 1,
				Text = if props.isExpanded then "▼" else "▶",
				TextSize = 9,
				TextColor3 = Color3.fromRGB(180, 180, 180),
				Font = Enum.Font.Gotham,
				ZIndex = 2,
				MouseButton1Click = props.onToggleExpand or function() end,
			})
			else nil,

		create("Frame")({
			Position = UDim2.fromOffset(indentOffset + arrowWidth + 4, 0),
			Size = UDim2.new(1, -(indentOffset + arrowWidth + 8), 1, 0),
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
			}),

			create("TextLabel")({
				Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
				BackgroundTransparency = 1,
				Text = if props.isEntity then "" else "🔷",
				TextSize = 12,
				Font = Enum.Font.Gotham,
			}),

			create("TextLabel")({
				Size = UDim2.new(1, -ICON_SIZE - 4, 1, 0),
				BackgroundTransparency = 1,
				Text = props.text,
				TextSize = 12,
				TextColor3 = Color3.fromRGB(220, 220, 220),
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
		}),
	})
end

return function()
	local state = EditorState.get()
	local expandedEntities = source({})

	local function toggleEntityExpand(entityId: string)
		local expanded = table.clone(expandedEntities())
		expanded[entityId] = if expanded[entityId] then nil else true
		expandedEntities(expanded)
	end

	local function isEntityExpanded(entityId: string): boolean
		return expandedEntities()[entityId] == true
	end

	return create("ScrollingFrame")({
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = function()
			local entities = state.entities()
			local totalItems = #entities

			for _, entity in entities do
				if isEntityExpanded(entity.id) then
					totalItems = totalItems + #entity.physicsObjects
				end
			end

			return UDim2.fromOffset(0, totalItems * ITEM_HEIGHT + 10)
		end,

		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 1),
		}),

		create("Frame")({
			Size = UDim2.new(1, -10, 0, ITEM_HEIGHT + 4),
			BackgroundColor3 = Color3.fromRGB(40, 40, 42),
			BorderSizePixel = 0,
			LayoutOrder = 0,

			create("TextLabel")({
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "Scene",
				TextSize = 13,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,

				create("UIPadding")({
					PaddingLeft = UDim.new(0, 8),
				}),
			}),
		}),

		function()
			local entities = state.entities()
			local spawnPoints = state.spawnPoints()
			local selectedEntityId = state.selectedEntityId()
			local selectedPhysicsObjectId = state.selectedPhysicsObjectId()
			local selectedSpawnPointId = state.selectedSpawnPointId()
			local items = {}
			local layoutOrder = 1

			for _, entity in entities do
				local isExpanded = isEntityExpanded(entity.id)
				local hasChildren = #entity.physicsObjects > 0

				local entityItem = createTreeItem({
					text = entity.name,
					indent = 1,
					isSelected = selectedEntityId == entity.id and not selectedPhysicsObjectId,
					isEntity = true,
					hasChildren = hasChildren,
					isExpanded = isExpanded,
					onClick = function()
						EditorState.selectEntity(entity.id)
					end,
					onToggleExpand = function()
						toggleEntityExpand(entity.id)
					end,
				})
				entityItem.LayoutOrder = layoutOrder
				layoutOrder = layoutOrder + 1
				table.insert(items, entityItem)

				if isExpanded then
					for _, physicsObject in entity.physicsObjects do
						local poItem = createTreeItem({
							text = physicsObject.name,
							indent = 2,
							isSelected = selectedPhysicsObjectId == physicsObject.id,
							isEntity = false,
							hasChildren = false,
							onClick = function()
								EditorState.selectEntity(entity.id)
								EditorState.selectPhysicsObject(physicsObject.id)
							end,
						})
						poItem.LayoutOrder = layoutOrder
						layoutOrder = layoutOrder + 1
						table.insert(items, poItem)
					end
				end
			end

			if #spawnPoints > 0 then
				local spawnsHeader = create("Frame")({
					Size = UDim2.new(1, -10, 0, ITEM_HEIGHT + 4),
					BackgroundColor3 = Color3.fromRGB(40, 40, 42),
					BorderSizePixel = 0,
					LayoutOrder = layoutOrder,

					create("TextLabel")({
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = "Spawns",
						TextSize = 13,
						TextColor3 = Color3.fromRGB(200, 200, 200),
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,

						create("UIPadding")({
							PaddingLeft = UDim.new(0, 8),
						}),
					}),
				})
				table.insert(items, spawnsHeader)
				layoutOrder = layoutOrder + 1

				for _, spawn in spawnPoints do
					local spawnItem = createTreeItem({
						text = "P" .. spawn.playerIndex,
						indent = 1,
						isSelected = selectedSpawnPointId == spawn.id,
						isEntity = false,
						hasChildren = false,
						onClick = function()
							EditorState.selectSpawnPoint(spawn.id)
						end,
					})
					spawnItem.LayoutOrder = layoutOrder
					layoutOrder = layoutOrder + 1
					table.insert(items, spawnItem)
				end
			end

			return items
		end,
	})
end
