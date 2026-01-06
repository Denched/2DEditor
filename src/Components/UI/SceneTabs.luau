--# selene: allow(mixed_table)

local Dropdown = require(script.Parent.Dropdown)
local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create
local source = vide.source
local indexes = vide.indexes
local show = vide.show

local TAB_HEIGHT = 28

local function Tab(props: {
	scene: () -> EditorState.SceneData,
	isActive: () -> boolean,
	onSelect: () -> (),
	onClose: () -> (),
})
	local isHovered = source(false)
	local isCloseHovered = source(false)

	return create("Frame")({
		Name = function()
			return "Tab_" .. props.scene().name
		end,
		Size = UDim2.fromOffset(100, TAB_HEIGHT - 2),
		BackgroundColor3 = function()
			if props.isActive() then
				return Color3.fromRGB(40, 40, 40)
			end
			return Color3.fromRGB(50, 50, 53)
		end,
		BorderSizePixel = 0,

		create("TextButton")({
			Name = "TabButton",
			Size = UDim2.new(1, -20, 1, 0),
			BackgroundTransparency = 1,
			Text = function()
				return props.scene().name
			end,
			TextSize = 11,
			TextColor3 = function()
				if props.isActive() then
					return Color3.fromRGB(255, 255, 255)
				end
				return Color3.fromRGB(180, 180, 180)
			end,
			Font = Enum.Font.GothamMedium,
			AutoButtonColor = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			MouseButton1Click = props.onSelect,

			create("UIPadding")({
				PaddingLeft = UDim.new(0, 8),
			}),
		}),

		create("TextButton")({
			Name = "CloseButton",
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(1, -18, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = function()
				if isCloseHovered() then
					return Color3.fromRGB(180, 60, 60)
				end
				return Color3.fromRGB(80, 80, 85)
			end,
			BackgroundTransparency = function()
				if isHovered() or isCloseHovered() then
					return 0
				end
				return 1
			end,
			BorderSizePixel = 0,
			Text = "×",
			TextSize = 12,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			MouseEnter = function()
				isCloseHovered(true)
			end,
			MouseLeave = function()
				isCloseHovered(false)
			end,
			MouseButton1Click = props.onClose,

			create("UICorner")({
				CornerRadius = UDim.new(0, 3),
			}),
		}),

		MouseEnter = function()
			isHovered(true)
		end,
		MouseLeave = function()
			isHovered(false)
		end,
	})
end

return function()
	local state = EditorState.get()
	local dropdownOpen = source(false)
	local addButtonHovered = source(false)

	local visibleScenes = function()
		local result = {}
		for _, scene in state.scenes() do
			if scene.visible then
				table.insert(result, scene)
			end
		end
		return result
	end

	local function closeDropdown()
		dropdownOpen(false)
	end

	local function toggleDropdown()
		dropdownOpen(not dropdownOpen())
	end

	local function selectScene(sceneId: number)
		EditorState.switchScene(sceneId)
	end

	local function hideScene(sceneId: number)
		EditorState.hideScene(sceneId)
	end

	local function showScene(sceneId: number)
		EditorState.showScene(sceneId)
	end

	local function createNewScene()
		EditorState.createScene()
	end

	local function getDropdownItems()
		local scenes = state.scenes()
		local items = {}

		if #scenes < 5 then
			table.insert(items, { label = "New Scene", onClick = createNewScene })
		else
			table.insert(items, { label = "New Scene", onClick = function() end, disabled = true })
		end

		-- Add hidden scenes to reopen
		local hiddenScenes = {}
		for _, scene in scenes do
			if not scene.visible then
				table.insert(hiddenScenes, scene)
			end
		end

		if #hiddenScenes > 0 then
			table.insert(items, { label = "", isSeparator = true, onClick = nil })
			for _, scene in hiddenScenes do
				table.insert(items, {
					label = "Reopen: " .. scene.name,
					onClick = function()
						showScene(scene.id)
					end,
				})
			end
		end

		return items
	end

	return create("Frame")({
		Name = "SceneTabs",
		Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(50, 50, 53),
		BorderSizePixel = 1,
		BorderColor3 = Color3.fromRGB(60, 60, 65),

		create("Frame")({
			Name = "TabContainer",
			Size = UDim2.new(1, -36, 1, -4),
			Position = UDim2.fromOffset(2, 2),
			BackgroundTransparency = 1,
			ClipsDescendants = true,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				Padding = UDim.new(0, 2),
			}),

			-- Dynamic tabs using vide indexes for reactive scopes
			indexes(visibleScenes, function(scene, _index)
				return Tab({
					scene = scene,
					isActive = function()
						return scene().id == state.activeSceneId()
					end,
					onSelect = function()
						selectScene(scene().id)
					end,
					onClose = function()
						hideScene(scene().id)
					end,
				})
			end),
		}),

		create("TextButton")({
			Name = "AddButton",
			Size = UDim2.fromOffset(26, TAB_HEIGHT - 4),
			Position = UDim2.new(1, -30, 0, 2),
			BackgroundColor3 = function()
				if dropdownOpen() or addButtonHovered() then
					return Color3.fromRGB(70, 70, 75)
				end
				return Color3.fromRGB(60, 60, 63)
			end,
			BorderSizePixel = 0,
			Text = "+",
			TextSize = 14,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			MouseEnter = function()
				addButtonHovered(true)
			end,
			MouseLeave = function()
				addButtonHovered(false)
			end,
			MouseButton1Click = toggleDropdown,
		}),

		show(dropdownOpen, function()
			return Dropdown({
				items = getDropdownItems(),
				isOpen = function()
					return true
				end,
				onClose = closeDropdown,
				anchorPosition = Vector2.new(4, TAB_HEIGHT),
				rightAligned = true,
			})
		end),
	})
end
