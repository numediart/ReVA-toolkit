tool

extends Spatial

var init = null

func _ready():
	pass
	
func _process(delta):
	
	if init == null:
		init = $tester.transform.origin
	
	var diff = $tester.transform.origin - init
	
	$cub.transform = $p0.transform * $p0/p1.transform
	
	var q = Quat()
	q.set_euler( $p0.transform.basis.get_euler() )
	var t = Transform(q)
	var t2 = Transform()
	t2.origin = diff
	t2 = t2 * t.inverse()
	$cub.translation += t2.origin
