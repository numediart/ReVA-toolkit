extends VBoxContainer

var closed_icon = preload( "res://textures/svg/icon_GUI_tree_arrow_right.svg" )
var open_icon = preload( "res://textures/svg/icon_GUI_tree_arrow_down.svg" )

var opened = false
var group_edition = false

onready var parent = get_parent()

func prepare_correction(g):
	
	$correction/wrapper/values/name.text = g.name
	$correction/wrapper/values/rot_panel/xaxis/value.value = g.correction.rotation.x * 180 / PI
	$correction/wrapper/values/rot_panel/yaxis/value.value = g.correction.rotation.y * 180 / PI
	$correction/wrapper/values/rot_panel/zaxis/value.value = g.correction.rotation.z * 180 / PI
	$correction/wrapper/values/trans_panel/xaxis/value.value = g.correction.translation.x
	$correction/wrapper/values/trans_panel/yaxis/value.value = g.correction.translation.y
	$correction/wrapper/values/trans_panel/zaxis/value.value = g.correction.translation.z
	$correction/wrapper/values/scale_panel/xaxis/value.value = g.correction.scale.x
	$correction/wrapper/values/scale_panel/yaxis/value.value = g.correction.scale.y
	$correction/wrapper/values/scale_panel/zaxis/value.value = g.correction.scale.z
	$correction/wrapper/values/scale_panel/xaxis/value.step = 0.0001
	$correction/wrapper/values/scale_panel/yaxis/value.step = 0.0001
	$correction/wrapper/values/scale_panel/zaxis/value.step = 0.0001
	if 'symmetry' in g:
		$correction/wrapper/values/symetry_panel/vgrid/rx.pressed = g.symmetry.rotation.x == -1
		$correction/wrapper/values/symetry_panel/vgrid/ry.pressed = g.symmetry.rotation.y == -1
		$correction/wrapper/values/symetry_panel/vgrid/rz.pressed = g.symmetry.rotation.z == -1
		$correction/wrapper/values/symetry_panel/vgrid/tx.pressed = g.symmetry.translation.x == -1
		$correction/wrapper/values/symetry_panel/vgrid/ty.pressed = g.symmetry.translation.y == -1
		$correction/wrapper/values/symetry_panel/vgrid/tz.pressed = g.symmetry.translation.z == -1
		$correction/wrapper/values/symetry_panel/vgrid/sx.pressed = g.symmetry.scale.x == -1
		$correction/wrapper/values/symetry_panel/vgrid/sy.pressed = g.symmetry.scale.y == -1
		$correction/wrapper/values/symetry_panel/vgrid/sz.pressed = g.symmetry.scale.z == -1
		$correction/wrapper/values/symetry_panel.visible = true
	else:
		$correction/wrapper/values/symetry_panel.visible = false

func prepare_edit(g, gid):

	$edit/wrapper/values/vgrid/name.text = g.name
	
	$edit/wrapper/values/vgrid/parent.clear()
	$edit/wrapper/values/vgrid/parent.add_item( '[root]' )
	for pg in parent.calibration.content.groups:
		if not pg == g:
			$edit/wrapper/values/vgrid/parent.add_item( group_fullname( pg ) )
	
	if 'symmetry' in g:
		
		$edit/wrapper/values/vgrid/type.select(1)
		$edit/wrapper/values/vgrid/l_simple.visible = false
		$edit/wrapper/values/vgrid/simple.visible = false
		$edit/wrapper/values/vgrid/l_sym0.visible = true
		$edit/wrapper/values/vgrid/sym0.visible = true
		$edit/wrapper/values/vgrid/l_sym1.visible = true
		$edit/wrapper/values/vgrid/sym1.visible = true
		
		var pl = len( g.points[0] )
		$edit/wrapper/values/vgrid/sym0/info.text = str(pl) + ' point'
		if pl > 1:
			$edit/wrapper/values/vgrid/sym0/info.text += 's'
		pl = len( g.points[1] )
		$edit/wrapper/values/vgrid/sym1/info.text = str(pl) + ' point'
		if pl > 1:
			$edit/wrapper/values/vgrid/sym1/info.text += 's'
		
	else:
		
		$edit/wrapper/values/vgrid/type.select(0)
		$edit/wrapper/values/vgrid/l_simple.visible = true
		$edit/wrapper/values/vgrid/simple.visible = true
		$edit/wrapper/values/vgrid/l_sym0.visible = false
		$edit/wrapper/values/vgrid/sym0.visible = false
		$edit/wrapper/values/vgrid/l_sym1.visible = false
		$edit/wrapper/values/vgrid/sym1.visible = false
		
		var pl = len( g.points )
		$edit/wrapper/values/vgrid/simple/info.text = str(pl) + ' point'
		if pl > 1:
			$edit/wrapper/values/vgrid/simple/info.text += 's'

func adjust_visibility():
	
	$title/wrapper/cols/load.visible = opened
	$title/wrapper/cols/new.visible = opened
	
	if opened:
		$title/wrapper/cols/title.icon = open_icon
	else:
		$title/wrapper/cols/title.icon = closed_icon
	
	if opened and parent.calib_check():
		
		$title/wrapper/cols/reset.visible = true
		$title/wrapper/cols/save.visible = true
		$title/wrapper/cols/saveas.visible = true
		
		$info.visible = opened
		$calib.visible = opened
		
		if parent.groupid == -1:
			
			group_icons( false )
			$correction.visible = false
			$edit.visible = false
			
		else:
			
			group_icons( true )
			
			var g = parent.calibration.content.groups[ parent.groupid ]
			# preventing value changed callbacks
			var prevg = parent.groupid
			parent.groupid = -1
			
			prepare_correction(g)
			prepare_edit(g, prevg)
			
			parent.groupid = prevg
			
			if group_edition:
				$correction.visible = false
				$edit.visible = true
			else:
				$correction.visible = true
				$edit.visible = false
		
	else:
		
		$title/wrapper/cols/reset.visible = false
		$title/wrapper/cols/save.visible = false
		$title/wrapper/cols/saveas.visible = false
		
		$info.visible = false
		$calib.visible = false
		$correction.visible = false
		$edit.visible = false

func open_subs( b ):
	opened = b
	adjust_visibility()

func group_icons( b ):
	$calib/wrapper/reset.visible = b
	$calib/wrapper/edit.visible = b
	$calib/wrapper/duplicate.visible = b

func group_fullname( g ):
	var out = ""
	if g.parent != null:
		for gg in parent.calibration.content.groups:
			if gg.name == g.parent:
				out += group_fullname( gg ) + "/"
	return out + g.name

func group_menu():
	if not parent.calib_check():
		return
	# info
	$info/info.text = "file: " + parent.calibration.path
	$info/info.text += "\ngroups: " + str(len(parent.calibration.content.groups))
	# groups
	$calib/wrapper/groups.clear()
	$calib/wrapper/groups.add_item( 'select' )
	$calib/wrapper/groups.add_separator()
	for g in parent.calibration.content.groups:
		$calib/wrapper/groups.add_item( group_fullname( g ) )
	if parent.groupid != -1:
		$calib/wrapper/groups.select( parent.groupid + 2 )

func set_calibration():
	group_edition = false
	if parent.calibration != null:
		# info
		$info/path.text = parent.calibration.path.get_file()
		group_menu()
	else:
		$title/wrapper/cols/reset.visible = false
		$title/wrapper/cols/save.visible = false
		$title/wrapper/cols/saveas.visible = false

func _ready():
	
	open_subs(false)
	
	$edit/wrapper/values/vgrid/type.add_item( "simple" )
	$edit/wrapper/values/vgrid/type.add_item( "symmetric" )

func _process(delta):
	pass

func _on_title_pressed():
	open_subs( not opened )

func _on_groups_selected(id):
	adjust_visibility()

func _on_group_edit():
	group_edition = true
	adjust_visibility()

func _on_edit_close():
	group_edition = false
	adjust_visibility()
