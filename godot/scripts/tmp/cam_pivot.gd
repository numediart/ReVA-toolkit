extends Spatial

export(bool) var limit_rotx = true
export(float,-360,360) var min_rotx = 0
export(float,-360,360) var max_rotx = 0
export(float,0,10) var max_speed = 1
export(float,0,5) var accumulation_speed = 1
export(float,0,5) var deceleration_speed = 1
export(float,0,5) var bouncing_speed = 1
export(String) var mirror_path = ""

var previous_mouse = Vector2()
var cam_dragged = false
var cam_speed = Vector3()
var mouse_pos = Vector2()

var main_vp_size = Vector2()

func _ready():
	pass

func _process(delta):
	
	if get_viewport().size != main_vp_size:
		main_vp_size = get_viewport().size
	
	mouse_pos = get_viewport().get_mouse_position()
	if cam_dragged:
		var mpd = mouse_pos - previous_mouse
		previous_mouse = mouse_pos
		var pc = accumulation_speed * delta
		cam_speed = cam_speed * (1-pc) + Vector3( mpd.y, mpd.x, 0 ) * 2 * pc
	
	var pc = deceleration_speed * delta
	cam_speed = cam_speed * (1-pc)
	
	if limit_rotx:
		if rotation_degrees.x < min_rotx:
			cam_speed.x -= (rotation_degrees.x - min_rotx) * bouncing_speed * delta
		if rotation_degrees.x > max_rotx:
			cam_speed.x -= (rotation_degrees.x - max_rotx) * bouncing_speed * delta
	
	if cam_speed.length() > max_speed:
		cam_speed = cam_speed.normalized() * max_speed
	
	rotation_degrees += cam_speed
	
	var b = global_transform.basis 
	$cam.look_at( $lookat.global_transform.origin, b.xform( Vector3(0,1,0) ) )

func _input(event):
	if event is InputEventMouseButton:	
		if event.pressed and event.button_index == 2:
			cam_dragged = true
			previous_mouse = event.position
		elif not event.pressed and event.button_index == 2:
			cam_dragged = false
