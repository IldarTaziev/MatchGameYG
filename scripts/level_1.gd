extends Node2D
@onready var grid : GridContainer = $GridContainer

const ROWS = 8
const COLS = 8
const TYPES = 6

var tiles = []
var selected : Node = null


func _ready() -> void:
	randomize()
	_create_board()
	
	
func _create_board():
	tiles = []
	grid.columns = COLS
	var tile_scene = preload("res://scenes/tile.tscn")
	for r in range(ROWS):
		var row = []
		for c in range(COLS):
			var tile = tile_scene.instantiate()
			tile.set_type(
				randi()%TYPES , r , c
			)
			tile.connect(
				"clicked_tile",
				Callable(self, "_on_tile_clicked")
			)
			grid.add_child(tile)
			row.append(tile)
		tiles.append(row)


func _on_tile_clicked(tile):
	#когда не выбран не один тайл
	if selected == null:
		selected = tile
		tile.highlight(true)
	else:
	# когда уже выбран, меняем на другой
		if tile == selected:
			tile.highlight(false)
			selected = null
			return
		if _is_adjacent(selected, tile):
			selected.highlight(false)
			try_swap(selected, tile)
			selected = null
		else:
			selected.highlight(false)
			selected = tile
			selected.highlight(true)
			
func _is_adjacent (a, b): # проверка но то примыкает ли тайл к другому
	return (
		(a.row == b.row and abs(a.col - b.col) == 1)
		or 
		(a.col == b.col and abs(a.row - b.row) == 1)
	)
		

func try_swap(a, b):
	pass
