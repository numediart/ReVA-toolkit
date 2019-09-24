extends VBoxContainer

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
func _on_group_duplicate():
	if not group_check():
		return
func _on_group_new():
	if not group_check():
		return

func _on_group_rot_reset():
	if not group_check():
		return
func _on_group_rotx(value):
	if not group_check():
		return
func _on_group_roty(value):
	if not group_check():
		return
func _on_group_rotz(value):
	if not group_check():
		return

func _on_group_trans_reset():
	if not group_check():
		return
func _on_group_transx(value):
	if not group_check():
		return
func _on_group_transy(value):
	if not group_check():
		return
func _on_group_transz(value):
	if not group_check():
		return

func _on_group_scale_reset():
	if not group_check():
		return
func _on_group_scalex(value):
	if not group_check():
		return
func _on_group_scaley(value):
	if not group_check():
		return
func _on_group_scalez(value):
	if not group_check():
		return

func _on_group_sym_reset():
	if not group_check():
		return
func _on_group_sym_rx():
	if not group_check():
		return
func _on_group_sym_ry():
	if not group_check():
		return
func _on_group_sym_rz():
	if not group_check():
		return
func _on_group_sym_tx():
	if not group_check():
		return
func _on_group_sym_ty():
	if not group_check():
		return
func _on_group_sym_tz():
	if not group_check():
		return
func _on_group_sym_sx():
	if not group_check():
		return
func _on_group_sym_sy():
	if not group_check():
		return
func _on_group_sym_sz():
	if not group_check():
		return
