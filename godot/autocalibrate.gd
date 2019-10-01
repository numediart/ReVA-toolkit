# how to bring set2 on set1 ?
extends Spatial

func minmax( v, o ):
	return { 
		'obj': o,
		'center': Vector3(v.x,v.y,v.z),
		'size': Vector3(0,0,0),
		'min': Vector3(v.x,v.y,v.z),
		'max': Vector3(v.x,v.y,v.z),
		'up': Vector3(0,0,0),
		'front': Vector3(0,0,0)
	}

func expand( mm, v ):
	for i in range(0,3):
		if mm.min[i] > v[i]:
			mm.min[i] = v[i]
		if mm.max[i] < v[i]:
			mm.max[i] = v[i]

func obj_minmax( o, up, front ):
	var mm = null
	for c in o.get_children():
		var p = c.global_transform.origin
		if mm == null:
			mm = minmax( p, o )
		else:
			expand(mm,p)
	mm.size = mm.max - mm.min
	mm.center = mm.min + mm.size * 0.5
	var u = up.global_transform.origin - mm.center
	var f = front.global_transform.origin - mm.center
	mm.up = u.normalized()
	mm.front = f.normalized()
	print( mm )
	return mm

func align( ref, mm ):
	var diffref = ref.center - ref.obj.global_transform.origin
	var diffmm = mm.center - mm.obj.global_transform.origin
	print( diffref, ' / ', diffmm )
	var trgt = ref.obj.global_transform.origin + diffref
	mm.obj.global_transform.origin = trgt - diffmm
	var refsiz = null
	var mmsiz = null
	for i in range(0,3):
		if refsiz == null:
			refsiz = ref.size[i]
			mmsiz = mm.size[i]
		else:
			if refsiz < ref.size[i]:
				refsiz = ref.size[i]
			if mmsiz < mm.size[i]:
				mmsiz = mm.size[i]
	print( refsiz, ' > ', mmsiz )
	var sc = refsiz / mmsiz
	print( sc )
	mm.obj.scale = mm.obj.scale * Vector3(sc,sc,sc)
	
	var refb = Basis( ref.front.cross( ref.up ), ref.up, ref.front )
	var mmb = Basis( mm.front.cross( mm.up ), mm.up, mm.front )
	$ref_axis.rotation = refb.get_euler()
	$mm_axis.rotation = mmb.get_euler()
	$ref_axis.global_transform.origin = ref.obj.global_transform.origin
	$mm_axis.global_transform.origin = mm.obj.global_transform.origin
	
	var diffb = refb.inverse() * mmb
	mm.obj.rotation += diffb.get_euler()

func _ready():
	
	var mm1 = obj_minmax( $set1, $set1/pt02, $set1/pt04 )
	var mm2 = obj_minmax( $set2, $set2/pt02, $set2/pt04 )
	align( mm1, mm2 )
	
func _process(delta):
	pass
