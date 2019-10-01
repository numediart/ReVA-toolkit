extends Spatial

var animation = null
var calibration = null
var mask = null
var axis = null

func configure( anim, calib ):
	
	animation = anim
	calibration = calib
	
	if mask != null:
		var p = mask.get_parent()
		p.remove_child( mask )
		p.queue_free()
	
	mask = $mask.duplicate()
	mask.visible = true
	add_child( mask )
	
	for i in range( animation.content.point_count ):
		var p = $pt.duplicate()
		p.visible = true
		p.input_ray_pickable = false
		var mesh = p.get_node("mesh")
		mesh.material_override = mesh.get_surface_material(0).duplicate()
		mask.add_child( p )
	
	axis = $axis.duplicate()
	axis.visible = true
	mask.add_child( axis )
	axis.translation = Vector3(0,0,0)
	
	# getting the first frame
	var frame = animation.content.frames[0]
	mask.translation = frame.pose_translation
	mask.rotation = frame.pose_euler
	for i in range( animation.content.point_count ):
		mask.get_child(i).translation = frame.points[i]

	for g in calibration.content.groups:
		if 'symmetry' in g:
			for subg in g.points:
				for i in subg:
					mask.get_child(i).get_node("mesh").material_override.albedo_color = g.color
		else:
			for i in g.points:
				mask.get_child(i).get_node("mesh").material_override.albedo_color = g.color

func _ready():
	# hiding all template objects
	$mask.visible = false
	$pt.visible = false
	$pt.input_ray_pickable = false
	$group_viz.visible = false
	$axis.visible = false

func visualise( frame, sel_group ):
	
	if mask != null:
		axis.rotation = frame.pose_euler
		for i in range( animation.content.point_count ):
			mask.get_child(i).translation = frame.points[i]
	
	if sel_group != -1:
		$group_viz.clear()
		$group_viz.begin( Mesh.PRIMITIVE_LINES )
		var g = calibration.content.groups[sel_group]
		if 'symmetry' in g:
			for subg in g.points:
				for i in range(1, len(subg) ):
					var p0 = subg[i-1]
					var p1 = subg[i]
					$group_viz.add_vertex( mask.get_child(p0).global_transform.origin )
					$group_viz.add_vertex( mask.get_child(p1).global_transform.origin )
		else:
			for i in range(1, len(g.points) ):
				var p0 = g.points[i-1]
				var p1 = g.points[i]
				$group_viz.add_vertex( mask.get_child(p0).global_transform.origin )
				$group_viz.add_vertex( mask.get_child(p1).global_transform.origin )
		$group_viz.end()
		$group_viz.visible = true
	else:
		$group_viz.visible = false
