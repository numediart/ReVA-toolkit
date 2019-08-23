tool

extends Skeleton

export(bool) var reload = false
export(bool) var update_config = false setget _update_config

var avatar_bones = null
var avatar_map = null
var elapsed_time = 0

func _update_config( b ):
	update_config = false
	if not b:
		return
	for c in get_children():
		if c.is_class("BoneAttachment") and c.active:
			var am = avatar_map[ c.bone_name ]
			am['rot_enabled'] = c.rot_enabled
			am['rot_lock'] = [ c.rot_lock_x, c.rot_lock_y, c.rot_lock_z ]
			am['rot_mult'] = c.rot_mult
			am['trans_enabled'] = c.trans_enabled
			am['trans_lock'] = [ c.trans_lock_x, c.trans_lock_y, c.trans_lock_z ]
			am['trans_mult'] = c.rot_mult

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
				'pose_rot': Transform( q ),
				'origin': t.origin,
				'scale': t.basis.get_scale(),
				'rest_inverse': get_bone_rest( bone_by_name[c.bone_name] ).inverse(),
				# controls
				'rot_enabled': c.rot_enabled,
				'rot_lock': [ c.rot_lock_x, c.rot_lock_y, c.rot_lock_z ],
				'rot_mult': c.rot_mult,
				'trans_enabled': c.trans_enabled,
				'trans_lock': [ c.trans_lock_x, c.trans_lock_y, c.trans_lock_z ],
				'trans_mult': c.rot_mult,
				'front_y': c.front_y,
				# hierarchy related
				'correction': Transform(),
				'child_count': 0,
				'children': []
			}
			
			print( d['name'], ' > ', d['origin'] )
			
			register_in_hierarchy( d )
			avatar_bones.append( d )
			if c.bone_name in avatar_map:
				print( "joan.gd: WARNING! there is already a key for ", c.bone_name, " in avatar_map!!!" )
			avatar_map[ c.bone_name ] = d
	
	for a in avatar_bones:
		a['child_count'] = len(a['children'])

func _ready():
	init_avatar()

func look_at( avatar_bone, global_pos ):
	
	if not avatar_bone['rot_enabled']:
		return
	
	# working in global space
	var i = avatar_bone['bid']
	var T = avatar_bone['origin']
	var S = avatar_bone['scale']
	
	# expressing the global position in object space
	var local_pos = to_local( global_pos )
	# global pos to object space
	var corrected_pos = avatar_bone['correction'].xform( local_pos )
	
	
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
	if avatar_bone['child_count'] > 0:
		if avatar_bone['front_y']:
			y_vec = avatar_bone['pose_rot'].xform( y_vec )
			z_vec = T - corrected_pos
			z_vec = z_vec.normalized()
			x_vec = y_vec.cross( z_vec )
			x_vec = x_vec.normalized()
			y_vec = x_vec.cross( z_vec )
		t = Transform( Basis( x_vec, y_vec, z_vec ), Vector3() )
		get_node( 'debug_01' ).translation = t.xform(Vector3(5,0,0))
		get_node( 'debug_02' ).translation = t.xform(Vector3(0,5,0))
		get_node( 'debug_03' ).translation = t.xform(Vector3(0,0,5))
		t.origin = t.xform( T ) - T
		for index in avatar_bone['children']:
			avatar_bones[index]['correction'] *= t
			pass

func _process(delta):
	
	if reload or avatar_bones == null:
		init_avatar()
		reload = false
	
	for ab in avatar_bones:
		ab['correction'] = Transform()
	
	elapsed_time += delta
	
#	look_at( avatar_map['head'], get_node( "../head" ).global_transform.origin )
#	look_at( avatar_map['jaw'], get_node( "../head" ).global_transform.origin )
#	look_at( avatar_map['chin'], get_node( "../head" ).global_transform.origin )
	look_at( avatar_map['eyeL'], get_node( "../gaze" ).global_transform.origin )
	look_at( avatar_map['eyeR'], get_node( "../gaze" ).global_transform.origin )