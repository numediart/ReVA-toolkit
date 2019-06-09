tool

extends Skeleton

export (Vector3) var mask_offset = Vector3()
export (bool) var enable_ik = false setget _enable_ik

var iks = null
var json = null
var tester_pos = null

func _enable_ik( b ):
	enable_ik = b
	for i in get_child_count():
		var c = get_child( i )
		if c.get_class() == "SkeletonIK":
			if enable_ik:
				c.start()
			else:
				c.stop()
	if not enable_ik:
		for i in get_bone_count():
			set_bone_pose( i, Transform() )
		prepare_iks()

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
	iks[ 'lip_lower_left' ] = {
		'bid': find_bone( 'oris07.L' ),
		'ctrl': get_node( "ctrls/lip_lowerL" )
	}
	iks[ 'lip_lower' ] = {
		'bid': find_bone( 'oris02' ),
		'ctrl': get_node( "ctrls/lip_lowerC" )
	}
	iks[ 'lip_lower_right' ] = {
		'bid': find_bone( 'oris07.R' ),
		'ctrl': get_node( "ctrls/lip_lowerR" )
	}
	iks[ 'lip_upper_left' ] = {
		'bid': find_bone( 'oris03.L' ),
		'ctrl': get_node( "ctrls/lip_upperL" )
	}
	iks[ 'lip_upper' ] = {
		'bid': find_bone( 'oris06' ),
		'ctrl': get_node( "ctrls/lip_upperC" )
	}
	iks[ 'lip_upper_right' ] = {
		'bid': find_bone( 'oris03.R' ),
		'ctrl': get_node( "ctrls/lip_upperR" )
	}
#	iks[ 'lid_upper_left' ] = {
#		'bid': find_bone( 'orbicularis03.L' ),
#		'ctrl': get_node( "ctrls/lid_upperL" )
#	}
	iks[ 'brow_left' ] = {
		'bid': find_bone( 'oculi01.L' ),
		'ctrl': get_node( "ctrls/browL" )
	}
	iks[ 'brow_right' ] = {
		'bid': find_bone( 'oculi01.R' ),
		'ctrl': get_node( "ctrls/browR" )
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
	var q2 = Quat()
	var t
	var t2
	
	bid = find_bone( "head" )
	q.set_euler( json.get_pose_euler() * 0.3 )
	t = Transform(q)
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
