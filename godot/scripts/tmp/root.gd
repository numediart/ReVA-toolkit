extends Spatial
const ReVA = preload( "res://scripts/reva/ReVA.gd" )

var animation = null

func _ready():
	
	animation = ReVA.load_animation( "../json/anim/smile.json" )
	if animation.success:
		pass

#	var calibration = ReVA.load_calibration( "../json/anim/smile.json" )
#	print( calibration.errors )

func _process(delta):
	pass
