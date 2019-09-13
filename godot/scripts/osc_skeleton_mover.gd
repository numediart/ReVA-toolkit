tool

extends Skeleton

var current_quat = Quat()
var target_quat = Quat()

func _ready():
	pass

func received( msg ):
	print( msg )

func _process(delta):
	var head_id = find_bone( "head" ) 
	var head_transform = get_bone_transform( head_id )
	current_quat = current_quat.slerp( target_quat,1.0 / 12 )
	var t = head_transform.interpolate_with( Transform( current_quat ), 1 )
	set_bone_pose( head_id, t )


func _on_oscin_osc_message_received( msg ):
#	if (msg.address() == )
	if msg.address() == "/4dface/head":
		target_quat.set_euler( Vector3( msg.arg(0), msg.arg(1), msg.arg(2) ) )
	else:
		print( msg.address() )
