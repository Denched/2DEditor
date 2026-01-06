--# selene: allow(mixed_table)

local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create
local source = vide.source

local PANEL_HEIGHT = 140
local TAB_HEIGHT = 28
local LOG_ITEM_HEIGHT = 18

local LOG_COLORS = {
	info = Color3.fromRGB(200, 200, 200),
	warn = Color3.fromRGB(255, 200, 80),
	error = Color3.fromRGB(255, 100, 100),
}

local function formatTime(timestamp: number): string
	return os.date("[%H:%M:%S]", timestamp)
end

local function createLogEntry(log: EditorState.LogEntry, layoutOrder: number)
	local color = LOG_COLORS[log.level] or LOG_COLORS.info

	return create("Frame")({
		Size = UDim2.new(1, -8, 0, LOG_ITEM_HEIGHT),
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,

		create("TextLabel")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = formatTime(log.timestamp) .. " " .. log.message,
			TextSize = 11,
			TextColor3 = color,
			Font = Enum.Font.RobotoMono,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
	})
end

local function createTab(name: string, isActive: boolean, onClick: () -> ())
	return create("Frame")({
		Size = UDim2.fromOffset(80, TAB_HEIGHT),
		BackgroundTransparency = 1,

		create("TextButton")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = name,
			TextSize = 11,
			TextColor3 = if isActive then Color3.fromRGB(200, 200, 200) else Color3.fromRGB(140, 140, 140),
			Font = Enum.Font.GothamMedium,
			AutoButtonColor = false,
			MouseButton1Click = onClick or function() end,
		}),

		create("Frame")({
			Size = UDim2.new(1, -8, 0, 2),
			Position = UDim2.new(0.5, 0, 1, -2),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(68, 137, 255),
			BackgroundTransparency = if isActive then 0 else 1,
			BorderSizePixel = 0,
		}),
	})
end

return function()
	local activeTab = source(1)

	return create("Frame")({
		Name = "BottomPanel",
		Size = UDim2.new(1, 0, 0, PANEL_HEIGHT),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(37, 37, 37),
		BorderSizePixel = 0,

		create("Frame")({
			Name = "TopBorder",
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = Color3.fromRGB(28, 28, 28),
			BorderSizePixel = 0,
		}),

		create("Frame")({
			Name = "TabBar",
			Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
			Position = UDim2.fromOffset(0, 1),
			BackgroundColor3 = Color3.fromRGB(48, 48, 48),
			BorderSizePixel = 0,

			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			}),

			function()
				local active = activeTab()
				return createTab("Animation", active == 1, function()
					activeTab(1)
				end)
			end,

			function()
				local active = activeTab()
				return createTab("Output", active == 2, function()
					activeTab(2)
				end)
			end,
		}),

		create("ScrollingFrame")({
			Name = "Content",
			Position = UDim2.fromOffset(0, TAB_HEIGHT),
			Size = UDim2.new(1, 0, 1, -TAB_HEIGHT),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromScale(0, 0),

			create("UIPadding")({
				PaddingLeft = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),

			create("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),

			function()
				local active = activeTab()
				if active == 1 then
					return create("TextLabel")({
						Size = UDim2.new(1, -8, 0, 24),
						BackgroundTransparency = 1,
						Text = "Animation editor will go here",
						TextSize = 12,
						TextColor3 = Color3.fromRGB(150, 150, 150),
						Font = Enum.Font.Gotham,
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 0,
					})
				else
					local state = EditorState.get()
					local logs = state.logs()

					if #logs == 0 then
						return create("TextLabel")({
							Size = UDim2.new(1, -8, 0, 24),
							BackgroundTransparency = 1,
							Text = "No output yet...",
							TextSize = 11,
							TextColor3 = Color3.fromRGB(120, 120, 120),
							Font = Enum.Font.RobotoMono,
							TextXAlignment = Enum.TextXAlignment.Left,
							LayoutOrder = 0,
						})
					end

					local items = {}
					for i, log in logs do
						table.insert(items, createLogEntry(log, i))
					end
					return items
				end
			end,
		}),

		create("TextButton")({
			Name = "ClearButton",
			Size = UDim2.fromOffset(50, 20),
			Position = UDim2.new(1, -58, 0, 4),
			BackgroundColor3 = Color3.fromRGB(60, 60, 65),
			BorderSizePixel = 0,
			Text = "Clear",
			TextSize = 10,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			Font = Enum.Font.GothamMedium,
			Visible = function()
				return activeTab() == 2
			end,
			MouseButton1Click = function()
				EditorState.clearLogs()
			end,
		}),
	})
end
