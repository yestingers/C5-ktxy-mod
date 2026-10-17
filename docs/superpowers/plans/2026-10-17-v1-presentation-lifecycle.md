# v1.0 Presentation and Lifecycle Implementation Plan

> **For agentic workers:** 使用任务分工并行实施，根代理集成、验证和独立审阅。用户已直接要求完成这轮改版，无需重复请求实施批准。

**Goal:** 完成Civ5原生槽位适配、短文案、人物头像/开场/地图/技能图案、开局赠送、10回合复活、原生音乐与v1.0发布。

**Architecture:** 保留现有SP动作面板与同对象双形态；只改资源引用和原生数据。生命周期状态增加持久化复活快照，不覆盖全局UI或引入DLL。艺术通过imagegen制作，构建脚本仅做尺寸/alpha/DDS/atlas打包。

**Tech Stack:** XML/SQL/Lua5.1、DDS、Python标准库/Pillow格式打包、游戏现有音乐。

**Spec:** ../specs/2026-10-17-v1-presentation-lifecycle-design.md

## Constraints and review focus

- 世界唯一性维持每玩家一名；初始赠送不依赖城市；复活T+10、当前首都、保留经验晋升及冷却。
- 开局堵格/失败重试，死亡双事件/读档/旧死亡档迁移，无首都/首都堵格，不复制英雄或覆盖别的单位。
- 头像透明四角，地图实际槽位大小，开场右侧文字遮挡，三动作图标不同；原有模型31段动作不改。
- 沿用功能分支；旧根目录迁移不整体暂存/提交。无游戏操作权限，真人验收保持用户手动。

## Task 1 Lifecycle
Files: Lua/Cartethyia_StartUnit.lua; Tests/test_runtime.lua; optional Lua/Cartethyia_Lifecycle.lua if needed.
- [x] 为无首都初始赠送、10回合边界、复活快照/冷却、堵格与当前首都、重复回调、迁移/保存读取先写失败测试。
- [x] 实现与验证实际控制器；给根代理新增文件/API/本地依赖依据。

## Task 2 Presentation data and audio
Files: XML/Cartethyia_Text.xml, Cartethyia_Civilization.xml, Cartethyia_Unit.xml; UI/Cartethyia_Actions.lua; audio XML if necessary.
- [x] 核对本地原版/SP图像与音频契约。
- [x] 精简名称/特性短描述，保留帮助详情并更新开局/复活规则，三语言一致。
- [x] 单位头像指向人物atlas；技能atlas新名CARTETHYIA_ACTION_ATLAS，索引0切换/1神启/2裁决。
- [x] 使用原生音乐挂接并移除美国旁白；检查没有重复播放入口。

## Task 3 Art and integration
Files: Art/Source/V1/*, Art/Atlases/*, Tools/build_art.py or build_v1_art.py, XML/Cartethyia_Art.xml, manifest.
- [x] 用现有人物参考生成圆形头像、左侧人物开场、地理地图和三个可辨技能图案。
- [x] 构建全部尺寸与DDS，视觉检查透明边缘和真实UI遮挡布局。
- [x] 更新manifest version6与v1.0、资源/入口、README和验证记录。

## Task 4 Verify and release
- [x] 运行Tests/validate_all.py，包含实际Lua、数据库、atlas/音频引用。
- [x] 独立复核生命周期与UI集成，修正实质问题。
- [x] 打包并逐文件SHA256验证；游戏退出时备份后安装。
- [ ] 人工验收由用户在游戏内完成，未测项目明确保留。
