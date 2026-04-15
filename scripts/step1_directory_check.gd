extends RefCounted
class_name Step1DirectoryCheck

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
	var missing: PackedStringArray = []

	for dir_path in REQUIRED_DIRS:
		# 使用 DirAccess.dir_exists_absolute 可直接检查 res:// 绝对路径，逻辑最直观。
		if not DirAccess.dir_exists_absolute(dir_path):
			missing.append(dir_path)

	# 返回结构化数据，后续在编辑器、单元测试或调试输出中都容易复用。
	return {
		"is_ok": missing.is_empty(),
		"missing_dirs": missing,
	}
