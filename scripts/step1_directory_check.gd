extends RefCounted
class_name Step1DirectoryCheck

# -----------------------------------------------------------------------------
# Step1DirectoryCheck
# -----------------------------------------------------------------------------
# 这个工具类的定位：给“第 1 步目录初始化”提供可复用的自动验收逻辑。
# 为什么用工具类而不是把检查逻辑写在某个场景脚本里：
# 1) 第 1 步还不依赖具体场景，工具类更独立；
# 2) 后续可在编辑器脚本、测试脚本、启动检查里重复调用；
# 3) 减少耦合，避免“只为验收目录却必须先跑主场景”的反直觉流程。
# -----------------------------------------------------------------------------

# 第 1 步验收用：集中维护必须存在的目录，避免在多个地方写死字符串。
const REQUIRED_DIRS: PackedStringArray = [
	"res://scenes",
	"res://scripts",
	"res://ui",
	"res://art",
	"res://audio",
	"res://data",
]


static func validate_required_dirs() -> Dictionary:
	# missing 用于收集“缺失目录列表”。
	# 用数组而不是遇到第一个错误就 return，目的是一次性给出完整诊断结果。
	var missing: PackedStringArray = []

	for dir_path in REQUIRED_DIRS:
		# 使用 DirAccess.dir_exists_absolute 可直接检查 res:// 绝对路径，逻辑最直观。
		if not DirAccess.dir_exists_absolute(dir_path):
			missing.append(dir_path)

	# 返回结构化数据，后续在编辑器、单元测试或调试输出中都容易复用。
	# 字段设计说明：
	# - is_ok: 给调用方快速布尔判断（例如 if result.is_ok）
	# - missing_dirs: 给 UI/日志展示具体缺失项，便于立即修复
	return {
		"is_ok": missing.is_empty(),
		"missing_dirs": missing,
	}
