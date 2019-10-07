extends TextureButton

signal picker3d_button_pressed
const btn_offset = Vector2(-8,-8)
const icon_normal = preload("res://textures/svg/icon_status_error.svg")
const icon_selected = preload("res://textures/svg/icon_play.svg")

onready var ray = $ray
var cam = null
var obj = null
var selectable = true
var selected = false

func _ready():
	pass

func _physics_process(delta):
	if not visible or cam != null or obj != null:
		return
	ray.global_transform = cam.global_transform
	ray.cast_to( obj.global_transform.origin )
	if ray.is_colliding():
		var collider = ray.get_collider()
	
func _process(delta):
	if visible and cam != null and obj != null:
		var pos = cam.unproject_position( obj.global_transform.origin )
		rect_position = pos + btn_offset

func _on_pressed():
	selected = !selected
	texture_normal = icon_selected if selected else icon_normal
	emit_signal( "picker3d_button_pressed", self )
