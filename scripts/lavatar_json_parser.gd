tool

extends Spatial

export (String) var json_path = '' setget load_json
export (float) var playhead = 0

var animation = {}
var animation_loaded = true
var prev_playhead = 0
var current_index = 0

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
	while( $debug.get_child_count() > 0 ):
		$debug.remove_child( $debug.get_child(0) )
	$animplayer.remove_animation( "json" )

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
		$debug.add_child( d )
	var f0 = animation['frames'][0]['landmarks']
	for i in range(len(f0)):
		$debug.get_child( i ).translation = f0[i]

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

func load_animation():
	
	print( "loading animation" )
	
	for f in range( animation['frame_count'] ):
		for i in range( animation['landmark_count'] ):
			var l = animation['frames'][f]['landmarks'][i]
			animation['frames'][f]['landmarks'][i] = Vector3( l[0], l[1], l[2] )
	
	load_sound()
	load_debug()
	load_animplayer()
	animation_loaded = true

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
	
	for i in range( animation['landmark_count'] ):
		var v3 = frame['landmarks'][i] * pc + prev_frame['landmarks'][i] * pci
		$debug.get_child( i ).translation = v3

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
