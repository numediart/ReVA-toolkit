extends Spatial
const ReVA = preload( "res://scripts/reva/ReVA.gd" )

export(float, 0, 20) var anim_speed = 1
export(bool) var apply_pose_euler = true
export(bool) var apply_pose_translation = true

var animation = null
var calibration = null
var mask = null
var axis = null
var elapsed_time = 0
var sel_group = -1

func group_fullname( g ):
	var out = ""
	if g.parent != null:
		for gg in calibration.content.groups:
			if gg.name == g.parent:
				out += group_fullname( gg ) + "/"
	return out + g.name

func _ready():
	
	group_config_visibility(false)
	
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
			p.material_override = p.get_surface_material(0).duplicate()
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

	calibration = ReVA.load_calibration( "../json/calibration/openface_default.json" )
	ReVA.check_calibration( calibration, animation )
	
	print( calibration )
	
	# apply colors on points
	for g in calibration.content.groups:
		if 'symmetry' in g:
			for subg in g.points:
				for i in subg:
					mask.get_child(i).material_override.albedo_color = g.color
		else:
			for i in g.points:
				mask.get_child(i).material_override.albedo_color = g.color
	
	$ui/groups.add_item( 'select' )
	$ui/groups.add_separator()
	for g in calibration.content.groups:
		$ui/groups.add_item( group_fullname( g ) )

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

func group_config_visibility( b ):
	$ui/gname.visible = b
	$ui/ginfo.visible = b
	$ui/rot_panel.visible = b
	$ui/trans_panel.visible = b
	$ui/scale_panel.visible = b

func group_config_load( g ):
	$ui/rot_panel/rotx.value = g.correction.rotation.x
	$ui/rot_panel/roty.value = g.correction.rotation.y
	$ui/rot_panel/rotz.value = g.correction.rotation.z
	$ui/trans_panel/transx.value = g.correction.translation.x
	$ui/trans_panel/transy.value = g.correction.translation.y
	$ui/trans_panel/transz.value = g.correction.translation.z
	$ui/scale_panel/scalex.value = g.correction.scale.x
	$ui/scale_panel/scaley.value = g.correction.scale.y
	$ui/scale_panel/scalez.value = g.correction.scale.z

func _on_groups_item_selected(id):
	var sel_group = id - 2
	if sel_group < 0:
		sel_group = -1
	if sel_group != -1:
		var g = calibration.content.groups[sel_group]
		$ui/gname.text = g.name
		$ui/ginfo.text = 'points ' 
		if 'symmetry' in g:
			print( g.points )
			$ui/ginfo.text += str( len(g.points[0]) + len(g.points[1]) )
			$ui/ginfo.text += ' [' + str(len(g.points[0])) + ',' + str(len(g.points[1])) + ']'
			$ui/ginfo.text += ' [symmetric]'
		else:
			$ui/ginfo.text += str( len(g.points) )
		group_config_load( g )
		group_config_visibility(true)
	else:
		group_config_visibility(false)
