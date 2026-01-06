local RunService = game:GetService("RunService")

local EditorLayout = require(script.Parent.Components.UI.EditorLayout)
local EditorState = require(script.Parent.State.EditorState)
local vide = require(script.Parent.Packages.vide)

if RunService:IsRunning() then
	return
end

local mount = vide.mount

local toolbar = plugin:CreateToolbar("2D Editor")
local toggleButton = toolbar:CreateButton("2D Editor", "Open/Close", "rbxassetid://116802545746415")

local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 1200, 800, 600, 400)
local widget = plugin:CreateDockWidgetPluginGuiAsync("2DEditor", widgetInfo)

widget.Title = "2D Editor"
widget.Name = "2DEditor"

local cleanupMount = nil

local function mountUI()
	if cleanupMount then
		cleanupMount()
	end

	EditorState.init()

	cleanupMount = mount(function()
		return EditorLayout()
	end, widget)
end

local function unmountUI()
	if cleanupMount then
		cleanupMount()
		cleanupMount = nil
	end

	EditorState.cleanup()
end

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	if widget.Enabled then
		mountUI()
	else
		unmountUI()
	end
end)

plugin.Unloading:Connect(function()
	unmountUI()
end)
