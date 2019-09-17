tool

extends Spatial
const ReVA = preload( "res://scripts/reva/ReVA.gd" )

export(float, 0, 20) var anim_speed = 1
export(bool) var apply_pose_euler = true
export(bool) var apply_pose_translation = true

var animation = null
var mask = null
var axis = null
var elapsed_time = 0

func _ready():
	
#	animation = ReVA.load_animation( "../json/anim/smile.json" )
	animation = ReVA.load_animation( "../json/anim/laugh.json" )
	
	if animation.success:
		
		print( "animation: ", animation.content.display_name )
		
		mask = $mask.duplicate()
		mask.visible = true
		add_child( mask )
		
		for i in range( animation.content.point_count ):
			var p = $pt.duplicate()
			p.visible = true
			mask.add_child( p )
		
		axis = $axis.duplicate()
		axis.visible = true
		mask.add_child( axis )
		axis.translation = Vector3(0,0,0)
		
		# getting the first frame
		var frame = animation.content.frames[0]
		mask.translation = frame.pose_translation
		mask.rotation = frame.pose_euler
		for i in range( animation.content.point_count ):
			mask.get_child(i).translation = frame.points[i]

	var calibration = ReVA.load_calibration( "../json/calibration/openface_default.json" )
	ReVA.check_calibration( calibration, animation )
	
	for k in calibration:
		print( '####### ', k , ' #######' )
		if k ==  'content':
			for kk in calibration[k]:
				if kk == 'groups':
					print( 'groups' )
					for g in calibration[k][kk]:
						print( '\t\t',g )
				else:
					print( kk )
					print( '\t',calibration[k][kk] )
		else:
			print( calibration[k] )

func _process(delta):
	
	#print( elapsed_time )
	elapsed_time += delta
	var frame = ReVA.animation_frame( animation, elapsed_time * anim_speed )
	if frame != null:
		if apply_pose_euler:
			mask.rotation = frame.pose_euler
			axis.rotation = Vector3()
		else:
			mask.rotation = Vector3()
			axis.rotation = frame.pose_euler
		if apply_pose_translation:
			mask.translation = frame.pose_translation
		else:
			mask.translation = Vector3()
		for i in range( animation.content.point_count ):
			mask.get_child(i).translation = frame.points[i]
