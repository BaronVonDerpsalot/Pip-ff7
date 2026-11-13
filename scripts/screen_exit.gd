class_name ScreenExit
extends Polygon2D
## A zone on a screen that leads to another screen. Draw it over the edge of the
## walk area, where the path leaves the picture. When Pip's feet step inside it,
## he moves to the entry point named to_entry on the screen to_screen.

## The screen this exit leads to.
@export_file("*.tscn") var to_screen := ""
## The name of the ScreenEntry (under that screen's Entries node) Pip arrives at.
@export var to_entry: StringName = &""


func contains(point: Vector2, from: Node2D) -> bool:
	var local := to_local(from.to_global(point))
	return Geometry2D.is_point_in_polygon(local, polygon)
