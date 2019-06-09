tool

extends Skeleton

export (Vector3) var mask_offset = Vector3()

var iks = null
var json = null
var tester_pos = null

func prepare_iks():
	
	iks = {}
	
	iks[ 'lip_corner_left' ] = {
		'bid': find_bone( 'levator05.L' ),
		'ctrl': get_node( "ctrls/lip_corner_left" )
	}
	iks[ 'lip_corner_right' ] = {
		'bid': find_bone( 'levator05.R' ),
		'ctrl': get_node( "ctrls/lip_corner_right" )
	}
	iks[ 'lip_lowerL' ] = {
		'bid': find_bone( 'oris07.L' ),
		'ctrl': get_node( "ctrls/lip_lowerL" )
	}
	iks[ 'lip_lowerC' ] = {
		'bid': find_bone( 'oris01' ),
		'ctrl': get_node( "ctrls/lip_lowerC" )
	}
	iks[ 'lip_lowerR' ] = {
		'bid': find_bone( 'oris07.R' ),
		'ctrl': get_node( "ctrls/lip_lowerR" )
	}
	iks[ 'lip_upperL' ] = {
		'bid': find_bone( 'oris03.L' ),
		'ctrl': get_node( "ctrls/lip_upperL" )
	}
	iks[ 'lip_upperC' ] = {
		'bid': find_bone( 'oris05' ),
		'ctrl': get_node( "ctrls/lip_upperC" )
	}
	iks[ 'lip_upperR' ] = {
		'bid': find_bone( 'oris03.R' ),
		'ctrl': get_node( "ctrls/lip_upperR" )
	}

	var headt = get_bone_global_pose( find_bone( 'head' ) )
	var headti = headt.affine_inverse()
	for k in iks:
		set_bone_pose( iks[ k ]['bid'], Transform() )
		iks[ k ]['pid'] = get_bone_parent( iks[ k ]['bid'] )
		iks[ k ]['bone_glob'] = headti * get_bone_global_pose( iks[ k ]['bid'] )
		var q = Quat()
		q.set_euler( iks[ k ]['bone_glob'].basis.get_euler() )
		iks[ k ]['glob_rot'] = Transform( q )
		iks[ k ]['ctrl'].transform = headt * iks[ k ]['bone_glob']
	
	tester_pos = get_node( "../tester" ).global_transform.origin

func _ready():
	pass # Replace with function body.

func _process(delta):
	
	if iks == null:
		prepare_iks()
	
	if json == null:
		json = get_node( "../json" )
	
	var bid
	var pid
	var v
	var q = Quat()
	var t
	var t2
	
	bid = find_bone( "head" )
	q.set_euler( json.get_pose_euler() )
	t = Transform(q)
	pid = get_bone_parent( bid )
	set_bone_pose( bid, t )
	var headt = get_bone_global_pose( bid )
	var headti = headt.affine_inverse()
	
	# moving the mask in front of the face
	t = get_bone_global_pose( bid )
	json.translation = t.xform( mask_offset )
	
	bid = find_bone( "eye.R" )
	q.set_euler( json.get_gaze(0) )
	set_bone_pose( bid, Transform(q) )
	
	bid = find_bone( "eye.L" )
	q.set_euler( json.get_gaze(1) )
	set_bone_pose( bid, Transform(q) )
	
	var diff = get_node( "../tester" ).global_transform.origin - tester_pos
	
	for k in iks:
		var ik = iks[k]
		t = Transform()
		t.origin = json.get_delta( k )
		t = t * ik['glob_rot'].inverse()
		ik['ctrl'].transform = headt * ik['bone_glob']
		ik['ctrl'].translation += t.origin
		# ctrl location is expressed in skeleton space
		# we need to convert it to local
		v = ik['ctrl'].translation
#		t.origin -= get_bone_transform( ik['pid'] ).origin
#		t = t * get_bone_rest( ik['bid'] ).inverse()
#		t.origin = get_bone_rest( ik['bid'] ).xform( t.origin )
		t = t * headti * ik['bone_glob'].inverse()
#		set_bone_pose( iks[ k ]['bid'], t )
	
#	bid = find_bone( 'levator05.L' )
#	pid = get_bone_parent( bid )
#	q.set_euler( get_bone_global_pose( pid ).basis.get_euler() )
#	t = Transform(q)
#	t2 = Transform()
#	t2.origin = diff
#	t2 = t2 * t.inverse()
#	$ctrls/lip_corner_left.translation = get_bone_global_pose( bid ).origin + t2.origin
