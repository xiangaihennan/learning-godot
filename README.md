# learning-godot

基于 Godot 4 的 2D Roguelite（吸血鬼幸存者风格）学习型项目。  
目标是通过“边做边学”的方式，逐步完成一个可运行、可扩展、可导出的完整原型。

## 项目目标

1. 跑通一局完整流程：开始 -> 战斗 -> 升级 -> 结算 -> 重开。
2. 在实战中掌握 Godot 2D 核心能力（场景、脚本、输入、碰撞、UI、数据驱动）。
3. 建立后期扩展基础（新敌人、新关卡主题、新升级、新反馈）。

## 学习文档入口

1. 学习总纲：[study_godot.md](./study_godot.md)
2. 详细执行计划：[godot_2d_learning_plan.md](./godot_2d_learning_plan.md)
3. 提示词手册：[godot_prompt_playbook.md](./godot_prompt_playbook.md)

## 推荐学习流程

1. 打开 `godot_2d_learning_plan.md`，确定当前步骤编号。
2. 在 `godot_prompt_playbook.md` 复制对应提示词。
3. 在 Godot 编辑器完成该步骤实现与验收。
4. 记录问题与修复，完成后再进入下一步。

## 项目结构（当前约定）

```text
.
├── scenes/
├── scripts/
├── ui/
├── art/
├── audio/
├── data/
├── study_godot.md
├── godot_2d_learning_plan.md
└── godot_prompt_playbook.md
```

## 环境要求

1. Godot 4.x
2. Git
3. GitHub CLI（可选，用于仓库管理）

## 提交规范（建议）

1. `feat:` 新功能
2. `fix:` 修复
3. `refactor:` 重构
4. `docs:` 文档更新
5. `chore:` 工程杂项

## 贡献与协作

欢迎通过 Issue 提交问题、通过 PR 提交改进。  
请优先保证：

1. 修改范围清晰
2. 有最小复测说明
3. 不引入与当前学习步骤无关的大改动

