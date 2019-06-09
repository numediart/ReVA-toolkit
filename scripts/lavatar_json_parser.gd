tool

extends Spatial

export (String) var json_path = '' setget set_json_path
export (float) var playhead = 0

export (bool) var center_offset = true setget _center_offset
export (bool) var center_rotation = true setget _center_rotation

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

var animation = {}
var original_animation = {} # full copy of the animation once successfully loaded

var animation_loaded = true
var prev_playhead = 0
var current_index = 0
# contains all values of current frame
var current_frame = null

# right is red, left is blue -> respect order or it will be weird!!!
var structure = {
	'brow_right': 		{ 'indices': [], 'correction': Transform(), 'color': Color( 0.7,0.0,0.0 ), 	'parent': null },
	'eye_right': 		{ 'indices': [], 'correction': Transform(), 'color': Color( 1.0,0.0,0.0 ), 	'parent': null },
	'lid_right_upper': 	{ 'indices': [], 'correction': null, 'color': Color( 1.0,0.3,0.0 ), 		'parent': 'eye_right' },
	'lid_right_lower': 	{ 'indices': [], 'correction': null, 'color': Color( 1.0,0.6,0.0 ), 		'parent': 'eye_right' },
	'brow_left': 		{ 'indices': [], 'correction': Transform(), 'color': Color( 0.0,0.0,0.7 ), 	'parent': null },
	'eye_left': 		{ 'indices': [], 'correction': Transform(), 'color': Color( 0.0,0.0,1.0 ), 	'parent': null },
	'lid_left_upper': 	{ 'indices': [], 'correction': null, 'color': Color( 0.0,0.3,1.0 ), 		'parent': 'eye_left' },
	'lid_left_lower': 	{ 'indices': [], 'correction': null, 'color': Color( 0.0,0.6,1.0 ), 		'parent': 'eye_left' },
	'mouth_all': 		{ 'indices': [], 'correction': Transform(), 'color': Color( 0.4,1.0,1.0 ), 	'parent': null },
	'lip_corner_right': { 'indices': [], 'correction': null, 'color': Color( 1.0,1.0,0.4 ), 		'parent': 'mouth_all' },
	'lip_corner_left': 	{ 'indices': [], 'correction': null, 'color': Color( 0.7,1.0,0.0 ), 		'parent': 'mouth_all' },
	'lip_upper': 		{ 'indices': [], 'correction': Transform(), 'color': Color( 0.7,1.0,0.0 ), 	'parent': 'mouth_all' },
	'lip_lower': 		{ 'indices': [], 'correction': Transform(), 'color': Color( 1.0,1.0,0.0 ), 	'parent': 'mouth_all' },
	'nose_all': 		{ 'indices': [], 'correction': Transform(), 'color': Color( 0.0,0.6,0.2 ), 	'parent': null },
	'nose_tip': 		{ 'indices': [], 'correction': null, 'color': Color( 0.5,1.0,0.5 ), 		'parent': 'nose_all' },
	'nostril_right': 	{ 'indices': [], 'correction': Transform(), 'color': Color( 0.0,0.6,1.0 ), 	'parent': 'nose_all' },
	'nostril_left': 	{ 'indices': [], 'correction': Transform(), 'color': Color( 0.8,0.6,0.2 ), 	'parent': 'nose_all' }
}

func _center_offset( b ):
	center_offset = b
	load_frame()

func _center_rotation( b ):
	center_rotation = b
	load_frame()

func _brow_rotation( v ):
	brow_rotation = v
	update_correction( 
		['brow_right','brow_left'], 
		structure['brow_right']['correction'].xform( Vector3() ),
		v,
		structure['brow_right']['correction'].basis.get_scale()
		)

func _brow_translation( v ):
	brow_translation = v
	update_correction( 
		['brow_right','brow_left'], 
		v, 
		structure['brow_right']['correction'].basis.get_euler(),
		structure['brow_right']['correction'].basis.get_scale()
		)

func _brow_scale( v ):
	brow_scale = v
	update_correction( 
		['brow_right','brow_left'], 
		structure['brow_right']['correction'].xform( Vector3() ),
		structure['brow_right']['correction'].basis.get_euler(),
		v
		)

func _eye_rotation( v ):
	eye_rotation = v
	update_correction( 
		['eye_right','eye_left'], 
		structure['eye_right']['correction'].xform( Vector3() ), 
		v,
		structure['eye_right']['correction'].basis.get_scale()
		)

func _eye_translation( v ):
	eye_translation = v
	update_correction( 
		['eye_right','eye_left'], 
		v, 
		structure['eye_right']['correction'].basis.get_euler(),
		structure['eye_right']['correction'].basis.get_scale()
		)
		
func _eye_scale( v ):
	eye_scale = v
	update_correction( 
		['eye_right','eye_left'], 
		structure['eye_right']['correction'].xform( Vector3() ),
		structure['eye_right']['correction'].basis.get_euler(),
		v
		)

func _mouth_rotation( v ):
	mouth_rotation = v
	update_correction( 
		['mouth_all'], 
		structure['mouth_all']['correction'].xform( Vector3() ), 
		v,
		structure['mouth_all']['correction'].basis.get_scale()
		)

func _mouth_translation( v ):
	mouth_translation = v
	update_correction( 
		['mouth_all'], 
		v, 
		structure['mouth_all']['correction'].basis.get_euler(),
		structure['mouth_all']['correction'].basis.get_scale()
		)
		
func _mouth_scale( v ):
	mouth_scale = v
	update_correction( 
		['mouth_all'], 
		structure['mouth_all']['correction'].xform( Vector3() ),
		structure['mouth_all']['correction'].basis.get_euler(),
		v
		)

func _nose_rotation( v ):
	nose_rotation = v
	update_correction( 
		['nose_all'], 
		structure['nose_all']['correction'].xform( Vector3() ), 
		v,
		structure['nose_all']['correction'].basis.get_scale()
		)

func _nose_translation( v ):
	nose_translation = v
	update_correction( 
		['nose_all'], 
		v, 
		structure['nose_all']['correction'].basis.get_euler(),
		structure['nose_all']['correction'].basis.get_scale()
		)
		
func _nose_scale( v ):
	nose_scale = v
	update_correction( 
		['nose_all'], 
		structure['nose_all']['correction'].xform( Vector3() ),
		structure['nose_all']['correction'].basis.get_euler(),
		v
		)

func _nostril_rotation( v ):
	nostril_rotation = v
	update_correction( 
		['nostril_right','nostril_left'], 
		structure['nostril_right']['correction'].xform( Vector3() ), 
		v,
		structure['nostril_right']['correction'].basis.get_scale()
		)

func _nostril_translation( v ):
	nostril_translation = v
	update_correction( 
		['nostril_right','nostril_left'], 
		v, 
		structure['nostril_right']['correction'].basis.get_euler(),
		structure['nostril_right']['correction'].basis.get_scale()
		)

func _nostril_scale( v ):
	nostril_scale = v
	update_correction( 
		['nostril_right','nostril_left'], 
		structure['nostril_right']['correction'].xform( Vector3() ),
		structure['nostril_right']['correction'].basis.get_euler(),
		v
		)

func set_json_path( path ):
	
	json_path = path
	animation_loaded = false

func apply_correction( key ):
	
	if not 'frame_count' in animation:
		return
	
	var struct = structure[key]
	if ( struct['correction'] == null ):
		return
	var transfo = struct['correction']
	if struct['parent'] != null and structure[struct['parent']]['correction'] != null:
		transfo = structure[struct['parent']]['correction'] * transfo
	
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

func update_correction( keys, trans, rot, sca ):
	
	var q = Quat()
	for k in keys:
		if k.find( "left" ) != -1:
			q.set_euler( rot * Vector3(1,-1,-1) )
			structure[k]['correction'] = Transform( q ).scaled( sca )
			structure[k]['correction'].origin = trans * Vector3(-1,1,1)
		else:
			q.set_euler( rot )
			structure[k]['correction'] = Transform( q ).scaled( sca )
			structure[k]['correction'].origin = trans
		
		apply_correction( k )
		
	load_frame()

func clear_all():
	
	$soundplayer.stream = null
	while( $gazes.get_child_count() > 0 ):
		$gazes.remove_child( $gazes.get_child(0) )
	while( $landmarks.get_child_count() > 0 ):
		$landmarks.remove_child( $landmarks.get_child(0) )
	$animplayer.remove_animation( "json" )

func structure_find( i ):
	
	var keys = []
	var forbid = []
	for k in structure:
		if k in forbid:
			continue
		if i in structure[k][ 'indices' ]:
			keys.append( k )
			if structure[k][ 'parent' ] != null:
				keys.erase( structure[k][ 'parent' ] )
				if not structure[k][ 'parent' ] in forbid:
					forbid.append( structure[k][ 'parent' ] )
	# anti-collision
	if len( keys ) > 0:
		return structure[keys[0]]
	return null

func load_structure():
	
	if not 'structure' in animation:
		return
	
	for k in structure:
		if k in animation['structure']:
			structure[k]['indices'] = animation['structure'][k]

func load_json():
	
	animation = {}
	var file = File.new()
	file.open( json_path, file.READ )
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
	for k in structure:
		apply_correction(k)

func load_sound():
	
	if not 'sound' in animation:
		return
	
	var file = File.new()
	if file.open(animation['sound']['path'], File.READ) != OK:
		printerr("Could not open audio file: " + animation['sound']['path'])
		return
	var buffer = file.get_buffer(file.get_len())
	file.close()
	var stream = AudioStreamSample.new()
	stream.format = AudioStreamSample.FORMAT_16_BITS
	stream.data = buffer
	stream.mix_rate = 22050
	stream.stereo = false
	$soundplayer.stream = stream

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
		var struct = structure_find(i)
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
	
	$animplayer.disconnect( "animation_started", self, "play_sound" )
	
	var a = Animation.new()
	a.length = animation['duration']
	
	var ti;
	ti = a.add_track( 0 )
	a.track_set_path( ti, "../" + self.name + ":playhead" )
	a.track_insert_key( ti, 0.0, 0.0 )
	a.track_insert_key( ti, animation['duration'], animation['duration'] )
	
	$animplayer.add_animation( "json", a )
	$animplayer.connect( "animation_started", self, "play_sound" )

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
	load_structure()
	load_data()
	load_sound()
	load_debug()
	load_animplayer()
	load_frame()

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
	
	var tmp_landmarks = []
	for i in range( animation['landmark_count'] ):
		current_frame['landmarks'][i] = pose.xform( frame['landmarks'][i] * pc + prev_frame['landmarks'][i] * pci )
		tmp_landmarks.append( current_frame['landmarks'][i] )
		$landmarks.get_child( i ).translation = current_frame['landmarks'][i]
		
	for i in range( animation['gaze_count'] ):
		var side = 'left'
		if i%2 == 1:
			side = 'right'
		var upper = structure['lid_' + side + '_upper']
		var lower = structure['lid_' + side + '_lower']
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
#		current_frame['gazes'][i] = $gazes.get_child( i ).global_transform.basis.get_euler()
	
func _ready():
	pass # Replace with function body.

#warning-ignore:unused_argument
func play_sound( n ):
	if playhead == 0:
		$soundplayer.play( playhead )

#warning-ignore:unused_argument
func _process(delta):
	if not animation_loaded:
		load_animation()
	if prev_playhead != playhead:
		load_frame()
		prev_playhead = playhead

############# GETTERS #############

func get_center():
	if current_frame == null or not center_offset:
		return Vector3()
	return current_frame['aabb']['center']

func get_pose_euler():
	if current_frame == null:
		return Vector3()
	return current_frame['pose_euler']

func get_gaze( i ):
	if current_frame == null or i < 0 or i >= len( current_frame['gazes'] ):
		return Vector3()
	return current_frame['gazes'][i]

func get_delta( group ):
	
	if not group in structure or current_frame == null or len( structure[group]['indices'] ) == 0:
		return Vector3()
	
	var l = len( structure[group]['indices'] )
	var first_frame_avrg = Vector3()
	var current_frame_avrg = Vector3()
	var ids = structure[group]['indices']
	# averaging default & current frame
	for id in ids:
		first_frame_avrg += animation['frames'][0]['landmarks'][id]
		current_frame_avrg += current_frame['landmarks'][id]
	first_frame_avrg /= l
	current_frame_avrg /= l
	return ( current_frame_avrg - first_frame_avrg ) * scale
	