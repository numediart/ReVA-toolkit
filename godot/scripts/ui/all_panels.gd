extends VBoxContainer

const ReVA = preload( "res://scripts/reva/ReVA.gd" )

var calibration = null
var groupid = -1

func _ready():
	pass

func _process(delta):
	pass

func set_calibration( c ):
	calibration = c
	$calibration.set_calibration()

func calib_check():
	return calibration != null

func group_check():
	return calib_check() and groupid != -1

func sym_check():
	if not group_check():
		return false
	return 'symmetry' in calibration.content.groups[groupid]

func _on_calib_load():
	if not calib_check():
		return
func _on_calib_reset():
	if not calib_check():
		return
func _on_calib_save():
	if not calib_check():
		return
func _on_calib_save_as():
	if not calib_check():
		return
func _on_calib_new():
	if not calib_check():
		return
func _on_calib_name():
	if not calib_check():
		return

func _on_groups_selected(id):
	if not calib_check():
		return
	groupid = id - 2
	if groupid < 0:
		groupid = -1
func _on_group_reset():
	if not group_check():
		return
	ReVA.reset_calibration_group( groupid, calibration )
	$calibration.group_menu()
	$calibration.adjust_visibility()

func _on_group_duplicate():
	if not group_check():
		return
func _on_group_new():
	if not group_check():
		return

func _on_groupe_name():
	if not group_check():
		return
	var t = $calibration.fields.group_name.text
	if len( t ) > 0:
		calibration.content.groups[groupid].name = $calibration.fields.group_name.text
		$calibration.group_menu()

func _on_group_rot_reset():
	if not group_check():
		return
func _on_group_rotx(value):
	if not group_check():
		return
	calibration.content.groups[groupid].correction.rotation.x = value / 180 * PI
func _on_group_roty(value):
	if not group_check():
		return
	calibration.content.groups[groupid].correction.rotation.y = value / 180 * PI
func _on_group_rotz(value):
	if not group_check():
		return
	calibration.content.groups[groupid].correction.rotation.z = value / 180 * PI

func _on_group_trans_reset():
	if not group_check():
		return
func _on_group_transx(value):
	if not group_check():
		return
	calibration.content.groups[groupid].correction.translation.x = value
func _on_group_transy(value):
	if not group_check():
		return
	calibration.content.groups[groupid].correction.translation.y = value
func _on_group_transz(value):
	if not group_check():
		return
	calibration.content.groups[groupid].correction.translation.z = value

func _on_group_scale_reset():
	if not group_check():
		return
func _on_group_scalex(value):
	if not group_check():
		return
	calibration.content.groups[groupid].correction.scale.x = value
func _on_group_scaley(value):
	if not group_check():
		return
	calibration.content.groups[groupid].correction.scale.y = value
func _on_group_scalez(value):
	if not group_check():
		return
	calibration.content.groups[groupid].correction.scale.z = value

func _on_group_sym_reset():
	if not group_check():
		return
func _on_group_sym_rx():
	if not sym_check():
		return
	var c = $calibration.fields.rx.pressed
	calibration.content.groups[groupid].symmetry.rotation.x = -1 if c else 1
func _on_group_sym_ry():
	if not sym_check():
		return
	var c = $calibration.fields.ry.pressed
	calibration.content.groups[groupid].symmetry.rotation.y = -1 if c else 1
func _on_group_sym_rz():
	if not sym_check():
		return
	var c = $calibration.fields.rz.pressed
	calibration.content.groups[groupid].symmetry.rotation.z = -1 if c else 1
func _on_group_sym_tx():
	if not sym_check():
		return
	var c = $calibration.fields.tx.pressed
	calibration.content.groups[groupid].symmetry.translation.x = -1 if c else 1
func _on_group_sym_ty():
	if not sym_check():
		return
	var c = $calibration.fields.ty.pressed
	calibration.content.groups[groupid].symmetry.translation.y = -1 if c else 1
func _on_group_sym_tz():
	if not sym_check():
		return
	var c = $calibration.fields.tz.pressed
	calibration.content.groups[groupid].symmetry.translation.z = -1 if c else 1
func _on_group_sym_sx():
	if not sym_check():
		return
	var c = $calibration.fields.sx.pressed
	calibration.content.groups[groupid].symmetry.scale.x = -1 if c else 1
func _on_group_sym_sy():
	if not sym_check():
		return
	var c = $calibration.fields.sy.pressed
	calibration.content.groups[groupid].symmetry.scale.y = -1 if c else 1
func _on_group_sym_sz():
	if not sym_check():
		return
	var c = $calibration.fields.sz.pressed
	calibration.content.groups[groupid].symmetry.scale.z = -1 if c else 1
