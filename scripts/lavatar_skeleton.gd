tool

extends Skeleton

export (bool) var reload = false setget _reload

func _reload(b):
	tracked_bones = null

var tracked_bone_names = [ 'head', 'jaw', 'eye.L', 'eye.R' ]
var tracked_bones = null
var json_server = null

func prepare():
	
	json_server = get_node( '../json' )
	
	tracked_bones = []
	for n in tracked_bone_names:
		var id = find_bone( n )
		var tb = {
			'id': id,
			'name': n,
			'glob': Transform( get_bone_global_pose( id ) ),
			'ctrl': null
		}
		match( n ):
			'head':
#				tb['ctrl'] = get_node('ctrl_head')
#				tb['ctrl'].rotation = tb['glob'].basis.get_euler()
				pass
		tracked_bones.append( tb )
	
	while( $dots.get_child_count() > 0 ):
		 $dots.remove_child( $dots.get_child(0) )
	
	# debug bones
	for tb in tracked_bones:
		var d = $dot_tmpl.duplicate()
		d.visible = true
		$dots.add_child( d )

func upadte_tracked_bones():
	
	var i = 0
	for tb in tracked_bones:
		
		match( tb['name'] ):
			'head':
				var pose = get_bone_pose( tb['id'] )
				var rot = json_server.get_pose_euler()
				var q = Quat()
				q.set_euler( rot )
				var t = tb['glob'] * Transform( q )
#				tb['ctrl'].rotation = t.basis.get_euler()
		
		$dots.get_child( i ).rotation = tb['glob'].basis.get_euler()
		$dots.get_child( i ).translation = tb['glob'].origin
		i += 1

func _ready():
	
	for i in range( get_bone_count() ):
		print( str(i) + ' : ' + get_bone_name( i ) )
	
	pass # Replace with function body.

func _process(delta):
	
	if tracked_bones == null:
		prepare()
	else:
		upadte_tracked_bones()
	pass # Replace with function body.
	