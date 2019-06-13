extends Spatial

func calibration_enable( b ):
	
	$json.visible = b
	
	if b:
		$sasha/att_face_cam/face_cam.make_current()
		$ui/main.hide()
		$ui/calib.show()
	else:
		$cam.make_current()
		$ui/main.show()
		$ui/calib.hide()

func _ready():
	calibration_enable( false )
	
func _process(delta):
	pass
	
func _on_load_pressed():
	$ui/json_load.popup()
	$ui/json_load.rect_position = Vector2( 10,10 )
	$ui/main.hide()

func _on_json_load_file_selected(path):
	$ui/main/btn_load/json_path.text = path

func _on_json_load_hide():
	$ui/main/btn_load.pressed = false
	$ui/main.show()

func _on_calibration_pressed():
	calibration_enable( true )

func _on_calib_validate_pressed():
	calibration_enable( false )
