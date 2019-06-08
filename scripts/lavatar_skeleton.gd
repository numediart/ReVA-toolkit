tool

extends Skeleton

export (bool) var reload = false setget _reload

func _reload(b):
	attachements = null
	iks = null

var attachements = null
var iks = null
var ctrls = null

func prepare_attachements():
	
	attachements = []
	for i in get_child_count():
		if get_child(i).name.begins_with("att_"):
			attachements.append( get_child(i) )
	print( "attachements ", attachements )

func prepare_iks():
	
	iks = []
	for i in get_child_count():
		if get_child(i).name.begins_with("ik_"):
			iks.append( get_child(i) )
	
	ctrls = []
	var ctrl_root = get_node( "../ctrls" )
	for i in ctrl_root.get_child_count():
		var c = ctrl_root.get_child(i)
		if c.name.begins_with( "ctrl_" ):
			var trg = "ik_" + c.name.replace( "ctrl_", "" )
			for ik in iks:
				if ik.name == trg:
					var bid = find_bone( ik.tip_bone )
					var glob = get_bone_global_pose( bid )
#					var globp = get_bone_global_pose( get_bone_parent( bid ) )
#					var offs = glob.origin - globp.origin
					c.global_transform = glob
					ctrls.append(c)
					break
			
	print( "iks ", iks )

func _ready():
	pass

func _process(delta):
	
	if attachements == null:
		prepare_attachements()
	if iks == null:
		prepare_iks()
	
	pass
	