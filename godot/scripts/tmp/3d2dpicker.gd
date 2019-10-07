extends Node2D

const color_normal = Color( 1,1,1 )
const color_select = Color( 1,0,0 )
onready var cam = get_node("../cam_pivot/cam")
var pickables = null

func prepare( root ):
	while $pickers.get_child_count() > 0:
		$pickers.remove_child( $pickers.get_child(0) )
	pickables = []
	for c in root.get_children():
		if c is MeshInstance:
			var pos = cam.unproject_position( c.global_transform.origin )
			var btn = $tmpl.duplicate()
			btn.cam = cam
			btn.obj = c
			$pickers.add_child(btn)
			btn.connect( "picker3d_button_pressed", self, "on_pressed" )

func _ready():
	prepare( get_node( "../" ) )

func _process(delta):
	pass

func on_pressed( btn ):
	if btn.selected:
		btn.obj.material_override = btn.obj.material_override.duplicate()
		btn.obj.material_override.albedo_color = color_select
	else:
		btn.obj.material_override = btn.obj.material_override.duplicate()
		btn.obj.material_override.albedo_color = color_normal
