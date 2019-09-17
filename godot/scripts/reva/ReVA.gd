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

#static func 

static func clone_array( l ):
	var clone = []
	for i in l:
		if i is Dictionary:
			clone.append( clone_dict(i) )
		elif i is Array:
			clone.append( clone_array(i) )
		elif i is Vector2:
			clone.append( Vector2(i.x,i.y) )
		elif i is Vector3:
			clone.append( Vector3(i.x,i.y,i.z) )
		elif i is Quat:
			clone.append( Quat(i.x,i.y,i.z,i.w) )
		else:
			clone.append( i )
	return clone

static func clone_dict( d ):
	var clone = {}
	for k in d:
		var i = d[k]
		if i is Dictionary:
			clone[k] = clone_dict(i)
		elif i is Array:
			clone[k] = clone_array(i)
		elif i is Vector2:
			clone[k] = Vector2(i.x,i.y)
		elif i is Vector3:
			clone[k] = Vector3(i.x,i.y,i.z)
		elif i is Quat:
			clone[k] = Quat(i.x,i.y,i.z,i.w)
		else:
			clone[k] = i
	return clone

static func blank_jdata():
	return {
		'path': null,
		'content': null,
		'success': false,
		'errors': []
	}

static func blank_animation():
	return {
		'path': null,
		'original': null,
		'content': null,
		'success': false,
		'errors': []
	}

static func blank_calibration():
	return {
		'path': null,
		'original': null,
		'content': null,
		'success': false,
		'errors': []
	}

static func blank_frame( animation ):
	if not animation.success:
		return null
	var frame = {
		'gazes': [],
		'points': [],
		'pose_euler': Vector3(),
		'pose_translation': Vector3(),
		'timestamp': 0
	}
	for i in range( animation.content.gaze_count ):
		frame.gazes.append( Vector3() )
	for i in range( animation.content.point_count ):
		frame.points.append( Vector3() )
	return frame

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
	
	var jdata = blank_jdata()
	jdata.path = p
	
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

### ANIMATIONS ###

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
		
		# removal of rotation delta from points => the rotation will be applied
		# on the parents of the points -> allows stable face alignement
		var q = Quat()
		q.set_euler( f.pose_euler - jdata.content.frames[0].pose_euler )
		var t = Transform( Basis(q.inverse()), Vector3() )
		for p in f.points:
			vs.append( t.xform( Vector3( p[0],p[1],p[2] ) ) )
		f.points = vs
	
	# reference to a sound file
	if 'sound' in jdata.content:
		var keepon = true
		if not jdata.content.sound is Dictionary:
			jlog( jdata, ReVA_WARNING, "animation sound field must be a dictionary" )
			jdata.content.erase('sound')
			keepon = false
		if keepon and not 'bits_per_sample' in jdata.content.sound:
			jlog( jdata, ReVA_WARNING, "animation sound field must have a bits_per_sample field" )
			jdata.content.erase('sound')
			keepon = false
		if keepon and not 'channels' in jdata.content.sound:
			jlog( jdata, ReVA_WARNING, "animation sound field must have a channels field" )
			jdata.content.erase('sound')
			keepon = false
		if keepon and not 'sample_rate' in jdata.content.sound:
			jlog( jdata, ReVA_WARNING, "animation sound field must have a sample_rate field" )
			jdata.content.erase('sound')
			keepon = false
		if keepon and not 'path' in jdata.content.sound:
			jlog( jdata, ReVA_WARNING, "animation sound field must have a path field" )
			jdata.content.erase('sound')
			keepon = false
		if keepon and ( jdata.content.sound.path.find('/') == -1 or jdata.content.sound.path.find('\\') == -1 ):
			var sp = jdata.content.sound.path
			jdata.content.sound.path = get_directory(jdata.path) 
			if OS.get_name() == "Windows":
				jdata.content.sound.path += '\\'
			else:
				jdata.content.sound.path += '/'
			jdata.content.sound.path += sp
		if  keepon and not file_exists( jdata.content.sound.path ):
			jlog( jdata, ReVA_WARNING, "animation sound invalid path " + jdata.content.sound.path )
			jdata.content.erase('sound')
			keepon = false
	
	# reference to a video file
	if 'video' in jdata.content:
		var keepon = true
		if not jdata.content.video is Dictionary:
			jlog( jdata, ReVA_WARNING, "animation video field must be a dictionary" )
			jdata.content.erase('video')
			keepon = false
		if keepon and not 'width' in jdata.content.video:
			jlog( jdata, ReVA_WARNING, "animation video must have a width field" )
			jdata.content.erase('video')
			keepon = false
		if keepon and not 'height' in jdata.content.video:
			jlog( jdata, ReVA_WARNING, "animation video must have a height field" )
			jdata.content.erase('video')
			keepon = false
		if keepon and not 'path' in jdata.content.video:
			jlog( jdata, ReVA_WARNING, "animation video must have a path field" )
			jdata.content.erase('video')
			keepon = false
		if keepon and ( jdata.content.video.path.find('/') == -1 or jdata.content.video.path.find('\\') == -1 ):
			var vp = jdata.content.video.path
			jdata.content.video.path = get_directory(jdata.path) 
			if OS.get_name() == "Windows":
				jdata.content.video.path += '\\'
			else:
				jdata.content.video.path += '/'
			jdata.content.video.path += vp
		if keepon and not file_exists( jdata.content.video.path ):
			jlog( jdata, ReVA_WARNING, "animation video, invalid path " + jdata.content.video.path )
			jdata.content.erase('video')
			keepon = false
	
	var a = blank_animation()
	a.path = jdata.path
	a.original = clone_dict( jdata.content )
	a.content = jdata.content
	a.success = jdata.success
	a.errors = jdata.errors
	return a

static func load_animation( p ):
	return validate_animation( load_json( p ) )

static func reset( data ):
	if 'original' in data and 'content' in data:
		data.content = clone_dict( data.original )

static func interpolate_euler( src, dst, alpha ):
	var srcq = Quat()
	srcq.set_euler( src )
	var dstq = Quat()
	dstq.set_euler( dst )
	return srcq.slerp( dstq, alpha ).get_euler()

static func lerp_vec3( src, dst, alpha ):
	return src * (1-alpha) + dst * alpha

static func animation_frame( animation, ts, interpolation = true ):
	
	if not animation.success:
		return null
	
	var anim = animation.content
	while ts > anim.duration:
		ts -= anim.duration
	
	if not interpolation:
		var prev_frame = anim.frames[0]
		for f in anim.frames:
			if f.timestamp > ts:
				return prev_frame
			prev_frame = f
	else:
		# frame interpolation
		var prev_frame = anim.frames[0]
		var next_frame = anim.frames[0]
		for f in anim.frames:
			if f.timestamp >= ts:
				prev_frame = next_frame
				next_frame = f
				break
			else:
				prev_frame = next_frame
				next_frame = f
		
		var nframe = blank_frame( animation )
		nframe.timestamp = ts
		
		var ts_diff = next_frame.timestamp - prev_frame.timestamp
		var pc = ( ts - prev_frame.timestamp ) / ts_diff
		
		nframe.pose_euler = interpolate_euler( prev_frame.pose_euler, next_frame.pose_euler, pc )
		nframe.pose_translation = lerp_vec3( prev_frame.pose_translation, next_frame.pose_translation, pc )
		for i in range( animation.content.gaze_count ):
			nframe.gazes[i] = interpolate_euler( prev_frame.gazes[i], next_frame.gazes[i], pc )
		for i in range( animation.content.point_count ):
			nframe.points[i] = lerp_vec3( prev_frame.points[i], next_frame.points[i], pc )
		
		return nframe

### CALIBRATIONS ###

static func decompress_indexlist( l ):
	
	var out = []
	for i in l:
		if i is Array and len(i) == 2:
			for j in range( i[0], i[1]+1 ):
				out.append( j )
		else:
			out.append( i )
	return out

static func search_in_hierarchy( level, gname ):
	for node in level:
		if node.group == gname:
			return node
		var o = search_in_hierarchy( node.children, gname )
		if o != null:
			return o
	return null

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
		if 'symmetry' in g and not g.symmetry is Array:
			jlog( jdata, ReVA_ERROR, "calibration group symmetry must have be a list" )
			return cancel_json( jdata )
		if 'symmetry' in g and len( g.points ) != 2:
			jlog( jdata, ReVA_ERROR, "calibration group symmetry requires 2 list of points" )
			return cancel_json( jdata )
		
		var arr = g.correction.rotation
		g.correction.rotation = Vector3( arr[0],arr[1],arr[2] )
		arr = g.correction.translation
		g.correction.translation = Vector3( arr[0],arr[1],arr[2] )
		arr = g.correction.scale
		g.correction.scale = Vector3( arr[0],arr[1],arr[2] )
		
		# post processing of points:
		if 'symmetry' in g:
			arr = g.symmetry
			g.symmetry = Transform( Basis( Vector3(arr[0],0,0), Vector3(0,arr[1],0), Vector3(0,0,arr[2]) ), Vector3() )
			var pts = []
			for sub in g.points:
				pts.append( decompress_indexlist( sub ) )
			g.points = pts
		else:
			g.points = decompress_indexlist( g.points )
		
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
	
	# generation of a group hierarchy
	jdata.content.hierarchy = []
	for g in jdata.content.groups:
		if g.parent == null:
			jdata.content.hierarchy.append( { 'group': g.name, 'children': [] } )
		else:
			var p = search_in_hierarchy( jdata.content.hierarchy, g.parent )
			if p != null:
				p.children.append( { 'group': g.name, 'children': [] } )
	
	var a = blank_calibration()
	a.path = jdata.path
	a.original = clone_dict( jdata.content )
	a.content = jdata.content
	a.success = jdata.success
	a.errors = jdata.errors
	return a

static func load_calibration( p ):
	return validate_calibration( load_json( p ) )

static func check_calibration( calibration, animation ):
	
	if not calibration.success or not animation.success:
		return cancel_json( calibration )
	
	# looping over all groups to validate there is no off-range numbers
	var gs = []
	for g in calibration.content.groups:
		var newg = clone_dict(g)
		newg.points = []
		if 'symmetry' in g:
			for sub in g.points:
				var subg = []
				for i in sub:
					if i >= 0 and i < animation.content.point_count:
						subg.append( i )
					else:
						jlog( calibration, ReVA_WARNING, "invalid point index [" + str(i) + "] in group " + g.name )
				newg.points.append( subg )
		else:
			for i in g.points:
				if i >= 0 and i < animation.content.point_count:
					newg.points.append( i )
				else:
					jlog( calibration, ReVA_WARNING, "invalid point index [" + str(i) + "] in group " + g.name )
		gs.append( newg )
	calibration.content.groups = gs

static func apply_calibration( calibration, animation ):
	
	if not calibration.success or not animation.success:
		return
