extends Spatial
const ReVA = preload( "res://scripts/reva/ReVA.gd" )
const mod_path = "res://scenes/reva/joan.tscn"
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
var elapsed_time = 0

func _ready():
	
	# loading 
	model = ReVA.load_model( mod_path )
	if model.success:
		add_child( model.node )
	
	animation = ReVA.load_animation( ani_path )
	
	if not animation.success:
		return

	calibration = ReVA.load_calibration( cal_path )
	ReVA.check_calibration( calibration, animation )
	ReVA.apply_calibration( calibration, animation )
	
	# apply colors on points
	if not calibration.success:
		return
	
	mapping = ReVA.load_mapping( map_path )
	# validation of mapping against calibration & model (removal of invalid indices)
	ReVA.check_mapping( mapping, animation )
	ReVA.check_mapping( mapping, model )
	# applying constraints on model
	ReVA.apply_mapping( mapping, model )
	
	# not functional
	ReVA.autocalibrate( model, calibration, animation, 0 )

	$panels.filedialog = $filedialog
	$panels.set_calibration( calibration )
	
	$data_viz.configure( animation, calibration )
	# attacing mask to mapping.attachment_bone
	ReVA.attach_node( model, mapping, $data_viz.mask )
	
	$panels.connect( 'calibration_updated', self, 'apply_calibration' )
	
	$cam_pivot.configure( model )

func apply_calibration():
	print( 'apply_calibration' )
	ReVA.apply_calibration( calibration, animation )

func _process(delta):
	
	var frame = ReVA.animation_frame( animation, elapsed_time * anim_speed )
	if frame != null:
		$data_viz.visualise( frame, $panels.group_index )
