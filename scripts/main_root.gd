extends Node2D

# -----------------------------------------------------------------------------
# Main Root Script
# -----------------------------------------------------------------------------
# 这个脚本负责“主场景骨架层”的基础校验，不负责玩法逻辑本身。
# 当前阶段（第 2~3 步）我们只做两件事：
# 1) 保证分层节点存在：World / Entities / VFX / UIRoot
# 2) 在启动时给出明确日志，降低后续迭代时的排错成本
#
# 为什么要尽早做结构校验：
# - 学习期改动频繁，节点重命名/误删很常见；
# - 如果不在入口处校验，错误会延后到“玩家、敌人、UI 功能脚本”中才暴露，
#   新手会更难定位根因。
# -----------------------------------------------------------------------------

@onready var world: Node2D = $World
@onready var entities: Node2D = $Entities
@onready var vfx: Node2D = $VFX
@onready var ui_root: CanvasLayer = $UIRoot

# 下面 3 个 onready 引用是“第 5 步刷怪系统”的关键依赖：
# - player：刷怪位置计算要以玩家为圆心，避免把怪生成在地图随机点导致体验不可控。
# - enemy_spawner：作为刷怪逻辑容器，后续做波次系统时可集中管理刷怪参数。
# - spawn_timer：通过 Timer 周期触发刷怪，不在 _process 里写累计时间，代码更清晰稳定。
@onready var player: Node2D = $Entities/Player
@onready var enemy_spawner: Node2D = $Entities/EnemySpawner
@onready var spawn_timer: Timer = $Entities/EnemySpawner/SpawnTimer

# 第 5 步刷怪参数（MVP）：
# - enemy_scene：要实例化的敌人预制体（PackedScene）。先固定 1 种敌人，后续第 20 步再扩展变体。
# - min_spawn_distance：最小出生半径，防止“贴脸出生”直接撞到玩家。
# - max_spawn_distance：最大出生半径，防止刷得太远导致玩家长时间看不到敌人。
# 这三个参数都放到 Inspector，可边运行边调，不需要频繁改代码。
@export var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
@export_range(50.0, 600.0, 10.0) var min_spawn_distance: float = 180.0
@export_range(80.0, 900.0, 10.0) var max_spawn_distance: float = 320.0

func _ready() -> void:
	# 初始化随机数种子，避免每次运行刷怪角度/距离都完全一样。
	# 对学习阶段来说，“每局略有变化”更容易观察系统是否健壮。
	randomize()
	# 主场景负责结构校验 + 基础刷怪器初始化。
	_validate_layer_structure()
	_setup_enemy_spawner()


func _validate_layer_structure() -> void:
	# 用数组统一收集缺失节点，避免“报一个修一个”的低效循环。
	var missing_nodes: PackedStringArray = []

	# 逐项显式检查，而不是循环字符串列表，是为了让初学者更容易读懂：
	# “哪个变量对应哪个节点路径”一目了然。
	if world == null:
		missing_nodes.append("World")
	if entities == null:
		missing_nodes.append("Entities")
	if vfx == null:
		missing_nodes.append("VFX")
	if ui_root == null:
		missing_nodes.append("UIRoot")

	if missing_nodes.is_empty():
		# 成功日志不是冗余：它能确认“主场景骨架已就绪”，
		# 后续若玩家/敌人有问题，可更快排除“场景分层错误”。
		print("Main scene layers are ready: World, Entities, VFX, UIRoot")
		return

	# push_error 会进入 Godot 的错误通道，调试器中更醒目，
	# 比普通 print 更适合表示“必须修复的问题”。
	push_error("Main scene is missing required nodes: %s" % ", ".join(missing_nodes))


func _setup_enemy_spawner() -> void:
	# 先做依赖校验，避免“空引用导致直接崩溃”。
	# 校验失败时用 push_error 给出可操作提示，便于你在场景树里快速定位问题。
	if enemy_spawner == null or spawn_timer == null:
		push_error("EnemySpawner or SpawnTimer is missing. Step 5 setup is incomplete.")
		return
	if player == null:
		push_error("Player node is missing. Enemy spawns need a player anchor.")
		return
	if enemy_scene == null:
		push_error("Enemy scene is not assigned. Cannot spawn enemies.")
		return

	# 防重复连接：脚本热重载或场景重复初始化时，避免同一个回调被连多次。
	# 如果重复连接，表现通常是“一次计时触发刷多只怪”，会误判为逻辑 bug。
	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)


func _on_spawn_timer_timeout() -> void:
	# 运行期保护：即使中途节点被删/替换，也不要让回调抛异常中断游戏。
	if enemy_scene == null or player == null or entities == null:
		return

	# 1) 实例化敌人
	var enemy_instance: Node = enemy_scene.instantiate()
	# 2) 计算出生点（以玩家为中心，在 [min, max] 的环形区域内随机）
	var spawn_position := _generate_spawn_position(player.global_position)

	# 3) 只有 2D 节点才有 global_position，先做类型保护再赋值。
	if enemy_instance is Node2D:
		var enemy_node := enemy_instance as Node2D
		enemy_node.global_position = spawn_position

	# 4) 加入 Entities 层，保证场景分层语义清晰（玩家、敌人、子弹都在这里）。
	entities.add_child(enemy_instance)


func _generate_spawn_position(player_position: Vector2) -> Vector2:
	# max 距离至少比 min 大一点点，防止配置错误导致 randf_range 上下限异常。
	# maxf 返回 float，可避免“Variant 推断警告当错误”。
	var clamped_max_distance: float = maxf(max_spawn_distance, min_spawn_distance + 10.0)
	# 随机角度：0~TAU（2π）覆盖整圆。
	var angle := randf_range(0.0, TAU)
	# 随机半径：保证敌人不会贴脸，同时也不会离玩家太远。
	var distance := randf_range(min_spawn_distance, clamped_max_distance)
	# 用“单位向量旋转 + 半径”得到偏移，再叠加玩家位置得到最终世界坐标。
	return player_position + Vector2.RIGHT.rotated(angle) * distance
