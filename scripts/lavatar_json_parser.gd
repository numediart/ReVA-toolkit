tool

extends Spatial

var V3UNIT = Vector3(1,1,1)
var V3FRONT = Vector3(0,0,1)

export (String) var lavatar_json_path = '' setget set_lavatar_json_path
export (String) var lavatar_node_path = ''
export (String) var lavatar_anchor_bone = ''

export (Vector3) var anchor_rotation = Vector3() setget _anchor_rotation
export (Vector3) var anchor_translation = Vector3() setget _anchor_translation
export (Vector3) var anchor_scale = Vector3(1,1,1) setget _anchor_scale

export (float) var playhead = 0

export (bool) var center_offset = true setget _center_offset
export (bool) var center_rotation = true setget _center_rotation
export (bool) var reset_correction = false setget _reset_correction

export (Vector3) var brow_rotation = Vector3() setget _brow_rotation
export (Vector3) var brow_translation = Vector3() setget _brow_translation
export (Vector3) var brow_scale = Vector3(1,1,1) setget _brow_scale

export (Vector3) var eye_rotation = Vector3() setget _eye_rotation
export (Vector3) var eye_translation = Vector3() setget _eye_translation
export (Vector3) var eye_scale = Vector3(1,1,1) setget _eye_scale

export (Vector3) var mouth_rotation = Vector3() setget _mouth_rotation
export (Vector3) var mouth_translation = Vector3() setget _mouth_translation
export (Vector3) var mouth_scale = Vector3(1,1,1) setget _mouth_scale

export (Vector3) var nose_rotation = Vector3() setget _nose_rotation
export (Vector3) var nose_translation = Vector3() setget _nose_translation
export (Vector3) var nose_scale = Vector3(1,1,1) setget _nose_scale

export (Vector3) var nostril_rotation = Vector3() setget _nostril_rotation
export (Vector3) var nostril_translation = Vector3() setget _nostril_translation
export (Vector3) var nostril_scale = Vector3(1,1,1) setget _nostril_scale

export (String) var lavatar_config_path = ''
export (bool) var save_config = false setget set_save_config
export (bool) var load_config = false setget set_load_config

var animation = {}
var original_animation = {} # full copy of the animation once successfully loaded

var anchor_transform = Transform()
var animation_loaded = true
var prev_playhead = 0
var current_index = 0

# contains all values of current frame
var base_frame = null
var current_frame = null

var lavatar_node = null

# right is red, left is blue -> respect order or it will be weird!!!
var corrections = {
	'brow_right': { 
		'indices': [], 'correction': Transform(), 
		'color': Color( 0.7,0.0,0.0 ),
		'parent': null },
		
	'eye_right': { 
		'indices': [], 'correction': Transform(), 
		'color': Color( 1.0,0.0,0.0 ),
		'parent': null },
		
	'lid_right_upper': { 
		'indices': [], 'correction': null, 
		'color': Color( 1.0,0.3,0.0 ),
		'parent': 'eye_right' },
	
	'lid_right_lower': { 
		'indices': [], 'correction': null, 
		'color': Color( 1.0,0.6,0.0 ),
		'parent': 'eye_right' },
	
	'brow_left': { 
		'indices': [], 'correction': Transform(), 
		'color': Color( 0.0,0.0,0.7 ),
		'parent': null },
	
	'eye_left': { 
		'indices': [], 'correction': Transform(), 
		'color': Color( 0.0,0.0,1.0 ),
		'parent': null },
	
	'lid_left_upper': { 
		'indices': [], 'correction': null, 
		'color': Color( 0.0,0.3,1.0 ),
		'parent': 'eye_left' },
	
	'lid_left_lower': { 
		'indices': [], 'correction': null, 
		'color': Color( 0.0,0.6,1.0 ),
		'parent': 'eye_left' },
	
	'mouth_all': { 
		'indices': [], 'correction': Transform(), 
		'color': Color( 0.4,1.0,1.0 ),
		'parent': null },
	
	'lip_corner_right': { 
		'indices': [], 'correction': null, 
		'color': Color( 1.0,1.0,0.4 ), 
		'parent': 'mouth_all' },
	
	'lip_corner_left': { 
		'indices': [], 'correction': null, 
		'color': Color( 0.7,1.0,0.0 ),
		'parent': 'mouth_all' },
	
	'lip_upper': { 
		'indices': [], 'correction': Transform(), 
		'color': Color( 0.7,1.0,0.0 ),
		'parent': 'mouth_all' },
	
	'lip_upper_left': { 
		'indices': [], 'correction': null, 
		'color': Color( 0.7,1.0,0.0 ), 
		'parent': 'lip_upper' },
	
	'lip_upper_center': { 
		'indices': [], 'correction': null, 
		'color': Color( 0.7,1.0,0.0 ), 
		'parent': 'lip_upper' },
	
	'lip_upper_right': { 
		'indices': [], 'correction': null, 
		'color': Color( 0.7,1.0,0.0 ), 
		'parent': 'lip_upper' },
	
	'lip_lower': { 
		'indices': [], 'correction': Transform(), 
		'color': Color( 1.0,1.0,0.0 ), 
		'parent': 'mouth_all' },
	
	'lip_lower_left': { 
		'indices': [], 'correction': null, 
		'color': Color( 1.0,1.0,0.0 ), 
		'parent': 'lip_lower' },
	
	'lip_lower_center': { 
		'indices': [], 'correction': null, 
		'color': Color( 1.0,1.0,0.0 ), 
		'parent': 'lip_lower' },
	
	'lip_lower_right': { 
		'indices': [], 'correction': null, 
		'color': Color( 1.0,1.0,0.0 ), 
		'parent': 'lip_lower' },
	
	'nose_all': { 
		'indices': [], 'correction': Transform(), 
		'color': Color( 0.0,0.6,0.2 ), 
		'parent': null },
	
	'nose_tip': { 
		'indices': [], 'correction': null, 
		'color': Color( 0.5,1.0,0.5 ), 
		'parent': 'nose_all' },
	
	'nostril_right': { 
		'indices': [], 'correction': Transform(), 
		'color': Color( 0.0,0.6,1.0 ), 
		'parent': 'nose_all' },
	
	'nostril_left': { 
		'indices': [], 'correction': Transform(), 
		'color': Color( 0.8,0.6,0.2 ), 
		'parent': 'nose_all' }
}

var mapping = {
	
	'jaw': {
		'landmarks': [
			{ 'id': 7, 'weight': 0.3 },
			{ 'id': 8, 'weight': 0.3 },
			{ 'id': 9, 'weight': 0.3 },
			{ 'id': 58, 'weight': 0.7 },
			{ 'id': 57, 'weight': 1 },
			{ 'id': 56, 'weight': 0.7 } ]
	},
	
	'commissureR': {
		'landmarks': [
			{ 'id': 49, 'weight': 0.1 },
			{ 'id': 48, 'weight': 1 },
			{ 'id': 59, 'weight': 0.1 } ]
	},
	
	'upper_lipR': {
		'landmarks': [
			{ 'id': 49, 'weight': 0.8 },
			{ 'id': 50, 'weight': 1 },
			{ 'id': 51, 'weight': 0.2 } ]
	},
	'upper_lip': {
		'landmarks': [
			{ 'id': 50, 'weight': 0.2 },
			{ 'id': 51, 'weight': 1 },
			{ 'id': 52, 'weight': 0.2 } ]
	},
	'upper_lipL': {
		'landmarks': [
			{ 'id': 51, 'weight': 0.2 },
			{ 'id': 52, 'weight': 1 },
			{ 'id': 53, 'weight': 0.8 } ]
	},
	
	'lower_lipR': {
		'landmarks': [
			{ 'id': 59, 'weight': 0.8 },
			{ 'id': 58, 'weight': 1 },
			{ 'id': 57, 'weight': 0.2 } ]
	},
	'lower_lip': {
		'landmarks': [
			{ 'id': 58, 'weight': 0.2 },
			{ 'id': 57, 'weight': 1 },
			{ 'id': 56, 'weight': 0.2 } ]
	},
	'lower_lipL': {
		'landmarks': [
			{ 'id': 57, 'weight': 0.2 },
			{ 'id': 56, 'weight': 1 },
			{ 'id': 55, 'weight': 0.8 } ]
	},
	
	'commissureL': {
		'landmarks': [
			{ 'id': 53, 'weight': 0.1 },
			{ 'id': 54, 'weight': 1 },
			{ 'id': 55, 'weight': 0.1 } ]
	},
	
	'muscle_lip02R': {
		'landmarks': [
			{ 'id': 48, 'weight': 0.7 },
			{ 'id': 49, 'weight': 0.3 } ]
	},
	'muscle_lip01R': {
		'landmarks': [
			{ 'id': 48, 'weight': 0.5 },
			{ 'id': 49, 'weight': 0.3 } ]
	},
	'nostrilR': {
		'landmarks': [
			{ 'id': 48, 'weight': 0.2 },
			{ 'id': 49, 'weight': 0.1 } ]
	},
	'cheekR': {
		'landmarks': [
			{ 'id': 48, 'weight': 1 } ]
	},
	
	'muscle_lip02L': {
		'landmarks': [
			{ 'id': 54, 'weight': 0.7 },
			{ 'id': 53, 'weight': 0.3 } ]
	},
	'muscle_lip01L': {
		'landmarks': [
			{ 'id': 54, 'weight': 0.5 },
			{ 'id': 53, 'weight': 0.3 } ]
	},
	'nostrilL': {
		'landmarks': [
			{ 'id': 54, 'weight': 0.2 },
			{ 'id': 53, 'weight': 0.1 } ]
	},
	'cheekL': {
		'landmarks': [
			{ 'id': 54, 'weight': 1 } ]
	},
	
	'upper_lidL': {
		'landmarks': [
			{ 'id': 43, 'weight': 1 },
			{ 'id': 44, 'weight': 1 } ]
	},
	'lower_lidL': {
		'landmarks': [
			{ 'id': 46, 'weight': 1 },
			{ 'id': 47, 'weight': 1 } ]
	},
	'upper_lidR': {
		'landmarks': [
			{ 'id': 37, 'weight': 1 },
			{ 'id': 38, 'weight': 1 } ]
	},
	
	'lower_lidR': {
		'landmarks': [
			{ 'id': 40, 'weight': 1 },
			{ 'id': 41, 'weight': 1 } ]
	},
	
	'eyeL': { 'gaze': 0 },
	'eyeR': { 'gaze': 1 },
	
	'eyebrow01R': {
		'landmarks': [
			{ 'id': 20, 'weight': 0.3 },
			{ 'id': 21, 'weight': 1 } ]
	},
	'eyebrow02R': {
		'landmarks': [
			{ 'id': 18, 'weight': 0.2 },
			{ 'id': 19, 'weight': 1 },
			{ 'id': 20, 'weight': 0.2 } ]
	},
	'eyebrow03R': {
		'landmarks': [
			{ 'id': 17, 'weight': 1 },
			{ 'id': 18, 'weight': 0.3 } ]
	},
	'foreheadR': {
		'landmarks': [
			{ 'id': 17, 'weight': 0.2 },
			{ 'id': 18, 'weight': 0.4 },
			{ 'id': 19, 'weight': 0.7 },
			{ 'id': 20, 'weight': 0.7 },
			{ 'id': 21, 'weight': 0.5 } ]
	},
	
	'eyebrow01L': {
		'landmarks': [
			{ 'id': 23, 'weight': 0.3 },
			{ 'id': 22, 'weight': 1 } ]
	},
	'eyebrow02L': {
		'landmarks': [
			{ 'id': 25, 'weight': 0.2 },
			{ 'id': 24, 'weight': 1 },
			{ 'id': 23, 'weight': 0.2 } ]
	},
	'eyebrow03L': {
		'landmarks': [
			{ 'id': 26, 'weight': 1 },
			{ 'id': 25, 'weight': 0.3 } ]
	},
	'foreheadL': {
		'landmarks': [
			{ 'id': 26, 'weight': 0.2 },
			{ 'id': 25, 'weight': 0.4 },
			{ 'id': 24, 'weight': 0.7 },
			{ 'id': 23, 'weight': 0.7 },
			{ 'id': 22, 'weight': 0.5 } ]
	}
}

############# EXPORT SETGETS #############

func _anchor_rotation( v ):
	anchor_rotation = v
	anchor_correction()

func _anchor_translation( v ):
	anchor_translation = v
	anchor_correction()

func _anchor_scale( v ):
	anchor_scale = v
	anchor_correction()

func _center_offset( b ):
	center_offset = b
	load_frame()

func _center_rotation( b ):
	center_rotation = b
	load_frame()

func _reset_correction( b ):
	
	reset_correction = false
	
	_brow_rotation( Vector3() )
	_brow_translation( Vector3() )
	_brow_scale( V3UNIT )
	
	_eye_rotation( Vector3() )
	_eye_translation( Vector3() )
	_eye_scale( V3UNIT )
	
	_mouth_rotation( Vector3() )
	_mouth_translation( Vector3() )
	_mouth_scale( V3UNIT )
	
	_nose_rotation( Vector3() )
	_nose_translation( Vector3() )
	_nose_scale( V3UNIT )
	
	_nostril_rotation( Vector3() )
	_nostril_translation( Vector3() )
	_nostril_scale( V3UNIT )

func _brow_rotation( v ):
	brow_rotation = v
	update_correction( 
		['brow_right','brow_left'], 
		corrections['brow_right']['correction'].xform( Vector3() ),
		v,
		corrections['brow_right']['correction'].basis.get_scale()
		)

func _brow_translation( v ):
	brow_translation = v
	update_correction( 
		['brow_right','brow_left'], 
		v, 
		corrections['brow_right']['correction'].basis.get_euler(),
		corrections['brow_right']['correction'].basis.get_scale()
		)

func _brow_scale( v ):
	brow_scale = v
	update_correction( 
		['brow_right','brow_left'], 
		corrections['brow_right']['correction'].xform( Vector3() ),
		corrections['brow_right']['correction'].basis.get_euler(),
		v
		)

func _eye_rotation( v ):
	eye_rotation = v
	update_correction( 
		['eye_right','eye_left'], 
		corrections['eye_right']['correction'].xform( Vector3() ), 
		v,
		corrections['eye_right']['correction'].basis.get_scale()
		)

func _eye_translation( v ):
	eye_translation = v
	update_correction( 
		['eye_right','eye_left'], 
		v, 
		corrections['eye_right']['correction'].basis.get_euler(),
		corrections['eye_right']['correction'].basis.get_scale()
		)
		
func _eye_scale( v ):
	eye_scale = v
	update_correction( 
		['eye_right','eye_left'], 
		corrections['eye_right']['correction'].xform( Vector3() ),
		corrections['eye_right']['correction'].basis.get_euler(),
		v
		)

func _mouth_rotation( v ):
	mouth_rotation = v
	update_correction( 
		['mouth_all'], 
		corrections['mouth_all']['correction'].xform( Vector3() ), 
		v,
		corrections['mouth_all']['correction'].basis.get_scale()
		)

func _mouth_translation( v ):
	mouth_translation = v
	update_correction( 
		['mouth_all'], 
		v, 
		corrections['mouth_all']['correction'].basis.get_euler(),
		corrections['mouth_all']['correction'].basis.get_scale()
		)
		
func _mouth_scale( v ):
	mouth_scale = v
	update_correction( 
		['mouth_all'], 
		corrections['mouth_all']['correction'].xform( Vector3() ),
		corrections['mouth_all']['correction'].basis.get_euler(),
		v
		)

func _nose_rotation( v ):
	nose_rotation = v
	update_correction( 
		['nose_all'], 
		corrections['nose_all']['correction'].xform( Vector3() ), 
		v,
		corrections['nose_all']['correction'].basis.get_scale()
		)

func _nose_translation( v ):
	nose_translation = v
	update_correction( 
		['nose_all'], 
		v, 
		corrections['nose_all']['correction'].basis.get_euler(),
		corrections['nose_all']['correction'].basis.get_scale()
		)
		
func _nose_scale( v ):
	nose_scale = v
	update_correction( 
		['nose_all'], 
		corrections['nose_all']['correction'].xform( Vector3() ),
		corrections['nose_all']['correction'].basis.get_euler(),
		v
		)

func _nostril_rotation( v ):
	nostril_rotation = v
	update_correction( 
		['nostril_right','nostril_left'], 
		corrections['nostril_right']['correction'].xform( Vector3() ), 
		v,
		corrections['nostril_right']['correction'].basis.get_scale()
		)

func _nostril_translation( v ):
	nostril_translation = v
	update_correction( 
		['nostril_right','nostril_left'], 
		v, 
		corrections['nostril_right']['correction'].basis.get_euler(),
		corrections['nostril_right']['correction'].basis.get_scale()
		)

func _nostril_scale( v ):
	nostril_scale = v
	update_correction( 
		['nostril_right','nostril_left'], 
		corrections['nostril_right']['correction'].xform( Vector3() ),
		corrections['nostril_right']['correction'].basis.get_euler(),
		v
		)

func set_lavatar_json_path( path ):
	
	lavatar_json_path = path
	animation_loaded = false

func anchor_correction():
	
	var q = Quat()
	q.set_euler( anchor_rotation )
	anchor_transform = Transform( Basis(q).scaled( anchor_scale ), anchor_translation )
	load_frame()

func update_correction( keys, trans, rot, sca ):
	
	var q = Quat()
	for k in keys:
		if k.find( "left" ) != -1:
			q.set_euler( rot * Vector3(1,-1,-1) )
			corrections[k]['correction'] = Transform( Basis(q).scaled( sca ), trans * Vector3(-1,1,1) )
		else:
			q.set_euler( rot )
			corrections[k]['correction'] = Transform( Basis(q).scaled( sca ), trans )
		apply_correction( k )
		
	load_frame()
	if current_frame != null:
		base_frame = current_frame.duplicate(true)

############# CONFIGURATION #############

func set_save_config( b ):
	save_config = false
	if b:
		if lavatar_node_path == '' or get_node( lavatar_node_path ) == null:
			print ( "a lavatar (Skeleton + lavatar_skeleton.gd) must be linked to to script to enable saving" )
			return
		if len( lavatar_config_path ) == 0:
			print ( "specify a file path (lavatar_config_path field) to enable saving" )
			return
		# getting lavatar
		var savefile = File.new()
		savefile.open(lavatar_config_path, File.WRITE)
		var jdata = {
			'lavatar_type': 'lavatar_config',
			'corrections': corrections,
			'mapping': mapping,
			'skeleton': get_node( lavatar_node_path ).serialise()
		}
		savefile.store_string(to_json(jdata))
		savefile.close()
		print ( "config saved at " + lavatar_config_path )

func set_load_config( b ):
	load_config = false
	if b:
		if lavatar_node_path == '' or get_node( lavatar_node_path ) == null:
			print ( "a lavatar (Skeleton + lavatar_skeleton.gd) must be linked to to script to enable saving" )
			return
		if len( lavatar_config_path ) == 0:
			print ( "specify a file path (lavatar_config_path field) to enable saving" )
			return
		var file = File.new()
		file.open(lavatar_config_path, File.READ)
		var result_json = JSON.parse(file.get_as_text())
		file.close()
		if result_json.error == OK:  # If parse OK
			var jdata = result_json.result
			if not 'lavatar_type' in jdata or jdata['lavatar_type'] != 'lavatar_config':
				print("Error: no key 'lavatar_type' in json data, or type mismatch, should be 'lavatar_config'")
				return false
			if not 'corrections' in jdata or not 'mapping' in jdata or not 'skeleton' in jdata:
				print("Error: no key 'corrections', 'mapping' and/or 'skeleton' in json data")
				return false
			corrections = jdata['corrections']
			mapping = jdata['mapping']
			get_node( lavatar_node_path ).deserialise( jdata['skeleton'] )
		else:  # If parse has errors
			print("Error: ", result_json.error)
			print("Error Line: ", result_json.error_line)
			print("Error String: ", result_json.error_string)
			return false
		return true

############# PROCESSING #############

func apply_correction( key ):
	
	if not 'frame_count' in animation:
		return
	
	var struct = corrections[key]
	if ( struct['correction'] == null ):
		return
	var transfo = struct['correction']
	if struct['parent'] != null and corrections[struct['parent']]['correction'] != null:
		transfo = corrections[struct['parent']]['correction'] * transfo
	
	for f in range(animation['frame_count']):
		
		var src_frame = original_animation['frames'][f]['landmarks']
		var dst_frame = animation['frames'][f]['landmarks']
		var framet = transfo * animation['frames'][f]['pose_transform']
		
		# computation of group barycenter
		var bary = Vector3()
		for i in struct['indices']:
			bary += src_frame[i]
		bary /= len( struct['indices'] )
		for i in struct['indices']:
			var rel = src_frame[i] - bary
			rel = framet.xform( rel )
			dst_frame[i] = bary + rel

func clear_all():
	
	$soundplayer.stream = null
	while( $gazes.get_child_count() > 0 ):
		$gazes.remove_child( $gazes.get_child(0) )
	while( $landmarks.get_child_count() > 0 ):
		$landmarks.remove_child( $landmarks.get_child(0) )
	$animplayer.remove_animation( "json" )
	
	prev_playhead = 0
	current_index = 0

func corrections_find( i ):
	
	var keys = []
	var forbid = []
	for k in corrections:
		if k in forbid:
			continue
		if i in corrections[k][ 'indices' ]:
			keys.append( k )
			if corrections[k][ 'parent' ] != null:
				keys.erase( corrections[k][ 'parent' ] )
				if not corrections[k][ 'parent' ] in forbid:
					forbid.append( corrections[k][ 'parent' ] )
	# anti-collision
	if len( keys ) > 0:
		return corrections[keys[0]]
	return null

func load_corrections():
	
	if not 'structure' in animation:
		return
	
	for k in corrections:
		if k in animation['structure']:
			corrections[k]['indices'] = animation['structure'][k]

func load_json():
	
	animation = {}
	var file = File.new()
	file.open( lavatar_json_path, file.READ )
	var result_json = JSON.parse(file.get_as_text())
	file.close()
	if result_json.error == OK:  # If parse OK
		animation = result_json.result
	else:  # If parse has errors
		print("Error: ", result_json.error)
		print("Error Line: ", result_json.error_line)
		print("Error String: ", result_json.error_string)
		return false
	return true

func load_data():
	
	# transformation of lists into Vector3
	transform_aabb( animation['aabb'] )
	transform_aabb( animation['aabb_total'] )
	for f in range( animation['frame_count'] ):
		transform_aabb( animation['frames'][f]['aabb'] )
		var l
		l = animation['frames'][f]['pose_euler']
		animation['frames'][f]['pose_euler'] = Vector3( l[0], l[1], l[2] )
		# generation of a rotation transform
		var q = Quat()
		q.set_euler( animation['frames'][f]['pose_euler'] )
		animation['frames'][f]['pose_transform'] = Transform( q )
		
		for i in range( animation['gaze_count'] ):
			l = animation['frames'][f]['gazes'][i]
			animation['frames'][f]['gazes'][i] = Vector3( l[0], l[1], l[2] )
		for i in range( animation['landmark_count'] ):
			l = animation['frames'][f]['landmarks'][i]
			animation['frames'][f]['landmarks'][i] = Vector3( l[0], l[1], l[2] )
	
	# everything is ok, let's make a full copy of the data
	original_animation = animation.duplicate( true )
	
	# and applying all corrections
	for k in corrections:
		apply_correction(k)

func load_sound():
	
	if not 'sound' in animation:
		return
	if not 'path' in animation['sound']:
		print( "no path to sound file in this json" )
		return
	if not 'bits_per_sample' in animation['sound']:
		print( "no bits_per_sample info in this json" )
		return
	if not 'sample_rate' in animation['sound']:
		print( "no sample_rate info in this json" )
		return
	if not 'channels' in animation['sound']:
		print( "no channels info in this json" )
		return
	
	var file = File.new()
	if file.open(animation['sound']['path'], File.READ) != OK:
		printerr("Could not open audio file: " + animation['sound']['path'])
		return
	var buffer = file.get_buffer(file.get_len())
	file.close()
	var stream = AudioStreamSample.new()
	animation['sound']['bits_per_sample'] = int(animation['sound']['bits_per_sample'])
	match animation['sound']['bits_per_sample']:
		8:
			stream.format = AudioStreamSample.FORMAT_8_BITS
		16:
			stream.format = AudioStreamSample.FORMAT_16_BITS
		_:
			print( "unsupported format '" + str(animation['sound']['bits_per_sample']) + "', awaits serious sound issues..." )
		
	stream.data = buffer
	stream.mix_rate = animation['sound']['sample_rate']
	stream.stereo = animation['sound']['channels'] == 2
	$soundplayer.stream = stream

func load_video():
	
	if not 'video' in animation or animation['video']['path'] == null:
		return

func load_debug():
	
	var tmpl = $axis
	tmpl.translation = Vector3()
	tmpl.rotation = Vector3()
#warning-ignore:unused_variable
	for i in range( animation['gaze_count'] ):
		var d = tmpl.duplicate()
		d.visible = true
		$gazes.add_child( d )
		
	tmpl = $dot_tmpl
	tmpl.translation = Vector3()
	tmpl.rotation = Vector3()
	for i in range( animation['landmark_count'] ):
		var d = tmpl.duplicate()
		d.visible = true
		var struct = corrections_find(i)
		if struct == null:
			d.get_child(0).material_override.albedo_color = Color(1,1,1)
		else:
			var m = d.get_child(0).material_override.duplicate()
			d.get_child(0).material_override = m
			d.get_child(0).material_override.albedo_color = struct['color']
		$landmarks.add_child( d )
	var f0 = animation['frames'][0]['landmarks']
	for i in range(len(f0)):
		$landmarks.get_child( i ).translation = f0[i]
	
func load_animplayer():
	
	var a = Animation.new()
	a.length = animation['duration']
	
	var ti;
	ti = a.add_track( 0 )
	a.track_set_path( ti, "../" + self.name + ":playhead" )
	a.track_insert_key( ti, 0.0, 0.0 )
	a.track_insert_key( ti, animation['duration'], animation['duration'] )
	
	$animplayer.add_animation( "json", a )

func transform_aabb( aabb ):
	var l 
	l = aabb['center']
	aabb['center'] = Vector3( l[0], l[1], l[2] ) * animation['scale']
	l = aabb['min']
	aabb['min'] = Vector3( l[0], l[1], l[2] ) * animation['scale']
	l = aabb['max']
	aabb['max'] = Vector3( l[0], l[1], l[2] ) * animation['scale']
	l = aabb['size']
	aabb['size'] = Vector3( l[0], l[1], l[2] ) * animation['scale']

func load_animation():
	
	print( "loading animation" )
	
	animation_loaded = true
	
	clear_all()
	if not load_json():
		# recover from the original
		animation = original_animation.duplicate( true )
		return
	load_corrections()
	load_data()
	load_sound()
	load_video()
	load_debug()
	load_animplayer()
	load_frame()
	
	base_frame = current_frame.duplicate(true)

func interpolate_euler( eul_src, eul_dst, pc ):
	var srcq = Quat()
	srcq.set_euler( eul_src )
	var dstq = Quat()
	dstq.set_euler( eul_dst )
	var interq = srcq.slerp( dstq, pc )
	return interq.get_euler()

func load_frame():
	
	if len( animation ) == 0:
		return
	
	# get closest frame
	var frame = animation['frames'][ current_index ]
	if prev_playhead < playhead:
		while frame['timestamp'] < playhead:
			current_index += 1
			if current_index >= animation['frame_count']:
				current_index = animation['frame_count'] - 1
				break
			frame = animation['frames'][ current_index ]
	elif prev_playhead > playhead:
		while frame['timestamp'] > playhead:
			current_index -= 1
			if current_index == -1:
				current_index = 0
				break
			if animation['frames'][ current_index ]['timestamp'] < playhead:
				current_index += 1
				if current_index >= animation['frame_count']:
					current_index = animation['frame_count'] - 1
				break
	
	if current_index == 0:
		current_index = 1
	
	var prev_frame = animation['frames'][ current_index-1 ]
	frame = animation['frames'][ current_index ]
	
	current_frame = prev_frame.duplicate(true)
	
	var diff = frame['timestamp'] - prev_frame['timestamp']
	var delta = playhead - prev_frame['timestamp']
	var pc = delta / diff
	var pci = 1 - pc

	current_frame['aabb']['center'] = frame['aabb']['center'] * pc + prev_frame['aabb']['center'] * pci
	if not center_offset:
		$axis.translation = Vector3()
	else:
		$axis.translation = current_frame['aabb']['center']
	current_frame['pose_euler'] = interpolate_euler( prev_frame['pose_euler'], frame['pose_euler'], pc )
	$axis.rotation = current_frame['pose_euler']
	
	var q = Quat()
	if not center_rotation:
		q.set_euler( current_frame['pose_euler'] )
		q = q.inverse()
	var pose = Transform( q )
	if not center_offset:
		pose.origin = current_frame['aabb']['center'] * -1
	
	pose = anchor_transform * pose
	
	var tmp_landmarks = []
	for i in range( animation['landmark_count'] ):
		current_frame['landmarks'][i] = pose.xform( frame['landmarks'][i] * pc + prev_frame['landmarks'][i] * pci )
		tmp_landmarks.append( current_frame['landmarks'][i] )
		$landmarks.get_child( i ).translation = current_frame['landmarks'][i]
		
	for i in range( animation['gaze_count'] ):
		var side = 'left'
		if i%2 == 1:
			side = 'right'
		var upper = corrections['lid_' + side + '_upper']
		var lower = corrections['lid_' + side + '_lower']
		if len( upper['indices'] ) == 0 or len( lower['indices'] ) == 0 :
			continue
		# average upper
		var upper_v3 = Vector3()
		for id in upper['indices']:
			upper_v3 += tmp_landmarks[ id ]
		upper_v3 /= len( upper['indices'] )
		# average lower
		var lower_v3 = Vector3()
		for id in lower['indices']:
			lower_v3 += tmp_landmarks[ id ]
		lower_v3 /= len( lower['indices'] )
		var pos = global_transform.xform(  ( upper_v3 + lower_v3 ) * 0.5 )
		var la = frame['gazes'][i] * pc + prev_frame['gazes'][i] * pci
		la = la.normalized()
		current_frame['gazes'][i] = la
		la = pos + la
		$gazes.get_child( i ).look_at_from_position( pos, pos + current_frame['gazes'][i], Vector3(0,1,0) )

#warning-ignore:unused_argument
func play_sound():
	
	if not 'sound' in animation or animation['sound']['path'] == null:
		return null
	$soundplayer.play()

func apply_mapping( k ):
	
	var lbone = lavatar_node.avatar_map[k]
	var lconf = mapping[k]
	
	if 'gaze' in lconf:
		if ( lconf['gaze'] == 0 or lconf['gaze'] == 1 ) and lbone['rot_enabled']:
			lavatar_node.bone_rotate( lbone, get_gaze(lconf['gaze']).get_euler() )
		return
	
	if base_frame == null or current_frame == null:
		return
	
	if not 'landmarks' in lconf or len(lconf['landmarks']) == 0: 
		return
	
	# avareging the landmarks
	var basis = Vector3()
	var current = Vector3()
	var totalw = 0
	for l in lconf['landmarks']:
		basis += base_frame['landmarks'][l['id']] * l['weight']
		current += current_frame['landmarks'][l['id']] * l['weight']
		totalw += l['weight']
	basis /= totalw
	current /= totalw
	
	if lbone['lookat_enabled']:
		lavatar_node.bone_look_at( lbone, to_global(current) )
		
	elif lbone['rot_enabled']:
		# rendering the rotation from basis to current
		var absc = lavatar_node.to_local( to_global(current) ) - lbone['origin']
		var absb = lavatar_node.to_local( to_global(basis) ) - lbone['origin']
		var x = Vector3(1,0,0)
		var y = Vector3(0,1,0)
		var z = Vector3(0,1,0)
		z = absc.normalized()
		x = z.cross( y )
		y = x.cross( z )
		var bc = Basis(x,y,z)
		z = absb.normalized()
		x = z.cross( y )
		y = x.cross( z )
		bc = Basis(x,y,z).inverse() * bc
		lavatar_node.bone_rotate( lbone, bc.get_euler() )
		
	elif lbone['trans_enabled']:
		lavatar_node.bone_translate( lbone, to_global(current) - to_global(basis) )

func orient():
	
	if lavatar_anchor_bone == '' or lavatar_node.find_bone( lavatar_anchor_bone ) == -1:
		return
	
	var bt = lavatar_node.get_bone_global_pose(lavatar_node.find_bone( lavatar_anchor_bone ))
	var q = Quat()
	q.set_euler( lavatar_node.rotation )
	
	var glob_head = Transform(Basis(q),lavatar_node.translation) * bt
	
	q.set_euler( glob_head.basis.get_euler() )
	var t_rot = Transform( Basis(q), Vector3())
	var t = Transform( Basis(q), glob_head.origin * lavatar_node.scale )
	global_transform = t

func _ready():
	pass # Replace with function body.

#warning-ignore:unused_argument
func _process(delta):
	
	if lavatar_node == null:
		lavatar_node = get_node( lavatar_node_path )
	if lavatar_node == null:
		return
	
	if not animation_loaded:
		load_animation()
	if prev_playhead != playhead:
		load_frame()
		prev_playhead = playhead
	
	orient()
	
	if lavatar_node.debug:
		return
	
	for k in mapping:
		apply_mapping( k )

############# INTERNAL GETTERS #############

func get_center():
	if current_frame == null or not center_offset:
		return Vector3()
	return current_frame['aabb']['center']

func get_pose_euler():
	if current_frame == null:
		return Vector3()
	# removal of first frame rotation
	var q0 = Quat()
	q0.set_euler( animation['frames'][0]['pose_euler'] )
	var qc = Quat()
	qc.set_euler( current_frame['pose_euler'] )
	qc *= q0.inverse()
	return qc.get_euler()

func get_gaze( i ):
	if current_frame == null or i < 0 or i >= len( current_frame['gazes'] ):
		return Quat()
	var q = Quat()
	q.set_euler( $gazes.get_child( i ).global_transform.basis.get_euler() )
	return q

func get_delta( group ):
	
	if not group in corrections or current_frame == null or len( corrections[group]['indices'] ) == 0:
		return Vector3()
	
	var l = len( corrections[group]['indices'] )
	var first_frame_avrg = Vector3()
	var current_frame_avrg = Vector3()
	# averaging default & current frame
	for id in corrections[group]['indices']:
		first_frame_avrg += animation['frames'][0]['landmarks'][id]
		current_frame_avrg += current_frame['landmarks'][id]
	first_frame_avrg /= l
	current_frame_avrg /= l
	return ( current_frame_avrg - first_frame_avrg ) * scale

func get_global( group ):
	
	if not group in corrections or current_frame == null or len( corrections[group]['indices'] ) == 0:
		return Vector3()
	var l = len( corrections[group]['indices'] )
	var current_frame_avrg = Vector3()
	for id in corrections[group]['indices']:
		current_frame_avrg += current_frame['landmarks'][id]
	return global_transform.xform( current_frame_avrg / l )

func get_video():
	
	if not 'video' in animation or animation['video']['path'] == null:
		return null
	
	return  animation['video']['path']

func is_animation_valid():
	return len(animation) > 0
