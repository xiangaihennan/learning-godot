extends CharacterBody2D

# -----------------------------------------------------------------------------
# Player Controller (Step 3 MVP)
# -----------------------------------------------------------------------------
# 目标：实现 Godot 4.x 下最小可运行的 WASD 八方向移动。
# 设计取舍：
# 1) 先保证“输入正确 + 移动稳定”，暂不引入动画/状态机；
# 2) 使用 CharacterBody2D 标准移动链路（velocity + move_and_slide）；
# 3) 输入映射缺失时自动补齐，降低新手首次运行门槛。
# -----------------------------------------------------------------------------

# 采用导出参数，让“移动速度”在 Inspector 可调，而不是写死在代码里。
# 这样后续调手感时不用改脚本，降低学习和迭代成本。
@export_range(50.0, 600.0, 10.0) var move_speed: float = 220.0

# 使用静态标记，避免每次实例化 Player 都重复注册 Input Map。
static var _input_initialized: bool = false


func _ready() -> void:
	# 在 _ready 做一次输入映射兜底：
	# - 保证场景一运行就能移动；
	# - 避免把“无法移动”的问题误判成物理或脚本 bug。
	_ensure_movement_actions()


func _physics_process(_delta: float) -> void:
	# _physics_process 以固定物理帧率执行（默认 60Hz），
	# 适合处理角色移动、碰撞这类“与物理同步”的逻辑。
	# Input.get_vector 会把四个方向合成为单位向量，并自动处理对角线归一化。
	# 这能保证八方向移动时速度一致，不会出现“斜着走更快”的常见问题。
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# CharacterBody2D 的 velocity 表示“每秒速度”（像素/秒）。
	# 这里用“方向 * 速度标量”得到期望移动速度：
	# - 只按 D：velocity 约等于 (220, 0)
	# - 只按 W：velocity 约等于 (0, -220)
	# - 按 W+D：velocity 长度仍约等于 220（因为 input_direction 已归一化）
	velocity = input_direction * move_speed

	# move_and_slide() 是 CharacterBody2D 的核心移动函数，作用可以理解为：
	# 1) 读取你当前设置的 velocity；
	# 2) 在“本次物理帧”内按物理步长推进位移；
	# 3) 如果碰到碰撞体，会做“滑动”处理，而不是直接穿过去或卡死；
	# 4) 根据碰撞结果，更新内部运动状态（例如贴墙后的实际速度）。
	#
	# 为什么第 3 步就用它：
	# - 这是 Godot 角色移动最标准入口，后续加墙体、敌人碰撞、击退都复用这套机制；
	# - 比手动 position += ... 更安全，不容易穿模。
	#
	# 常见误区：
	# - 不要在调用前再手动写 position += velocity * delta，否则会“双重移动”；
	# - velocity 已是“每秒速度”，move_and_slide() 内部会按物理帧处理时间步进，
	#   所以这里通常不需要再乘 delta。
	move_and_slide()


func _ensure_movement_actions() -> void:
	# static 标记保证整个运行期只初始化一次，避免重复 add_action。
	if _input_initialized:
		return

	# 第 3 步目标是 WASD 输入。这里在运行时补齐映射：
	# 1) 新手即使忘了在 Project Settings 里手动配置，也能立刻跑通。
	# 2) 后续若你已在编辑器里配置了同名 Action，这段逻辑不会破坏已有设置。
	_add_action_if_missing("move_up", KEY_W)
	_add_action_if_missing("move_down", KEY_S)
	_add_action_if_missing("move_left", KEY_A)
	_add_action_if_missing("move_right", KEY_D)
	_input_initialized = true


func _add_action_if_missing(action_name: StringName, keycode: Key) -> void:
	# 只在 action 不存在时创建，避免覆盖你在编辑器里手动绑定的按键方案。
	if InputMap.has_action(action_name):
		return

	InputMap.add_action(action_name)
	var key_event := InputEventKey.new()
	# physical_keycode 对应物理按键位置，跨键盘布局更稳定（例如中英文输入法切换时）。
	key_event.physical_keycode = keycode
	InputMap.action_add_event(action_name, key_event)
