const version = 1
const prefix = 'ReVA'
const animation_type = prefix + '_animation'
const error_prefix = "ReVA Error: "
const warning_prefix = "ReVA Warning: "

static func file_exists( p ):
	var f = File.new()
	if not f.file_exists( p ):
		print( error_prefix, "invalid path ", p)
		return false
	return true

static func load_json( p ):
	
	var jdata = {
		'path': p,
		'content': null,
		'success': false
	}
	
	if not file_exists( p ):
		return jdata
	
	var file = File.new()
	file.open( p, file.READ )
	var result_json = JSON.parse(file.get_as_text())
	file.close()
	if result_json.error == OK:  # If parse OK
		jdata.content = result_json.result
		jdata.success = true
	else:  # If parse has errors
		print( error_prefix, result_json.error)
		print( error_prefix, "line: ", result_json.error_line)
		print( error_prefix, "string: ", result_json.error_string)
	return jdata

static func invalidate_animation( jdata ):
	jdata.success = false
	jdata.data = null
	return jdata

static func validate_animation( jdata ):
	
	# basic stuff
	if not jdata.success:
		return invalidate_animation( jdata )
	if not jdata.content is Dictionary:
		print( error_prefix, "json content is NOT a dictionnary")
		return invalidate_animation( jdata )
	
	# type & version
	if not 'type' in jdata.content or jdata.content.type != animation_type:
		print( error_prefix, "json type must be ", animation_type)
		return invalidate_animation( jdata )
	if not 'version' in jdata.content or jdata.content.version != version:
		print( error_prefix, "json version must be ", version)
		return invalidate_animation( jdata )
	
	# missing data
	if not 'frames' in jdata.content or not jdata.content.frames is Array:
		print( error_prefix, "json must have a frames key")
		return invalidate_animation( jdata )
	if not 'duration' in jdata.content or not jdata.content.duration is float:
		print( error_prefix, "json must have a duration key")
		return invalidate_animation( jdata )
	
	if not 'gaze_count' in jdata.content or not jdata.content.gaze_count is float:
		print( error_prefix, "json must have a gaze_count key")
		return invalidate_animation( jdata )
	else:
		jdata.content.gaze_count = int(jdata.content.gaze_count)
	if not 'point_count' in jdata.content or not jdata.content.point_count is float:
		print( error_prefix, "json must have a point_count key")
		return invalidate_animation( jdata )
	else:
		jdata.content.point_count = int(jdata.content.point_count)
	
	# aabb validation and transtyping
	if not 'aabb' in jdata.content or not jdata.content.aabb is Dictionary:
		print( error_prefix, "json must have a aabb key")
		return invalidate_animation( jdata )
	
	if not 'center' in jdata.content.aabb or not jdata.content.aabb.center is Array:
		print( error_prefix, "aabb must have a center key")
		return invalidate_animation( jdata )
	if not 'min' in jdata.content.aabb or not jdata.content.aabb.min is Array:
		print( error_prefix, "aabb must have a min key")
		return invalidate_animation( jdata )
	if not 'max' in jdata.content.aabb or not jdata.content.aabb.max is Array:
		print( error_prefix, "aabb must have a max key")
		return invalidate_animation( jdata )
	if not 'size' in jdata.content.aabb or not jdata.content.aabb.size is Array:
		print( error_prefix, "aabb must have a size key")
		return invalidate_animation( jdata )
	var arr = jdata.content.aabb.center
	jdata.content.aabb.center = Vector3( arr[0],arr[1],arr[2] )
	arr = jdata.content.aabb.min
	jdata.content.aabb.min = Vector3( arr[0],arr[1],arr[2] )
	arr = jdata.content.aabb.max
	jdata.content.aabb.max = Vector3( arr[0],arr[1],arr[2] )
	arr = jdata.content.aabb.size
	jdata.content.aabb.size = Vector3( arr[0],arr[1],arr[2] )
	
	# frames validation and transtyping
	for f in jdata.content.frames:
		if not 'gazes' in f or not f.gazes is Array:
			print( error_prefix, "each frame must have a gazes list")
			return invalidate_animation( jdata )
		if not 'points' in f or not f.points is Array:
			print( error_prefix, "each frame must have a points list")
			return invalidate_animation( jdata )
		if not 'pose_euler' in f or not f.pose_euler is Array:
			print( error_prefix, "each frame must have a pose_euler key")
			return invalidate_animation( jdata )
		if not 'pose_translation' in f or not f.pose_translation is Array:
			print( error_prefix, "each frame must have a pose_translation key")
			return invalidate_animation( jdata )
		if not 'timestamp' in f or not f.timestamp is float:
			print( error_prefix, "each frame must have a timestamp key")
		if len(f.gazes) != jdata.content.gaze_count:
			print( error_prefix, "inconsistent gaze count in frame")
			return invalidate_animation( jdata )
		if len(f.points) != jdata.content.point_count:
			print( error_prefix, "inconsistent point count in frame")
			return invalidate_animation( jdata )
		# swapping to vector3
		f.pose_euler = Vector3( f.pose_euler[0], f.pose_euler[1], f.pose_euler[2] )
		f.pose_translation = Vector3( f.pose_translation[0], f.pose_translation[1], f.pose_translation[2] )
		var vs = []
		for g in f.gazes:
			vs.append( Vector3( g[0],g[1],g[2] ) )
		f.gazes = vs
		vs = []
		for p in f.points:
			vs.append( Vector3( p[0],p[1],p[2] ) )
		f.points = vs
	
	# reference to a sound file
	if 'sound' in jdata.content:
		if not jdata.content.sound is Dictionary:
			print( warning_prefix, "sound field must be a dictionary")
			jdata.content.erase('sound')
			return jdata
		if not 'bits_per_sample' in jdata.content.sound:
			print( warning_prefix, "sound must have a bits_per_sample field")
			jdata.content.erase('sound')
			return jdata
		if not 'channels' in jdata.content.sound:
			print( warning_prefix, "sound must have a channels field")
			jdata.content.erase('sound')
			return jdata
		if not 'sample_rate' in jdata.content.sound:
			print( warning_prefix, "sound must have a sample_rate field")
			jdata.content.erase('sound')
			return jdata
		if not 'path' in jdata.content.sound:
			print( warning_prefix, "sound must have a path field")
			jdata.content.erase('sound')
			return jdata
		if not file_exists( jdata.content.sound.path ):
			jdata.content.erase('sound')
			return jdata

static func load_animation( p ):
	var jdata = load_json( p )
	validate_animation( jdata )
	return jdata
