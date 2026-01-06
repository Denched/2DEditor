--# selene: allow(mixed_table)

local HttpService = game:GetService("HttpService")
local Explorer = require(script.Parent.Explorer)
local Dropdown = require(script.Parent.Dropdown)
local PanelTab = require(script.Parent.PanelTab)
local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local EntityUtil = require(script.Parent.Parent.Parent.Util.EntityUtil)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create
local source = vide.source

local function createNewSpawn()
	local spawnPoint = EditorState.addSpawnPoint(vector.create(320, 180, 0))
	if spawnPoint then
		EditorState.selectSpawnPoint(spawnPoint.id)
	end
end

local function createNewHitbox()
	local state = EditorState.get()
	local selectedEntityId = state.selectedEntityId()

	if not selectedEntityId then
		EditorState.log("No entity selected. Select an entity first.", "warn")
		return
	end

	local entity = EditorState.getEntity(selectedEntityId)
	if not entity then
		return
	end

	local id = HttpService:GenerateGUID(false)
	local physicsObject: EditorState.PhysicsObject = {
		id = id,
		name = "Hitbox" .. id:sub(1, 4),
		position = entity.position,
		halfExtents = vector.create(50, 50, 0),
		rotation = 0,
		color = Color3.fromRGB(100, 200, 100),
	}

	EditorState.addPhysicsObject(selectedEntityId, physicsObject)
	EditorState.selectPhysicsObject(id)
end

return function()
	local dropdownOpen = source(false)
	local isAddHovered = source(false)

	local function closeDropdown()
		dropdownOpen(false)
	end

	local function toggleDropdown()
		dropdownOpen(not dropdownOpen())
	end

	local dropdownItems = {
		{ label = "New Image", onClick = EntityUtil.createImage },
		{ label = "New Spawn", onClick = createNewSpawn },
		{ label = "New Hitbox", onClick = createNewHitbox },
	}

	local addButton = create("TextButton")({
		Name = "AddButton",
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -42, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = function()
			if dropdownOpen() or isAddHovered() then
				return Color3.fromRGB(70, 90, 70)
			end
			return Color3.fromRGB(60, 80, 60)
		end,
		BorderSizePixel = 0,
		Text = "+",
		TextSize = 12,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		MouseEnter = function()
			isAddHovered(true)
		end,
		MouseLeave = function()
			isAddHovered(false)
		end,
		MouseButton1Click = toggleDropdown,

		create("UICorner")({
			CornerRadius = UDim.new(0, 4),
		}),
	})

	return create("Frame")({
		Name = "LeftPanel",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(37, 37, 37),
		BorderSizePixel = 0,

		create("Frame")({
			Size = UDim2.new(0, 1, 1, 0),
			Position = UDim2.fromScale(1, 0),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromRGB(28, 28, 28),
			BorderSizePixel = 0,
		}),

		PanelTab({
			title = "Explorer",
			onClose = function()
				EditorState.hideExplorer()
			end,
			headerActions = addButton,
			children = create("Frame")({
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,

				Explorer(),
			}),
		}),

		Dropdown({
			items = dropdownItems,
			isOpen = dropdownOpen,
			onClose = closeDropdown,
			anchorPosition = Vector2.new(110, 22),
		}),
	})
end
