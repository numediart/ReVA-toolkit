extends Node2D

export(bool) var json_debug = true

var wsize = null
var vp_offset = Vector2(224,0)
var vp_front_rel = Rect2()
var vp_side_rel = Rect2()
var json = null
var selected_calib_group = null

var last_pause_playhead = 0

func adjust_layout():
	
	wsize = get_viewport().size
	var partial = wsize - vp_offset
	$calib_panel/front.rect_position = vp_offset + partial * vp_front_rel.position
	$calib_panel/front.rect_size = partial * vp_front_rel.size
	$calib_panel/front/vp.size = partial * vp_front_rel.size
	$calib_panel/side.rect_position = vp_offset + partial * vp_side_rel.position
	$calib_panel/side.rect_size = partial * vp_side_rel.size
	$calib_panel/side/vp.size = partial * vp_side_rel.size

func show_transform_panel( b ):
	$calib_panel/rot_panel.visible = b
	$calib_panel/trans_panel.visible = b
	$calib_panel/scale_panel.visible = b

func display_loaded_json():
	if json == null or json.lavatar_json_path == '':
		$main_panel/playpanel/loadedjson.text = 'no json loaded'
	var t = json.lavatar_json_path.split('/')
	$main_panel/playpanel/loadedjson.text = t[len(t)-1]

func _ready():
	
	json = get_node("../json")
	wsize = get_viewport().size
	var partial = wsize - vp_offset
	vp_front_rel.position = ( $calib_panel/front.rect_position  - vp_offset ) / partial
	vp_front_rel.size = $calib_panel/front.rect_size / partial
	vp_side_rel.position = ( $calib_panel/side.rect_position  - vp_offset ) / partial
	vp_side_rel.size = $calib_panel/side.rect_size / partial
	
	if not json_debug:
		json.visible = false
	$main_panel.visible = false
	$calib_panel.visible = false
	show_transform_panel( false )
	
	$calib_panel/groups.add_item( 'select' )
	$calib_panel/groups.add_separator()
	$calib_panel/groups.add_item( 'all' )
	$calib_panel/groups.add_item( 'brow' )
	$calib_panel/groups.add_item( 'eye' )
	$calib_panel/groups.add_item( 'mouth' )
#	$calib_panel/groups.add_item( 'nose' )
#	$calib_panel/groups.add_item( 'nostril' )
	
	display_loaded_json()
	
	_on_calib_back_pressed()

func _process(delta):
	if wsize != get_viewport().size:
		adjust_layout()

func _on_main_calib_pressed():
	$main_panel.visible = false
	$main_panel/playpanel/play.pressed = false
	json.visible = true
	if not json.OSC_enabled:
		json.ANIMATION_enabled = false
	json.MAPPING_enabled = false
	json.POSE_EULER_enabled = false
	$calib_panel/preview.pressed = false
	_on_preview_pressed()
	$calib_panel.visible = true

func _on_calib_back_pressed():
	$calib_panel.visible = false
	if not json_debug:
		json.visible = false
	json.playhead = 0
	json.load_frame()
	json.ANIMATION_enabled = false
	json.MAPPING_enabled = true
	json.POSE_EULER_enabled = true
	$main_panel/playpanel/play.visible = true
	$main_panel/playpanel/pause.visible = false
	$main_panel.visible = true

func load_transform_panel( g ):
	
	if g == 'all':
		$calib_panel/rot_panel/rotx.value = json.anchor_rotation.x
		$calib_panel/rot_panel/roty.value = json.anchor_rotation.y
		$calib_panel/rot_panel/rotz.value = json.anchor_rotation.z
		$calib_panel/trans_panel/transx.value = json.anchor_translation.x
		$calib_panel/trans_panel/transy.value = json.anchor_translation.y
		$calib_panel/trans_panel/transz.value = json.anchor_translation.z
		$calib_panel/scale_panel/scalex.value = json.anchor_scale.x
		$calib_panel/scale_panel/scaley.value = json.anchor_scale.y
		$calib_panel/scale_panel/scalez.value = json.anchor_scale.z
	elif g == 'brow':
		$calib_panel/rot_panel/rotx.value = json.brow_rotation.x
		$calib_panel/rot_panel/roty.value = json.brow_rotation.y
		$calib_panel/rot_panel/rotz.value = json.brow_rotation.z
		$calib_panel/trans_panel/transx.value = json.brow_translation.x
		$calib_panel/trans_panel/transy.value = json.brow_translation.y
		$calib_panel/trans_panel/transz.value = json.brow_translation.z
		$calib_panel/scale_panel/scalex.value = json.brow_scale.x
		$calib_panel/scale_panel/scaley.value = json.brow_scale.y
		$calib_panel/scale_panel/scalez.value = json.brow_scale.z
	elif g == 'eye':
		$calib_panel/rot_panel/rotx.value = json.eye_rotation.x
		$calib_panel/rot_panel/roty.value = json.eye_rotation.y
		$calib_panel/rot_panel/rotz.value = json.eye_rotation.z
		$calib_panel/trans_panel/transx.value = json.eye_translation.x
		$calib_panel/trans_panel/transy.value = json.eye_translation.y
		$calib_panel/trans_panel/transz.value = json.eye_translation.z
		$calib_panel/scale_panel/scalex.value = json.eye_scale.x
		$calib_panel/scale_panel/scaley.value = json.eye_scale.y
		$calib_panel/scale_panel/scalez.value = json.eye_scale.z
	elif g == 'mouth':
		$calib_panel/rot_panel/rotx.value = json.mouth_rotation.x
		$calib_panel/rot_panel/roty.value = json.mouth_rotation.y
		$calib_panel/rot_panel/rotz.value = json.mouth_rotation.z
		$calib_panel/trans_panel/transx.value = json.mouth_translation.x
		$calib_panel/trans_panel/transy.value = json.mouth_translation.y
		$calib_panel/trans_panel/transz.value = json.mouth_translation.z
		$calib_panel/scale_panel/scalex.value = json.mouth_scale.x
		$calib_panel/scale_panel/scaley.value = json.mouth_scale.y
		$calib_panel/scale_panel/scalez.value = json.mouth_scale.z
	elif g == 'nose':
		$calib_panel/rot_panel/rotx.value = json.nose_rotation.x
		$calib_panel/rot_panel/roty.value = json.nose_rotation.y
		$calib_panel/rot_panel/rotz.value = json.nose_rotation.z
		$calib_panel/trans_panel/transx.value = json.nose_translation.x
		$calib_panel/trans_panel/transy.value = json.nose_translation.y
		$calib_panel/trans_panel/transz.value = json.nose_translation.z
		$calib_panel/scale_panel/scalex.value = json.nose_scale.x
		$calib_panel/scale_panel/scaley.value = json.nose_scale.y
		$calib_panel/scale_panel/scalez.value = json.nose_scale.z
	elif g == 'nostril':
		$calib_panel/rot_panel/rotx.value = json.nostril_rotation.x
		$calib_panel/rot_panel/roty.value = json.nostril_rotation.y
		$calib_panel/rot_panel/rotz.value = json.nostril_rotation.z
		$calib_panel/trans_panel/transx.value = json.nostril_translation.x
		$calib_panel/trans_panel/transy.value = json.nostril_translation.y
		$calib_panel/trans_panel/transz.value = json.nostril_translation.z
		$calib_panel/scale_panel/scalex.value = json.nostril_scale.x
		$calib_panel/scale_panel/scaley.value = json.nostril_scale.y
		$calib_panel/scale_panel/scalez.value = json.nostril_scale.z

func _on_calib_groups_selected(id):
	selected_calib_group = $calib_panel/groups.get_item_text(id)
	if selected_calib_group == 'select' or selected_calib_group == '':
		selected_calib_group = null
	if selected_calib_group == null:
		show_transform_panel( false )
	else:
		var tmp = selected_calib_group
		selected_calib_group = null
		load_transform_panel(tmp)
		selected_calib_group = tmp
		show_transform_panel( true )

func _on_rotx_value_changed(value):
	if selected_calib_group == 'all':
		json._anchor_rotation( Vector3( value, json.anchor_rotation.y, json.anchor_rotation.z ) )
	elif selected_calib_group == 'brow':
		json._brow_rotation( Vector3( value, json.brow_rotation.y, json.brow_rotation.z ) )
	elif selected_calib_group == 'eye':
		json._eye_rotation( Vector3( value, json.eye_rotation.y, json.eye_rotation.z ) )
	elif selected_calib_group == 'mouth':
		json._mouth_rotation( Vector3( value, json.mouth_rotation.y, json.mouth_rotation.z ) )
	elif selected_calib_group == 'nose':
		json._nose_rotation( Vector3( value, json.nose_rotation.y, json.nose_rotation.z ) )
	elif selected_calib_group == 'nostril':
		json._nostril_rotation( Vector3( value, json.nostril_rotation.y, json.nostril_rotation.z ) )

func _on_roty_value_changed(value):
	if selected_calib_group == 'all':
		json._anchor_rotation( Vector3( json.anchor_rotation.x, value, json.anchor_rotation.z ) )
	elif selected_calib_group == 'brow':
		json._brow_rotation( Vector3( json.brow_rotation.x, value, json.brow_rotation.z ) )
	elif selected_calib_group == 'eye':
		json._eye_rotation( Vector3( json.eye_rotation.x, value, json.eye_rotation.z ) )
	elif selected_calib_group == 'mouth':
		json._mouth_rotation( Vector3( json.mouth_rotation.x, value, json.mouth_rotation.z ) )
	elif selected_calib_group == 'nose':
		json._nose_rotation( Vector3( json.nose_rotation.x, value, json.nose_rotation.z ) )
	elif selected_calib_group == 'nostril':
		json._nostril_rotation( Vector3( json.nostril_rotation.x, value, json.nostril_rotation.z ) )

func _on_rotz_value_changed(value):
	if selected_calib_group == 'all':
		json._anchor_rotation( Vector3( json.anchor_rotation.x, json.anchor_rotation.y, value ) )
	elif selected_calib_group == 'brow':
		json._brow_rotation( Vector3( json.brow_rotation.x, json.brow_rotation.y, value ) )
	elif selected_calib_group == 'eye':
		json._eye_rotation( Vector3( json.eye_rotation.x, json.eye_rotation.y, value ) )
	elif selected_calib_group == 'mouth':
		json._mouth_rotation( Vector3( json.mouth_rotation.x, json.mouth_rotation.y, value ) )
	elif selected_calib_group == 'nose':
		json._nose_rotation( Vector3( json.nose_rotation.x, json.nose_rotation.y, value ) )
	elif selected_calib_group == 'nostril':
		json._nostril_rotation( Vector3( json.nostril_rotation.x, json.nostril_rotation.y, value ) )

func _on_transx_value_changed(value):
	if selected_calib_group == 'all':
		json._anchor_translation( Vector3( value, json.anchor_translation.y, json.anchor_translation.z ) )
	elif selected_calib_group == 'brow':
		json._brow_translation( Vector3( value, json.brow_translation.y, json.brow_translation.z ) )
	elif selected_calib_group == 'eye':
		json._eye_translation( Vector3( value, json.eye_translation.y, json.eye_translation.z ) )
	elif selected_calib_group == 'mouth':
		json._mouth_translation( Vector3( value, json.mouth_translation.y, json.mouth_translation.z ) )
	elif selected_calib_group == 'nose':
		json._nose_translation( Vector3( value, json.nose_translation.y, json.nose_translation.z ) )
	elif selected_calib_group == 'nostril':
		json._nostril_translation( Vector3( value, json.nostril_translation.y, json.nostril_translation.z ) )

func _on_transy_value_changed(value):
	if selected_calib_group == 'all':
		json._anchor_translation( Vector3( json.anchor_translation.x, value, json.anchor_translation.z ) )
	elif selected_calib_group == 'brow':
		json._brow_translation( Vector3( json.brow_translation.x, value, json.brow_translation.z ) )
	elif selected_calib_group == 'eye':
		json._eye_translation( Vector3( json.eye_translation.x, value, json.eye_translation.z ) )
	elif selected_calib_group == 'mouth':
		json._mouth_translation( Vector3( json.mouth_translation.x, value, json.mouth_translation.z ) )
	elif selected_calib_group == 'nose':
		json._nose_translation( Vector3( json.nose_translation.x, value, json.nose_translation.z ) )
	elif selected_calib_group == 'nostril':
		json._nostril_translation( Vector3( json.nostril_translation.x, value, json.nostril_translation.z ) )

func _on_transz_value_changed(value):
	if selected_calib_group == 'all':
		json._anchor_translation( Vector3( json.anchor_translation.x, json.anchor_translation.y, value ) )
	elif selected_calib_group == 'brow':
		json._brow_translation( Vector3( json.brow_translation.x, json.brow_translation.y, value ) )
	elif selected_calib_group == 'eye':
		json._eye_translation( Vector3( json.eye_translation.x, json.eye_translation.y, value ) )
	elif selected_calib_group == 'mouth':
		json._mouth_translation( Vector3( json.mouth_translation.x, json.mouth_translation.y, value ) )
	elif selected_calib_group == 'nose':
		json._nose_translation( Vector3( json.nose_translation.x, json.nose_translation.y, value ) )
	elif selected_calib_group == 'nostril':
		json._nostril_translation( Vector3( json.nostril_translation.x, json.nostril_translation.y, value ) )

func _on_scalex_value_changed(value):
	if selected_calib_group == 'all':
		json._anchor_scale( Vector3( value, json.anchor_scale.y, json.anchor_scale.z ) )
	elif selected_calib_group == 'brow':
		json._brow_scale( Vector3( value, json.brow_scale.y, json.brow_scale.z ) )
	elif selected_calib_group == 'eye':
		json._eye_scale( Vector3( value, json.eye_scale.y, json.eye_scale.z ) )
	elif selected_calib_group == 'mouth':
		json._mouth_scale( Vector3( value, json.mouth_scale.y, json.mouth_scale.z ) )
	elif selected_calib_group == 'nose':
		json._nose_scale( Vector3( value, json.nose_scale.y, json.nose_scale.z ) )
	elif selected_calib_group == 'nostril':
		json._nostril_scale( Vector3( value, json.nostril_scale.y, json.nostril_scale.z ) )

func _on_scaley_value_changed(value):
	if selected_calib_group == 'all':
		json._anchor_scale( Vector3( json.anchor_scale.x, value, json.anchor_scale.z ) )
	elif selected_calib_group == 'brow':
		json._brow_scale( Vector3( json.brow_scale.x, value, json.brow_scale.z ) )
	elif selected_calib_group == 'eye':
		json._eye_scale( Vector3( json.eye_scale.x, value, json.eye_scale.z ) )
	elif selected_calib_group == 'mouth':
		json._mouth_scale( Vector3( json.mouth_scale.x, value, json.mouth_scale.z ) )
	elif selected_calib_group == 'nose':
		json._nose_scale( Vector3( json.nose_scale.x, value, json.nose_scale.z ) )
	elif selected_calib_group == 'nostril':
		json._nostril_scale( Vector3( json.nostril_scale.x, value, json.nostril_scale.z ) )

func _on_scalez_value_changed(value):
	if selected_calib_group == 'all':
		json._anchor_scale( Vector3( json.anchor_scale.x, json.anchor_scale.y, value ) )
	elif selected_calib_group == 'brow':
		json._brow_scale( Vector3( json.brow_scale.x, json.brow_scale.y, value ) )
	elif selected_calib_group == 'eye':
		json._eye_scale( Vector3( json.eye_scale.x, json.eye_scale.y, value ) )
	elif selected_calib_group == 'mouth':
		json._mouth_scale( Vector3( json.mouth_scale.x, json.mouth_scale.y, value ) )
	elif selected_calib_group == 'nose':
		json._nose_scale( Vector3( json.nose_scale.x, json.nose_scale.y, value ) )
	elif selected_calib_group == 'nostril':
		json._nostril_scale( Vector3( json.nostril_scale.x, json.nostril_scale.y, value ) )

func _on_preview_pressed():
	
	if $calib_panel/preview.pressed:
		for c in $calib_panel/rot_panel.get_children():
			if c.is_class( "SpinBox" ):
				c.editable = false
		for c in $calib_panel/trans_panel.get_children():
			if c.is_class( "SpinBox" ):
				c.editable = false
		for c in $calib_panel/scale_panel.get_children():
			if c.is_class( "SpinBox" ):
				c.editable = false
		json.MAPPING_enabled = true
		json.ANIMATION_enabled = true
	else:
		for c in $calib_panel/rot_panel.get_children():
			if c.is_class( "SpinBox" ):
				c.editable = true
		for c in $calib_panel/trans_panel.get_children():
			if c.is_class( "SpinBox" ):
				c.editable = true
		for c in $calib_panel/scale_panel.get_children():
			if c.is_class( "SpinBox" ):
				c.editable = true
		json.MAPPING_enabled = false
		json.ANIMATION_enabled = false
		json.get_node("animplayer").seek(0)
		json.playhead = 0
		json.load_frame()

func _on_save_pressed():
	$calib_panel/save.focus_mode
	$calib_panel/preview.pressed = false
	_on_preview_pressed()
	$calib_panel/calibdialog.mode = 4
	$calib_panel/calibdialog.window_title = "save calibration"
	$calib_panel/calibdialog.popup()

func _on_load_pressed():
	$calib_panel/preview.pressed = false
	_on_preview_pressed()
	$calib_panel/calibdialog.mode = 0
	$calib_panel/calibdialog.window_title = "load calibration"
	$calib_panel/calibdialog.popup()

func _on_calibdialog_file_selected(path):
	if $calib_panel/calibdialog.mode == 0:
		var p = $calib_panel/calibdialog.current_path
		if p.find( '.json' ) == -1:
			return
		json.lavatar_config_path = p
		json.set_load_config(true)
	elif $calib_panel/calibdialog.mode == 4:
		var p = $calib_panel/calibdialog.current_path
		if p.find( '.json' ) == -1:
			p += '.json'
		json.lavatar_config_path = p
		json.set_save_config(true)

func _on_loadanim_pressed():
	$main_panel/playpanel/play.pressed = false
	json.ANIMATION_enabled = false
	$main_panel/animdialog.popup()

func _on_animdialog_file_selected(path):
	var p = $main_panel/animdialog.current_path
	if p.find( '.json' ) == -1:
		return
	last_pause_playhead = 0
	$main_panel/playpanel/play.visible = true
	$main_panel/playpanel/pause.visible = false
	json.set_lavatar_json_path(p)
	display_loaded_json()

func _on_play_pressed():
	if $main_panel.visible:
		$main_panel/playpanel/play.visible = false
		$main_panel/playpanel/pause.visible = true
		json.MAPPING_enabled = true
		json.ANIMATION_enabled = true
		var aplay = json.get_node("animplayer")
		aplay.play( 'json' )
		aplay.seek( last_pause_playhead )
		aplay.playback_speed = 1

func _on_pause_pressed():
	if $main_panel.visible:
		$main_panel/playpanel/play.visible = true
		$main_panel/playpanel/pause.visible = false
		json.MAPPING_enabled = true
		json.ANIMATION_enabled = false
		var aplay = json.get_node("animplayer")
		last_pause_playhead = aplay.current_animation_position
		aplay.playback_speed = 0

func _on_play_0_pressed():
	var aplay = json.get_node("animplayer")
	last_pause_playhead = 0
	aplay.seek( last_pause_playhead )
	json.playhead = 0
	json.load_frame()

func _on_play_1_pressed():
	var aplay = json.get_node("animplayer")
	last_pause_playhead = json.animation_duration()
	aplay.seek( last_pause_playhead )
	json.playhead = last_pause_playhead * 0.99
	print( json.playhead )
	json.load_frame()

func _on_realtime_pressed():
	if not json.OSC_enabled:
		$main_panel/realtime.text = 'stop'
		$main_panel/playpanel.visible = false
		json.enable_osc( true )
	else:
		json.enable_osc( false )
		$main_panel/realtime.text = 'realtime'
		$main_panel/playpanel.visible = true
