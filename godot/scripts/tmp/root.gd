extends Spatial
const ReVA = preload( "res://scripts/reva/ReVA.gd" )

var animation = null

func _ready():
	var animation = ReVA.load_animation( "../json/anim/smile.json" )
	print( animation )

func _process(delta):
	pass
