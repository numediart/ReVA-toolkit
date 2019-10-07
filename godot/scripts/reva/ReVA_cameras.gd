extends Position3D

export(String) var path_lookat = ""
export(String) var path_front_pivot = ""
export(String) var path_side_pivot = ""

onready var main_cam = get_node( "cam" )
onready var front_cam = get_node( "../front/vp/cam" )
onready var side_cam = get_node( "../side/vp/cam" )

var lookat = null
var front_pivot = null
var side_pivot = null

var mouse_rotor_previous = null
var mouse_rotor = Vector2()
var camera_rotor = Vector2()

func configure( model ):
	
	lookat = model.node.get_node( path_lookat )
	front_pivot = model.node.get_node( path_front_pivot )
	side_pivot = model.node.get_node( path_side_pivot )
	
	if lookat == null or front_pivot == null or side_pivot == null:
		lookat = null
		front_pivot = null
		side_pivot = null
		print( "FAILED TO CONFIGURE CAMERAS" )
		return
	
	global_transform.origin = lookat.global_transform.origin

func _ready():
	pass

func _input(event):
	
	if event is InputEventMouseButton and event.button_index == 2: 
		if event.pressed:
			if mouse_rotor_previous == null:
				mouse_rotor_previous = event.position
			mouse_rotor = event.position
		else:
			mouse_rotor_previous = null
	
	if event is InputEventMouseMotion and mouse_rotor_previous != null:
		mouse_rotor = event.position

func _process(delta):
	
	if lookat == null:
		return
	
	if mouse_rotor_previous != null:
		var delta_mr = mouse_rotor - mouse_rotor_previous
		mouse_rotor_previous = mouse_rotor
		camera_rotor += delta_mr * delta
	camera_rotor -= camera_rotor * 10 * delta
	rotation_degrees += Vector3( camera_rotor.y, camera_rotor.x, 0 )
