--# selene: allow(mixed_table)

local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local EntityUtil = require(script.Parent.Parent.Parent.Util.EntityUtil)
local StageExporter = require(script.Parent.Parent.Parent.Util.StageExporter)
local Dropdown = require(script.Parent.Dropdown)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create
local source = vide.source

local TOOLBAR_HEIGHT = 32

local function deleteSelected()
	local state = EditorState.get()
	local selectedEntityId = state.selectedEntityId()
	local selectedPhysicsObjectId = state.selectedPhysicsObjectId()
	local selectedSpawnPointId = state.selectedSpawnPointId()

	if selectedSpawnPointId then
		EditorState.removeSpawnPoint(selectedSpawnPointId)
	elseif selectedPhysicsObjectId and selectedEntityId then
		EditorState.removePhysicsObject(selectedEntityId, selectedPhysicsObjectId)
	elseif selectedEntityId then
		EditorState.removeEntity(selectedEntityId)
	else
		EditorState.log("Nothing selected to delete", "warn")
	end
end

local function createMenuButton(label: string, isOpen: () -> boolean, onClick: () -> ())
	local isHovered = source(false)

	return create("TextButton")({
		Name = "Menu_" .. label,
		Size = UDim2.fromOffset(0, TOOLBAR_HEIGHT),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = function()
			if isOpen() or isHovered() then
				return Color3.fromRGB(60, 60, 65)
			end
			return Color3.fromRGB(48, 48, 48)
		end,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Text = label,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		Font = Enum.Font.GothamMedium,
		AutoButtonColor = false,
		MouseEnter = function()
			isHovered(true)
		end,
		MouseLeave = function()
			isHovered(false)
		end,
		MouseButton1Click = onClick,

		create("UIPadding")({
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
	})
end

local function createIconButton(icon: string, tooltip: string, onClick: () -> (), isEnabled: () -> boolean)
	local isHovered = source(false)

	return create("TextButton")({
		Name = "IconBtn_" .. tooltip,
		Size = UDim2.fromOffset(28, 22),
		BackgroundColor3 = function()
			if isHovered() and isEnabled() then
				return Color3.fromRGB(70, 70, 75)
			end
			return Color3.fromRGB(55, 55, 60)
		end,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Text = icon,
		TextSize = 14,
		TextColor3 = function()
			if isEnabled() then
				return Color3.fromRGB(200, 200, 200)
			end
			return Color3.fromRGB(255, 255, 255)
		end,
		Font = Enum.Font.SourceSans,
		AutoButtonColor = false,
		MouseEnter = function()
			isHovered(true)
		end,
		MouseLeave = function()
			isHovered(false)
		end,
		MouseButton1Click = function()
			if isEnabled() then
				onClick()
			end
		end,

		create("UICorner")({
			CornerRadius = UDim.new(0, 4),
		}),
	})
end

return function()
	local state = EditorState.get()

	local openDropdown = source("")

	local function closeDropdown()
		openDropdown("")
	end

	local function toggleDropdown(name: string)
		if openDropdown() == name then
			openDropdown("")
		else
			openDropdown(name)
		end
	end

	local fileItems = {
		{ label = "New Image", onClick = EntityUtil.createImage },
		{ label = "", isSeparator = true },
		{
			label = "Export as JSON",
			onClick = function()
				local stageName = "Stage_" .. os.date("%Y%m%d_%H%M%S")
				local json = StageExporter.exportToJSON(stageName)
				print("=== EXPORTED STAGE JSON ===")
				print(json)
				print("=== END STAGE JSON ===")
			end,
		},
		{
			label = "Export as Lua",
			onClick = function()
				local stageName = "Stage_" .. os.date("%Y%m%d_%H%M%S")
				local code = StageExporter.exportToLuaModule(stageName)
				print("=== EXPORTED STAGE LUA MODULE ===")
				print(code)
				print("=== END STAGE MODULE ===")
			end,
		},
	}

	local editItems = {
		{
			label = "Undo",
			onClick = function()
				EditorState.undo()
			end,
		},
		{
			label = "Redo",
			onClick = function()
				EditorState.redo()
			end,
		},
		{ label = "", isSeparator = true },
		{ label = "Delete", onClick = deleteSelected },
	}

	local viewItems = {
		{
			label = "Reset View",
			onClick = function()
				EditorState.resetView()
			end,
		},
		{ label = "", isSeparator = true },
		{
			label = function()
				return if state.explorerVisible() then "Hide Explorer" else "Show Explorer"
			end,
			onClick = function()
				EditorState.toggleExplorer()
			end,
		},
		{
			label = function()
				return if state.inspectorVisible() then "Hide Inspector" else "Show Inspector"
			end,
			onClick = function()
				EditorState.toggleInspector()
			end,
		},
	}

	return create("Frame")({
		Name = "TopToolbar",
		Size = UDim2.new(1, 0, 0, TOOLBAR_HEIGHT),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(48, 48, 48),
		BorderSizePixel = 0,

		create("Frame")({
			Name = "BottomBorder",
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = Color3.fromRGB(28, 28, 28),
			BorderSizePixel = 0,
		}),

		create("Frame")({
			Name = "MenuBar",
			Size = UDim2.new(0.5, 0, 1, 0),
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			}),

			create("UIPadding")({
				PaddingTop = UDim.new(0, -1),
			}),

			createMenuButton("File", function()
				return openDropdown() == "File"
			end, function()
				toggleDropdown("File")
			end),

			createMenuButton("Edit", function()
				return openDropdown() == "Edit"
			end, function()
				toggleDropdown("Edit")
			end),

			createMenuButton("View", function()
				return openDropdown() == "View"
			end, function()
				toggleDropdown("View")
			end),
		}),

		create("Frame")({
			Name = "IconButtons",
			Size = UDim2.new(0.5, -8, 1, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			BackgroundTransparency = 1,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 4),
			}),

			create("UIPadding")({
				PaddingRight = UDim.new(0, 8),
			}),

			createIconButton("<", "Undo", function()
				EditorState.undo()
			end, function()
				return EditorState.canUndo()
			end),

			createIconButton(">", "Redo", function()
				EditorState.redo()
			end, function()
				return EditorState.canRedo()
			end),
		}),

		Dropdown({
			items = fileItems,
			isOpen = function()
				return openDropdown() == "File"
			end,
			onClose = closeDropdown,
			anchorPosition = Vector2.new(0, TOOLBAR_HEIGHT),
		}),

		Dropdown({
			items = editItems,
			isOpen = function()
				return openDropdown() == "Edit"
			end,
			onClose = closeDropdown,
			anchorPosition = Vector2.new(50, TOOLBAR_HEIGHT),
		}),

		Dropdown({
			items = viewItems,
			isOpen = function()
				return openDropdown() == "View"
			end,
			onClose = closeDropdown,
			anchorPosition = Vector2.new(100, TOOLBAR_HEIGHT),
		}),
	})
end
