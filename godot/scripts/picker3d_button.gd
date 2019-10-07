extends TextureButton

signal picker3d_button_pressed
const btn_offset = Vector2(-8,-8)
const icon_normal = preload("res://textures/svg/icon_add.svg")
const icon_selected = preload("res://textures/svg/icon_close.svg")
const icon_deactivated = preload("res://textures/svg/icon_status_error.svg")

onready var ray = $ray
var cam = null
var obj = null
var mesh = null
var selectable = true
var selected = false

func _ready():
	set_physics_process(true)

func configure( _cam, _obj ):
	cam = _cam
	obj = _obj
	mesh = null
	for c in obj.get_children():
		if c is MeshInstance:
			mesh = c
			break
	set_selected(selected)

func _physics_process(delta):
	if cam == null or obj == null:
		return
	if ray.is_colliding():
		set_selectable( ray.get_collider() == obj )
	
func _process(delta):
	if cam != null and obj != null: 
		ray.translation = cam.global_transform.origin
		ray.cast_to = obj.global_transform.origin - cam.global_transform.origin
	if visible and cam != null and obj != null:
		var pos = cam.unproject_position( obj.global_transform.origin )
		rect_position = pos + btn_offset

func set_selected( s ):
	selected = s
	texture_normal = icon_selected if selected else icon_normal

func set_selectable( s ):
	selectable = s
	if not selectable:
		texture_normal = icon_deactivated
	else:
		set_selected( selected )

func toggle_selection():
	set_selected( !selected )

func _on_pressed():
	if selectable:
		toggle_selection()
		emit_signal( "picker3d_button_pressed", self )
