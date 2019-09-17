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
	ReVA.apply_calibration( calibration, animation )
	
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
	if sel_group != -1:
		$group_viz.clear()
		$group_viz.begin( Mesh.PRIMITIVE_LINES )
		var g = calibration.content.groups[sel_group]
		if 'symmetry' in g:
			for subg in g.points:
				for i in range(1, len(subg) ):
					var p0 = subg[i-1]
					var p1 = subg[i]
					$group_viz.add_vertex( mask.get_child(p0).global_transform.origin )
					$group_viz.add_vertex( mask.get_child(p1).global_transform.origin )
		else:
			for i in range(1, len(g.points) ):
				var p0 = g.points[i-1]
				var p1 = g.points[i]
				$group_viz.add_vertex( mask.get_child(p0).global_transform.origin )
				$group_viz.add_vertex( mask.get_child(p1).global_transform.origin )
		$group_viz.end()
		$group_viz.visible = true
	else:
		$group_viz.visible = false

func group_config_visibility( b ):
	$ui/gname.visible = b
	$ui/ginfo.visible = b
	$ui/rot_panel.visible = b
	$ui/trans_panel.visible = b
	$ui/scale_panel.visible = b

func group_config_load( g ):
	# disabling on_value_changed callbacks
	var sg = sel_group
	sel_group = -1
	$ui/rot_panel/rotx.value = g.correction.rotation.x
	$ui/rot_panel/roty.value = g.correction.rotation.y
	$ui/rot_panel/rotz.value = g.correction.rotation.z
	$ui/trans_panel/transx.value = g.correction.translation.x
	$ui/trans_panel/transy.value = g.correction.translation.y
	$ui/trans_panel/transz.value = g.correction.translation.z
	$ui/scale_panel/scalex.value = g.correction.scale.x
	$ui/scale_panel/scaley.value = g.correction.scale.y
	$ui/scale_panel/scalez.value = g.correction.scale.z
	# enabling on_value_changed callbacks
	sel_group = sg

func _on_groups_item_selected(id):
	sel_group = id - 2
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

func _on_rotx_value_changed(value):
	if sel_group != -1:
		calibration.content.groups[sel_group].correction.rotation.x = value
		ReVA.apply_calibration( calibration, animation )

func _on_roty_value_changed(value):
	if sel_group != -1:
		calibration.content.groups[sel_group].correction.rotation.y = value
		ReVA.apply_calibration( calibration, animation )

func _on_rotz_value_changed(value):
	if sel_group != -1:
		calibration.content.groups[sel_group].correction.rotation.z = value
		ReVA.apply_calibration( calibration, animation )

func _on_transx_value_changed(value):
	if sel_group != -1:
		calibration.content.groups[sel_group].correction.translation.x = value
		ReVA.apply_calibration( calibration, animation )

func _on_transy_value_changed(value):
	if sel_group != -1:
		calibration.content.groups[sel_group].correction.translation.y = value
		ReVA.apply_calibration( calibration, animation )

func _on_transz_value_changed(value):
	if sel_group != -1:
		calibration.content.groups[sel_group].correction.translation.z = value
		ReVA.apply_calibration( calibration, animation )

func _on_scalex_value_changed(value):
	if sel_group != -1:
		calibration.content.groups[sel_group].correction.scale.x = value
		ReVA.apply_calibration( calibration, animation )

func _on_scaley_value_changed(value):
	if sel_group != -1:
		calibration.content.groups[sel_group].correction.scale.y = value
		ReVA.apply_calibration( calibration, animation )

func _on_scalez_value_changed(value):
	if sel_group != -1:
		calibration.content.groups[sel_group].correction.scale.z = value
		ReVA.apply_calibration( calibration, animation )
