# 卡提希娅模型接入 Implementation Plan

> **For agentic workers:** Use executing-plans to implement task-by-task.

**Goal:** 让现有卡提希娅角色在 Civ5 中正常显示、移动、近战攻击。
**Architecture:** 保留 V0.2 玩法及原始源文件，检查 GR2；以游戏长剑士骨架/动画作为适配基准，生成独立的游戏用模型、贴图、FXSXML 和 ArtDefine。使用模型回读、动画预览、数据库模拟和游戏内观察分别验证。
**Tech Stack:** Blender 4.4.3、Nexus Buddy 2.5.3/Firaxis Granny、Python、Civ5 XML/SQL。
**Spec:** 用户 2026-10-17 指令及 `CartethyiaCivilization/Tests/PROJECT_STATUS_2026-10-17.md`。

## Global Constraints
- 保留原始 Standalone.blend、已有 GR2、V0.2 发布快照与存档。
- 不更改单位数值或引入双形态。
- 不以离线通过冒充游戏内通过。
- 当前开发成果未提交，直接在现有目录工作，新增资产使用独立命名。

## Review Focus
- 模型材质中的路径必须解析到实际加载的 DDS。
- 骨骼名/绑定姿态必须匹配所引用动画，不能只验证有动画文件。
- 显示比例、朝向、脚底位置和攻击动作需可视检查。
- 每个模型与贴图都必须登记到 VFS，数据库引用必须完整。
- 发布包不得包含本机工具 DLL、游戏提取参考文件或开发缓存。

## Tasks
- [x] 1. 读取现有 GR2，提取原版长剑士参考模型/动画至本地开发缓存，记录真实骨架和材质。
- [x] 2. 生成独立的角色游戏资产；回读顶点、权重、材质；预览待机/移动/攻击动作。
- [x] 3. 添加验证加载链路的集成测试，先观察当前失败，再补齐 FXSXML、ArtDefine 和 modinfo，运行现有回归检查。
- [x] 4. 制作安装候选包，游戏内检验显示、移动、攻击，记录结果和任何未完成的项目。用户于 2026-10-17 对姿态改进版反馈“刚刚测试了一下，基本正常”；按该反馈完成基础阶段，未逐项确认的死亡衔接等边界记录在 `CartethyiaCivilization/Tests/MODEL_STYLE_2026-10-17.md`。

## Execution Notes
- 用户已明确授权按上述目标继续；在当前聊天内执行，不再请求重复批准。
- Git 仍跟踪旧根目录布局，不在此任务中整体暂存既有目录迁移。

