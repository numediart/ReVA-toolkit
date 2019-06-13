extends Spatial

func _ready():
	pass # Replace with function body.

func _process(delta):
	pass


func _on_load_pressed():
	$ui/json_load.popup()
	$ui/json_load.rect_position = Vector2( 10,10 )
	pass # Replace with function body.

func _on_json_load_file_selected(path):
	$ui/main/load/json_path.text = path
	pass # Replace with function body.
