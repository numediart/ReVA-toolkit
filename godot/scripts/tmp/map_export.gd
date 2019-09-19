tool

extends Spatial

export(bool) var do_extract = false

func extract():
	
	print( "MAPPING EXTRACTION" )
	
	var json = get_node("../json")
	var joan = get_node("../joan")
	
	var dict = []
	
	for k in json.mapping:
		var m = json.mapping[k]
		
		var newm = {}
		newm['bone'] = k
		if 'gaze' in m:
			newm['gaze'] = {
				'id': m.gaze,
				"damping" : 0,
				"weight" : 1
			}
		if 'pose_euler' in m:
			newm['pose_euler'] = {
				"damping" : m.pose_euler[1],
				"weight" : m.pose_euler[0]
			}
		if 'landmarks' in m:
			newm['point_weights'] = []
			for lm in m.landmarks:
				newm.point_weights.append(
				{
					'id': lm.id,
					'weight': lm.weight,
				}
				)
		newm['bone'] = k
		
		for c in joan.get_children():
			if c is BoneAttachment and c.bone_name == k:
				if not 'lookat_enabled' in c:
					print( 'invalid ' + c.name )
				newm.constraint = {}
				newm.constraint.lookat_enabled = c.lookat_enabled
				newm.constraint.rot_enabled = c.rot_enabled
				newm.constraint.rot_lock = [c.rot_lock_x,c.rot_lock_y,c.rot_lock_z]
				newm.constraint.rot_mult = [c.rot_mult.x,c.rot_mult.y,c.rot_mult.z]
				newm.constraint.trans_enabled = c.trans_enabled
				newm.constraint.trans_lock = [c.trans_lock_x,c.trans_lock_y,c.trans_lock_z]
				newm.constraint.trans_mult = [c.trans_mult.x,c.trans_mult.y,c.trans_mult.z]
		
		dict.append( newm )
		
	print(dict)
	
	var file = File.new()
	file.open( "../map_export.txt", file.WRITE )
	file.store_string( JSON.print(dict,'\t') )
	file.close()

func _ready():
	pass

func _process(delta):
	if do_extract:
		extract()
		do_extract = false
