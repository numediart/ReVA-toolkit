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
	if calibration.success:
		for g in calibration.content.groups:
			if 'symmetry' in g:
				for subg in g.points:
					for i in subg:
						mask.get_child(i).material_override.albedo_color = g.color
			else:
				for i in g.points:
					mask.get_child(i).material_override.albedo_color = g.color
		
		$ui/calib_panel/groups.add_item( 'select' )
		$ui/calib_panel/groups.add_separator()
		for g in calibration.content.groups:
			$ui/calib_panel/groups.add_item( group_fullname( g ) )

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

func group_sub_visibility( b ):
	$ui/calib_panel/rot_panel.visible = b
	$ui/calib_panel/trans_panel.visible = b
	$ui/calib_panel/scale_panel.visible = b
	$ui/calib_panel/sym_panel.visible = b

func group_config_visibility( b ):
	$ui/calib_panel/gname.visible = b
	$ui/calib_panel/ginfo.visible = b
	$ui/calib_panel/b_rot.visible = b
	$ui/calib_panel/b_trans.visible = b
	$ui/calib_panel/b_scale.visible = b
	if b and sel_group != -1 and 'symmetry' in calibration.content.groups[sel_group]:
		$ui/calib_panel/b_sym.visible = b
	else:
		$ui/calib_panel/b_sym.visible = false
	group_sub_visibility( false )

func group_config_load( g ):
	# disabling on_value_changed callbacks
	var sg = sel_group
	sel_group = -1
	$ui/calib_panel/rot_panel/rotx.value = g.correction.rotation.x * 180 / PI
	$ui/calib_panel/rot_panel/roty.value = g.correction.rotation.y * 180 / PI
	$ui/calib_panel/rot_panel/rotz.value = g.correction.rotation.z * 180 / PI
	$ui/calib_panel/trans_panel/transx.value = g.correction.translation.x
	$ui/calib_panel/trans_panel/transy.value = g.correction.translation.y
	$ui/calib_panel/trans_panel/transz.value = g.correction.translation.z
	$ui/calib_panel/scale_panel/scalex.value = g.correction.scale.x
	$ui/calib_panel/scale_panel/scaley.value = g.correction.scale.y
	$ui/calib_panel/scale_panel/scalez.value = g.correction.scale.z
	# if symmetry
	if 'symmetry' in g:
		$ui/calib_panel/sym_panel/rot_symx.pressed = g.symmetry.rotation.x == -1
		$ui/calib_panel/sym_panel/rot_symy.pressed = g.symmetry.rotation.y == -1
		$ui/calib_panel/sym_panel/rot_symz.pressed = g.symmetry.rotation.z == -1
		$ui/calib_panel/sym_panel/trans_symx.pressed = g.symmetry.translation.x == -1
		$ui/calib_panel/sym_panel/trans_symy.pressed = g.symmetry.translation.y == -1
		$ui/calib_panel/sym_panel/trans_symz.pressed = g.symmetry.translation.z == -1
		$ui/calib_panel/sym_panel/scale_symx.pressed = g.symmetry.scale.x == -1
		$ui/calib_panel/sym_panel/scale_symy.pressed = g.symmetry.scale.y == -1
		$ui/calib_panel/sym_panel/scale_symz.pressed = g.symmetry.scale.z == -1
	# enabling on_value_changed callbacks
	sel_group = sg

func _on_groups_item_selected(id):
	sel_group = id - 2
	if sel_group < 0:
		sel_group = -1
	if sel_group != -1:
		var g = calibration.content.groups[sel_group]
		$ui/calib_panel/gname.text = g.name
		$ui/calib_panel/ginfo.text = ''
		if 'symmetry' in g:
			print( g.points )
			$ui/calib_panel/ginfo.text += str( len(g.points[0]) + len(g.points[1]) )
			$ui/calib_panel/ginfo.text += ' points'
			$ui/calib_panel/ginfo.text += ' [' + str(len(g.points[0])) + ',' + str(len(g.points[1])) + ']'
			$ui/calib_panel/ginfo.text += ' [symmetric]'
		else:
			$ui/calib_panel/ginfo.text += str( len(g.points) )
			$ui/calib_panel/ginfo.text += ' point'
			if len(g.points) > 1:
				$ui/calib_panel/ginfo.text += 's'
		group_config_load( g )
		group_config_visibility(true)
	else:
		group_config_visibility(false)

func _on_rotx_value_changed(value):
	if sel_group != -1:
		calibration.content.groups[sel_group].correction.rotation.x = value / 180 * PI
		ReVA.apply_calibration( calibration, animation )

func _on_roty_value_changed(value):
	if sel_group != -1:
		calibration.content.groups[sel_group].correction.rotation.y = value / 180 * PI
		ReVA.apply_calibration( calibration, animation )

func _on_rotz_value_changed(value):
	if sel_group != -1:
		calibration.content.groups[sel_group].correction.rotation.z = value / 180 * PI
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

func _on_rot_symx_pressed():
	if sel_group != -1:
		calibration.content.groups[sel_group].symmetry.rotation.x = -1 if $ui/calib_panel/sym_panel/rot_symx.pressed else 1
		ReVA.apply_calibration( calibration, animation )

func _on_rot_symy_pressed():
	if sel_group != -1:
		calibration.content.groups[sel_group].symmetry.rotation.y = -1 if $ui/calib_panel/sym_panel/rot_symy.pressed else 1
		ReVA.apply_calibration( calibration, animation )

func _on_rot_symz_pressed():
	if sel_group != -1:
		calibration.content.groups[sel_group].symmetry.rotation.z = -1 if $ui/calib_panel/sym_panel/rot_symz.pressed else 1
		ReVA.apply_calibration( calibration, animation )

func _on_trans_symx_pressed():
	if sel_group != -1:
		calibration.content.groups[sel_group].symmetry.translation.x = -1 if $ui/calib_panel/sym_panel/trans_symx.pressed else 1
		ReVA.apply_calibration( calibration, animation )

func _on_trans_symy_pressed():
	if sel_group != -1:
		calibration.content.groups[sel_group].symmetry.translation.y = -1 if $ui/calib_panel/sym_panel/trans_symy.pressed else 1
		ReVA.apply_calibration( calibration, animation )

func _on_trans_symz_pressed():
	if sel_group != -1:
		calibration.content.groups[sel_group].symmetry.translation.z = -1 if $ui/calib_panel/sym_panel/trans_symz.pressed else 1
		ReVA.apply_calibration( calibration, animation )

func _on_scale_symx_pressed():
	if sel_group != -1:
		calibration.content.groups[sel_group].symmetry.scale.x = -1 if $ui/calib_panel/sym_panel/scale_symx.pressed else 1
		ReVA.apply_calibration( calibration, animation )

func _on_scale_symy_pressed():
	if sel_group != -1:
		calibration.content.groups[sel_group].symmetry.scale.y = -1 if $ui/calib_panel/sym_panel/scale_symy.pressed else 1
		ReVA.apply_calibration( calibration, animation )

func _on_scale_symz_pressed():
	if sel_group != -1:
		calibration.content.groups[sel_group].symmetry.scale.z = -1 if $ui/calib_panel/sym_panel/scale_symz.pressed else 1
		ReVA.apply_calibration( calibration, animation )

func _on_rot_pressed():
	group_sub_visibility( false )
	$ui/calib_panel/rot_panel.visible = true

func _on_trans_pressed():
	group_sub_visibility( false )
	$ui/calib_panel/trans_panel.visible = true

func _on_scale_pressed():
	group_sub_visibility( false )
	$ui/calib_panel/scale_panel.visible = true

func _on_sym_pressed():
	group_sub_visibility( false )
	$ui/calib_panel/sym_panel.visible = true
