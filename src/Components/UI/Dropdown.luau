--# selene: allow(mixed_table)

local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create
local action = vide.action

export type DropdownItem = {
	label: string | () -> string,
	onClick: (() -> ())?,
	shortcut: string?,
	disabled: boolean?,
	isSeparator: boolean?,
}

export type DropdownProps = {
	items: { DropdownItem } | () -> { DropdownItem },
	isOpen: () -> boolean,
	onClose: () -> (),
	anchorPosition: Vector2,
	rightAligned: boolean?,
}

local ITEM_HEIGHT = 24
local DROPDOWN_WIDTH = 160
local SEPARATOR_HEIGHT = 9
local MAX_VISIBLE_HEIGHT = 300
local SCROLLBAR_WIDTH = 6
local BASE_ZINDEX = 99

local NORMAL_BG = Color3.fromRGB(45, 45, 48)
local HOVER_BG = Color3.fromRGB(68, 137, 255)

local function createDropdownItem(item: DropdownItem, onClose: () -> (), layoutOrder: number)
	if item.isSeparator then
		return create("Frame")({
			Name = "Separator",
			Size = UDim2.new(1, 0, 0, SEPARATOR_HEIGHT),
			BackgroundTransparency = 1,
			LayoutOrder = layoutOrder,
			ZIndex = BASE_ZINDEX + 2,

			create("Frame")({
				Size = UDim2.new(1, -16, 0, 1),
				Position = UDim2.new(0, 8, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),
				BorderSizePixel = 0,
				ZIndex = BASE_ZINDEX + 2,
			}),
		})
	end

	local labelText = if type(item.label) == "function" then item.label() else item.label
	return create("TextButton")({
		Name = "Item_" .. labelText,
		Size = UDim2.new(1, 0, 0, ITEM_HEIGHT),
		BackgroundColor3 = NORMAL_BG,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = layoutOrder,
		ZIndex = BASE_ZINDEX + 2,

		action(function(btn: TextButton)
			if item.disabled then
				return
			end

			btn.MouseEnter:Connect(function()
				btn.BackgroundColor3 = HOVER_BG
				btn.BackgroundTransparency = 0.7
			end)

			btn.MouseLeave:Connect(function()
				btn.BackgroundColor3 = NORMAL_BG
				btn.BackgroundTransparency = 0
			end)
		end),

		MouseButton1Click = function()
			if not item.disabled and item.onClick then
				item.onClick()
				onClose()
			end
		end,

		create("TextLabel")({
			Name = "Label",
			Size = UDim2.new(1, -60, 1, 0),
			Position = UDim2.fromOffset(12, 0),
			BackgroundTransparency = 1,
			Text = if type(item.label) == "function" then item.label else item.label,
			TextSize = 11,
			TextColor3 = if item.disabled then Color3.fromRGB(100, 100, 100) else Color3.fromRGB(200, 200, 200),
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = BASE_ZINDEX + 3,
		}),
		if item.shortcut
			then create("TextLabel")({
				Name = "Shortcut",
				Size = UDim2.new(0, 50, 1, 0),
				Position = UDim2.new(1, -55, 0, 0),
				BackgroundTransparency = 1,
				Text = item.shortcut,
				TextSize = 10,
				TextColor3 = Color3.fromRGB(120, 120, 120),
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = BASE_ZINDEX + 3,
			})
			else nil,
	})
end

return function(props: DropdownProps)
	local items = if type(props.items) == "function" then props.items() else props.items

	local totalHeight = 0
	for _, item in items do
		if item.isSeparator then
			totalHeight = totalHeight + SEPARATOR_HEIGHT
		else
			totalHeight = totalHeight + ITEM_HEIGHT
		end
	end

	local contentHeight = totalHeight
	local needsScrolling = contentHeight > MAX_VISIBLE_HEIGHT
	local menuHeight = math.min(contentHeight + 8, MAX_VISIBLE_HEIGHT)

	local scrollFrameProps = {
		Name = "ScrollFrame",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = if needsScrolling then SCROLLBAR_WIDTH else 0,
		ScrollBarImageColor3 = Color3.fromRGB(80, 80, 85),
		CanvasSize = UDim2.fromOffset(0, contentHeight),
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ClipsDescendants = true,
		ZIndex = BASE_ZINDEX + 1,
	}

	table.insert(
		scrollFrameProps,
		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
	)

	table.insert(
		scrollFrameProps,
		create("UIPadding")({
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		})
	)

	for i, item in items do
		local element = createDropdownItem(item, props.onClose, i)
		table.insert(scrollFrameProps, element)
	end

	local menuPosition
	if props.rightAligned then
		menuPosition = UDim2.new(1, -DROPDOWN_WIDTH - props.anchorPosition.X, 0, props.anchorPosition.Y)
	else
		menuPosition = UDim2.fromOffset(props.anchorPosition.X, props.anchorPosition.Y)
	end

	local menuProps = {
		Name = "DropdownMenu",
		Size = UDim2.fromOffset(DROPDOWN_WIDTH, menuHeight),
		Position = menuPosition,
		BackgroundColor3 = Color3.fromRGB(45, 45, 48),
		BorderSizePixel = 1,
		BorderColor3 = Color3.fromRGB(60, 60, 60),
		ZIndex = BASE_ZINDEX + 1,
		ClipsDescendants = true,
	}

	table.insert(
		menuProps,
		create("UICorner")({
			CornerRadius = UDim.new(0, 4),
		})
	)

	table.insert(menuProps, create("ScrollingFrame")(scrollFrameProps))

	local overlayProps = {
		Name = "DropdownOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = props.isOpen,
		ZIndex = BASE_ZINDEX,
	}

	table.insert(
		overlayProps,
		create("TextButton")({
			Name = "ClickCatcher",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = BASE_ZINDEX,
			MouseButton1Click = function()
				props.onClose()
			end,
		})
	)

	table.insert(overlayProps, create("Frame")(menuProps))

	return create("Frame")(overlayProps)
end
