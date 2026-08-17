extends Button

signal clicked_tile(tile)
var row : int = -1
var col : int = -1
var tile_type : int = 0

@onready var color_rect : ColorRect = $ColorRect

func _ready() -> void:
	color_rect.hide()



func set_type(type,row,col):
	self.row = row
	self.col = col
	self.tile_type = type
	update_visual()
	
func update_visual():
	var color
	match tile_type:
		0: color = Color.AQUAMARINE
		1: color = Color.TOMATO
		2: color = Color.YELLOW_GREEN
		3: color = Color.WHEAT
		4: color = Color.ORANGE
		5: color = Color.DARK_BLUE
		_: color = Color.BLACK
	modulate = color


func _on_pressed() -> void:
	emit_signal("clicked_tile", self)


func highlight(on : bool):
	color_rect.visible = on
