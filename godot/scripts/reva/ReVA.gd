const ReVA_VERSION = 1
const ReVA_PREFIX = 'ReVA'
const ReVA_TYPE_NONE = ReVA_PREFIX + '_none'
const ReVA_TYPE_MODEL = ReVA_PREFIX + '_model'
const ReVA_TYPE_ANIM = ReVA_PREFIX + '_animation'
const ReVA_TYPE_CALIB = ReVA_PREFIX + '_calibration'
const ReVA_TYPE_MAPP = ReVA_PREFIX + '_mapping'
const ReVA_ERR_PREFIX = "ReVA Error: "
const ReVA_WARN_PREFIX = "ReVA Warning: "
const ReVA_INFO_PREFIX = "ReVA Info: "
const ReVA_BONEATTACHMENT_PREFIX = "ba_"

const ReVA_DEBUG = true
const ReVA_ERROR = 		1
const ReVA_WARNING = 	10
const ReVA_INFO = 		20

const ReVA_PATH_CONSTRAINT = "res://scripts/reva/ReVA_constraint.gd"

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

static func vec2_to_list( v2 ):
	return [v2.x,v2.y]

static func vec3_to_list( v3 ):
	return [v3.x,v3.y,v3.z]

static func quat_to_list( q ):
	return [q.x,q.y,q.z,q.w]

static func rgb_to_list( c ):
	return [c.r,c.g,c.b]

static func blank_jdata():
	return {
		'type': ReVA_TYPE_NONE,
		'path': null,
		'content': null,
		'success': false,
		'errors': []
	}

static func blank_model():
	return {
		'type': ReVA_TYPE_MODEL,
		'path': null,
		'node': null,
		'attachments': {
			'list':[],
			'dict':{}
		},
		'face_bones': [],
		'success': false,
		'errors': []
	}

static func blank_animation():
	return {
		'type': ReVA_TYPE_ANIM,
		'path': null,
		'original': null,
		'content': null,
		'success': false,
		'errors': []
	}

static func blank_calibration():
	return {
		'type': ReVA_TYPE_CALIB,
		'path': null,
		'original': null,
		'content': null,
		'success': false,
		'errors': []
	}

static func blank_mapping():
	return {
		'type': ReVA_TYPE_MAPP,
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
# warning-ignore:unused_variable
	for i in range( animation.content.gaze_count ):
		frame.gazes.append( Vector3() )
# warning-ignore:unused_variable
	for i in range( animation.content.point_count ):
		frame.points.append( Vector3() )
	return frame

static func blank_group():
	return {
		'name': 'new group',
		'display_name': 'new group',
		'points': [],
		'correction': {
			'rotation': Vector3(0,0,0),
			'translation': Vector3(0,0,0),
			'scale': Vector3(1,1,1),
		},
		'parent': null,
		'color': Color( randf(),randf(),randf() )
	}

static func get_directory( p ):
	return p.get_base_dir()

static func file_exists( p ):
	var f = File.new()
	if not f.file_exists( p ):
		return false
	return true

static func rlog( data, lvl, txt ):
	data.errors.append( [lvl, txt] )
	if ReVA_DEBUG:
		match lvl:
			ReVA_ERROR:
				print( ReVA_ERR_PREFIX, txt )
			ReVA_WARNING:
				print( ReVA_WARN_PREFIX, txt )
			ReVA_INFO:
				print( ReVA_INFO_PREFIX, txt )
			_:
				print( txt )

static func load_json( p ):
	
	var jdata = blank_jdata()
	jdata.path = p
	
	if not file_exists( p ):
		rlog( jdata, ReVA_ERROR, "invalid path " + p )
		return jdata
	var file = File.new()
	file.open( p, file.READ )
	var result_json = JSON.parse(file.get_as_text())
	file.close()
	if result_json.error == OK:  # If parse OK
		jdata.content = result_json.result
		jdata.success = true
	else:  # If parse has errors
		rlog( jdata, ReVA_ERROR, result_json.error )
		rlog( jdata, ReVA_ERROR,  "line: " + result_json.error_line )
		rlog( jdata, ReVA_ERROR,  "string: " + result_json.error_string )
	return jdata

static func save_json( jdata ):
	
	if not file_exists( jdata.path ):
		rlog( jdata, ReVA_ERROR, "invalid path " + jdata.path )
		return jdata
	
	var file = File.new()
	file.open( jdata.path, file.WRITE )
	file.store_string( JSON.print(jdata.content) )
	file.close()
	return jdata

static func cancel_json( jdata ):
	return {
		'type': jdata.type,
		'path': jdata.path,
		'content': null,
		'success': false,
		'errors': jdata.errors
	}

static func cancel_model( mdata ):
	var out = blank_model()
	out.type = mdata.type
	out.path = mdata.path
	out.errors = mdata.errors

### MODELS ###

static func load_model( path ):
	
	var mdata = blank_model()
	
	mdata.path = path
	if not file_exists( mdata.path ):
		rlog( mdata, ReVA_ERROR, "invalid path " + mdata.path )
		return mdata
	
	mdata.node = load( path ).instance()
	if not mdata.node is Skeleton:
		rlog( mdata, ReVA_ERROR, "first node in model must be a Skeleton" )
		return cancel_model( mdata )
	
	if mdata.node.get_node( 'face_cam' ) == null or not mdata.node.get_node( 'face_cam' ) is BoneAttachment:
		rlog( mdata, ReVA_WARNING, "model must have a BoneAttachment called 'face_cam' for calibration views" )
	
	# generation of bone attachements:
	var cscript = load( ReVA_PATH_CONSTRAINT )
	for i in range( mdata.node.get_bone_count() ):
		var bname = mdata.node.get_bone_name(i)
		var ba = BoneAttachment.new()
		ba.set_script( cscript )
		mdata.node.add_child( ba )
		ba.name = ReVA_BONEATTACHMENT_PREFIX + bname
		ba.bone_name = bname
		mdata.attachments.list.append( ba )
		mdata.attachments.dict[bname] = ba
	
	if not 'face_bones' in mdata.node or not mdata.node.face_bones is Array:
		rlog( mdata, ReVA_WARNING, "model doesn't have a ReVA_avatar_configuration.gd or equivalent, this will causes errors in automatic calibration" )
		mdata.face_bones = clone_array( mdata.attachments.list )
	else:
		for n in mdata.node.face_bones:
			var bid = mdata.node.find_bone(n)
			if bid == -1:
				rlog( mdata, ReVA_WARNING, "no bone " + n + " in " + mdata.node.name )
			else:
				mdata.face_bones.append(  mdata.node.get_node( ReVA_BONEATTACHMENT_PREFIX + n ) )
	
	print( mdata.node.get_script() )
	
	mdata.success = true
	return mdata

### ANIMATIONS ###

static func validate_animation( jdata ):
	
	# basic stuff
	if not jdata.success:
		return cancel_json( jdata )
	if not jdata.content is Dictionary:
		rlog( jdata, ReVA_ERROR, "animation must be a dictionary" )
		return cancel_json( jdata )
	
	# type & version
	if not 'type' in jdata.content or jdata.content.type != ReVA_TYPE_ANIM:
		rlog( jdata, ReVA_ERROR, "animation type must be " + ReVA_TYPE_ANIM )
		return cancel_json( jdata )
	if not 'version' in jdata.content or jdata.content.version != ReVA_VERSION:
		rlog( jdata, ReVA_ERROR, "animation version must be " + str(ReVA_VERSION) )
		return cancel_json( jdata )
	
	# missing data
	if not 'frames' in jdata.content or not jdata.content.frames is Array:
		rlog( jdata, ReVA_ERROR, "animation must have a frames key" )
		return cancel_json( jdata )
	if not 'duration' in jdata.content or not jdata.content.duration is float:
		rlog( jdata, ReVA_ERROR, "animation must have a duration key" )
		return cancel_json( jdata )
	
	if not 'gaze_count' in jdata.content or not jdata.content.gaze_count is float:
		rlog( jdata, ReVA_ERROR, "animation must have a gaze_count key" )
		return cancel_json( jdata )
	else:
		jdata.content.gaze_count = int(jdata.content.gaze_count)
	if not 'point_count' in jdata.content or not jdata.content.point_count is float:
		rlog( jdata, ReVA_ERROR, "animation must have a point_count key" )
		return cancel_json( jdata )
	else:
		jdata.content.point_count = int(jdata.content.point_count)
	
	# aabb validation and transtyping
	if not 'aabb' in jdata.content or not jdata.content.aabb is Dictionary:
		rlog( jdata, ReVA_ERROR, "animation must have a aabb key" )
		return cancel_json( jdata )
	
	if not 'center' in jdata.content.aabb or not jdata.content.aabb.center is Array:
		rlog( jdata, ReVA_ERROR, "animation aabb must have a center key" )
		return cancel_json( jdata )
	if not 'min' in jdata.content.aabb or not jdata.content.aabb.min is Array:
		rlog( jdata, ReVA_ERROR, "animation aabb must have a min key" )
		return cancel_json( jdata )
	if not 'max' in jdata.content.aabb or not jdata.content.aabb.max is Array:
		rlog( jdata, ReVA_ERROR, "animation aabb must have a max key" )
		return cancel_json( jdata )
	if not 'size' in jdata.content.aabb or not jdata.content.aabb.size is Array:
		rlog( jdata, ReVA_ERROR, "animation aabb must have a size key" )
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
			rlog( jdata, ReVA_ERROR, "animation frame must be a dictionary" )
			return cancel_json( jdata )
		if not 'gazes' in f or not f.gazes is Array:
			rlog( jdata, ReVA_ERROR, "animation frame must have a gazes key" )
			return cancel_json( jdata )
		if not 'points' in f or not f.points is Array:
			rlog( jdata, ReVA_ERROR, "animation frame must have a points key" )
			return cancel_json( jdata )
		if not 'pose_euler' in f or not f.pose_euler is Array:
			rlog( jdata, ReVA_ERROR, "animation frame must have a pose_euler key" )
			return cancel_json( jdata )
		if not 'pose_translation' in f or not f.pose_translation is Array:
			rlog( jdata, ReVA_ERROR, "animation frame must have a pose_translation key" )
			return cancel_json( jdata )
		if not 'timestamp' in f or not f.timestamp is float:
			rlog( jdata, ReVA_ERROR, "animation frame must have a timestamp key" )
		if len(f.gazes) != jdata.content.gaze_count:
			rlog( jdata, ReVA_ERROR, "animation frame, inconsistent gaze count in frame" )
			return cancel_json( jdata )
		if len(f.points) != jdata.content.point_count:
			rlog( jdata, ReVA_ERROR, "animation frame, inconsistent point count in frame" )
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
			rlog( jdata, ReVA_WARNING, "animation sound field must be a dictionary" )
			jdata.content.erase('sound')
			keepon = false
		if keepon and not 'bits_per_sample' in jdata.content.sound:
			rlog( jdata, ReVA_WARNING, "animation sound field must have a bits_per_sample field" )
			jdata.content.erase('sound')
			keepon = false
		if keepon and not 'channels' in jdata.content.sound:
			rlog( jdata, ReVA_WARNING, "animation sound field must have a channels field" )
			jdata.content.erase('sound')
			keepon = false
		if keepon and not 'sample_rate' in jdata.content.sound:
			rlog( jdata, ReVA_WARNING, "animation sound field must have a sample_rate field" )
			jdata.content.erase('sound')
			keepon = false
		if keepon and not 'path' in jdata.content.sound:
			rlog( jdata, ReVA_WARNING, "animation sound field must have a path field" )
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
			rlog( jdata, ReVA_WARNING, "animation sound invalid path " + jdata.content.sound.path )
			jdata.content.erase('sound')
			keepon = false
	
	# reference to a video file
	if 'video' in jdata.content:
		var keepon = true
		if not jdata.content.video is Dictionary:
			rlog( jdata, ReVA_WARNING, "animation video field must be a dictionary" )
			jdata.content.erase('video')
			keepon = false
		if keepon and not 'width' in jdata.content.video:
			rlog( jdata, ReVA_WARNING, "animation video must have a width field" )
			jdata.content.erase('video')
			keepon = false
		if keepon and not 'height' in jdata.content.video:
			rlog( jdata, ReVA_WARNING, "animation video must have a height field" )
			jdata.content.erase('video')
			keepon = false
		if keepon and not 'path' in jdata.content.video:
			rlog( jdata, ReVA_WARNING, "animation video must have a path field" )
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
			rlog( jdata, ReVA_WARNING, "animation video, invalid path " + jdata.content.video.path )
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
		var pc = 0
		if ts_diff != 0:
			pc = ( ts - prev_frame.timestamp ) / ts_diff
		
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

static func get_group_by_id( src, id ):
	
	var gs = null
	if 'content' in src:
		# full calibration
		gs = src.content.groups
	elif 'groups' in src:
		# subpart
		gs = src.groups
	else:
		return null
	for g in gs:
		if g.id == id:
			return g
	return null

static func get_group_index( src, id ):
	var gs = null
	if 'content' in src:
		# full calibration
		gs = src.content.groups
	elif 'groups' in src:
		# subpart
		gs = src.groups
	else:
		return -1
	var gi = 0
	for g in gs:
		if g.id == id:
			return gi
		gi += 1
	return -1

static func search_in_hierarchy( level, gid ):
	for node in level:
		if node.group.id == gid:
			return node
		var o = search_in_hierarchy( node.children, gid )
		if o != null:
			return o
	return null

static func generate_group_ids( calibration ):
	var gid = 0
	for g in calibration.content.groups:
		g.id = gid
		gid += 1

static func generate_group_hierarchy( calibration ):
	
	# generation of a group hierarchy
	calibration.content.hierarchy = []
	for g in calibration.content.groups:
		if g.parent == null:
			calibration.content.hierarchy.append( { 'group': g, 'children': [] } )
		else:
			var p = search_in_hierarchy( calibration.content.hierarchy, g.parent )
			if p != null:
				p.children.append( {'group': g, 'children': [] } )

static func validate_calibration( jdata ):
	
	# basic stuff
	if not jdata.success:
		return cancel_json( jdata )
	if not jdata.content is Dictionary:
		rlog( jdata, ReVA_ERROR, "calibration must be a dictionary" )
		return cancel_json( jdata )
	
	# type & version
	if not 'type' in jdata.content or jdata.content.type != ReVA_TYPE_CALIB:
		rlog( jdata, ReVA_ERROR, "calibration type must be " + ReVA_TYPE_CALIB )
		return cancel_json( jdata )
	if not 'version' in jdata.content or jdata.content.version != ReVA_VERSION:
		rlog( jdata, ReVA_ERROR, "calibration version must be " + str(ReVA_VERSION) )
		return cancel_json( jdata )
	
	if not 'groups' in jdata.content or not jdata.content.groups is Array:
		rlog( jdata, ReVA_ERROR, "calibration must have a groups key" )
		return cancel_json( jdata )
	if not 'display_name' in jdata.content or len(jdata.content.display_name) == 0:
		rlog( jdata, ReVA_ERROR, "calibration must have a display_name key" )
		return cancel_json( jdata )
	
	var seen_names = []
	# groups validation and transtyping
	for g in jdata.content.groups:
		# errors
		if not g is Dictionary:
			rlog( jdata, ReVA_ERROR, "calibration group must be a dictionary" )
			return cancel_json( jdata )
		if not 'name' in g or len(g.name) == 0:
			rlog( jdata, ReVA_ERROR, "calibration group must have a name field" )
			return cancel_json( jdata )
		if g.name in seen_names:
			rlog( jdata, ReVA_ERROR, "calibration group must have a UNIQUE name" )
			return cancel_json( jdata )
		seen_names.append( g.name )
		if not 'points' in g or not g.points is Array:
			rlog( jdata, ReVA_ERROR, "calibration group must have a points array" )
			return cancel_json( jdata )
		if not 'correction' in g or not g.correction is Dictionary:
			rlog( jdata, ReVA_ERROR, "calibration group must have a correction dictionary" )
			return cancel_json( jdata )
		if not 'rotation' in g.correction or not g.correction.rotation is Array:
			rlog( jdata, ReVA_ERROR, "calibration group correction must have a rotation key" )
			return cancel_json( jdata )
		if not 'translation' in g.correction or not g.correction.translation is Array:
			rlog( jdata, ReVA_ERROR, "calibration group correction must have a translation key" )
			return cancel_json( jdata )
		if not 'scale' in g.correction or not g.correction.scale is Array:
			rlog( jdata, ReVA_ERROR, "calibration group correction must have a scale key" )
			return cancel_json( jdata )
		if 'symmetry' in g and not g.symmetry is Dictionary:
			rlog( jdata, ReVA_ERROR, "calibration group symmetry must have be a dictionary" )
			return cancel_json( jdata )
		if 'symmetry' in g and (not 'rotation' in g.symmetry or not g.symmetry.rotation is Array):
			rlog( jdata, ReVA_ERROR, "calibration group symmetry must have a rotation key" )
			return cancel_json( jdata )
		if 'symmetry' in g and (not 'translation' in g.symmetry or not g.symmetry.translation is Array):
			rlog( jdata, ReVA_ERROR, "calibration group symmetry must have a translation key" )
			return cancel_json( jdata )
		if 'symmetry' in g and (not 'scale' in g.symmetry or not g.symmetry.scale is Array):
			rlog( jdata, ReVA_ERROR, "calibration group symmetry must have a scale key" )
			return cancel_json( jdata )
		if 'symmetry' in g and len( g.points ) != 2:
			rlog( jdata, ReVA_ERROR, "calibration group symmetry requires 2 list of points" )
			return cancel_json( jdata )
		
		var arr = g.correction.rotation
		g.correction.rotation = Vector3( arr[0],arr[1],arr[2] )
		arr = g.correction.translation
		g.correction.translation = Vector3( arr[0],arr[1],arr[2] )
		arr = g.correction.scale
		g.correction.scale = Vector3( arr[0],arr[1],arr[2] )
		
		# post processing of points:
		if 'symmetry' in g:
			arr = g.symmetry.rotation
			g.symmetry.rotation = Vector3(arr[0],arr[1],arr[2])
			arr = g.symmetry.translation
			g.symmetry.translation = Vector3(arr[0],arr[1],arr[2])
			arr = g.symmetry.scale
			g.symmetry.scale = Vector3(arr[0],arr[1],arr[2])
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
			rlog( jdata, ReVA_WARNING, "calibration group invalid color" )
			g.color = Color(1.0,1.0,1.0)
		else:
			g.color = Color(g.color[0],g.color[1],g.color[2])
		if not 'display_name' in g or len(g.display_name) == 0:
			rlog( jdata, ReVA_WARNING, "calibration group invalid display_name" )
			g.display_name = g.name
	
	generate_group_ids( jdata )
	
	# relinking parents with ids
	var newgs = []
	for g in jdata.content.groups:
		var newg = clone_dict(g)
		if g.parent != null:
			for pg in jdata.content.groups:
				if pg.name == g.parent:
					newg.parent = pg.id
		newgs.append( newg )
	jdata.content.groups = newgs
	
	generate_group_hierarchy( jdata )
	
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
	
	if not calibration.success:
		rlog( animation, ReVA_INFO, "calibration is not successfully loaded" )
		return
	
	if not calibration.type == ReVA_TYPE_CALIB:
		rlog( calibration, ReVA_INFO, "calibration must be of type " + ReVA_TYPE_CALIB )
		return
	
	if not animation.success:
		rlog( animation, ReVA_INFO, "animation is not successfully loaded" )
		return
	
	if not animation.type == ReVA_TYPE_ANIM:
		rlog( animation, ReVA_INFO, "mapping must be of type " + ReVA_TYPE_ANIM )
		return
	
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
						rlog( calibration, ReVA_WARNING, "invalid point index [" + str(i) + "] in group " + g.name )
				newg.points.append( subg )
		else:
			for i in g.points:
				if i >= 0 and i < animation.content.point_count:
					newg.points.append( i )
				else:
					rlog( calibration, ReVA_WARNING, "invalid point index [" + str(i) + "] in group " + g.name )
		gs.append( newg )
	calibration.content.groups = gs

static func apply_calibration_group( ginfo, calibration, animation ):
	
	if not animation.success:
		return
	var group = get_group_by_id( calibration, ginfo.group.id )
	var corr = group.correction
	if not identity_correction(corr):
		var t = Transform( Basis( corr.rotation ), corr.translation ).scaled( corr.scale )
		if 'symmetry' in group:
			apply_correction( t, group.points[0], animation )
			t = Transform( Basis( corr.rotation * group.symmetry.rotation ), corr.translation * group.symmetry.translation ).scaled( corr.scale * group.symmetry.scale )
			apply_correction( t, group.points[1], animation )
		else:
			apply_correction( t, group.points, animation )
	
	for g in ginfo.children:
		apply_calibration_group( g, calibration, animation )

static func apply_calibration( calibration, animation ):
	
	if not calibration.success or not animation.success:
		return
	reset( animation )
	for g in calibration.content.hierarchy:
		apply_calibration_group( g, calibration, animation )

static func save_calibration( calibration ):
	
	if not calibration.success:
		return
	
	var jdata = blank_jdata()
	jdata.path = calibration.path
	jdata.content = clone_dict( calibration.content )
	jdata.content.erase( 'hierarchy' )
	
	for g in jdata.content.groups:
		g.correction.rotation = vec3_to_list(g.correction.rotation)
		g.correction.translation = vec3_to_list(g.correction.translation)
		g.correction.scale = vec3_to_list(g.correction.scale)
		if 'symmetry' in g:
			g.symmetry.rotation = vec3_to_list(g.symmetry.rotation)
			g.symmetry.translation = vec3_to_list(g.symmetry.translation)
			g.symmetry.scale = vec3_to_list(g.symmetry.scale)
		g.color = rgb_to_list(g.color)
		if g.parent  == null:
			g.erase( 'parent' )
	
	return save_json( jdata )

static func reset_calibration_group( calibration, gid ):
	
	if not calibration.success:
		return
	
	var g = get_group_by_id( calibration, gid )
	var original = get_group_by_id( calibration.original, gid )
	if g == null or original == null:
		rlog( calibration, ReVA_WARNING, "no group with ID " + str(gid) + " in this calibration" )
		return
	
	for i in range( 0, len( calibration.content.groups ) ):
		if calibration.content.groups[i].id == gid:
			calibration.content.groups[i] = clone_dict( original )
			break
	generate_group_hierarchy( calibration )

static func calibration_group_parented( calibration, group, needle ):
	if group == null or needle == null or group.parent == null:
		return false
	elif group.parent == needle.id:
		return true
	else:
		return calibration_group_parented( calibration, get_group_by_id(calibration, group.parent), needle )

static func calibration_groups_not_in_path( calibration, group ):
	
	if not calibration.success:
		return
	
	if not calibration.type == ReVA_TYPE_CALIB:
		rlog( calibration, ReVA_INFO, "calibration must be of type " + ReVA_TYPE_CALIB )
		return
	
	var out = []
	for g in calibration.content.groups:
		if g == group:
			continue
		if not calibration_group_parented( calibration, g, group ):
			out.append( clone_dict( g ) )
	return out

static func group_unique_name( src ):
	
	if 'content' in src:
		# it's the calibration structure!
		group_unique_name( src.content.hierarchy )
		return
	
	if not src is Array:
		return
	
	var seen_names = []
	var to_rename = []
	for gi in src:
		group_unique_name( gi.children )
		if not gi.group.name in seen_names:
			seen_names.append( gi.group.name )
		else:
			to_rename.append( gi.group )
	
	for g in to_rename:
		var iteration = 0
		var newname = g.name
		while newname in seen_names:
			newname = g.name
			if iteration < 10:
				newname += '.000'
			elif iteration < 100:
				newname += '.00'
			elif iteration < 1000:
				newname += '.0'
			else:
				newname += '.'
			newname += str(iteration)
			if not newname in seen_names:
				break
			iteration += 1
		seen_names.append( newname )
		g.name = newname

static func calibration_group_duplicate( calibration, groupid ):
	
	if not calibration.success:
		return -1
	
	if not calibration.type == ReVA_TYPE_CALIB:
		rlog( calibration, ReVA_INFO, "calibration must be of type " + ReVA_TYPE_CALIB )
		return -1
	
	var src = get_group_by_id( calibration, groupid )
	if src == null:
		rlog( calibration, ReVA_INFO, "group " + str(groupid) + " not found in this calibration!" )
		return -1
	
	var newg = clone_dict( src )
	var newid = 0
	while get_group_by_id( calibration, newid ) != null:
		newid += 1
	newg.id = newid
	if newg.name.find_last( '.' ) == len(newg.name) - 5:
		newg.name = newg.name.substr(0, len(newg.name) - 5 )
	calibration.content.groups.append( newg )
	generate_group_hierarchy( calibration )
	group_unique_name( calibration.content.hierarchy )
	
	return newg.id

static func calibration_group_delete( calibration, groupid ):
	
	if not calibration.success:
		return
	
	if not calibration.type == ReVA_TYPE_CALIB:
		rlog( calibration, ReVA_INFO, "calibration must be of type " + ReVA_TYPE_CALIB )
		return
	
	var del = get_group_by_id( calibration, groupid )
	var newgs = []
	for g in calibration.content.groups:
		if g.id != groupid and not calibration_group_parented( calibration, g, del ):
			newgs.append( g )
	calibration.content.groups = newgs
	generate_group_hierarchy( calibration )

static func calibration_group_new( calibration ):
	
	if not calibration.success:
		return -1
	
	if not calibration.type == ReVA_TYPE_CALIB:
		rlog( calibration, ReVA_INFO, "calibration must be of type " + ReVA_TYPE_CALIB )
		return -1
	
	var newg = blank_group()
	var newid = 0
	while get_group_by_id( calibration, newid ) != null:
		newid += 1
	newg.id = newid
	calibration.content.groups.append(newg)
	generate_group_hierarchy( calibration )
	group_unique_name( calibration.content.hierarchy )
	
	return newg.id

static func calibration_group_parent( calibration, groupid, parentid ):
	
	if not calibration.success:
		return
	
	if not calibration.type == ReVA_TYPE_CALIB:
		rlog( calibration, ReVA_INFO, "calibration must be of type " + ReVA_TYPE_CALIB )
		return
	
	var src = get_group_by_id( calibration, groupid )
	var parent = get_group_by_id( calibration, parentid )
	if src == null:
		rlog( calibration, ReVA_INFO, "group " + str(groupid) + " not found in this calibration!" )
		return -1
	
	if parent == null:
		src.parent = null
	else:
		src.parent = parentid
	
	generate_group_hierarchy( calibration )
	group_unique_name( calibration.content.hierarchy )
	

### MAPPINGS ###

static func validate_mapping( jdata ):
	
	# basic stuff
	if not jdata.success:
		return cancel_json( jdata )
	if not jdata.content is Dictionary:
		rlog( jdata, ReVA_ERROR, "mapping must be a dictionary" )
		return cancel_json( jdata )
	
	# type & version
	if not 'type' in jdata.content or jdata.content.type != ReVA_TYPE_MAPP:
		rlog( jdata, ReVA_ERROR, "mapping type must be " + ReVA_TYPE_MAPP )
		return cancel_json( jdata )
	if not 'version' in jdata.content or jdata.content.version != ReVA_VERSION:
		rlog( jdata, ReVA_ERROR, "mapping version must be " + str(ReVA_VERSION) )
		return cancel_json( jdata )
	
	if not 'attachment_bone' in jdata.content:
		rlog( jdata, ReVA_ERROR, "mapping must have a attachment_bone key" )
		return cancel_json( jdata )
	if not 'maps' in jdata.content or not jdata.content.maps is Array:
		rlog( jdata, ReVA_ERROR, "mapping must have a maps key" )
		return cancel_json( jdata )
	
	# validation of maps
	var valid_ms = []
	for m in jdata.content.maps:
		
		if not 'bone' in m or m.bone == null or len(m.bone) == 0:
			rlog( jdata, ReVA_WARNING, "map must have a bone key" )
			continue
		
		if not 'constraint' in m or not m.constraint is Dictionary:
			rlog( jdata, ReVA_WARNING, "map must have a constraint key" )
			continue
		if not 'lookat_enabled' in m.constraint:
			rlog( jdata, ReVA_WARNING, "map constraint must have a lookat_enabled key" )
			continue
		if not 'rot_enabled' in m.constraint:
			rlog( jdata, ReVA_WARNING, "map constraint must have a rot_enabled key" )
			continue
		if not 'trans_enabled' in m.constraint:
			rlog( jdata, ReVA_WARNING, "map constraint must have a trans_enabled key" )
			continue
		if not 'rot_lock' in m.constraint or not m.constraint.rot_lock is Array:
			rlog( jdata, ReVA_WARNING, "map constraint must have a rot_lock list" )
			continue
		if not 'rot_mult' in m.constraint or not m.constraint.rot_mult is Array:
			rlog( jdata, ReVA_WARNING, "map constraint must have a rot_mult list" )
			continue
		if not 'trans_lock' in m.constraint or not m.constraint.trans_lock is Array:
			rlog( jdata, ReVA_WARNING, "map constraint must have a trans_lock list" )
			continue
		if not 'trans_mult' in m.constraint or not m.constraint.trans_mult is Array:
			rlog( jdata, ReVA_WARNING, "map constraint must have a trans_mult list" )
			continue
		
		var arr = m.constraint.rot_mult
		m.constraint.rot_mult = Vector3( arr[0],arr[1],arr[2] )
		arr = m.constraint.trans_mult
		m.constraint.trans_mult = Vector3( arr[0],arr[1],arr[2] )
			
		var missing_field = 0	
		if not 'point_weights' in m or not m.point_weights is Array:
			missing_field += 1
		if not 'pose_euler' in m or not m.pose_euler is Dictionary:
			missing_field += 1
		if not 'gaze' in m or not m.gaze is Dictionary:
			missing_field += 1
		if missing_field == 3:
			rlog( jdata, ReVA_WARNING, "map must have at least one of these keys: 'point_weights', 'pose_euler' or 'gaze'" )
			continue
		
		if 'gaze' in m:
			if not 'id' in m.gaze:
				rlog( jdata, ReVA_WARNING, "map gaze must have an id field" )
				continue
			if not 'damping' in m.gaze:
				rlog( jdata, ReVA_WARNING, "map gaze must have a damping field" )
				continue
			if not 'weight' in m.gaze:
				rlog( jdata, ReVA_WARNING, "map gaze must have a weight field" )
				continue
			var newm = clone_dict(m)
			if 'point_weights' in newm:
				newm.erase( 'point_weights' )
			if 'pose_euler' in newm:
				newm.erase( 'pose_euler' )
			valid_ms.append(newm)
			continue
		
		if 'pose_euler' in m:
			if not 'damping' in m.pose_euler:
				rlog( jdata, ReVA_WARNING, "map pose_euler must have a damping field" )
				continue
			if not 'weight' in m.pose_euler:
				rlog( jdata, ReVA_WARNING, "map pose_euler must have a weight field" )
				continue
			var newm = clone_dict(m)
			if 'point_weights' in newm:
				newm.erase( 'point_weights' )
			valid_ms.append(newm)
			continue
		
		var valid_pws = []
		for pw in m.point_weights:
			if not 'id' in pw:
				rlog( jdata, ReVA_WARNING, "map point_weight must have an id field" )
				continue
			if not 'weight' in pw:
				rlog( jdata, ReVA_WARNING, "map point_weight must have a weight field" )
				continue
			valid_pws.append( clone_dict(pw) )
		var newm = clone_dict(m)
		newm.point_weights = valid_pws
		valid_ms.append(newm)
	
	jdata.content.maps = valid_ms
	
	var a = blank_mapping()
	a.path = jdata.path
	a.original = clone_dict( jdata.content )
	a.content = jdata.content
	a.success = jdata.success
	a.errors = jdata.errors
	return a

static func check_mapping( mapping, data ):
	
	if not mapping.success:
		rlog( mapping, ReVA_INFO, "mapping is not successfully loaded" )
		return
	
	if not mapping.type == ReVA_TYPE_MAPP:
		rlog( mapping, ReVA_INFO, "mapping must be of type " + ReVA_TYPE_MAPP )
		return
	
	if not data.success:
		rlog( mapping, ReVA_INFO, "data is not successfully loaded" )
		return
	
	if not data.type == ReVA_TYPE_ANIM and not data.type == ReVA_TYPE_MODEL:
		rlog( mapping, ReVA_INFO, "data must be of type " + ReVA_TYPE_ANIM + " or " + ReVA_TYPE_MODEL )
		return
	
	if data.type == ReVA_TYPE_ANIM:
		
		var valid_ms = []
		for m in mapping.content.maps:
			if 'gaze' in m:
				if m.gaze.id < 0 or m.gaze.id >= data.content.gaze_count:
					rlog( mapping, ReVA_WARNING, "map ''" + m.bone + "', gaze id " + str(m.gaze.id) + " is out of range" )
					continue
				valid_ms.append( m )
			if 'point_weights' in m:
				var newm = clone_dict( m )
				newm.point_weights = []
				for pw in m.point_weights:
					if pw.id < 0 or pw.id >= data.content.point_count:
						rlog( mapping, ReVA_WARNING, "map '" + m.bone + "',  point id " + str(pw.id) + " is out of range" )
						continue
					newm.point_weights.append( pw )
				valid_ms.append( newm )
		# storage of valid maps
		mapping.content.maps = valid_ms
	
	elif data.type == ReVA_TYPE_MODEL:
		
		if not mapping.content.attachment_bone in data.attachments.dict:
			rlog( mapping, ReVA_WARNING, "attachment_bone " + data.attachment_bone + " is not available in the model" )
			data.attachment_bone = null
		
		var valid_ms = []
		for m in mapping.content.maps:
			if not m.bone in data.attachments.dict:
				rlog( mapping, ReVA_WARNING, "no bone " + m.bone + " in " + data.node.name )
				continue
			valid_ms.append( m )
		# storage of valid maps
		mapping.content.maps = valid_ms

static func load_mapping( p ):
	return validate_mapping( load_json( p ) )

static func apply_mapping( mapping, data ):
	
	if not mapping.success:
		rlog( mapping, ReVA_INFO, "mapping is not successfully loaded" )
		return
	
	if not mapping.type == ReVA_TYPE_MAPP:
		rlog( mapping, ReVA_INFO, "mapping must be of type " + ReVA_TYPE_MAPP )
		return
	
	if not 'success' in data or not 'type' in data or not data.success:
		rlog( mapping, ReVA_INFO, "invalid data" )
		return
	
	if data.type == ReVA_TYPE_MODEL:
		
		for map in mapping.content.maps:
			
			var ab = data.node.get_node( ReVA_BONEATTACHMENT_PREFIX + map.bone )
			if ab == null:
				rlog( mapping, ReVA_INFO, "no AttachmentBone named " + ReVA_BONEATTACHMENT_PREFIX + map.bone + " in " + data.path )
				continue
			ab.lookat_enabled = map.constraint.lookat_enabled
			ab.rot_enabled = map.constraint.rot_enabled
			ab.rot_lock_x = map.constraint.rot_lock[0]
			ab.rot_lock_y = map.constraint.rot_lock[1]
			ab.rot_lock_z = map.constraint.rot_lock[2]
			ab.rot_mult = map.constraint.rot_mult
			ab.trans_enabled = map.constraint.trans_enabled
			ab.trans_lock_x = map.constraint.trans_lock[0]
			ab.trans_lock_y = map.constraint.trans_lock[1]
			ab.trans_lock_z = map.constraint.trans_lock[2]
			ab.trans_mult = map.constraint.trans_mult

### MIXED ###

static func attach_node( model, mapping, node ):
	
	if not model.success or not mapping.success:
		return
	
	if mapping.content.attachment_bone == null:
		rlog( mapping, ReVA_WARNING, "no attachment_bone in mapping" )
		return
	
	if node.get_parent() != null:
		node.get_parent().remove_child( node )
	model.node.get_node( ReVA_BONEATTACHMENT_PREFIX + mapping.content.attachment_bone ).add_child( node )

static func minmax( bounds, v ):
	var vmin = bounds[0]
	var vmax = bounds[1]
	if vmin == null or vmax == null:
		vmin = v
		vmax = v
	else:
		if vmin.x > v.x:
			vmin.x = v.x
		if vmin.y > v.y:
			vmin.y = v.y
		if vmin.z > v.z:
			vmin.z = v.z
		if vmax.x < v.x:
			vmax.x = v.x
		if vmax.y < v.y:
			vmax.y = v.y
		if vmax.z < v.z:
			vmax.z = v.z
	return [vmin,vmax]

static func autocalibrate( model, calibration, animation, timestamp = 0 ):
	
	if not model.success or not calibration.success or not animation.success:
		return
	
	# getting the first animation frame
	var reff = animation_frame( animation, timestamp )
	
	# computing aabb for model & frame timestamp
	var aabb = [null,null]
	for c in model.face_bones:
		var p = c.global_transform.origin
		aabb = minmax( aabb, p )
	var m_aabb = AABB( aabb[0] + (aabb[1] - aabb[0])*0.5, aabb[1] - aabb[0] )
	
	aabb = [null,null]
	for i in range( animation.content.point_count ):
		var p = reff.points[i]
		aabb = minmax( aabb, p )
	var f_aabb = AABB( aabb[0] + (aabb[1] - aabb[0])*0.5, aabb[1] - aabb[0] )
	
	print( "model: ", m_aabb )
	print( "frame: ", f_aabb )

static func identity_correction( c ):
	return c.rotation.x == 0 and c.rotation.y == 0 and c.rotation.z == 0 and c.translation.x == 0 and c.translation.y == 0 and c.translation.z == 0 and c.scale.x == 1 and c.scale.y == 1 and c.scale.z == 1

static func apply_correction( transform, indices, animation ):
	for f in animation.content.frames:
		# averaging the position of points in the frame
		var avrg = Vector3()
		for i in indices:
			avrg += f.points[i]
		avrg /= len(indices)
		for i in indices:
			f.points[i] = avrg + transform.xform( f.points[i] - avrg )
