extends Node2D

var area_sel = null
var json = null
var model = null

func get_value( field, component, axis ):
	
	if field == null or json == null:
		return 0
	
	match field:
		'brows':
			match component:
				'trans':
					return json.brow_translation[axis]
				'rot':
					return json.brow_rotation[axis]
				'scale':
					return json.brow_scale[axis]
		'nose':
			match component:
				'trans':
					return json.nose_translation[axis]
				'rot':
					return json.nose_rotation[axis]
				'scale':
					return json.nose_scale[axis]
		'mouth':
			match component:
				'trans':
					return json.mouth_translation[axis]
				'rot':
					return json.mouth_rotation[axis]
				'scale':
					return json.mouth_scale[axis]
		'eyes':
			match component:
				'trans':
					return json.eye_translation[axis]
				'rot':
					return json.eye_rotation[axis]
				'scale':
					return json.eye_scale[axis]
		'nostrils':
			match component:
				'trans':
					return json.nostril_translation[axis]
				'rot':
					return json.nostril_rotation[axis]
				'scale':
					return json.nostril_scale[axis]
	
	return 0

func set_value( field, component, axis, value ):
	
	if field == null or json == null:
		return
	
	var json = get_node( '../../json' )
	var v = Vector3()
	for i in range(3):
		if axis != i:
			v[i] = get_value( field, component, i )
	v[axis] = value
	
	match field:
		'brows':
			match component:
				'trans':
					json._brow_translation(v)
				'rot':
					json._brow_rotation(v)
				'scale':
					json._brow_scale(v)
		'nose':
			match component:
				'trans':
					json._nose_translation(v)
				'rot':
					json._nose_rotation(v)
				'scale':
					json._nose_scale(v)
		'mouth':
			match component:
				'trans':
					json._mouth_translation(v)
				'rot':
					json._mouth_rotation(v)
				'scale':
					json._mouth_scale(v)
		'eyes':
			match component:
				'trans':
					json._eye_translation(v)
				'rot':
					json._eye_rotation(v)
				'scale':
					json._eye_scale(v)
		'nostrils':
			match component:
				'trans':
					json._nostril_translation(v)
				'rot':
					json._nostril_rotation(v)
				'scale':
					json._nostril_scale(v)

func load_sliders( area ):
	
	$sliders.visible = true
	area_sel = null
	$sliders/rot/x.value = get_value( area, 'rot', 0 )
	$sliders/rot/y.value = get_value( area, 'rot', 1 )
	$sliders/rot/z.value = get_value( area, 'rot', 2 )
	$sliders/trans/x.value = get_value( area, 'trans', 0 )
	$sliders/trans/y.value = get_value( area, 'trans', 1 )
	$sliders/trans/z.value = get_value( area, 'trans', 2 )
	$sliders/scale/x.value = get_value( area, 'scale', 0 )
	$sliders/scale/y.value = get_value( area, 'scale', 1 )
	$sliders/scale/z.value = get_value( area, 'scale', 2 )
	area_sel = area

func reset():
	area_sel = null
	$sliders.visible = false

func _ready():
	reset()
	json = get_node( '../../json' )
	model = get_node( '../../sasha' )

func _on_nose_pressed():
	$area_sel.text = "area selected: nose"
	load_sliders('nose')

func _on_eyes_pressed():
	$area_sel.text = "area selected: eyes"
	load_sliders('eyes')

func _on_mouth_pressed():
	$area_sel.text = "area selected: mouth"
	load_sliders('mouth')

func _on_nostrils_pressed():
	$area_sel.text = "area selected: nostrils"
	load_sliders('nostrils')

func _on_upper_lip_pressed():
	$area_sel.text = "area selected: upper lip"
	load_sliders('upper lip')

func _on_lower_lip_pressed():
	$area_sel.text = "area selected: lower lip"
	load_sliders('lower lip')

func _on_lower_lid_pressed():
	$area_sel.text = "area selected: lower lids"
	load_sliders('lower lids')

func _on_upper_lid_pressed():
	$area_sel.text = "area selected: upper lids"
	load_sliders('upper lids')

func _on_brows_pressed():
	$area_sel.text = "area selected: brows"
	load_sliders('brows')

func _on_transx_value_changed(value):
	set_value( area_sel, 'trans', 0, value )

func _on_transy_value_changed(value):
	set_value( area_sel, 'trans', 1, value )
	
func _on_transz_value_changed(value):
	set_value( area_sel, 'trans', 2, value )

func _on_rotx_value_changed(value):
	set_value( area_sel, 'rot', 0, value )

func _on_roty_value_changed(value):
	set_value( area_sel, 'rot', 1, value )

func _on_rotz_value_changed(value):
	set_value( area_sel, 'rot', 2, value )

func _on_scalex_value_changed(value):
	set_value( area_sel, 'scale', 0, value )

func _on_scaley_value_changed(value):
	set_value( area_sel, 'scale', 1, value )

func _on_scalez_value_changed(value):
	set_value( area_sel, 'scale', 2, value )

func _on_btn_reset_pressed():
	if model != null:
		model._enable_ik(false)
		model._enable_ik(true)
