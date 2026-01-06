--# selene: allow(mixed_table)

local AxisOverlay = require(script.Parent.AxisOverlay)
local ZoomControls = require(script.Parent.ZoomControls)
local RulerCorner = require(script.Parent.RulerCorner)
local Ruler = require(script.Parent.Ruler)
local PerformanceMonitor = require(script.Parent.PerformanceMonitor)
local ImageRenderer = require(script.Parent.Parent.Rendering.ImageRenderer)
local SpawnPointRenderer = require(script.Parent.Parent.Rendering.SpawnPointRenderer)
local PhysicsObjectOverlay = require(script.Parent.Parent.Physics.PhysicsObjectOverlay)
local PhysicsObjectInputHandler = require(script.Parent.Parent.Inputs.PhysicsObjectInputHandler)
local ImageInputHandler = require(script.Parent.Parent.Inputs.ImageInputHandler)
local SpawnPointInputHandler = require(script.Parent.Parent.Inputs.SpawnPointInputHandler)
local ImageSelectionOverlay = require(script.Parent.Parent.Inputs.ImageSelectionOverlay)
local EditorState = require(script.Parent.Parent.Parent.State.EditorState)
local Throttle = require(script.Parent.Parent.Parent.Util.Throttle)
local ZIndexes = require(script.Parent.Parent.Parent.Constants.ZIndexes)
local vide = require(script.Parent.Parent.Parent.Packages.vide)

local source = vide.source
local action = vide.action
local create = vide.create

local function Viewport()
	local state = EditorState.get()

	local isDragging = source(false)
	local dragStart = source(vector.create(0, 0, 0))

	-- A throttled pan update for performance
	local throttledPanUpdate = Throttle.throttle(function(delta: vector)
		EditorState.panViewport(delta)
	end, 1 / 60)

	local function handleMouseInput(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			if input.UserInputState == Enum.UserInputState.Begin then
				isDragging(true)
				dragStart(vector.create(input.Position.X, input.Position.Y, 0))
				state.isPanning(true)
			elseif input.UserInputState == Enum.UserInputState.End then
				isDragging(false)
				state.isPanning(false)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseMovement then
			if isDragging() then
				local currentPos = vector.create(input.Position.X, input.Position.Y, 0)
				local delta = currentPos - dragStart()
				throttledPanUpdate(delta)
				dragStart(currentPos)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			local screenPoint = vector.create(input.Position.X, input.Position.Y, 0)

			local currentZoom = state.zoom()
			local zoomDelta = input.Position.Z * 0.1

			EditorState.zoomTowardPoint(currentZoom + zoomDelta, screenPoint)
		end
	end

	local root = create("Frame")({
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = state.backgroundColor(),

		RulerCorner(),
		Ruler({
			isHorizontal = true,
		}),
		Ruler({
			isHorizontal = false,
		}),
		-- Toolbar(),

		create("Frame")({
			Name = "Canvas",
			Position = UDim2.fromOffset(20, 20),
			Size = UDim2.new(1, -20, 1, -20),
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			ClipsDescendants = true,
			BorderSizePixel = 0,
			ZIndex = ZIndexes.Canvas,
			action(function(canvasFrame: Frame)
				local function updateOrigin()
					local abs = canvasFrame.AbsolutePosition
					EditorState.setCanvasOrigin(vector.create(abs.X, abs.Y, 0))
				end

				local function updateSize()
					local size = canvasFrame.AbsoluteSize
					EditorState.setCanvasSize(vector.create(size.X, size.Y, 0))
				end

				updateOrigin()
				updateSize()

				local positionConn = canvasFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateOrigin)
				local sizeConn = canvasFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSize)
				canvasFrame.Destroying:Connect(function()
					if positionConn then
						positionConn:Disconnect()
						positionConn = nil
					end
					if sizeConn then
						sizeConn:Disconnect()
						sizeConn = nil
					end
				end)
			end),

			AxisOverlay(),

			create("Frame")({
				Name = "InputHandler",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ZIndex = 1,
				Active = true,

				InputBegan = handleMouseInput,
				InputChanged = handleMouseInput,
				InputEnded = handleMouseInput,
			}),

			ImageRenderer(),

			ImageSelectionOverlay(),

			PhysicsObjectOverlay(),

			SpawnPointRenderer(),

			SpawnPointInputHandler(),

			PhysicsObjectInputHandler(),

			ImageInputHandler(),

			ZoomControls(),
		}),
		PerformanceMonitor(),
	})

	vide.cleanup(root)
	return root
end

return Viewport
