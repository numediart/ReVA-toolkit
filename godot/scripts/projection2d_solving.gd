tool

extends Node2D

export(float,-6.8,6.8) var rot_A = 0

var O = null
var T = null
var elapsed_time = 0

var elements = []

func load_debuggers( i ):
	
	var el = elements[i]
	print( 'loading debuggers for ' + el['node'].name )
	
	if el['node'].get_node( 'O' ) == null:
		print( 'no O_debug in ' + el['node'].name )
		return
	
	el['O'] = el['node'].get_node( 'O' )
	el['O'].global_transform.origin = O.global_transform.origin
	
	el['T_origin'] = el['node'].get_node( 'O/T_origin' )
	el['T_origin'].global_transform.origin = T.global_transform.origin
	
	el['T'] = el['node'].get_node( 'O/T' )
	el['T'].global_transform.origin = T.global_transform.origin

func load_stuff():
	
	O = get_node( "O" )
	T = get_node( "O/T" )

	var o = get_node("O")
	var n = o
	
	# 0
	elements.append( {
		'node': n,
		'init': Transform2D(),
		'children': [ 1,2,3 ],
		'correction': Transform2D()
	} )
	
	# 1
	n = get_node("O/A")
	elements.append( {
		'node': n,
		'init': o.global_transform.inverse() * Transform2D( n.global_transform ),
		'children': [ 2,3 ],
		'correction': Transform2D()
	} )
	
	# 2
	n = get_node("O/A/B")
	elements.append( {
		'node': n,
		'init': o.global_transform.inverse() * Transform2D( n.global_transform ),
		'children': [ 3 ],
		'correction': Transform2D()
	} )
	load_debuggers( len(elements)-1 )
	
	# 3
	n = get_node("O/A/B/C")
	elements.append( {
		'node': n,
		'init': o.global_transform.inverse() * Transform2D( n.global_transform ),
		'children': [],
		'correction': Transform2D()
	} )
	load_debuggers( len(elements)-1 )
	
	for e in elements:
		print(e)
	

func _ready():
	rot_A = 0
	load_stuff()

func rotate_element( el, rad ):
	
	el['node'].rotation = rad
	var t1 = Transform2D( el['init'] )
	t1.origin -= el['init'].origin
	
	var delta_transf = t1.inverse() * Transform2D( rad, Vector2() )
	var origin_pos = delta_transf * elements[1]['init'].origin
	var delta_pos = origin_pos - elements[1]['init'].origin
	
	var t = Transform2D( -rad, -delta_pos )
	for c in el['children']:
		elements[ c ]['correction'] *= t

func apply_corrections( el ):

	if not 'T' in el:
		return
	
	var p
	p = el['T_origin'].position - el['correction'].origin
	el['T'].position = Transform2D( el['correction'].get_rotation(), Vector2() ).xform( p )
	

func _process(delta):
	
	elapsed_time += rot_A
	
	if elements == null or len(elements) == 0:
		rot_A = 0
		load_stuff()
	
	for n in elements:
		n['correction'] = Transform2D()
	
	# ROTATION OF A
	rotate_element( elements[2], rot_A )
	
	for n in elements:
		apply_corrections( n )
	
#	return
#
#	if elements == null or len(elements) == 0:
#		rot_A = 0
#		load_stuff()
#
#	elements[1]['node'].rotation = elapsed_time
#
#	var t1 = Transform2D( elements[1]['init'] )
#	t1.origin -= elements[1]['init'].origin
#
#	var delta_transf = t1.inverse() * Transform2D( rot_A, Vector2() )
#
#	var origin_pos = delta_transf * elements[1]['init'].origin
#	var delta_pos = origin_pos - elements[1]['init'].origin
#
##	O_debug.global_transform.origin = get_node( "O/A/B/O" ).global_transform.origin + delta_pos
#
#	var t = Transform2D( -rot_A, delta_pos )
#	for c in elements[1]['children']:
#		elements[ c ]['correction'] *= t
#
#	var rotT = Transform2D( -elapsed_time, Vector2() )
#	BOT.position = T_origin.position + delta_pos
#	BOT.position = rotT * BOT.position
#
#	get_node( "lbl_x" ).text = str(delta_pos.x)
#	get_node( "lbl_y" ).text = str(delta_pos.y)
#	var diff = get_node("O/A/B/O").global_transform.origin - get_node("O").global_transform.origin
#	get_node( "lbl_x2" ).text = str(diff.x)
#	get_node( "lbl_y2" ).text = str(diff.y)
