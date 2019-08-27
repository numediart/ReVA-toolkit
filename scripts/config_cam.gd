extends ViewportContainer

export(String) var pivot_path = ''

var cam = null
var pivot = null

func _ready():
	cam = get_node("vp/cam")
	pivot = get_node( pivot_path )
	if cam == null or pivot == null:
		cam = null
		pivot = null

func _process(delta):
	
	if cam == null:
		return
	cam.global_transform = pivot.global_transform
