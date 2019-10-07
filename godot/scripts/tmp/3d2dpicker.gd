extends Node2D

const color_normal = Color( 0.16,1,1 )
const color_select = Color( 1,0,0 )
onready var cam = get_node("../cam_pivot/cam")
var pickables = null

func prepare( root ):
	while $pickers.get_child_count() > 0:
		$pickers.remove_child( $pickers.get_child(0) )
	pickables = []
	for c in root.get_children():
		if c is RigidBody:
			var pos = cam.unproject_position( c.global_transform.origin )
			var btn = $tmpl.duplicate()
			btn.configure( cam, c )
			$pickers.add_child(btn)
			btn.connect( "picker3d_button_pressed", self, "on_pressed" )

func _ready():
	prepare( get_node( "../" ) )

func _process(delta):
	pass

func on_pressed( btn ):
	if btn.mesh != null:
		if btn.selected:
			btn.mesh.material_override = btn.mesh.material_override.duplicate()
			btn.mesh.material_override.albedo_color = color_select
		else:
			btn.mesh.material_override = btn.mesh.material_override.duplicate()
			btn.mesh.material_override.albedo_color = color_normal
