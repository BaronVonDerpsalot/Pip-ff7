class_name ScreenEntry
extends Marker2D
## Where Pip's feet are when he arrives on this screen through an exit.
## Its node name is what an exit's to_entry refers to. Put it inside the walk
## area and clear of every exit, or Pip leaves again as soon as he arrives.

## The way Pip faces when he arrives (screen directions: right is +x, down is +y).
@export var facing := Vector2.DOWN
