tool

extends Skeleton

export (Vector3) var mask_offset = Vector3()
export (bool) var enable_ik = false setget _enable_ik
export (String) var disable_ik = ''

enum POS_TYPE {
	DEFAULT,
	DELTA,
	GLOBAL
}

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
		'ctrl': get_node( "ctrls/lip_corner_left" ),
		'type': POS_TYPE.DELTA
	}
	iks[ 'lip_corner_right' ] = {
		'bid': find_bone( 'levator05.R' ),
		'ctrl': get_node( "ctrls/lip_corner_right" ),
		'type': POS_TYPE.DELTA
	}
	iks[ 'lip_lower_left' ] = {
		'bid': find_bone( 'oris07.L' ),
		'ctrl': get_node( "ctrls/lip_lowerL" ),
		'type': POS_TYPE.DELTA
	}
	iks[ 'lip_lower' ] = {
		'bid': find_bone( 'oris02' ),
		'ctrl': get_node( "ctrls/lip_lowerC" ),
		'type': POS_TYPE.DELTA
	}
	iks[ 'lip_lower_right' ] = {
		'bid': find_bone( 'oris07.R' ),
		'ctrl': get_node( "ctrls/lip_lowerR" ),
		'type': POS_TYPE.DELTA
	}
	iks[ 'lip_upper_left' ] = {
		'bid': find_bone( 'oris03.L' ),
		'ctrl': get_node( "ctrls/lip_upperL" ),
		'type': POS_TYPE.DELTA
	}
	iks[ 'lip_upper_right' ] = {
		'bid': find_bone( 'oris03.R' ),
		'ctrl': get_node( "ctrls/lip_upperR" ),
		'type': POS_TYPE.DELTA
	}
	iks[ 'lip_upper' ] = {
		'bid': find_bone( 'oris05' ),
		'ctrl': get_node( "ctrls/lip_upperC" ),
		'type': POS_TYPE.DELTA
	}
	iks[ 'brow_left' ] = {
		'bid': find_bone( 'oculi01.L' ),
		'ctrl': get_node( "ctrls/browL" ),
		'type': POS_TYPE.DELTA
	}
	iks[ 'brow_right' ] = {
		'bid': find_bone( 'oculi01.R' ),
		'ctrl': get_node( "ctrls/browR" ),
		'type': POS_TYPE.DELTA
	}
	iks[ 'lid_left_upper' ] = {
		'bid': find_bone( 'orbicularis03.L.end' ),
		'ctrl': get_node( "ctrls/lid_upperL" ),
		'type': POS_TYPE.GLOBAL
	}
	iks[ 'lid_left_lower' ] = {
		'bid': find_bone( 'orbicularis04.L.end' ),
		'ctrl': get_node( "ctrls/lid_lowerL" ),
		'type': POS_TYPE.GLOBAL
	}
	iks[ 'lid_right_upper' ] = {
		'bid': find_bone( 'orbicularis03.R.end' ),
		'ctrl': get_node( "ctrls/lid_upperR" ),
		'type': POS_TYPE.GLOBAL
	}
	iks[ 'lid_right_lower' ] = {
		'bid': find_bone( 'orbicularis04.R.end' ),
		'ctrl': get_node( "ctrls/lid_lowerR" ),
		'type': POS_TYPE.GLOBAL
	}
	iks[ 'eye_left' ] = {
		'bid': find_bone( 'eye.L' ),
		'ctrl': get_node( "ctrls/eyeL" ),
		'type': POS_TYPE.DEFAULT
	}
	iks[ 'eye_right' ] = {
		'bid': find_bone( 'eye.R' ),
		'ctrl': get_node( "ctrls/eyeR" ),
		'type': POS_TYPE.DEFAULT
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
	
	q.set_euler( Vector3(0,PI,0) )
	t = headt * iks[ 'eye_left' ]['bone_glob'] # * Transform(q)
	v = t.origin
	iks[ 'eye_left' ]['ctrl'].global_transform = Transform( json.get_gaze(0) * q )
	iks[ 'eye_left' ]['ctrl'].global_transform.origin = v
	
	t = headt * iks[ 'eye_right' ]['bone_glob'] # * Transform(q)
	v = t.origin
	iks[ 'eye_right' ]['ctrl'].global_transform = Transform( json.get_gaze(1) * q )
	iks[ 'eye_right' ]['ctrl'].global_transform.origin = v
	
#	bid = find_bone( "eye.R" )
#	q.set_euler( json.get_gaze(0) )
#	set_bone_pose( bid, Transform(q) )
#	bid = find_bone( "eye.L" )
#	q.set_euler( json.get_gaze(1) )
#	set_bone_pose( bid, Transform(q) )
	
#	var diff = get_node( "../tester" ).global_transform.origin - tester_pos
	
	for k in iks:
		var ik = iks[k]
		t = Transform()
		match ik['type']:
			POS_TYPE.DELTA:
				t.origin = json.get_delta( k )
				t = t * ik['glob_rot'].inverse()
				ik['ctrl'].transform = headt * ik['bone_glob']
				ik['ctrl'].translation += t.origin
			POS_TYPE.GLOBAL:
				ik['ctrl'].global_transform.origin = json.get_global( k )
