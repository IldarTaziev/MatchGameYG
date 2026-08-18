extends Node2D

@onready var grid : GridContainer = $GridContainer
@onready var timer : Timer = $Timer
@onready var label_score : RichTextLabel = $GUI/score
@onready var label_timer : RichTextLabel = $GUI/timer

const TOTAL_DURATION_SECONDS = 30
const ROWS = 8
const COLS = 8
const TYPES = 6

var tiles = []
var selected : Node = null
var score = 0


func _ready() -> void:
	randomize()
	_create_board()
	_ensure_no_initial_matches()
	reset_timer()
	set_score(0)

## Создает доску с тайлами
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

## Функция сигнал нажатия на тайл
func _on_tile_clicked(tile):
	#когда не выбран не один тайл
	if selected == null:
		selected = tile
		tile.highlight(true)
	else:
	# когда уже выбран
		#нажали на тот же тайл
		if tile == selected:
			selected.highlight(false)
			selected = null
			return
		if _is_adjacent(selected, tile): # если тайлы соседи
			selected.highlight(false)
			try_swap(selected, tile)
			selected = null
		else: # если тайлы не соседи
			selected.highlight(false)
			selected = tile
			selected.highlight(true)

## Проверяет примыкает ли тайл a к другому тайлу b
func _is_adjacent (a, b): # проверка но то примыкает ли тайл к другому
	return (
		(a.row == b.row and abs(a.col - b.col) == 1)
		or 
		(a.col == b.col and abs(a.row - b.row) == 1)
	)


func try_swap(a, b):
	await swap(a,b)
	var matches = find_matches()
	if len(matches) == 0:
		# отмена swap
		await swap(a,b)
	else:
		await remove_matches(matches, true)
		await refill()
		# убедимся что в игре больше нет совпадений в ряд
		while true:
			matches = find_matches()
			if len(matches) == 0:
				break
			await remove_matches(matches, true)
			await refill()

## меняет местами типы тайлов, и делаем анимацию замены 
func swap(a,b):
	# обмениваем типы тайлов, и делаем анимацию
	var t = a.tile_type
	a.change_type(b.tile_type)
	b.change_type(t)
	
	# анимация
	var tween = create_tween()
	tween.tween_property(a, "scale", Vector2(1.08,1.08), 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(b, "scale", Vector2(1.08,1.08), 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(a, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(b, "scale", Vector2.ONE, 0.1)
	await tween.finished

## Возвращает список содержащий {r,c} ряд и столбец что бы удалить их из-за совпадения ряда
func find_matches():
	"""
	Возвращает список содержащий {r,c} ряд и столбец что бы удалить их из-за совпадения ряда
	"""
	var remove = []
	# провверка горизонтальных совпадений 
	for r in range(ROWS):
		var run_type = -1
		var run_start = 0
		var run_len = 0
		
		for c in range(COLS):
			var t = tiles[r][c].tile_type 
			if run_type == t:
				run_len += 1
			else:
				if run_len >=3:
					for i in range(run_start, run_start + run_len):
						remove.append({"r": r, "c": i})
				run_type = t
				run_start = c
				run_len = 1
		if run_len >=3:
			for i in range(run_start, run_start + run_len):
				remove.append({"r": r, "c": i})
	print(len(remove))
	# провверка вертикальных совпадений 
	for c in range(COLS):
		var run_type = -1
		var run_start = 0
		var run_len = 0
		
		for r in range(ROWS):
			var t = tiles[r][c].tile_type 
			if run_type == t:
				run_len += 1
			else:
				if run_len >=3:
					for i in range(run_start, run_start + run_len):
						remove.append({"r": i, "c": c})
				run_type = t
				run_start = r
				run_len = 1
		if run_len >=3:
			for i in range(run_start, run_start + run_len):
				remove.append({"r": i, "c": c})
	print(len(remove))
	# убираем дубликаты 
	var uniq = {}
	var out = []
	
	for p in remove:
		var key = str(p['r']) + "." + str(p['c'])
		if not uniq.has(key):
			uniq[key] = true
			out.append(p)
	
	return out

## Убирает совпадения. Принимает список содержащий {r, c} ряд и столбец 
func remove_matches(matches, update_score : bool = false):
	for tile in matches:
		var r = tile['r']
		var c = tile['c']
		tiles[r][c].set_type(-1,r,c)
	if update_score:
		set_score(len(matches))

## восполняет пустые тайлы , добавляет новые сверху и анимирует
func refill():
	var pop_duration = 0.1
	var pop_stagger = 0.03
	
	var new_tiles = []
	
	for c in range(COLS):
		var stack = []
		# find rows which are empty
		for r in range(ROWS-1,-1,-1):
			if tiles[r][c].tile_type != -1:
				stack.append(tiles[r][c].tile_type)
		# запишем не пустые тайлы в место пустых тайлов
		var idx = 0
		for r in range(ROWS-1,-1,-1):
			if idx < stack.size():
				var ttype = stack[idx]
				tiles[r][c].set_type(ttype,r,c)
				tiles[r][c].scale = Vector2.ONE
				idx += 1
			else:
				# если нет тайлов для смещения
				tiles[r][c].set_type(-1,r,c)
		# заполняем верхушку новыми типами тайлов
		for r in range(0,ROWS):
			if tiles[r][c].tile_type == -1:
				var new_type = randi()%TYPES
				tiles[r][c].set_type(new_type,r,c)
				tiles[r][c].scale = Vector2(0,0)
				new_tiles.append(tiles[r][c])
			
	# pop анимация 
	if new_tiles.size() > 0:
		var tween = create_tween()
		for i in range(new_tiles.size()):
			if i > 0:
				tween.tween_interval(pop_stagger)
			tween.tween_property(
				new_tiles[i], "scale", Vector2.ONE, pop_duration
				).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tween.finished


func _ensure_no_initial_matches():
	var matches
	while true:
			matches = find_matches()
			if len(matches) == 0:
				break
			for tile in matches:
				tiles[tile['r']][tile['c']].set_type(
					randi() % TYPES,
					tile['r'],
					tile['c']
				)


func set_score(increment):
	score += increment
	label_score.text = "Score : " + str(score)


func reset_timer():
	score = 0
	if not timer.is_stopped():
		timer.stop()
	timer.wait_time = TOTAL_DURATION_SECONDS
	timer.start()


func _on_timer_timeout() -> void:
	# пока что конец игры
	print("Games over! Your score is "+str(score))


func _process(delta: float) -> void:
	label_timer.text =  "Time : " + str(int(timer.time_left)) 
