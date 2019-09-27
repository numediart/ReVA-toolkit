extends Spatial
const ReVA = preload( "res://scripts/reva/ReVA.gd" )
const mod_path = "res://models/joan.tscn"
#const apath = "../json/anim/smile.json"
const ani_path = "../json/anim/laugh.json"
const cal_path = "/home/frankiezafe/projects/avatar-numediart/reva-toolkit/json/calibration/openface_calib.json"
const map_path = "../json/mapping/openface_mapping.json"

export(float, 0, 20) var anim_speed = 1
export(bool) var apply_pose_euler = true
export(bool) var apply_pose_translation = true

var model = null
var animation = null
var calibration = null
var mapping = null
var mask = null
var axis = null
var elapsed_time = 0
var sel_group = -1

func _ready():
	
	# loading 
	model = ReVA.load_model( mod_path )
	if model.success:
		add_child( model.node )
	
	animation = ReVA.load_animation( ani_path )
	
	if animation.success:
		
		print( "animation: ", animation.content.display_name )
		
		mask = $mask.duplicate()
		mask.visible = true
		add_child( mask )
		
# warning-ignore:unused_variable
		for i in range( animation.content.point_count ):
			var p = $pt.duplicate()
			p.visible = true
			p.material_override = p.get_surface_material(0).duplicate()
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

	calibration = ReVA.load_calibration( cal_path )
	ReVA.check_calibration( calibration, animation )
	ReVA.apply_calibration( calibration, animation )
	
	# apply colors on points
	if calibration.success:
		for g in calibration.content.groups:
			if 'symmetry' in g:
				for subg in g.points:
					for i in subg:
						mask.get_child(i).material_override.albedo_color = g.color
			else:
				for i in g.points:
					mask.get_child(i).material_override.albedo_color = g.color
	
	mapping = ReVA.load_mapping( map_path )
	# validation of mapping against calibration & model (removal of invalid indices)
	ReVA.check_mapping( mapping, animation )
	ReVA.check_mapping( mapping, model )
	# applying constraints on model
	ReVA.apply_mapping( mapping, model )
	# attacing mask to mapping.attachment_bone
	ReVA.attach_node( model, mapping, mask )
	mask.translation = Vector3()
	
	# not functional
	ReVA.autocalibrate( model, calibration, animation, 0 )

	$panels.filedialog = $filedialog
	$panels.set_calibration( calibration )
