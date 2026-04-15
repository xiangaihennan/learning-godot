extends Node2D

@onready var world: Node2D = $World
@onready var entities: Node2D = $Entities
@onready var vfx: Node2D = $VFX
@onready var ui_root: CanvasLayer = $UIRoot

const PLAYER_SCENE_PATH: String = "res://scenes/Player.tscn"


func _ready() -> void:
	# 先校验层级，再做玩家实例化。
	# 这样如果层级出错，会优先暴露“结构问题”，排错路径更短。
	_validate_layer_structure()
	_spawn_player_mvp()


func _validate_layer_structure() -> void:
	var missing_nodes: PackedStringArray = []

	if world == null:
		missing_nodes.append("World")
	if entities == null:
		missing_nodes.append("Entities")
	if vfx == null:
		missing_nodes.append("VFX")
	if ui_root == null:
		missing_nodes.append("UIRoot")

	if missing_nodes.is_empty():
		print("Main scene layers are ready: World, Entities, VFX, UIRoot")
		return

	push_error("Main scene is missing required nodes: %s" % ", ".join(missing_nodes))


func _spawn_player_mvp() -> void:
	if entities == null:
		push_error("Cannot spawn player because Entities node is missing.")
		return

	# 防止场景热重载或重复调用时生成多个玩家实例。
	if entities.get_node_or_null("Player") != null:
		return

	# 主场景通过 PackedScene 加载玩家，保持“场景组合”而不是把所有逻辑塞进 Main。
	# 这样后续替换玩家实现（动画版、受伤版）时，只改 Player.tscn 即可。
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	if player_scene == null:
		push_error("Failed to load player scene: %s" % PLAYER_SCENE_PATH)
		return

	# 第 3 步直接约束为 CharacterBody2D，确保后续碰撞/受击步骤可平滑衔接。
	var player_instance := player_scene.instantiate() as CharacterBody2D
	if player_instance == null:
		push_error("Failed to instantiate player scene.")
		return

	# 先放在世界原点，便于第 3 步专注验证“输入与移动”。
	player_instance.position = Vector2.ZERO
	entities.add_child(player_instance)
