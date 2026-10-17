# Dual Form Traits Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 交付已批准的启明之国、双形态英雄、十时代成长、专属晋升及两个主动技能的可安装试玩版本。

**Architecture:** 保持原 UNIT_CARTETHYIA 对象，以持久化形态、动态基础战力和形态专属晋升实现切换，避免替换单位丢失伤势、经验和晋升。城市效果由三种隐藏建筑同步；纯 Lua 规则与游戏适配分离。使用 SP UnitPanelAddin 扩展技能入口，不覆盖原版或 SP 面板。

**Tech Stack:** Civ5 BNW XML/SQL/Lua 5.1；本机 CIV5MPDLL 62 / Super Power 10FF；Python 标准库和游戏 Lua 5.1 用于离线验证。

**Spec:** ../specs/2026-10-17-cartethyia-traits-design.md，用户已于本轮批准执行。

## Global Constraints

- 六种城市产出仅 FOOD、PRODUCTION、GOLD、SCIENCE、CULTURE、FAITH。全国科文产 +10%，首都总计 +20%；辅政六项各 +10、+30%。
- 力量基础战力按 SP 十时代为 30/40/55/75/100/130/170/220/300/400，智慧为 20%；力量 3 移动、智慧 2 移动。
- 切换和技能耗尽剩余行动，攻击后不可切换；不恢复生命、攻击或冷却。智慧技能标准20回合、力量技能5回合。
- 直线三格70/60/50%最大生命伤害，忽略隐藏和非交战目标，城市与平民不受损。
- 只更新开发目录 CartethyiaCivilization；历史快照不动。保存备份和发布包，不自动重写现有存档。

## Review Focus

- 旧档已赠送但英雄阵亡：不能补发；旧英雄迁移保持损伤、经验和晋升。
- 切换、技能和普通攻击同回合串用：共享行动标记与实际单位攻击状态都检查。
- 城市交易、首都迁移、离城和死亡：撤销失效加成，不能留永久产出。
- 队列只有一项/奇观竞争/持续转换：立即完成真实项目、不给溢出、不误消耗技能。
- 地图边缘、隐形目标、环绕重复格：预览和伤害同一射线，命中去重，不泄露隐藏单位。

## Task 1 规则与实际 Lua 测试

Files: create Lua/Cartethyia_Rules.lua, Tests/test_traits.lua, Tests/run_lua_tests.py; helper Tests/native_lua_host.cs if no local Lua runner.
Interfaces: CartethyiaRules.Strength(eraType,form), Ready(state,action,turn), CanAct(state,context,action), Commit(state,action,turn,wisdomCooldown), Ray(origin,direction,nextPlot), Damage(maxHP,distance).

- [x] 写失败测试：十时代与20%比例、未知时代拒绝、冷却T+20/T+5、跨形态不重置、无行动/已攻击/重复操作拒绝、射线三格/边界/环绕去重。
- [x] 执行 Lua 测试确认缺少规则功能。
- [x] 实现纯 Lua 规则，不引用游戏 globals。
- [x] 测试全部通过，记录真实 Lua 执行结果。

## Task 2 数据与本地化

Files: modify XML/Cartethyia_Building.xml, XML/Cartethyia_Unit.xml, XML/Cartethyia_Text.xml; create XML/Cartethyia_Promotions.xml; update manifest.
Interfaces: BUILDING_DUAL_RESONANCE (base10), BUILDING_CARTETHYIA_CAPITAL (extra10), BUILDING_CARTETHYIA_WISDOM (six10+30); five PROMOTION_CARTETHYIA_*; unchanged UNIT_CARTETHYIA.

- [x] 在临时数据库/结构检查中添加期望值与缺失数据失败检查。
- [x] 实现三个隐藏建筑、五个专属晋升、初始智慧战力6、三语言完整特性/技能/失败原因文本。
- [x] 数据库加载验证并检查无文本遗漏；模型回归保持通过。

## Task 3 游戏状态与技能控制器

Files: replace Lua/Cartethyia_StartUnit.lua; add Tests/test_runtime.lua with mocked Civ engine boundary (execute actual controller).
Interfaces: LuaEvents.CartethyiaQuery(playerID,unitID,out), LuaEvents.CartethyiaCommand(playerID,unitID,action,direction), LuaEvents.CartethyiaChanged; controller supplies state, reasons, cooldowns and ray preview coordinates.

- [x] 先写英雄迁移、死亡不补发、城市收益撤销、技能/切换互斥、可见敌军命中和建造完成测试并运行失败。
- [x] 保留旧 SaveUtils granted 标记兼容，新增独立持久化形态/CD/本回合动作标记；同对象动态战力与晋升。
- [x] 同步城市与时代，事件触发立即更新并用回合/有限UI dirty兜底；初始化不推进冷却。
- [x] 实现两个技能，生产完成使用本地已验证API；伤害带攻击方归属，先快照后伤害避免死亡修改迭代器。
- [x] 运行实际Lua控制器测试；记录引擎边界仍需实测的项目。

## Task 4 技能面板与发布

Files: UI/Cartethyia_Actions.lua (+ XML方向选择界面若需要), manifest, README, Tests/TRAITS_IMPLEMENTATION_2026-10-17.md; package_candidate.py versioned folder option.

- [x] 写UI事件注册与按钮调用烟雾测试、所有文件VFS/入口/文本引用验证。
- [x] 注册切换、智慧技能、战争方向预览与执行按钮，显示不可用原因和冷却。
- [x] 更新版本为 V0.3.0 Alpha，manifest version5；生成备份与可验证发布包。
- [x] 新鲜上下文独立代码审阅；修复影响行为的问题并补回归。
- [x] 完成离线验证；游戏关闭时备份安装目录后部署，并核对安装后77个文件的SHA256。
- [ ] 用户进行真实游戏内验收（此前已选择手动验证）；不以离线测试代替。

## Execution Record

执行记录保存在 Tests/TRAITS_IMPLEMENTATION_2026-10-17.md。本仓库旧根目录迁移尚未整理，采用功能分支和完整发布包备份，不为本次玩法把所有历史变更一并提交。任务实现和验证通过后勾选步骤；离线模拟不代替真实游戏验收。
