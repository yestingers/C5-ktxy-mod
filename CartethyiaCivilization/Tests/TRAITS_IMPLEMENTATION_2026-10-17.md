# 双形态特性实现记录

Plan: docs/superpowers/plans/2026-10-17-dual-form-traits.md
Spec: docs/superpowers/specs/2026-10-17-cartethyia-traits-design.md（用户已批准执行）

## 基线与执行方式

- 功能分支 codex/dual-form-traits；保留旧根目录迁移形成的工作区状态，不盲目暂存历史目录。
- 备份 artifacts/backups/Traits-before-20261017.zip，70 个运行文件逐一 SHA256 验证。
- 开工基线 validate_v02.py 的7项检查、validate_model.py 的4项检查通过。
- 使用本机游戏 lua51_Win32.dll 与 x86 C# host 实际执行 Lua 5.1；测试宿主只供本地验证，不进入发布包。
- 主执行者实现规则/控制器，独立代理并行完成XML数据与UI，最后统一集成和独立审阅。
- 采用同一个 UNIT_CARTETHYIA 对象切换形态，不创建替代英雄；旧档已有英雄迁移为力量形态，新游戏从智慧形态开始。

## 进度

- Task 1 RED：Tests/test_traits.lua 在缺少规则模块时按预期失败。
- Task 1 GREEN：真实 Lua5.1 规则测试通过，十时代战力与形态比例、动作互斥、20/5回合冷却、射线边界与去重。
- Task 2 数据：三类隐藏建筑、六项晋升（五项力量专属与永久身份保护）、三语言全部完成；7项数据测试通过。
- Task 3 控制器：真实控制器与安装SP SaveUtils共同执行通过，涵盖旧英雄/阵亡旧档、两种技能、伤势/经验/通用晋升、序列化后冷却/行动锁、首都迁移、城市转手、敌友/隐藏目标和失败生产回滚。
- Task 4 UI：三个SP动作、右侧状态面板、六方向预览与施放完成；回合/选择/城市界面/取消路径通过Lua烟雾检查。
- 全套命令 `python Tests/validate_all.py` 通过：3组真实Lua5.1、10项数据/发布Python测试、4项模型回归；135行玩法XML+模型SQL和288行三语言文本在安装依赖schema上重复加载通过。
- 上述套件中的3条 injected failure 日志为故意注入的异常恢复测试，不是常规运行报错。

## 独立代码审阅与修复

独立审阅未发现Critical；Important为引擎异常可能遗留executing/syncing锁。先补错误注入测试，确认旧实现失败，再统一加入受保护执行与锁释放。部分伤害保留已消费状态；明确未完成的生产恢复原进度、行动与冷却。修复后完整套件通过。

审阅的文档项已落实：裁决是带英雄玩家/单位来源的直接伤害，不额外授予普通战斗经验或主动模拟普通战斗事件；原生死亡/伤害钩子的SP联动需实测。AI本轮使用被动和默认智慧形态，主动切换与技能策略留待后续。

## 接口与实现选择

- 旧英雄迁移为力量形态，新英雄从智慧形态开始；不替换单位，原始经验、伤势和通用晋升天然保留。
- SaveUtils显式cacheState=0读写Player独立命名空间，且继续使用CARTETHYIA_V02的START_UNIT_GRANTED键。
- 本机DLL/PDB已核验 GetNumAttacksMadeThisTurn、SetBaseCombatStrength、SetMadeAttack及ChangeDamage(damage,ownerID,unitID)。
- PopOrder的三个参数为iNum,bFinish,bChoose，但本机Lua封装要求数字标记，实际调用为PopOrder(0,1,1)。会CreateUnit/Building/Project并触发完成奖励链，返回值不作为成功凭证。实现只补足当前生产成本，单次PopOrder，通过完成事件/实际数量变化确认；不清零已有溢出。
- CustomModOptions启用资本变化、预死亡、时代、命令、升级、城市及城邦交互事件；UnitSetXY与界面dirty作为即时同步入口，保留回合兜底。
- 为保护唯一英雄，禁止赠送、解散、常规升级、被俘和编军团；登船保留同一英雄，但禁止在海上切换/施放。

## 发布与安装

V0.3.0 Alpha，modinfo version5，同一Mod UUID；依赖最低DLL62。

- 发布包：artifacts/CartethyiaCivilization_DualForms_2026-10-17.zip，内部目录 CartethyiaCivilization_V0.3，共77个运行文件，ZIP完整性与逐文件SHA256均通过。
- 安装前备份：artifacts/backups/Installed-before-traits-20261017-111009.zip，原安装目录70个文件逐一验证。
- 已在游戏关闭时更新原安装目录 `C:/Users/hunxi/Documents/My Games/Sid Meier's Civilization 5/MODS/CartethyiaCivilization_V0.2`，保留文件夹名称以避免重复Mod UUID；游戏内名称为“卡提希娅文明 V0.3.0 Alpha”。未修改存档或其他模组。
- 安装后77个文件与发布清单的SHA256全部一致。安装回执：artifacts/DualForms_install_receipt_2026-10-17.json。
- 游戏内验收仍待用户手动完成，清单见README；未将离线通过标为游戏实测通过。

## 验证边界

离线 Lua 使用真实游戏 Lua 5.1 解释器，但 Civ5 对象及事件由测试替身提供；不代表真实游戏存读档、Lua跨上下文事件、战斗预览或项目完成已验收。游戏内由用户按先前选择手动验证。

## 首轮实测：神启敕令参数修复

用户报告点击后产出、行动、冷却均不变，截图显示智慧形态、2/2移动、冷却0且“可以使用”。本机Logs/Lua.log第1240—1266行反复记录：`bad argument #2 to 'PopOrder' (number expected, got boolean)`。这是已进入生产完成路径后的Lua参数错误，不是玩家前提条件遗漏；已有回滚恢复了生产、行动和冷却。

根因：控制器将原生C++布尔标记直接作为Lua布尔值传入，而实际Lua绑定要求数字。原离线替身接受任意真值，未暴露接口契约错误。先收紧PopOrder测试边界为数字标记，原实现按预期在生产完成断言失败；再仅将调用改为`PopOrder(0,1,1)`，完整validate_all.py通过（3组Lua、14项Python及数据库加载）。补丁不改变技能条件、冷却、存档格式或Mod版本；真实游戏完成与奖励链仍待复测。

独立只读复核进一步核对本机DLL/PDB：`CvLuaCity::lPopOrder`入口VA 0x10361ba0，0x10361c2a—0x10361c42对Lua栈3/4使用`luaL_optinteger`读取完成/选择标记，再以非零值转换为布尔值，与报错一致。修正版发布包为`artifacts/CartethyiaCivilization_DualForms_EdictFix_2026-10-17.zip`，77个文件通过哈希验证。

用户确认保存退出后，于2026-10-17 11:59（Asia/Shanghai）完成补丁安装。安装前完整备份77个文件至`artifacts/backups/Installed-before-edictfix-20261017-115954.zip`；安装后77个文件与修正版清单SHA256一致，未改存档。回执为`artifacts/DualForms_EdictFix_install_receipt_2026-10-17.json`。下一步由用户在原测试存档中复测真实生产完成、行动与冷却。

### 用户复测结果

2026-10-17，用户明确反馈“神启敕令现在可以正常使用了”。据此将原“点击无效果”缺陷标为用户游戏内复测通过。用户未逐项报告建造类型、队列溢出、各速度冷却或特殊完成奖励，不将该反馈扩展为所有边界均已通过。

接下来优先验证双形态切换与行动限制、首都/普通城市的六项收益及撤销、裁决之风的射线/伤害/敌友筛选，再检查存读档后形态与冷却是否保持。上述核心验收稳定后推进两形态独立外观、优雅动作、技能特效和差异化图标。
