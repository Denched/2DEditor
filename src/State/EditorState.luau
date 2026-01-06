local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local vide = require(script.Parent.Parent.Packages.vide)

local source = vide.source

export type LogEntry = {
	timestamp: number,
	level: "info" | "warn" | "error",
	message: string,
}

export type PhysicsObject = {
	id: string,
	name: string,
	position: vector,
	halfExtents: vector,
	rotation: number,
	color: Color3,
}

export type SpawnPoint = {
	id: string,
	playerIndex: number,
	position: vector,
}

local SPAWN_COLORS = {
	[1] = Color3.fromRGB(255, 80, 80),
	[2] = Color3.fromRGB(80, 255, 80),
	[3] = Color3.fromRGB(80, 150, 255),
	[4] = Color3.fromRGB(255, 230, 80),
}

export type ImageEntity = {
	id: string,
	name: string,
	textureId: string,
	position: vector,
	size: vector,
	imageRectOffset: Vector2,
	imageRectSize: Vector2?,
	physicsObjects: { PhysicsObject },
}

export type SceneObject = ImageEntity | PhysicsObject

export type SceneData = {
	id: number,
	name: string,
	visible: boolean,
	entities: { ImageEntity },
	spawnPoints: { SpawnPoint },
	viewportOffset: vector,
	zoom: number,
}

export type State = {
	gridSize: () -> number,
	gridVisible: () -> boolean,
	zoom: () -> number,
	viewportOffset: () -> vector,
	canvasOrigin: () -> vector,
	isPanning: () -> boolean,
	lastMousePosition: () -> vector,
	canvasSize: () -> vector,
	backgroundColor: () -> Color3,

	entities: () -> { ImageEntity },
	selectedEntityId: () -> string?,
	selectedPhysicsObjectId: () -> string?,
	selectedSpawnPointId: () -> string?,
	spawnPoints: () -> { SpawnPoint },
	logs: () -> { LogEntry },

	scenes: () -> { SceneData },
	activeSceneId: () -> number,

	explorerVisible: () -> boolean,
	inspectorVisible: () -> boolean,
}

export type EditorState = {
	init: () -> (),
	cleanup: () -> (),
	get: () -> State,
	setZoom: (newZoom: number) -> (),
	panViewport: (delta: vector) -> (),
	screenToWorld: (screenPos: vector) -> vector,
	worldToScreen: (worldPos: vector) -> vector,
	setCanvasOrigin: (origin: vector) -> (),
	setCanvasSize: (size: vector) -> (),
	resetView: () -> (),

	setWaypoint: (name: string?) -> (),
	undo: () -> (),
	redo: () -> (),
	canUndo: () -> boolean,
	canRedo: () -> boolean,
	getSelection: () -> { Instance },
	setSelection: (objects: { Instance }) -> (),

	addEntity: (entity: ImageEntity) -> (),
	removeEntity: (entityId: string) -> (),
	getEntity: (entityId: string) -> ImageEntity?,
	updateEntity: (entityId: string, updates: { [string]: any }) -> (),

	addPhysicsObject: (entityId: string, physicsObject: PhysicsObject) -> (),
	removePhysicsObject: (entityId: string, physicsObjectId: string) -> (),
	getPhysicsObject: (entityId: string, physicsObjectId: string) -> PhysicsObject?,
	updatePhysicsObject: (entityId: string, physicsObjectId: string, updates: { [string]: any }) -> (),

	selectEntity: (entityId: string?) -> (),
	selectPhysicsObject: (physicsObjectId: string?) -> (),
	getSelectedEntity: () -> ImageEntity?,
	getSelectedPhysicsObject: () -> PhysicsObject?,

	addSpawnPoint: (position: vector) -> SpawnPoint?,
	removeSpawnPoint: (spawnId: string) -> (),
	updateSpawnPoint: (spawnId: string, updates: { [string]: any }) -> (),
	selectSpawnPoint: (spawnId: string?) -> (),
	getSelectedSpawnPoint: () -> SpawnPoint?,
	getSpawnColor: (playerIndex: number) -> Color3,

	log: (message: string, level: ("info" | "warn" | "error")?) -> (),
	clearLogs: () -> (),

	getScenes: () -> { SceneData },
	getActiveSceneId: () -> number,
	switchScene: (sceneId: number) -> (),
	createScene: () -> SceneData?,
	hideScene: (sceneId: number) -> (),
	showScene: (sceneId: number) -> (),
	renameScene: (sceneId: number, name: string) -> (),

	toggleExplorer: () -> (),
	toggleInspector: () -> (),
	showExplorer: () -> (),
	showInspector: () -> (),
	hideExplorer: () -> (),
	hideInspector: () -> (),
}

local MAX_PAN_DISTANCE = 10000
local MIN_ZOOM = 0.1
local MAX_ZOOM = 3
local MAX_HISTORY_SIZE = 50
local MAX_SCENES = 5

local EditorState = {} :: EditorState

local state = nil
local selectionConnection = nil

local historyStack: { { entities: { ImageEntity }, spawnPoints: { SpawnPoint } } } = {}
local historyIndex = 0
local isUndoRedoing = false

local function deepCloneEntity(entity: ImageEntity): ImageEntity
	local clonedPhysicsObjects = {}
	for _, po in entity.physicsObjects do
		table.insert(clonedPhysicsObjects, table.clone(po))
	end
	local cloned = table.clone(entity)
	cloned.physicsObjects = clonedPhysicsObjects
	return cloned
end

local function deepCloneEntities(entities: { ImageEntity }): { ImageEntity }
	local cloned = {}
	for _, entity in entities do
		table.insert(cloned, deepCloneEntity(entity))
	end
	return cloned
end

local function deepCloneSpawnPoints(spawns: { SpawnPoint }): { SpawnPoint }
	local cloned = {}
	for _, spawn in spawns do
		table.insert(cloned, table.clone(spawn))
	end
	return cloned
end

local function findById<T>(list: { T }, id: any): T?
	for _, item in list do
		if item.id == id then
			return item
		end
	end
	return nil
end

local function updateById<T>(list: { T }, id: any, updates: { [string]: any }): { T }
	local newList = table.clone(list)
	for i, item in newList do
		if item.id == id then
			local updated = table.clone(item)
			for key, value in updates do
				updated[key] = value
			end
			newList[i] = updated
			break
		end
	end
	return newList
end

local function saveToHistory()
	if isUndoRedoing then
		return
	end

	while #historyStack > historyIndex do
		table.remove(historyStack)
	end

	local snapshot = {
		entities = deepCloneEntities(state.entities()),
		spawnPoints = deepCloneSpawnPoints(state.spawnPoints()),
	}
	table.insert(historyStack, snapshot)
	historyIndex = #historyStack

	if #historyStack > MAX_HISTORY_SIZE then
		table.remove(historyStack, 1)
		historyIndex = historyIndex - 1
	end
end

function EditorState.init()
	if state then
		return
	end

	local defaultScene: SceneData = {
		id = 1,
		name = "Scene1",
		visible = true,
		entities = {},
		spawnPoints = {},
		viewportOffset = vector.create(600, 400, 0),
		zoom = 1,
	}

	state = {
		gridSize = source(16),
		gridVisible = source(true),
		zoom = source(1),
		viewportOffset = source(vector.create(600, 400, 0)),
		canvasOrigin = source(vector.create(0, 0, 0)),

		isPanning = source(false),
		lastMousePosition = source(vector.create(0, 0, 0)),

		canvasSize = source(vector.create(4096, 4096, 0)),
		backgroundColor = source(Color3.fromRGB(40, 40, 40)),

		entities = source({}),
		selectedEntityId = source(nil),
		selectedPhysicsObjectId = source(nil),
		selectedSpawnPointId = source(nil),
		spawnPoints = source({}),
		logs = source({}),

		scenes = source({ defaultScene }),
		activeSceneId = source(1),
		nextSceneId = source(2),

		explorerVisible = source(true),
		inspectorVisible = source(true),
	}

	historyStack = {}
	historyIndex = 0
	saveToHistory()
end

function EditorState.cleanup()
	if selectionConnection then
		selectionConnection:Disconnect()
		selectionConnection = nil
	end
	state = nil
end

function EditorState.get()
	return state
end
function EditorState.setZoom(newZoom: number)
	local clamped = math.clamp(newZoom, MIN_ZOOM, MAX_ZOOM)
	state.zoom(clamped)
end
function EditorState.panViewport(delta: vector)
	local current = state.viewportOffset()
	local newOffset = current + delta

	newOffset = vector.create(
		math.clamp(newOffset.X, -MAX_PAN_DISTANCE, MAX_PAN_DISTANCE),
		math.clamp(newOffset.Y, -MAX_PAN_DISTANCE, MAX_PAN_DISTANCE),
		0
	)

	state.viewportOffset(newOffset)
end

function EditorState.screenToWorld(screenPos: vector): vector
	local zoom = state.zoom()
	local offset = state.viewportOffset()
	local origin = state.canvasOrigin()

	return (screenPos - origin - offset) / zoom
end

function EditorState.worldToScreen(worldPos: vector): vector
	local zoom = state.zoom()
	local offset = state.viewportOffset()
	local origin = state.canvasOrigin()
	local result = worldPos * zoom + offset + origin

	return result
end

function EditorState.resetView()
	state.viewportOffset(vector.create(600, 400, 0))
	state.zoom(1)
end

function EditorState.setCanvasOrigin(origin: vector)
	if not state then
		return
	end

	state.canvasOrigin(origin)
end

function EditorState.setCanvasSize(size: vector)
	if not state then
		return
	end

	state.canvasSize(size)
end

function EditorState.zoomTowardPoint(newZoom: number, screenPoint: vector)
	local currentZoom = state.zoom()
	local clamped = math.clamp(newZoom, MIN_ZOOM, MAX_ZOOM)

	if clamped == currentZoom then
		return
	end

	local worldPoint = EditorState.screenToWorld(screenPoint)
	state.zoom(clamped)

	local newScreenPoint = EditorState.worldToScreen(worldPoint)

	local screenDelta = screenPoint - newScreenPoint

	local currentOffset = state.viewportOffset()
	state.viewportOffset(currentOffset + screenDelta)
end

function EditorState.setWaypoint(_name: string?)
	saveToHistory()
end

function EditorState.undo()
	if historyIndex <= 1 then
		return
	end

	isUndoRedoing = true
	historyIndex = historyIndex - 1
	local snapshot = historyStack[historyIndex]
	state.entities(deepCloneEntities(snapshot.entities))
	state.spawnPoints(deepCloneSpawnPoints(snapshot.spawnPoints))
	isUndoRedoing = false
end

function EditorState.redo()
	if historyIndex >= #historyStack then
		return -- Nothing to redo
	end

	isUndoRedoing = true
	historyIndex = historyIndex + 1
	local snapshot = historyStack[historyIndex]
	state.entities(deepCloneEntities(snapshot.entities))
	state.spawnPoints(deepCloneSpawnPoints(snapshot.spawnPoints))
	isUndoRedoing = false
end

function EditorState.canUndo(): boolean
	return historyIndex > 1
end

function EditorState.canRedo(): boolean
	return historyIndex < #historyStack
end

function EditorState.getSelection(): { Instance }
	return Selection:Get()
end

function EditorState.setSelection(objects: { Instance })
	Selection:Set(objects)
end

function EditorState.addEntity(entity: ImageEntity)
	local entities = state.entities()

	local newEntities = table.clone(entities)
	table.insert(newEntities, entity)
	state.entities(newEntities)

	EditorState.log("Added entity: " .. entity.name)
	EditorState.setWaypoint("Add Entity")
end

function EditorState.removeEntity(entityId: string)
	local entities = state.entities()
	local removedName = nil
	local newEntities = {}
	for _, entity in entities do
		if entity.id ~= entityId then
			table.insert(newEntities, entity)
		else
			removedName = entity.name
		end
	end
	state.entities(newEntities)

	if state.selectedEntityId() == entityId then
		state.selectedEntityId(nil)
		state.selectedPhysicsObjectId(nil)
	end

	if removedName then
		EditorState.log("Removed entity: " .. removedName)
	end
	EditorState.setWaypoint("Remove Entity")
end

function EditorState.getEntity(entityId: string): ImageEntity?
	return findById(state.entities(), entityId)
end

function EditorState.updateEntity(entityId: string, updates: { [string]: any })
	state.entities(updateById(state.entities(), entityId, updates))
end

function EditorState.addPhysicsObject(entityId: string, physicsObject: PhysicsObject)
	local entity = EditorState.getEntity(entityId)
	if not entity then
		EditorState.log("Entity not found: " .. entityId, "error")
		return
	end

	local newPhysicsObjects = table.clone(entity.physicsObjects)
	table.insert(newPhysicsObjects, physicsObject)

	EditorState.updateEntity(entityId, {
		physicsObjects = newPhysicsObjects,
	})
	EditorState.log("Added hitbox: " .. physicsObject.name .. " to " .. entity.name)
	EditorState.setWaypoint("Add PhysicsObject")
end

function EditorState.removePhysicsObject(entityId: string, physicsObjectId: string)
	local entity = EditorState.getEntity(entityId)
	if not entity then
		return
	end

	local removedName = nil
	local newPhysicsObjects = {}
	for _, po in entity.physicsObjects do
		if po.id ~= physicsObjectId then
			table.insert(newPhysicsObjects, po)
		else
			removedName = po.name
		end
	end

	EditorState.updateEntity(entityId, {
		physicsObjects = newPhysicsObjects,
	})

	if state.selectedPhysicsObjectId() == physicsObjectId then
		state.selectedPhysicsObjectId(nil)
	end

	if removedName then
		EditorState.log("Removed hitbox: " .. removedName .. " from " .. entity.name)
	end
	EditorState.setWaypoint("Remove PhysicsObject")
end

function EditorState.getPhysicsObject(entityId: string, physicsObjectId: string): PhysicsObject?
	local entity = EditorState.getEntity(entityId)
	if not entity then
		return nil
	end
	return findById(entity.physicsObjects, physicsObjectId)
end

function EditorState.updatePhysicsObject(entityId: string, physicsObjectId: string, updates: { [string]: any })
	local entity = EditorState.getEntity(entityId)
	if not entity then
		return
	end
	EditorState.updateEntity(entityId, {
		physicsObjects = updateById(entity.physicsObjects, physicsObjectId, updates),
	})
end

function EditorState.selectEntity(entityId: string?)
	state.selectedEntityId(entityId)
	state.selectedPhysicsObjectId(nil)
end

function EditorState.selectPhysicsObject(physicsObjectId: string?)
	state.selectedPhysicsObjectId(physicsObjectId)
end

function EditorState.getSelectedEntity(): ImageEntity?
	local selectedId = state.selectedEntityId()
	if not selectedId then
		return nil
	end
	return EditorState.getEntity(selectedId)
end

function EditorState.getSelectedPhysicsObject(): PhysicsObject?
	local selectedId = state.selectedPhysicsObjectId()
	local selectedEntityId = state.selectedEntityId()

	if not selectedId or not selectedEntityId then
		return nil
	end

	return EditorState.getPhysicsObject(selectedEntityId, selectedId)
end

local MAX_SPAWN_POINTS = 4

function EditorState.getSpawnColor(playerIndex: number): Color3
	return SPAWN_COLORS[playerIndex] or Color3.fromRGB(255, 255, 255)
end

function EditorState.addSpawnPoint(position: vector): SpawnPoint?
	local spawns = state.spawnPoints()

	if #spawns >= MAX_SPAWN_POINTS then
		EditorState.log("Maximum spawn points reached (4)", "warn")
		return nil
	end

	local usedIndices = {}
	for _, spawn in spawns do
		usedIndices[spawn.playerIndex] = true
	end

	local nextIndex = nil
	for i = 1, MAX_SPAWN_POINTS do
		if not usedIndices[i] then
			nextIndex = i
			break
		end
	end

	if not nextIndex then
		return nil
	end

	local id = HttpService:GenerateGUID(false)
	local spawnPoint: SpawnPoint = {
		id = id,
		playerIndex = nextIndex,
		position = position,
	}

	local newSpawns = table.clone(spawns)
	table.insert(newSpawns, spawnPoint)
	state.spawnPoints(newSpawns)

	EditorState.log("Added spawn point P" .. nextIndex)
	EditorState.setWaypoint("Add Spawn Point")

	return spawnPoint
end

function EditorState.removeSpawnPoint(spawnId: string)
	local spawns = state.spawnPoints()
	local removedIndex = nil
	local newSpawns = {}

	for _, spawn in spawns do
		if spawn.id ~= spawnId then
			table.insert(newSpawns, spawn)
		else
			removedIndex = spawn.playerIndex
		end
	end

	state.spawnPoints(newSpawns)

	if state.selectedSpawnPointId() == spawnId then
		state.selectedSpawnPointId(nil)
	end

	if removedIndex then
		EditorState.log("Removed spawn point P" .. removedIndex)
	end
	EditorState.setWaypoint("Remove Spawn Point")
end

function EditorState.updateSpawnPoint(spawnId: string, updates: { [string]: any })
	state.spawnPoints(updateById(state.spawnPoints(), spawnId, updates))
end

function EditorState.selectSpawnPoint(spawnId: string?)
	state.selectedSpawnPointId(spawnId)
	if spawnId then
		state.selectedEntityId(nil)
		state.selectedPhysicsObjectId(nil)
	end
end

function EditorState.getSelectedSpawnPoint(): SpawnPoint?
	local selectedId = state.selectedSpawnPointId()
	if not selectedId then
		return nil
	end
	return findById(state.spawnPoints(), selectedId)
end

local MAX_LOG_ENTRIES = 200

function EditorState.log(message: string, level: ("info" | "warn" | "error")?)
	local logs = state.logs()
	local newLogs = table.clone(logs)

	local entry: LogEntry = {
		timestamp = os.time(),
		level = level or "info",
		message = message,
	}

	table.insert(newLogs, entry)

	while #newLogs > MAX_LOG_ENTRIES do
		table.remove(newLogs, 1)
	end

	state.logs(newLogs)
end

function EditorState.clearLogs()
	state.logs({})
end

function EditorState.getScenes(): { SceneData }
	return state.scenes()
end

function EditorState.getActiveSceneId(): number
	return state.activeSceneId()
end

local function saveCurrentSceneData()
	local currentId = state.activeSceneId()
	local scenes = state.scenes()
	local newScenes = {}

	for _, scene in scenes do
		if scene.id == currentId then
			local updatedScene: SceneData = {
				id = scene.id,
				name = scene.name,
				visible = scene.visible,
				entities = deepCloneEntities(state.entities()),
				spawnPoints = deepCloneSpawnPoints(state.spawnPoints()),
				viewportOffset = state.viewportOffset(),
				zoom = state.zoom(),
			}
			table.insert(newScenes, updatedScene)
		else
			table.insert(newScenes, scene)
		end
	end

	state.scenes(newScenes)
end

local function findSceneById(sceneId: number): SceneData?
	return findById(state.scenes(), sceneId)
end

local function updateSceneProperty(sceneId: number, property: string, value: any): string?
	local scenes = state.scenes()
	local sceneName = nil
	local newScenes = {}

	for _, scene in scenes do
		if scene.id == sceneId then
			local updatedScene = table.clone(scene)
			updatedScene[property] = value
			sceneName = scene.name
			table.insert(newScenes, updatedScene)
		else
			table.insert(newScenes, scene)
		end
	end

	state.scenes(newScenes)
	return sceneName
end

function EditorState.switchScene(sceneId: number)
	local currentId = state.activeSceneId()
	if sceneId == currentId then
		return -- Already on this scene
	end

	local targetScene = findSceneById(sceneId)
	if not targetScene then
		EditorState.log("Scene not found: " .. sceneId, "error")
		return
	end

	saveCurrentSceneData()

	state.selectedEntityId(nil)
	state.selectedPhysicsObjectId(nil)
	state.selectedSpawnPointId(nil)

	state.entities(deepCloneEntities(targetScene.entities))
	state.spawnPoints(deepCloneSpawnPoints(targetScene.spawnPoints))
	state.viewportOffset(targetScene.viewportOffset)
	state.zoom(targetScene.zoom)
	state.activeSceneId(sceneId)

	historyStack = {}
	historyIndex = 0
	saveToHistory()

	EditorState.log("Switched to " .. targetScene.name)
end

function EditorState.createScene(): SceneData?
	local scenes = state.scenes()

	if #scenes >= MAX_SCENES then
		EditorState.log("Maximum scenes reached (" .. MAX_SCENES .. ")", "warn")
		return nil
	end

	saveCurrentSceneData()
	scenes = state.scenes() -- Re-fetch after save to get updated data

	local nextId = state.nextSceneId()
	local newScene: SceneData = {
		id = nextId,
		name = "Scene" .. nextId,
		visible = true,
		entities = {},
		spawnPoints = {},
		viewportOffset = vector.create(600, 400, 0),
		zoom = 1,
	}

	local newScenes = table.clone(scenes)
	table.insert(newScenes, newScene)
	state.scenes(newScenes)
	state.nextSceneId(nextId + 1)

	state.selectedEntityId(nil)
	state.selectedPhysicsObjectId(nil)
	state.selectedSpawnPointId(nil)
	state.entities({})
	state.spawnPoints({})
	state.viewportOffset(vector.create(600, 400, 0))
	state.zoom(1)
	state.activeSceneId(nextId)

	historyStack = {}
	historyIndex = 0
	saveToHistory()

	EditorState.log("Created " .. newScene.name)
	return newScene
end

function EditorState.hideScene(sceneId: number)
	local scenes = state.scenes()

	local visibleCount = 0
	for _, scene in scenes do
		if scene.visible then
			visibleCount = visibleCount + 1
		end
	end

	if visibleCount <= 1 then
		EditorState.log("Cannot hide last visible scene", "warn")
		return
	end

	saveCurrentSceneData()

	local hiddenSceneName = updateSceneProperty(sceneId, "visible", false)

	if state.activeSceneId() == sceneId then
		for _, scene in state.scenes() do
			if scene.visible then
				EditorState.switchScene(scene.id)
				break
			end
		end
	end

	if hiddenSceneName then
		EditorState.log("Closed " .. hiddenSceneName)
	end
end

function EditorState.showScene(sceneId: number)
	local shownSceneName = updateSceneProperty(sceneId, "visible", true)
	if shownSceneName then
		EditorState.switchScene(sceneId)
		EditorState.log("Reopened " .. shownSceneName)
	end
end

function EditorState.renameScene(sceneId: number, name: string)
	updateSceneProperty(sceneId, "name", name)
end

local function setPanelVisibility(panel: string, value: boolean?)
	if not state then
		return
	end
	local vis = if panel == "explorer" then state.explorerVisible else state.inspectorVisible
	vis(if value == nil then not vis() else value)
end

function EditorState.toggleExplorer()
	setPanelVisibility("explorer")
end
function EditorState.toggleInspector()
	setPanelVisibility("inspector")
end
function EditorState.showExplorer()
	setPanelVisibility("explorer", true)
end
function EditorState.showInspector()
	setPanelVisibility("inspector", true)
end
function EditorState.hideExplorer()
	setPanelVisibility("explorer", false)
end
function EditorState.hideInspector()
	setPanelVisibility("inspector", false)
end

return EditorState
