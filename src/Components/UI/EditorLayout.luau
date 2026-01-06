--# selene: allow(mixed_table)

local TopToolbar = require(script.Parent.TopToolbar)
local SceneTabs = require(script.Parent.SceneTabs)
local LeftPanel = require(script.Parent.LeftPanel)
local RightPanel = require(script.Parent.RightPanel)
local BottomPanel = require(script.Parent.BottomPanel)
local Viewport = require(script.Parent.Viewport)
local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local create = vide.create
local show = vide.show

local TOOLBAR_HEIGHT = 32
local TABS_HEIGHT = 28
local LEFT_PANEL_WIDTH = 160
local RIGHT_PANEL_WIDTH = 180
local BOTTOM_PANEL_HEIGHT = 140

return function()
	local state = EditorState.get()

	local function leftWidth()
		return if state.explorerVisible() then LEFT_PANEL_WIDTH else 0
	end

	local function rightWidth()
		return if state.inspectorVisible() then RIGHT_PANEL_WIDTH else 0
	end

	local root = create("Frame")({
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(37, 37, 37),

		TopToolbar(),

		create("Frame")({
			Size = function()
				return UDim2.new(1, -(leftWidth() + rightWidth()), 0, TABS_HEIGHT)
			end,
			Position = function()
				return UDim2.fromOffset(leftWidth(), TOOLBAR_HEIGHT)
			end,
			BackgroundTransparency = 1,

			SceneTabs(),
		}),

		show(state.explorerVisible, function()
			return create("Frame")({
				Name = "LeftPanelContainer",
				Size = UDim2.new(0, LEFT_PANEL_WIDTH, 1, -(TOOLBAR_HEIGHT + TABS_HEIGHT)),
				Position = UDim2.fromOffset(0, TOOLBAR_HEIGHT + TABS_HEIGHT),
				BackgroundTransparency = 1,

				LeftPanel(),
			})
		end),

		show(state.inspectorVisible, function()
			return create("Frame")({
				Name = "RightPanelContainer",
				Size = UDim2.new(0, RIGHT_PANEL_WIDTH, 1, -(TOOLBAR_HEIGHT + TABS_HEIGHT)),
				Position = UDim2.new(1, 0, 0, TOOLBAR_HEIGHT + TABS_HEIGHT),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,

				RightPanel(),
			})
		end),

		BottomPanel(),

		create("Frame")({
			Name = "ViewportContainer",
			Size = function()
				return UDim2.new(
					1,
					-(leftWidth() + rightWidth()),
					1,
					-(TOOLBAR_HEIGHT + TABS_HEIGHT + BOTTOM_PANEL_HEIGHT)
				)
			end,
			Position = function()
				return UDim2.fromOffset(leftWidth(), TOOLBAR_HEIGHT + TABS_HEIGHT)
			end,
			BackgroundColor3 = Color3.fromRGB(54, 57, 63),
			BorderSizePixel = 0,

			Viewport(),
		}),
	})

	vide.cleanup(root)
	return root
end
