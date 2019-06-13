extends Spatial

var playing = false

func calibration_enable( b ):
	
	$json.visible = b
	
	if b:
		$sasha._enable_ik( true )
		$sasha/att_face_cam/face_cam.make_current()
		$ui/main.hide()
		$ui/calib.reset()
		$ui/calib.show()
	else:
		$sasha._enable_ik( false )
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

func _on_play_pressed():
	
	playing = !playing
	
	if playing:
		playing = $json.is_animation_valid()
	
	if playing:
		$ui/main/btn_play.text = 'pause'
		$sasha._enable_ik( true )
		$json/animplayer.play("json")
	else:
		$ui/main/btn_play.text = 'play'
		$sasha._enable_ik( false )
		$json/animplayer.stop()
