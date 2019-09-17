extends Spatial
const ReVA = preload( "res://scripts/reva/ReVA.gd" )

var animation = null

func _ready():
	var animation = ReVA.load_animation( "../json/anim/smile.json" )
	print( animation )
	var calibration = ReVA.load_calibration( "../json/anim/smile.json" )
	print( calibration )

func _process(delta):
	pass
