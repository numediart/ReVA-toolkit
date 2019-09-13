tool

extends Skeleton

export(Vector3) var head_rotation = Vector3()
export(Vector3) var eyeL_rotation = Vector3()
export(Vector3) var eyeR_rotation = Vector3()

var bone_map = {}

func _ready():
	
	for i in get_bone_count():
		var n = get_bone_name(i)
		bone_map[n] = i

func rotate_bone( bname, eulers ):
	
	if not bname in bone_map:
		return
	var q = Quat()
	q.set_euler( eulers )
	set_bone_pose( bone_map[bname], Transform( Basis(q), Vector3() ) )
	

func _process(delta):
	
	rotate_bone( 'head', head_rotation )
	rotate_bone( 'eyeL', eyeL_rotation )
	rotate_bone( 'eyeR', eyeR_rotation )
