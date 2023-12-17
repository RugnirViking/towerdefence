extends Node

# Grid size
var grid_size: Vector2 = Vector2(64, 64)  # Adjust this to match your grid cell size

# Offset to center the selection box on the grid cell
var offset: Vector2 = Vector2(32, 32)

# Reference to the selection box sprite
@onready var selection_box: Node = $SelectionBox
# Reference to the selection box sprite
@onready var hover_box: Node = $HoverBox

@export var camera: Camera2D

@export var selectpreviewViewport: SubViewport
@export var selectPanel: Control
@export var buildPanel: Control
@export var tiles: TileMap
@export var barrierprefab: PackedScene
@export var gunprefab: PackedScene
@export var machinegunprefab: PackedScene
@export var drillprefab: PackedScene
@export var enemies: Array[Node2D]
@export var enemyPrefabs: Array[PackedScene]
@export var enemyprefab: PackedScene

var object_registry = []
var selected_object = {}

# Variable to store the selected position
var selected_position: Vector2 = Vector2()
var mouse_world_events: bool = true

func _ready():
	hover_box.visible = false
	selection_box.visible = false
	selectPanel.visible = false
	buildPanel.visible = false
	
	selectpreviewViewport.world_2d = get_viewport().world_2d

func deselect_all():
	for object in object_registry:
		if object["node"].has_method("set_selected"):
			object["node"].set_selected(false)
	selected_object = {}
func search_for_tiletype(type: String) -> Dictionary:
	var i = 0
	for object in object_registry:
		i += 1
		if object["type"] == type:
			return object
	return {}

func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)
func _process(delta):
	
	if Input.is_action_just_pressed("right_click"):
		
		deselect_all()
		selection_box.visible = false
		selectPanel.visible = false
		buildPanel.visible = false
		mouse_world_events = true
	# Check if the mouse is over the panel
	if not mouse_world_events:
		# Ignore hover events or other mouse interactions
		return

	var mouse_pos = get_global_mouse_position()
	var grid_position = world_to_grid(mouse_pos)

	# Update selection box position
	hover_box.global_position = grid_to_world(grid_position) + offset
	hover_box.visible = true

	# Check for mouse click
	if Input.is_action_just_pressed("click"):  # Make sure 'click' is defined in your input map
		deselect_all()
		selected_position = grid_position
		selection_box.global_position = grid_to_world(selected_position) + offset
		selection_box.visible = true
		selectPanel.visible = true
		selectpreviewViewport.get_node("TilePreviewCamera").global_position = grid_to_world(selected_position)
		
		# if shift held down
		if Input.is_action_pressed("shift"):
			if check_tile_free(world_to_grid(selection_box.global_position)) and tiletype(world_to_grid(selection_box.global_position)) == 2:
				var barrier = barrierprefab.instantiate()
				barrier.global_position = selection_box.global_position
				add_child(barrier)
				buildPanel.visible = false
				mouse_world_events = true
				object_registry.append({"type":"barrier","position":barrier.global_position,"grid_position":world_to_grid(barrier.global_position), "node":barrier})
				kill_navmesh_below(world_to_grid(selection_box.global_position))
			else:
				print("tile not free")
		
		# if ctrl held down
		if Input.is_action_pressed("ctrl"):
			# spawn a random enemy from the enemyPrefabs array
			var prefab = enemyPrefabs[randi() % enemyPrefabs.size()]
			var enemy = prefab.instantiate()
			enemy.global_position = selection_box.global_position
			enemies.append(enemy)
			add_child(enemy)
			var firstdrill = search_for_tiletype("drill")
			if firstdrill:
				enemy.call("set_target",firstdrill["position"])
			




		print("Selected grid position: ", selected_position, tiles.get_cell_atlas_coords(0,selected_position), tiles.get_cell_alternative_tile(0,selected_position))
		# Get the index of the tile at the grid position
		
		var selectedlbl = selectPanel.get_node("VBoxContainer/TileNameLabel")
		if check_tile_free(selected_position):
			deselect_all()
			var tile_index = tiles.get_cell_tile_data(0,selected_position)
			if tile_index:
				selectedlbl.text = tile_index.get_custom_data("name")
		else:
			# deselect previous object
			deselect_all()
			var obj = get_object_at(selected_position)
			selected_object = obj
			selectedlbl.text = selected_object.type
			
			if selected_object["node"].has_method("set_selected"):
				selected_object.node.set_selected(true)
	
	var statspanel = selectPanel.get_node("VBoxContainer/stats")
	var selecteddmglbl = selectPanel.get_node("VBoxContainer/stats/lifetimeDamagelbl")
	var lifetimeEngagedlbl = selectPanel.get_node("VBoxContainer/stats/lifetimeEngagedlbl")
	var engagedPctlbl = selectPanel.get_node("VBoxContainer/stats/engagedpctlbl")
	statspanel.visible = false
	if selected_object:
		if selected_object["node"].has_method("set_selected"):
			selecteddmglbl.text = str(selected_object["node"].get("lifetime_damage"))
			lifetimeEngagedlbl.text = str(round_to_dec(selected_object["node"].get("lifetime_engage_time"),2))
			engagedPctlbl.text = str(round_to_dec(selected_object["node"].get("lifetime_engage_time")*100/selected_object["node"].get("lifetime"),2))+ " %"
			statspanel.visible = true
			
			
		


func get_global_mouse_position() -> Vector2:
	# Convert the mouse position from viewport to world space, considering the camera zoom
	var viewport_mouse_pos = get_viewport().get_mouse_position()
	var viewport_center = get_viewport().size * 0.5
	return camera.global_position + (viewport_mouse_pos - viewport_center) / camera.zoom


func world_to_grid(world_position: Vector2) -> Vector2:
	return (world_position / grid_size).floor()

func grid_to_world(grid_position: Vector2) -> Vector2:
	return grid_position * grid_size

func _on_panel_mouse_entered():
	mouse_world_events = false

func _on_panel_mouse_exited():
	mouse_world_events = true

func _on_build_panel_button_pressed():
	buildPanel.visible=true

func check_tile_free(position: Vector2) -> bool:
	var index = -1
	var i = 0
	for object in object_registry:
		i += 1
		if object["grid_position"] == position:
			index = i
			break
	return index == -1

func get_object_at(position: Vector2) -> Dictionary:
	var i = 0
	for object in object_registry:
		i += 1
		if object["grid_position"] == position:
			return object
	return {}

func kill_navmesh_below(position: Vector2):
	var atlas = Vector2i(2,0)
	tiles.set_cell(0,position,0,atlas,1)
	print("killed navmesh at ",position)

func tiletype(position: Vector2) -> int:
	return tiles.get_cell_atlas_coords(0,position).x

func _on_buybarrierbutton_pressed():
	if check_tile_free(world_to_grid(selection_box.global_position)) and tiletype(world_to_grid(selection_box.global_position)) == 2:
		var barrier = barrierprefab.instantiate()
		barrier.global_position = selection_box.global_position
		add_child(barrier)
		buildPanel.visible = false
		mouse_world_events = true
		object_registry.append({"type":"barrier","position":barrier.global_position,"grid_position":world_to_grid(barrier.global_position),"node":barrier})
		kill_navmesh_below(world_to_grid(selection_box.global_position))
	else:
		print("tile not free")


func _on_buygunbutton_pressed():
	if check_tile_free(world_to_grid(selection_box.global_position)):
		var gun = gunprefab.instantiate()
		gun.global_position = selection_box.global_position
		add_child(gun)
		print("gun at ",gun.global_position)
		buildPanel.visible = false
		mouse_world_events = true
		
		deselect_all()
		gun.set_selected(true)
		object_registry.append({"type":"gun","position":gun.global_position,"grid_position":world_to_grid(gun.global_position),"node":gun})
		
		selected_object = object_registry[-1]
		kill_navmesh_below(world_to_grid(selection_box.global_position))
	else:
		print("tile not free")


func _on_buydrillbutton_pressed():
	if check_tile_free(world_to_grid(selection_box.global_position)):
		var drill = drillprefab.instantiate()
		drill.global_position = selection_box.global_position
		add_child(drill)
		buildPanel.visible = false
		mouse_world_events = true
		object_registry.append({"type":"drill","position":drill.global_position,"grid_position":world_to_grid(drill.global_position),"node":drill})
		
		for enemy in enemies:
			var wr = weakref(enemy);
			if (!wr.get_ref()):
				enemies.remove_at(enemies.find(enemy))
			else:
				enemy.call("set_target",selection_box.global_position)
	else:
		print("tile not free")


func _on_buymachinegun_pressed():
	if check_tile_free(world_to_grid(selection_box.global_position)):
		var machinegun = machinegunprefab.instantiate()
		machinegun.global_position = selection_box.global_position
		add_child(machinegun)
		buildPanel.visible = false
		mouse_world_events = true
		object_registry.append({"type":"machinegun","position":machinegun.global_position,"grid_position":world_to_grid(machinegun.global_position),"node":machinegun})
		
		selected_object = object_registry[-1]
		kill_navmesh_below(world_to_grid(selection_box.global_position))
	else:
		print("tile not free")
