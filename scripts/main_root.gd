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

func _ready() -> void:
	# 主场景只负责结构校验。
	# Player 改为静态挂载到 Main/Entities，避免运行时动态拼装造成结构不直观。
	_validate_layer_structure()


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
