extends VBoxContainer

const ReVA = preload( "res://scripts/reva/ReVA.gd" )

var calibration = null
var group_index = -1
var group_UID = -1

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
	return calib_check() and group_UID != -1 and group_index != -1 and ReVA.get_group_by_id(calibration, group_UID) != null

func sym_check():
	if not group_check():
		return false
	return 'symmetry' in calibration.content.groups[group_index]

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
	calibration.content.display_name = $calibration.fields.calib_name.text

func _on_groups_selected(id):
	if not calib_check():
		return
	group_index = id - 2
	var gl = len(calibration.content.groups)
	if group_index < 0 or group_index >= gl:
		group_index = -1
		group_UID = -1
	else:
		group_UID = calibration.content.groups[group_index].id
	
func _on_group_reset():
	if not group_check():
		return
	ReVA.reset_calibration_group( calibration, group_UID )
	$calibration.group_menu()
	$calibration.adjust_visibility()

func _on_group_duplicate():
	if not group_check():
		return
	group_UID = ReVA.calibration_group_duplicate( calibration, group_UID )
	group_index = ReVA.get_group_index( calibration, group_UID )
	$calibration.group_menu()
	$calibration.adjust_visibility()
	
func _on_group_new():
	if not group_check():
		return

func _on_group_delete():
	if not group_check():
		return
	ReVA.calibration_group_delete( calibration, group_UID )
	while group_index >= len( calibration.content.groups ):
		group_index -= 1
	if group_index == -1:
		group_UID = -1
	else:
		group_UID = calibration.content.groups[ group_index ].id
	$calibration.group_menu()
	$calibration.adjust_visibility()

func _on_groupe_name():
	if not group_check():
		return
	var t = $calibration.fields.group_name.text
	var apply = false
	if t.find( '\n' ) != -1:
		t = t.replace('\n','')
		apply = true
	if t.find( '\r' ) != -1:
		t = t.replace('\r','')
		apply = true
	if apply and len( t ) > 0:
		calibration.content.groups[group_index].name = t
		ReVA.group_unique_name( calibration )
		var prevgi = group_index
		group_index = -1
		$calibration.fields.group_name.text = calibration.content.groups[group_index].name
		group_index = prevgi
		$calibration.group_menu()

func _on_group_rot_reset():
	if not group_check():
		return
func _on_group_rotx(value):
	if not group_check():
		return
	calibration.content.groups[group_index].correction.rotation.x = value / 180 * PI
func _on_group_roty(value):
	if not group_check():
		return
	calibration.content.groups[group_index].correction.rotation.y = value / 180 * PI
func _on_group_rotz(value):
	if not group_check():
		return
	calibration.content.groups[group_index].correction.rotation.z = value / 180 * PI

func _on_group_trans_reset():
	if not group_check():
		return
func _on_group_transx(value):
	if not group_check():
		return
	calibration.content.groups[group_index].correction.translation.x = value
func _on_group_transy(value):
	if not group_check():
		return
	calibration.content.groups[group_index].correction.translation.y = value
func _on_group_transz(value):
	if not group_check():
		return
	calibration.content.groups[group_index].correction.translation.z = value

func _on_group_scale_reset():
	if not group_check():
		return
func _on_group_scalex(value):
	if not group_check():
		return
	calibration.content.groups[group_index].correction.scale.x = value
func _on_group_scaley(value):
	if not group_check():
		return
	calibration.content.groups[group_index].correction.scale.y = value
func _on_group_scalez(value):
	if not group_check():
		return
	calibration.content.groups[group_index].correction.scale.z = value

func _on_group_sym_reset():
	if not group_check():
		return
func _on_group_sym_rx():
	if not sym_check():
		return
	var c = $calibration.fields.rx.pressed
	calibration.content.groups[group_index].symmetry.rotation.x = -1 if c else 1
func _on_group_sym_ry():
	if not sym_check():
		return
	var c = $calibration.fields.ry.pressed
	calibration.content.groups[group_index].symmetry.rotation.y = -1 if c else 1
func _on_group_sym_rz():
	if not sym_check():
		return
	var c = $calibration.fields.rz.pressed
	calibration.content.groups[group_index].symmetry.rotation.z = -1 if c else 1
func _on_group_sym_tx():
	if not sym_check():
		return
	var c = $calibration.fields.tx.pressed
	calibration.content.groups[group_index].symmetry.translation.x = -1 if c else 1
func _on_group_sym_ty():
	if not sym_check():
		return
	var c = $calibration.fields.ty.pressed
	calibration.content.groups[group_index].symmetry.translation.y = -1 if c else 1
func _on_group_sym_tz():
	if not sym_check():
		return
	var c = $calibration.fields.tz.pressed
	calibration.content.groups[group_index].symmetry.translation.z = -1 if c else 1
func _on_group_sym_sx():
	if not sym_check():
		return
	var c = $calibration.fields.sx.pressed
	calibration.content.groups[group_index].symmetry.scale.x = -1 if c else 1
func _on_group_sym_sy():
	if not sym_check():
		return
	var c = $calibration.fields.sy.pressed
	calibration.content.groups[group_index].symmetry.scale.y = -1 if c else 1
func _on_group_sym_sz():
	if not sym_check():
		return
	var c = $calibration.fields.sz.pressed
	calibration.content.groups[group_index].symmetry.scale.z = -1 if c else 1
