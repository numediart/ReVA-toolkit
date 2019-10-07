#tool

extends Skeleton

export(bool) var debug = false
export(bool) var reload = false
export(bool) var update_config = false setget retrieve_configurations

export(float,-3.1416,3.1416) var lid_rotX = 0
export(Vector3) var lip_trans = Vector3()

var V3UNIT = Vector3(1,1,1)
var V3INVERTX = Vector3(-1,1,1)
var V3INVERTY = Vector3(1,-1,1)
# warning-ignore:unused_class_variable
var V3INVERTZ = Vector3(1,1,-1)
var V3NOX = Vector3(0,1,1)
# warning-ignore:unused_class_variable
var V3NOY = Vector3(1,0,1)
# warning-ignore:unused_class_variable
var V3NOZ = Vector3(1,1,0)

var avatar_bones = null
var avatar_map = null
var elapsed_time = 0

func verify_configuration( d ):
	
	var rot_locked = d['rot_lock'][0] or d['rot_lock'][1] or d['rot_lock'][2]
	var trans_locked = d['trans_lock'][0] or d['trans_lock'][1] or d['trans_lock'][2]
	
	if d['rot_enabled'] and d['rot_lock'][0] and d['rot_lock'][1] and d['rot_lock'][2]:
		d['rot_enabled'] = false
		print( "disabling rotations for " + d['name'] )
	elif d['rot_enabled'] and ( rot_locked or d['rot_mult'] != V3UNIT ):
		d['rot_postprocessing'] = true
#			print( "rotations postprocessing enabled for " + d['name'] )
	
	if d['trans_enabled'] and d['trans_lock'][0] and d['trans_lock'][1] and d['trans_lock'][2]:
		d['trans_enabled'] = false
		print( "disabling translations for " + d['name'] )
	elif d['trans_enabled'] and ( trans_locked or d['trans_mult'] != V3UNIT ):
		d['trans_postprocessing'] = true

func retrieve_configurations( b = true ):
	
	update_config = false
	
	if not b:
		return
	
	for d in avatar_bones:
		
		var c = d['attach']
		
		d['lookat_enabled'] = c.lookat_enabled
		d['rot_enabled'] = c.rot_enabled
		d['rot_lock'] = [ c.rot_lock_x, c.rot_lock_y, c.rot_lock_z ]
		d['rot_mult'] = c.rot_mult
		d['rot_postprocessing'] = false
		d['trans_enabled'] = c.trans_enabled
		d['trans_lock'] = [ c.trans_lock_x, c.trans_lock_y, c.trans_lock_z ]
		d['trans_mult'] = c.rot_mult
		d['trans_postprocessing'] = false
		d['front_y'] = c.front_y
		
		verify_configuration(d)

func register_in_hierarchy( bone ):
	
	var UID = bone['UID']
	var pid = bone['pid']
	if pid < 0:
		return
	
	while pid >= 0:
		for ab in avatar_bones:
			if ab['bid'] == pid:
				ab['children'].append( UID )
				break
		pid = get_bone_parent( pid )
	
	pass

func init_avatar():
	
	var bone_by_name = {}
	for i in get_bone_count():
		bone_by_name[ get_bone_name(i) ] = i
	
	avatar_bones = []
	avatar_map = {}
	
	for c in get_children():
		
		if c.is_class("BoneAttachment") and c.active:
			
			var bid = bone_by_name[c.bone_name]
			
			# resting bone pose (avoiding storing current transform)
			set_bone_pose( bid, Transform() )
			
			var parentid = get_bone_parent( bone_by_name[c.bone_name] )
			
			var pt = Transform()
			if ( parentid != -1 ):
				pt = get_bone_global_pose( parentid )
			else:
				parentid = null
			
			var t = get_bone_global_pose( bone_by_name[c.bone_name] )
			var q = Quat()
			q.set_euler( t.basis.get_euler() )
			
			var d = {
				'UID': len(avatar_bones),
				'name': c.bone_name,
				'attach': c,
				# parent info
				'pid': parentid,
				'parent_pose_inverse': pt.inverse(),
				# bone info
				'bid': bone_by_name[c.bone_name],
				'pose': t,
				'pose_inverse': t.inverse(),
				'pose_rot': Transform( q ),
				'origin': t.origin,
				'scale': t.basis.get_scale(),
				'rest_inverse': get_bone_rest( bone_by_name[c.bone_name] ).inverse(),
				# controls
				'lookat_enabled': c.lookat_enabled,
				'rot_enabled': c.rot_enabled,
				'rot_lock': [ c.rot_lock_x, c.rot_lock_y, c.rot_lock_z ],
				'rot_mult': c.rot_mult,
				'rot_postprocessing': false,
				'trans_enabled': c.trans_enabled,
				'trans_lock': [ c.trans_lock_x, c.trans_lock_y, c.trans_lock_z ],
				'trans_mult': c.rot_mult,
				'trans_postprocessing': false,
				'front_y': c.front_y,
				# hierarchy related
				'correction': Transform(),
				'child_count': 0,
				'children': []
			}
			
			register_in_hierarchy( d )
			avatar_bones.append( d )
			if c.bone_name in avatar_map:
				print( "joan.gd: WARNING! there is already a key for ", c.bone_name, " in avatar_map!!!" )
			avatar_map[ c.bone_name ] = d
	
	for a in avatar_bones:
		a['child_count'] = len(a['children'])
	
	retrieve_configurations()

func _ready():
	# reseting skeleton
	for i in get_bone_count():
		set_bone_pose( i, Transform() )
	pass

func bone_update_children( avatar_bone, t ):
	
	if avatar_bone['child_count'] > 0:
		
		var T = avatar_bone['origin']
		
		t = avatar_bone['pose_inverse'] * t
		t.origin = Vector3()
		
		# heavy black magic transformation of origin...
		t.basis = Basis( t.basis.x, t.basis.z, t.basis.y )
		t.basis *= Basis(Vector3(1,0,0),Vector3(0,1,0),Vector3(0,0,-1))
		var euls = t.basis.get_euler()
		euls.x += PI
		euls.y += PI
		euls.z += PI
		t.basis = Basis( euls )
		
#		get_node( 'debug_01' ).translation = t.xform(Vector3(5,0,0))
#		get_node( 'debug_02' ).translation = t.xform(Vector3(0,5,0))
#		get_node( 'debug_03' ).translation = t.xform(Vector3(0,0,5))
		
		t.origin += t.xform( -T ) + T
		for index in avatar_bone['children']:
			avatar_bones[index]['correction'] *= t

func bone_look_at( avatar_bone, global_pos ):
	
	if not avatar_bone['lookat_enabled'] or not avatar_bone['rot_enabled']:
		return
	
	# working in global space
	var i = avatar_bone['bid']
	var T = avatar_bone['origin']
	var S = avatar_bone['scale']
	
	# expressing the global position in object space
	var local_pos = to_local( global_pos )
	# global pos to object space
	var corrected_pos = avatar_bone['correction'].xform( local_pos )
	
	if avatar_bone['rot_postprocessing']:
		# let's create a position that correspond to a 0 rotation
		var diff = corrected_pos - T
		var front = Vector3()
		if avatar_bone['front_y']:
			front = avatar_bone['pose'].basis.y * diff.length()
		else:
			front = avatar_bone['pose'].basis.z * -diff.length()
		if avatar_bone['rot_lock'][0]:
			diff.x = front.x
		if avatar_bone['rot_lock'][1]:
			diff.y = front.y
		if avatar_bone['rot_lock'][2]:
			diff.z = front.z
		corrected_pos = T + diff * avatar_bone['rot_mult']
	
	var b = Basis()
	
	var x_vec = Vector3(1,0,0)
	var y_vec = Vector3(0,1,0)
	var z_vec = Vector3(0,0,1)
	
	if avatar_bone['front_y']:
		# FORWARD is Y axis!
		# up vector:
		z_vec = avatar_bone['pose_rot'].xform( z_vec )
		# delta of position
		y_vec = corrected_pos - T
		y_vec = y_vec.normalized()
		# first perp vector
		x_vec = y_vec.cross( z_vec )
		x_vec = x_vec.normalized()
		# and reprocessing the up vector
		z_vec = x_vec.cross( y_vec )
	else:
		# FORWARD is -Z axis!
		y_vec = avatar_bone['pose_rot'].xform( y_vec )
		z_vec = T - corrected_pos
		z_vec = z_vec.normalized()
		x_vec = y_vec.cross( z_vec )
		x_vec = x_vec.normalized()
		y_vec = z_vec.cross( x_vec )
	
	# new basis
	b = Basis( x_vec, y_vec, z_vec ).scaled( S )
	
	# creation of the obect space transfrom
	var t = avatar_bone['rest_inverse'] * avatar_bone['parent_pose_inverse'] * Transform( b, T )
	# turning global transform to parent space without rest
	set_bone_pose( i, t )
	
	# applying correction in all children:
	bone_update_children( avatar_bone, t )

func bone_rotate( avatar_bone, eulers, alpha = 1 ):
	
	if not avatar_bone['rot_enabled']:
		return
	
	var q = Quat()
	q.set_euler( eulers )
	var b = avatar_bone['correction'].basis * Basis( q )
	eulers = b.get_euler()
	
	var i = avatar_bone['bid']
	
	if avatar_bone['rot_postprocessing']:
		if avatar_bone['rot_lock'][0]:
			eulers.x = 0
		if avatar_bone['rot_lock'][1]:
			eulers.y = 0
		if avatar_bone['rot_lock'][2]:
			eulers.z = 0
		eulers *= avatar_bone['rot_mult']
	
	q = Quat()
	if alpha != 1:
		var q_full = Quat()
		q_full.set_euler( eulers )
		q = q.slerp( q_full, alpha )
	else:
		q.set_euler( eulers )
	var t = avatar_bone['rest_inverse'] * avatar_bone['parent_pose_inverse'] * Transform( Basis( q ), Vector3() )
	t.origin = Vector3()
	
	set_bone_pose( i, Transform( Basis( q ), Vector3() ) )

func bone_translate( avatar_bone, trans, alpha = 1 ):
	
	if not avatar_bone['trans_enabled']:
		return
	
	if avatar_bone['child_count'] > 0:
		print( 'bone ' + avatar_bone['name'] + ' has children, translations are disabled' )
		return
	
	if avatar_bone['trans_postprocessing']:
		if avatar_bone['trans_lock'][0]:
			trans.x = 0
		if avatar_bone['trans_lock'][1]:
			trans.y = 0
		if avatar_bone['trans_lock'][2]:
			trans.z = 0
		trans *= avatar_bone['trans_mult']
	
	trans = avatar_bone['correction'].xform( trans )
	
	get_node( "debug_local" ).translation = avatar_bone['origin'] + trans
	
	trans *= alpha
	trans = ( Transform( avatar_bone['rest_inverse'].basis, Vector3() ) * Transform( avatar_bone['parent_pose_inverse'].basis, Vector3() ) ).xform( trans )
	set_bone_pose( avatar_bone['bid'], Transform( Basis(), trans ) )

func _process(delta):
	
	if reload or avatar_bones == null:
		init_avatar()
		reload = false
	
	for ab in avatar_bones:
		ab['correction'] = Transform()
		set_bone_pose( ab['bid'], ab['correction'] )
	
	if not debug:
		return
	
	elapsed_time += delta
	
	if get_node( "../collarbones" ).visible:
		bone_look_at( avatar_map['collarboneL'], get_node( "../collarbones/left" ).global_transform.origin )
		bone_look_at( avatar_map['collarboneR'], get_node( "../collarbones/right" ).global_transform.origin )

	if get_node( "../head" ).visible:
		bone_look_at( avatar_map['head'], get_node( "../head" ).global_transform.origin )

	if get_node( "../jaw" ).visible:
		bone_look_at( avatar_map['jaw'], get_node( "../jaw" ).global_transform.origin )

	if get_node( "../gaze" ).visible:
		bone_look_at( avatar_map['eyeL'], get_node( "../gaze/left" ).global_transform.origin )
		bone_look_at( avatar_map['eyeR'], get_node( "../gaze/right" ).global_transform.origin )

#	# lids
#	bone_rotate( avatar_map['upper_lidL'], Vector3( lid_rotX,0,0 ) )
#	bone_rotate( avatar_map['upper_lidR'], Vector3( lid_rotX,0,0 ) )
#	bone_rotate( avatar_map['lower_lidL'], Vector3( -lid_rotX,0,0 ) )
#	bone_rotate( avatar_map['lower_lidR'], Vector3( -lid_rotX,0,0 ) )
#
#	#lips
#	var ilip_trans = lip_trans * V3INVERTY
#
#	bone_translate( avatar_map['nostrilL'], lip_trans * 0.65 )
#	bone_translate( avatar_map['muscle_lip01L'], lip_trans * 1.3 )
#	bone_translate( avatar_map['muscle_lip02L'], lip_trans * 0.9 )
#
#	bone_translate( avatar_map['nostrilR'], ilip_trans * V3INVERTX * 0.65 )
#	bone_translate( avatar_map['muscle_lip01R'], ilip_trans * V3INVERTX * 1.3 )
#	bone_translate( avatar_map['muscle_lip02R'], ilip_trans * V3INVERTX * 0.9 )
#
#	bone_translate( avatar_map['upper_lip'], lip_trans * V3NOX * V3NOX )
#	bone_translate( avatar_map['upper_lipL'], lip_trans * V3NOX )
#	bone_translate( avatar_map['upper_lipR'], lip_trans * V3NOX * V3INVERTX )
#
#	bone_translate( avatar_map['lower_lip'], ilip_trans * V3NOX )
#	bone_translate( avatar_map['lower_lipL'], ilip_trans * V3NOX )
#	bone_translate( avatar_map['lower_lipR'], ilip_trans * V3NOX * V3INVERTX )

############# SERIALISATION #############

func serialise():
	
	var out = []
	
	for a in avatar_bones:
		var cp = a.duplicate()
		cp['attach'] = cp['attach'].get_name()
		cp['correction'] = Transform()
		
		out.append( cp )
		
	return out

func deserialise_vec3( s ):
	
	s = s.replace('(','')
	s = s.replace(')','')
	var fs = s.split(',')
	if len(fs) != 3:
		return Vector3()
	return Vector3( float(fs[0]), float(fs[1]), float(fs[2]) )

func deserialise_quat( s ):
	
	s = s.replace('(','')
	s = s.replace(')','')
	var fs = s.split(',')
	if len(fs) != 4:
		return Quat()
	return Quat( float(fs[0]), float(fs[1]), float(fs[2]), float(fs[3]) )

func deserialise_transform( s ):
	
	s = s.replace('(','')
	s = s.replace(')','')
	var parts = s.split(' - ')
	if len(parts) != 2:
		return Transform()
	var basis = parts[0].split(',')
	var origin = parts[1].split(',')
	if len(basis) != 9 or len(origin) != 3:
		return Transform()
	return Transform( 
		Vector3( float(basis[0]), float(basis[1]), float(basis[2]) ),
		Vector3( float(basis[3]), float(basis[4]), float(basis[5]) ),
		Vector3( float(basis[6]), float(basis[7]), float(basis[8]) ),
		Vector3( float(origin[0]), float(origin[1]), float(origin[2]) ))

func deserialise( data ):
	
	for a in data:
		
		if not a['name'] in avatar_map:
			print( 'no key ' + a['name'] + ' in avatar_map' )
			continue
		
		var d = avatar_map[a['name']]
		d['lookat_enabled'] = a['lookat_enabled']
		d['rot_enabled'] = a['rot_enabled']
		d['rot_lock'] = a['rot_lock']
		d['rot_mult'] = deserialise_vec3( a['rot_mult'] )
		d['rot_postprocessing'] = a['rot_postprocessing']
		d['trans_enabled'] = a['trans_enabled']
		d['trans_lock'] = a['trans_lock']
		d['trans_mult'] = deserialise_vec3( a['trans_mult'] )
		d['trans_postprocessing'] = a['trans_postprocessing']
		d['front_y'] = a['front_y']
		
		verify_configuration(d)
