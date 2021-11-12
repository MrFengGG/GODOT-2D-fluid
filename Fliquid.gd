extends Node2D

const MAX_LIQUID = 1
const MAX_LIQUID_COMPLEX : float = 1.0
const MAX_LIQUID_COMPRESS : float = 0.06
const MIN_LIQUID : float = 0.0001
const MAX_LIQUID_SPEED = 1
const LIQUID_TIME = 0
const BLOCK_SIZE = 16

var liquid_array = []
#地图宽度
var width_block_num = 400
#地图深度
var height_block_num = 100

func _ready():
	for x in range(width_block_num):
		var row_liquid = []
		for y in range(height_block_num):
			row_liquid.append(0)
		liquid_array.append(row_liquid)

func _process(delta):
	update_liquid_compress(delta)
	if Input.is_action_pressed("put"):
		var world_position = get_global_mouse_position()
		var block_position = Vector2(world_position.x / BLOCK_SIZE, world_position.y / BLOCK_SIZE)
		liquid_array[block_position.x][block_position.y] = -1
	if Input.is_action_pressed("putwater"):
		var world_position = get_global_mouse_position()
		var block_position = Vector2(world_position.x / BLOCK_SIZE, world_position.y / BLOCK_SIZE)
		liquid_array[block_position.x][block_position.y] = MAX_LIQUID
func _draw():
	for x in range(0, width_block_num - 1):
		for y in range(0, height_block_num - 1):
			if liquid_array[x][y] == -1:
				draw_rect(Rect2(x * BLOCK_SIZE, y * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE), Color.gray)
			#绘制屏幕范围内的流体
			var cell = liquid_array[x][y]
			if cell > 0:	
				var f = clamp(cell / MAX_LIQUID, 0, 1)
				var col = Color(0.5, 0.5, 1.0, 0.5)
				var r
				var down_liquid = liquid_array[x][y + 1]
				if down_liquid > 0 && down_liquid < MAX_LIQUID:
					r = Rect2(x * BLOCK_SIZE, (y + 1.0 - f) * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
				else:
					r = Rect2(x * BLOCK_SIZE, (y + 1.0 - f) * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE * f)
				draw_rect(r, col)
func update_liquid_compress(delta):
	var flow : float = 0
	var remain_water : float = 0
	var actions = []
	for x in range(0, width_block_num - 1):
		for y in range(0, height_block_num - 1):
			var this_position = Vector2(x, y)
			if liquid_array[x][y] == -1:
				continue
			flow = 0
			remain_water = liquid_array[x][y]
			if remain_water <= 0:
				continue;
			var down = Vector2(x, y + 1)
			if liquid_array[down.x][down.y] != -1:
				flow = get_stable_state_b(remain_water + liquid_array[x][y + 1]) - liquid_array[x][y+1]
				
				flow = clamp(flow, 0, min(MAX_LIQUID_COMPLEX, remain_water))
				actions.append([this_position, -flow])
				actions.append([down, flow])
				remain_water -= flow
			if remain_water <= 0:
				continue
			var right = Vector2(x + 1, y)
			if liquid_array[right.x][right.y] != -1:
				flow = (liquid_array[x][y] - liquid_array[x+1][y]) / 4;
				
				flow = clamp(flow, 0, min(MAX_LIQUID_SPEED, remain_water))  
				actions.append([this_position, -flow])
				actions.append([right, flow])
				remain_water -= flow
			if remain_water <= 0:
				continue
			var left = Vector2(x - 1, y)
			if liquid_array[left.x][left.y] != -1:
				flow = (liquid_array[x][y] - liquid_array[x-1][y]) / 4;
				
				flow = clamp(flow, 0, min(MAX_LIQUID_SPEED, remain_water))  
				actions.append([this_position, -flow])
				actions.append([left, flow])
				remain_water -= flow
			if remain_water <= 0:
				continue
			var up = Vector2(x, y - 1)
			if liquid_array[up.x][up.y] != -1:
				flow = remain_water - get_stable_state_b(remain_water + liquid_array[x][y-1])
				
				flow = clamp(flow, 0, min(MAX_LIQUID_SPEED, remain_water))
				actions.append([this_position, -flow])
				actions.append([up, flow])
				remain_water -= flow
	for action in actions:
		var this_position = action[0]
		liquid_array[this_position.x][this_position.y] += action[1]
		if liquid_array[this_position.x][this_position.y] < MIN_LIQUID:
			liquid_array[this_position.x][this_position.y] = 0
	update()

#根据上下两个水量块计算流量
func get_stable_state_b(total_liquid: float):
	if total_liquid <= 1:
		return 1
	elif total_liquid < 2 * MAX_LIQUID + MAX_LIQUID_COMPRESS:
		return (MAX_LIQUID * MAX_LIQUID + total_liquid * MAX_LIQUID_COMPRESS) / (MAX_LIQUID + MAX_LIQUID_COMPRESS)
	else:
		return (total_liquid + MAX_LIQUID_COMPRESS) / 2
