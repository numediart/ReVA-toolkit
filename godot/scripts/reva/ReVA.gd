const version = 1
const prefix = 'ReVA'
const animation_type = prefix + '_animation'
const calibration_type = prefix + '_calibration'
const error_prefix = "ReVA Error: "
const warning_prefix = "ReVA Warning: "
const info_prefix = "ReVA Info: "

const ReVA_DEBUG = true
const ReVA_ERROR = 		1
const ReVA_WARNING = 	10
const ReVA_INFO = 		20

static func get_directory( p ):
	return p.get_base_dir()

static func file_exists( p ):
	var f = File.new()
	if not f.file_exists( p ):
		return false
	return true

static func jlog( jdata, lvl, txt ):
	jdata.errors.append( [lvl, txt] )
	if ReVA_DEBUG:
		match lvl:
			ReVA_ERROR:
				print( error_prefix, txt )
			ReVA_WARNING:
				print( warning_prefix, txt )
			ReVA_INFO:
				print( info_prefix, txt )
			_:
				print( txt )

static func load_json( p ):
	var jdata = {
		'path': p,
		'content': null,
		'success': false,
		'errors': []
	}
	if not file_exists( p ):
		jlog( jdata, ReVA_ERROR, "invalid path " + p )
		return jdata
	var file = File.new()
	file.open( p, file.READ )
	var result_json = JSON.parse(file.get_as_text())
	file.close()
	if result_json.error == OK:  # If parse OK
		jdata.content = result_json.result
		jdata.success = true
	else:  # If parse has errors
		jlog( jdata, ReVA_ERROR, result_json.error )
		jlog( jdata, ReVA_ERROR,  "line: " + result_json.error_line )
		jlog( jdata, ReVA_ERROR,  "string: " + result_json.error_string )
	return jdata

static func cancel_json( jdata ):
	return {
		'path': jdata.path,
		'content': null,
		'success': false,
		'errors': jdata.errors
	}

static func validate_animation( jdata ):
	
	# basic stuff
	if not jdata.success:
		return cancel_json( jdata )
	if not jdata.content is Dictionary:
		jlog( jdata, ReVA_ERROR, "animation must be a dictionary" )
		return cancel_json( jdata )
	
	# type & version
	if not 'type' in jdata.content or jdata.content.type != animation_type:
		jlog( jdata, ReVA_ERROR, "animation type must be " + animation_type )
		return cancel_json( jdata )
	if not 'version' in jdata.content or jdata.content.version != version:
		jlog( jdata, ReVA_ERROR, "animation version must be " + str(version) )
		return cancel_json( jdata )
	
	# missing data
	if not 'frames' in jdata.content or not jdata.content.frames is Array:
		jlog( jdata, ReVA_ERROR, "animation must have a frames key" )
		return cancel_json( jdata )
	if not 'duration' in jdata.content or not jdata.content.duration is float:
		jlog( jdata, ReVA_ERROR, "animation must have a duration key" )
		return cancel_json( jdata )
	
	if not 'gaze_count' in jdata.content or not jdata.content.gaze_count is float:
		jlog( jdata, ReVA_ERROR, "animation must have a gaze_count key" )
		return cancel_json( jdata )
	else:
		jdata.content.gaze_count = int(jdata.content.gaze_count)
	if not 'point_count' in jdata.content or not jdata.content.point_count is float:
		jlog( jdata, ReVA_ERROR, "animation must have a point_count key" )
		return cancel_json( jdata )
	else:
		jdata.content.point_count = int(jdata.content.point_count)
	
	# aabb validation and transtyping
	if not 'aabb' in jdata.content or not jdata.content.aabb is Dictionary:
		jlog( jdata, ReVA_ERROR, "animation must have a aabb key" )
		return cancel_json( jdata )
	
	if not 'center' in jdata.content.aabb or not jdata.content.aabb.center is Array:
		jlog( jdata, ReVA_ERROR, "animation aabb must have a center key" )
		return cancel_json( jdata )
	if not 'min' in jdata.content.aabb or not jdata.content.aabb.min is Array:
		jlog( jdata, ReVA_ERROR, "animation aabb must have a min key" )
		return cancel_json( jdata )
	if not 'max' in jdata.content.aabb or not jdata.content.aabb.max is Array:
		jlog( jdata, ReVA_ERROR, "animation aabb must have a max key" )
		return cancel_json( jdata )
	if not 'size' in jdata.content.aabb or not jdata.content.aabb.size is Array:
		jlog( jdata, ReVA_ERROR, "animation aabb must have a size key" )
		return cancel_json( jdata )
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
		if not f is Dictionary:
			jlog( jdata, ReVA_ERROR, "animation frame must be a dictionary" )
			return cancel_json( jdata )
		if not 'gazes' in f or not f.gazes is Array:
			jlog( jdata, ReVA_ERROR, "animation frame must have a gazes key" )
			return cancel_json( jdata )
		if not 'points' in f or not f.points is Array:
			jlog( jdata, ReVA_ERROR, "animation frame must have a points key" )
			return cancel_json( jdata )
		if not 'pose_euler' in f or not f.pose_euler is Array:
			jlog( jdata, ReVA_ERROR, "animation frame must have a pose_euler key" )
			return cancel_json( jdata )
		if not 'pose_translation' in f or not f.pose_translation is Array:
			jlog( jdata, ReVA_ERROR, "animation frame must have a pose_translation key" )
			return cancel_json( jdata )
		if not 'timestamp' in f or not f.timestamp is float:
			jlog( jdata, ReVA_ERROR, "animation frame must have a timestamp key" )
		if len(f.gazes) != jdata.content.gaze_count:
			jlog( jdata, ReVA_ERROR, "animation frame, inconsistent gaze count in frame" )
			return cancel_json( jdata )
		if len(f.points) != jdata.content.point_count:
			jlog( jdata, ReVA_ERROR, "animation frame, inconsistent point count in frame" )
			return cancel_json( jdata )
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
			jlog( jdata, ReVA_WARNING, "animation sound field must be a dictionary" )
			jdata.content.erase('sound')
			return jdata
		if not 'bits_per_sample' in jdata.content.sound:
			jlog( jdata, ReVA_WARNING, "animation sound field must have a bits_per_sample field" )
			jdata.content.erase('sound')
			return jdata
		if not 'channels' in jdata.content.sound:
			jlog( jdata, ReVA_WARNING, "animation sound field must have a channels field" )
			jdata.content.erase('sound')
			return jdata
		if not 'sample_rate' in jdata.content.sound:
			jlog( jdata, ReVA_WARNING, "animation sound field must have a sample_rate field" )
			jdata.content.erase('sound')
			return jdata
		if not 'path' in jdata.content.sound:
			jlog( jdata, ReVA_WARNING, "animation sound field must have a path field" )
			jdata.content.erase('sound')
			return jdata
		if jdata.content.sound.path.find('/') == -1 or jdata.content.sound.path.find('\\') == -1:
			var sp = jdata.content.sound.path
			jdata.content.sound.path = get_directory(jdata.path) 
			if OS.get_name() == "Windows":
				jdata.content.sound.path += '\\'
			else:
				jdata.content.sound.path += '/'
			jdata.content.sound.path += sp
		if not file_exists( jdata.content.sound.path ):
			jlog( jdata, ReVA_WARNING, "animation sound invalid path " + jdata.content.sound.path )
			jdata.content.erase('sound')
			return jdata
	
	# reference to a video file
	if 'video' in jdata.content:
		if not jdata.content.video is Dictionary:
			jlog( jdata, ReVA_WARNING, "animation video field must be a dictionary" )
			jdata.content.erase('video')
			return jdata
		if not 'width' in jdata.content.video:
			jlog( jdata, ReVA_WARNING, "animation video must have a width field" )
			jdata.content.erase('video')
			return jdata
		if not 'height' in jdata.content.video:
			jlog( jdata, ReVA_WARNING, "animation video must have a height field" )
			jdata.content.erase('video')
			return jdata
		if not 'path' in jdata.content.video:
			jlog( jdata, ReVA_WARNING, "animation video must have a path field" )
			jdata.content.erase('video')
			return jdata
		if jdata.content.video.path.find('/') == -1 or jdata.content.video.path.find('\\') == -1:
			var vp = jdata.content.video.path
			jdata.content.video.path = get_directory(jdata.path) 
			if OS.get_name() == "Windows":
				jdata.content.video.path += '\\'
			else:
				jdata.content.video.path += '/'
			jdata.content.video.path += vp
		if not file_exists( jdata.content.video.path ):
			jlog( jdata, ReVA_WARNING, "animation video, invalid path " + jdata.content.video.path )
			jdata.content.erase('video')
			return jdata
	
	return jdata

static func load_animation( p ):
	return validate_animation( load_json( p ) )

static func validate_calibration( jdata ):
	
	# basic stuff
	if not jdata.success:
		return cancel_json( jdata )
	if not jdata.content is Dictionary:
		jlog( jdata, ReVA_ERROR, "calibration must be a dictionary" )
		return cancel_json( jdata )
	
	# type & version
	if not 'type' in jdata.content or jdata.content.type != calibration_type:
		jlog( jdata, ReVA_ERROR, "calibration type must be " + calibration_type )
		return cancel_json( jdata )
	if not 'version' in jdata.content or jdata.content.version != version:
		jlog( jdata, ReVA_ERROR, "calibration version must be " + str(version) )
		return cancel_json( jdata )
	
	if not 'groups' in jdata.content or not jdata.content.groups is Array:
		jlog( jdata, ReVA_ERROR, "calibration must have a groups key" )
		return cancel_json( jdata )
	if not 'display_name' in jdata.content or len(jdata.content.display_name) == 0:
		jlog( jdata, ReVA_ERROR, "calibration must have a display_name key" )
		return cancel_json( jdata )
	
	var seen_names = []
	
	# groups validation and transtyping
	for g in jdata.content.groups:
		# errors
		if not g is Dictionary:
			jlog( jdata, ReVA_ERROR, "calibration group must be a dictionary" )
			return cancel_json( jdata )
		if not 'name' in g or len(g.name) == 0:
			jlog( jdata, ReVA_ERROR, "calibration group must have a name field" )
			return cancel_json( jdata )
		if g.name in seen_names:
			jlog( jdata, ReVA_ERROR, "calibration group must have a UNIQUE name" )
			return cancel_json( jdata )
		seen_names.append( g.name )
		if not 'points' in g or not g.points is Array:
			jlog( jdata, ReVA_ERROR, "calibration group must have a points array" )
			return cancel_json( jdata )
		if not 'correction' in g or not g.correction is Dictionary:
			jlog( jdata, ReVA_ERROR, "calibration group must have a correction dictionary" )
			return cancel_json( jdata )
		if not 'rotation' in g.correction or not g.correction.rotation is Array:
			jlog( jdata, ReVA_ERROR, "calibration group correction must have a rotation key" )
			return cancel_json( jdata )
		if not 'translation' in g.correction or not g.correction.translation is Array:
			jlog( jdata, ReVA_ERROR, "calibration group correction must have a translation key" )
			return cancel_json( jdata )
		if not 'scale' in g.correction or not g.correction.scale is Array:
			jlog( jdata, ReVA_ERROR, "calibration group correction must have a scale key" )
			return cancel_json( jdata )
		
		var arr = g.correction.rotation
		g.correction.rotation = Vector3( arr[0],arr[1],arr[2] )
		arr = g.correction.translation
		g.correction.translation = Vector3( arr[0],arr[1],arr[2] )
		arr = g.correction.scale
		g.correction.scale = Vector3( arr[0],arr[1],arr[2] )
		
		# warnings
		if not 'parent' in g or len(g.parent) == 0:
			g.parent = null
		if not 'color' in g or not g.color is Array:
			jlog( jdata, ReVA_WARNING, "calibration group invalid color" )
			g.color = Color(1.0,1.0,1.0)
		else:
			g.color = Color(g.color[0],g.color[1],g.color[2])
		if not 'display_name' in g or len(g.display_name) == 0:
			jlog( jdata, ReVA_WARNING, "calibration group invalid display_name" )
			g.display_name = g.name
	
	return jdata

static func load_calibration( p ):
	return validate_calibration( load_json( p ) )
