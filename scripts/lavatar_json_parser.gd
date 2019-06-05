tool

extends Spatial

export (String) var json_path = '' setget load_json
export (float) var playhead = 0

var animation = {}
var animation_loaded = true
var prev_playhead = 0
var current_index = 0

var structure = {
	'eye_right_brow': 		{ 'indices': [], 'color': Color( 0.7,0,0 ), 'parent': null },
	'eye_right_perimeter': 	{ 'indices': [], 'color': Color( 1,0,0 ), 'parent': null },
	'lid_right_upper': 		{ 'indices': [], 'color': Color( 1,0.3,0 ), 'parent': 'eye_right_perimeter' },
	'lid_right_lower': 		{ 'indices': [], 'color': Color( 1,0.6,0 ), 'parent': 'eye_right_perimeter' },
	'eye_left_brow': 		{ 'indices': [], 'color': Color( 0,0,0.7 ), 'parent': null },
	'eye_left_perimeter': 	{ 'indices': [], 'color': Color( 0,0,1 ), 'parent': null },
	'lid_left_upper': 		{ 'indices': [], 'color': Color( 0,0.3,1 ), 'parent': 'eye_left_perimeter' },
	'lid_left_lower': 		{ 'indices': [], 'color': Color( 0,0.6,1 ), 'parent': 'eye_left_perimeter' },
	'mouth_all': 			{ 'indices': [], 'color': Color( 0.2,1,0 ), 'parent': null },
	'lip_upper': 			{ 'indices': [], 'color': Color( 0.75,1,0 ), 'parent': 'mouth_all' },
	'lip_lower': 			{ 'indices': [], 'color': Color( 1,1,0 ), 'parent': 'mouth_all' },
	'nose_all': 			{ 'indices': [], 'color': Color( 0,0.6,0.2 ), 'parent': null },
	'nose_tip': 			{ 'indices': [], 'color': Color( 0.5,1,0.5 ), 'parent': 'nose_all' },
	'nostril_right': 		{ 'indices': [], 'color': Color( 0,0.6,1 ), 'parent': 'nose_all' },
	'nostril_left': 		{ 'indices': [], 'color': Color( 0.8,0.6,0.2 ), 'parent': 'nose_all' }
}

func load_json( path ):
	
	clear_all()
	
	json_path = path
	animation = {}
	var file = File.new()
	file.open( path, file.READ )
	var result_json = JSON.parse(file.get_as_text())
	file.close()
	if result_json.error == OK:  # If parse OK
		animation = result_json.result
		animation_loaded = false
	else:  # If parse has errors
	    print("Error: ", result_json.error)
	    print("Error Line: ", result_json.error_line)
	    print("Error String: ", result_json.error_string)

func clear_all():
	
	$soundplayer.stream = null
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
	print( structure )

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
	
	var tmpl = $dot_tmpl
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
	a.track_set_path( ti, "../root:playhead" )
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
	
	transform_aabb( animation['aabb'] )
	transform_aabb( animation['aabb_total'] )
	
	for f in range( animation['frame_count'] ):
		transform_aabb( animation['frames'][f]['aabb'] )
		var l
		l = animation['frames'][f]['pose_euler']
		animation['frames'][f]['pose_euler'] = Vector3( l[0], l[1], l[2] )
		for i in range( animation['landmark_count'] ):
			l = animation['frames'][f]['landmarks'][i]
			animation['frames'][f]['landmarks'][i] = Vector3( l[0], l[1], l[2] )
	
	load_structure()
	load_sound()
	load_debug()
	load_animplayer()
	animation_loaded = true

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
	
	var diff = frame['timestamp'] - prev_frame['timestamp']
	var delta = playhead - prev_frame['timestamp']
	var pc = delta / diff
	var pci = 1 - pc
	
	var v3
	
	v3 = frame['aabb']['center'] * pc + prev_frame['aabb']['center'] * pci
	$axis.translation = v3
	$axis.rotation = interpolate_euler( prev_frame['pose_euler'], frame['pose_euler'], pc )
	
	for i in range( animation['landmark_count'] ):
		v3 = frame['landmarks'][i] * pc + prev_frame['landmarks'][i] * pci
		$landmarks.get_child( i ).translation = v3

func _ready():
	pass # Replace with function body.

func play_sound( n ):
	if playhead == 0:
		$soundplayer.play( playhead )

func _process(delta):
	if not animation_loaded:
		load_animation()
	if prev_playhead != playhead:
		load_frame()
		prev_playhead = playhead
		
#	print( playhead )

