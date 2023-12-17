extends Control

@export var viewport1: SubViewport
@export var selectpreviewViewport: SubViewport

# Called when the node enters the scene tree for the first time.
func _ready():
	selectpreviewViewport.world_2d = viewport1.world_2d
