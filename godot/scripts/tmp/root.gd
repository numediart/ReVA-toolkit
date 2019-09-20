extends Spatial
const ReVA = preload( "res://scripts/reva/ReVA.gd" )
const mod_path = "res://models/joan.tscn"
#const apath = "../json/anim/smile.json"
const ani_path = "../json/anim/laugh.json"
const cal_path = "../json/calibration/openface_calib.json"
const map_path = "../json/mapping/openface_mapping.json"

export(float, 0, 20) var anim_speed = 1
export(bool) var apply_pose_euler = true
export(bool) var apply_pose_translation = true

var model = null
var animation = null
var calibration = null
var mapping = null
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
	
	# loading 
	model = ReVA.load_model( mod_path )
	if model.success:
		add_child( model.node )
	
	animation = ReVA.load_animation( ani_path )
	
	if animation.success:
		
		print( "animation: ", animation.content.display_name )
		
		mask = $mask.duplicate()
		mask.visible = true
		add_child( mask )
		
# warning-ignore:unused_variable
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

	calibration = ReVA.load_calibration( cal_path )
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
		$ui/calib_panel/cname.text = calibration.content.display_name
		$ui/calib_panel/cname.cursor_set_column(0)
		$ui/calib_panel/l_path.text = calibration.path.get_file()
		group_dropdown()
	
	mapping = ReVA.load_mapping( map_path )
	ReVA.check_mapping( mapping, animation )
	ReVA.check_mapping( mapping, model )
	
	ReVA.attach_node( model, mapping, mask )
	mask.translation = Vector3()
	
	ReVA.autocalibrate( model, calibration, animation, 0 )
	
func _process(delta):
	
	#elapsed_time += delta
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

func group_dropdown():
	if calibration.success:
		$ui/calib_panel/groups.clear()
		$ui/calib_panel/groups.add_item( 'select' )
		$ui/calib_panel/groups.add_separator()
		for g in calibration.content.groups:
			$ui/calib_panel/groups.add_item( group_fullname( g ) )
		if sel_group != -1:
			$ui/calib_panel/groups.select( sel_group + 2 )

func group_sub_visibility( b ):
	$ui/calib_panel/rot_panel.visible = b
	$ui/calib_panel/trans_panel.visible = b
	$ui/calib_panel/scale_panel.visible = b
	$ui/calib_panel/sym_panel.visible = b

func group_config_visibility( b ):
	$ui/calib_panel/l_name.visible = b
	$ui/calib_panel/gname.visible = b
	$ui/calib_panel/l_info.visible = b
	$ui/calib_panel/b_rot.visible = b
	$ui/calib_panel/b_trans.visible = b
	$ui/calib_panel/b_scale.visible = b
	$ui/calib_panel/b_greset.visible = b
	if b and sel_group != -1 and 'symmetry' in calibration.content.groups[sel_group]:
		$ui/calib_panel/b_sym.visible = b
	else:
		$ui/calib_panel/b_sym.visible = false
		$ui/calib_panel/sym_panel.visible = false
	if not b:
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
	$ui/calib_panel/scale_panel/scalex.step = 0.0001
	$ui/calib_panel/scale_panel/scaley.step = 0.0001
	$ui/calib_panel/scale_panel/scalez.step = 0.0001
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
		$ui/calib_panel/l_info.text = ''
		if 'symmetry' in g:
			print( g.points )
			$ui/calib_panel/l_info.text += str( len(g.points[0]) + len(g.points[1]) )
			$ui/calib_panel/l_info.text += ' points'
			$ui/calib_panel/l_info.text += ' [' + str(len(g.points[0])) + ',' + str(len(g.points[1])) + ']'
			$ui/calib_panel/l_info.text += ' [symmetric]'
		else:
			$ui/calib_panel/l_info.text += str( len(g.points) )
			$ui/calib_panel/l_info.text += ' point'
			if len(g.points) > 1:
				$ui/calib_panel/l_info.text += 's'
		group_config_load( g )
		group_config_visibility(true)
	else:
		group_config_visibility(false)

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

func _on_group_reset_pressed():
	if sel_group != -1:
		ReVA.reset_calibration_group( sel_group, calibration )
		ReVA.apply_calibration( calibration, animation )
		group_dropdown()
		group_config_load( calibration.content.groups[sel_group] )

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

func _on_gname_text_changed():
	if sel_group != -1 and len($ui/calib_panel/gname.text) > 0:
		var prev_name = calibration.content.groups[sel_group].name
		calibration.content.groups[sel_group].name = $ui/calib_panel/gname.text
		for g in calibration.content.groups:
			if g.parent == prev_name:
				g.parent = calibration.content.groups[sel_group].name
		group_dropdown()

func _on_cname_text_changed():
	if calibration.success:
		calibration.content.display_name = $ui/calib_panel/cname.text

func _on_calibration_reset_pressed():
	ReVA.reset( calibration )
	ReVA.apply_calibration( calibration, animation )
	sel_group = -1
	group_config_visibility(false)
	group_dropdown()
	$ui/calib_panel/cname.text = calibration.content.display_name
	$ui/calib_panel/cname.cursor_set_column(0)
	$ui/calib_panel/l_path.text = calibration.path.get_file()

func _on_calibration_save_pressed():
	ReVA.save_calibration( calibration )
