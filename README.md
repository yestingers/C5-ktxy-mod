# 卡提希娅文明 V0.1.2

这是《文明5：美丽新世界》Super Power 10.93 的最小测试版本。工程只实现：

- 可选择的 `CIVILIZATION_CARTETHYIA`
- 领袖 `LEADER_CARTETHYIA`
- 特性 `TRAIT_DUAL_RESONANCE`
- 所有城市科研与生产各提高 5%
- 首都建立后赠送一次 `UNIT_CARTETHYIA`
- 卡提希娅战斗力 30、移动力 2、视野 2、零维护且不可生产或购买

V0.1 不实现双形态、驻城加成、主动技能、AOE、冷却、复活、复杂 UI、自定义模型、动画、语音或 DDS。

## V0.1.2 加载顺序修复

- `Lua.log` 的实际错误为 SP `PopulateUniques.lua:887` 读取到空的 `trait`。
- `Database.log` 同时报告 `TRAIT_DUAL_RESONANCE` 不存在。
- SP 的 `Gameplay/SQL/Deletor.sql` 会清空 `Traits`、`Buildings`、`BuildingClasses`、
  `Units`、`UnitClasses` 及关联表。
- 旧版没有声明 SP 依赖和引用，卡提希娅数据可能先加载、再被 SP 清除。
- V0.1.2 在 `<Dependencies>` 中声明 CIV5MPDLL 47+ 与 SP 10+，并在
  `<References>` 中引用 SP，强制本模组在 SP 完成数据库重建后加载。

V0.1.1 中移除非必要 `Civilization_UnitClassOverrides`、隐藏百科单位条目的修改继续保留。

## 工程依据

知识库规则：

- XML 的每个 `Row` 对应数据库一行，同一 `Row` 不重复列。
- Type、Tag、表名、字段名和 Atlas 使用英文标识。
- XML/Lua 语法标点使用 ASCII 字符。
- 所有 `TXT_KEY` 均在 `Language_en_US` 中提供文本。
- SP 子模组必须声明依赖与引用，确保 SP 的清表重建先执行。
- 修改后需要清缓存并检查 `Database.log`、`xml.log` 和 `Lua.log`。

本机数据库验证：

- 已核对 `Civilizations`、`Leaders`、`Traits`、`Buildings`、`BuildingClasses`、
  `Building_YieldModifiers`、`Units`、`UnitClasses`、`Civilization_Leaders`、
  `Civilization_UnitClassOverrides`、`Leader_Traits`、`IconTextureAtlases` 等表的字段。
- `Traits` 没有直接的全城市科研/生产百分比字段，因此使用
  `Traits.FreeBuilding -> BUILDING_DUAL_RESONANCE`。
- 隐藏建筑通过两个 `Building_YieldModifiers` Row 提供科研与生产各 5%。
- 临时 Atlas、PortraitIndex 和基础美术引用来自本机 BNW 数据库。

运行环境：

- 必须启用 CIV5MPDLL 47+。
- 必须启用 Super Power - Rise of Hegemony 10+；本版本按本机 SP 10.93 制作。

仍需本地运行验证：

- `Traits.FreeBuilding` 是否在当前 DLL/大型整合 Mod 环境中对新建城市持续生效。
- `InGameUIAddin` 与 `Modding.OpenSaveData` 在新游戏、读档和同时启用其他 Mod 时的行为。
- 临时复用的领袖场景、文明图标、单位模型和旗帜是否正常显示。
- 与 SP 10.93 之外版本或其他大型 Mod 的兼容性。

## 文件与加载

以下文件通过 `OnModActivated -> UpdateDatabase` 按顺序加载：

1. `XML/Cartethyia_Text.xml`
2. `XML/Cartethyia_Building.xml`
3. `XML/Cartethyia_Trait.xml`
4. `XML/Cartethyia_Unit.xml`
5. `XML/Cartethyia_Leader.xml`
6. `XML/Cartethyia_Civilization.xml`

`Lua/Cartethyia_StartUnit.lua` 通过 `InGameUIAddin` 加载，并设置为
`Import into VFS = true`。XML 文件不需要 VFS 导入。

这些 ModBuddy 设置属于常见 Civ5 Mod 经验，知识库没有完整覆盖，最终以本地构建后的
`.modinfo` 和游戏日志为准。

## 本地测试

1. 在 Civ5 用户目录的 `config.ini` 中设置：

   ```ini
   [Debugging]
   EnableTuner = 1
   ValidateGameDatabase = 1
   ```

2. 关闭 DB Browser 中打开的 `Civ5DebugDatabase.db` 和 `Localization-Merged.db`。
3. 将整个 `CartethyiaCivilization` 目录复制到 Civ5 的 `MODS` 目录。
4. 清理 Civ5 用户目录下的 `cache`。
5. 启动游戏，确认 CIV5MPDLL、SP 10.93 和“卡提希娅文明 V0.1.2”均已启用。
6. 进入文明选择界面，确认完整文明列表和右侧滚动条恢复，且卡提希娅可被选择。
7. 检查文明、领袖、特性文本是否正常显示，且没有裸露的 `TXT_KEY`。
8. 建立首都，确认首都格生成一个卡提希娅单位。
9. 确认单位战斗力 30、移动力 2、零维护，且城市生产列表中无法建造。
10. 查看城市科研与生产修正，确认双生回响各提供 5%。
11. 保存并重新读取，确认不会再次生成卡提希娅。
12. 让卡提希娅死亡后保存并读取，确认不会复活。
13. 检查：

   - `Documents\My Games\Sid Meier's Civilization 5\Logs\Database.log`
   - `Documents\My Games\Sid Meier's Civilization 5\Logs\xml.log`
   - `Documents\My Games\Sid Meier's Civilization 5\Logs\Lua.log`

## 排错顺序

1. 先处理 `xml.log` 中最早的 XML 解析错误。
2. 再处理 `Database.log` 中的 `Invalid Reference`。
3. 若出现 Atlas 错误，逐字核对 Atlas、PortraitIndex 和基础游戏数据库记录。
4. 若文明列表再次中断，先检查 `.modinfo` 是否仍保留 SP 的 Dependency 和 Reference，
   再检查 `Database.log` 是否出现 `TRAIT_DUAL_RESONANCE` 缺失。
5. 若没有赠送单位，检查 `Lua.log` 是否出现脚本加载信息，并确认 Lua 是
   `InGameUIAddin` 且 VFS 为 true。
6. 若读档重复赠送，记录地图种子、玩家编号和 `Lua.log`，再调整持久化策略。
7. 每次修复后关闭数据库工具、清理缓存并重新加载 Mod。

## V0.2 建议

- 先替换文明徽记、领袖头像、黎明图和单位旗帜，再考虑复杂机制。
- 为卡提希娅制作独立单位模型前，先验证 V0.1 的数据库和读档稳定性。
- 双形态应作为独立里程碑设计，明确切换规则、状态保存和 AI 行为。
- AOE 与主动技能需要单独验证目标选择、伤害归属、城市交互和多人同步。
