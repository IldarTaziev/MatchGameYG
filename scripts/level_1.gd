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
			grid.add_child(tile)
			row.append(tile)
		tiles.append(row)
