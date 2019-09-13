tool

extends OSCreceiver

export (float, 0, 4) var scale_factor = 1
export (float, 0, 4) var point_size = 0.1 setget _point_size
export (Transform) var correction = Transform()

func _point_size(f):
	point_size = f
	apply_point_size()

var gaze0_index = 0
var gaze0_offset = Vector3( 0,1,2 )
var gaze0 = Vector3()

var gaze1_index = 3
var gaze1_offset = Vector3( 0,1,2 )
var gaze1 = Vector3()

var pupille_left = [39,40,41,42,43,44]
var pupille_right = [45,46,47,48,49,50]

var pose_translation_index = 6
var pose_translation_offset = Vector3( 0,1,2 )
var pose_translation = Vector3()

var pose_rotation_index = 9
var pose_rotation_offset = Vector3( 0,1,2 )
var pose_rotation = Vector3()

var position_num = 67
var positions_index = 148
var positions_offset = Vector3( 0,68,136 )
var positions = Array()

var scale_index = 352
var scale = 1

var center = null
var axis = null
var gaze0_axis = null
var gaze1_axis = null
var points = null

func apply_point_size():
	
	var obj = null
	obj = get_node( "../point" )
	if obj != null:
		obj.mesh.radius = point_size
		obj.mesh.height = point_size * 2
	obj = get_node( "../point/yaxis" )
	if obj != null:
		obj.mesh.size.y = point_size * 4
		obj.translation.y = point_size * 2
	obj = get_node( "../point/zaxis" )
	if obj != null:
		obj.mesh.size.z = point_size * 4
		obj.translation.z = -point_size * 2

func prepare():
	
	if center == null:
		center = get_node( "../center" )
		center.translation = Vector3()
		center.rotation = Vector3()
		while center.get_child_count() > 0:
			center.remove_child( center.get_child(0) )
		
	if center != null and points == null:
		var tmpl = get_node( "../point" )
		if tmpl != null:
			points = Array()
			var third = ceil( position_num / 3.0 )
			for i in range(0,position_num):
				var d = tmpl.duplicate()
				d.visible = true
				var m = d.material_override.duplicate()
				if i <= third:
					m.albedo_color = Color( 1, i / third, 0, 1 )
				elif i <= third * 2:
					m.albedo_color = Color( 1 - ((i-third) / third), 1, 0, 1 )
				else:
					m.albedo_color = Color( 0, 1, ((i-third*2) / third), 1 )
				d.material_override = m
				center.add_child( d )
				points.append( d )
	
	if center != null and axis == null:
		var tmpl = get_node( "../axis" )
		if tmpl != null:
			axis = tmpl.duplicate()
			axis.visible = true
			center.add_child( axis )
			gaze0_axis = tmpl.duplicate()
			gaze0_axis.visible = true
			center.add_child( gaze0_axis )
			gaze1_axis = tmpl.duplicate()
			gaze1_axis.visible = true
			center.add_child( gaze1_axis )
	
	if positions.size() != position_num:
		for i in range(0,position_num):
			positions.append( Vector3() )
	
	if center == null or points == null or axis == null:
		return false
	return true

func _ready():
	
	prepare()
	start()

func retrieve_openface_vector( msg, index, offset ):
	return Vector3( msg.arg( index + offset.x ), msg.arg( index + offset.y ), msg.arg( index + offset.z ) )

func parse_openface( msg ):
	
	if not prepare():
		return
	
	gaze0 = retrieve_openface_vector( msg, gaze0_index, gaze0_offset )
	gaze1 = retrieve_openface_vector( msg, gaze1_index, gaze1_offset )
	pose_translation = correction.xform( retrieve_openface_vector( msg, pose_translation_index, pose_translation_offset ) )
	pose_rotation = retrieve_openface_vector( msg, pose_rotation_index, pose_rotation_offset )
	scale = msg.arg( scale_index )
	for i in range( 0, position_num ):
		positions[i] = correction.xform( retrieve_openface_vector( msg, positions_index+i, positions_offset ) )

func update_center():
	
	if center == null or points == null or axis == null:
		return false
		
#	axis.translation = pose_translation
	axis.rotation_degrees = pose_rotation
	
	var gpos = Vector3()
	for i in pupille_left:
		gpos += positions[i]
	gpos /= len(pupille_left)
	gaze0_axis.translation = gpos * scale_factor
	gaze0_axis.rotation_degrees = gaze0
	
	gpos = Vector3()
	for i in pupille_right:
		gpos += positions[i]
	gpos /= len(pupille_right)
	gaze1_axis.translation = gpos * scale_factor
	gaze1_axis.rotation_degrees = gaze1
	
	for i in range(0,position_num):
		points[i].translation = positions[i] * scale_factor
		if points[i].translation.length_squared() != 0:
			points[i].look_at( points[i].translation * 2, Vector3(0,1,0) )
		
func _process(delta):
	
	while( has_waiting_messages() ):
		var msg = get_next_message()
		if msg.address() == "/openface":
			parse_openface( msg )
	
	update_center()
