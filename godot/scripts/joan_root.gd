
extends Spatial

var left_pressed = false
var cam_rot = Vector3()

func _ready():
	pass # Replace with function body.

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			left_pressed = event.pressed
	if event is InputEventMouseMotion:
		if not $ui/calib_panel.visible and not $ui/main_panel/animdialog.visible and left_pressed:
			var speed = event.get_speed() / get_viewport().size
			cam_rot.x -= speed.y * 0.02
			cam_rot.y -= speed.x * 0.02

func _process(delta):
	$cam_pivot.rotation += cam_rot
	cam_rot -= cam_rot * 20 * delta
