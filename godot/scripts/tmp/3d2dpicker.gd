extends Node2D

var normal_icon = preload("res://textures/svg/icon_status_error.svg")
var selected_icon = preload("res://textures/svg/icon_play.svg")

onready var cam = get_node("../cam_pivot/cam")
var pickables = null
var btn_offset = Vector2(-8,-8)

func _ready():
	pickables = []
	var r = get_node( "../" )
	for c in r.get_children():
		if c is MeshInstance:
			pickables.append( {'o3d':c,'button':null} )
	for p in pickables:
		var pos = cam.unproject_position( p.o3d.global_transform.origin )
		p.button = $tmpl.duplicate()
		p.button.rect_position = pos + btn_offset
		$pickers.add_child(p.button)

func _process(delta):
	for p in pickables:
		var pos = cam.unproject_position( p.o3d.global_transform.origin )
		p.button.rect_position = pos + btn_offset
