# 卡提希娅模型接入候选版 — 2026-10-17

状态：已生成、接线并安装；离线验证通过，用户正在游戏内手动验收。不能视为游戏内验证完成。

## 实现

- 旧 GR2 有 794 根骨骼、没有材质，保留原样。新模型从 Standalone.blend 的内嵌贴图和网格生成。
- 新模型使用原版长剑士的 27 根骨骼、绑定矩阵、蒙皮着色器和动画链；20,679 顶点、22,378 三角面、一个材质。
- 删除派生网格中重叠的 MMD 高光/表情层，合并为 2048×2048 DXT5 色彩贴图和 64×64 DXT5 高光贴图，添加原版剑网格。
- `SQL/Cartethyia_UnitArt.sql` 建立专属 ArtDefine，单位数量为 1。`.modinfo` 导入 GR2、FXSXML 和两张 DDS，并执行 SQL。
- 单位数值、赠送逻辑和原始模型未改。头发和裙摆仅随骨骼运动，没有独立布料物理。

## 验证证据

- 原有离线验证：7 项通过。
- 模型集成验证：3 项通过；涵盖实际文件哈希、Granny 回读、材质、骨骼、权重、VFS、FXSXML 动作事件和真实数据库结构中的引用链。
- 数据库临时副本模拟：108 条玩法行、120 条语言行通过，未修改游戏数据库。
- Firaxis SampleBone 采样待机 181 帧、跑动 21 帧、近战攻击 41 帧。实际序列化 GR2 回读网格全帧计算没有非有限坐标或异常膨胀；每段渲染三个关键帧进行目视检查。
- 独立只读代码复核：未发现确定的严重问题；确认序列化骨架名称、层级、绑定数值与原版完全一致，FXSXML 保留原版动作链。复核运行 3 项模型测试通过。
- 上述预览来自 Blender，不是 Civ5 游戏截图。引擎的透明度、世界比例、资源加载和完整战斗播放仍须游戏内验收。

## 安装与回退

已安装到 `Documents/My Games/Sid Meier's Civilization 5/MODS/CartethyiaCivilization_V0.2`，模组列表名称仍为“卡提希娅文明 V0.2”。安装前目录完整备份到工作区 `artifacts/backups/V0.2-before-model-20261017`。原 V0.2 发布目录和 ZIP 未覆盖，游戏存档未改动。

回退时退出游戏，将当前已安装模组目录移出 MODS，再把备份恢复为同名目录；不要同时启用相同 UUID 的两份模组。

## 游戏内验收（待用户结果）

1. 从“模组”入口启用 CIV5MPDLL、Super Power 与卡提希娅文明，开新局。
2. 建立首都，推进一回合；确认赠送白发蓝裙单人角色，记录脚底、大小和贴图。
3. 移动一格，检查移动中的肢体和停下后的姿势。
4. 对蛮族近战攻击，检查挥剑、转向、收招、伤害结算和下一步操作。
5. 另行检查死亡、存读档与旧 V0.2 功能清单。

Steam 已由用户登录；电脑操作工具拒绝访问 CivilizationV 窗口，用户选择手动实测。等待实际结果后更新本文，不能将未测项标为通过。

## 开发工具与复现顺序

工具源文件在 `Tools/`；本机工具 DLL、游戏参考资源与中间文件均位于忽略目录 `Tools/ModelWork/`，不进入安装包。

1. 参考文件从本机游戏 `Resource/Common/UnitModels.fpk` 提取到 `ModelWork/reference/`：长剑士 GR2/FXSXML/动画和 `unitmodels_stringdatabase.gsd`。
2. `inspect_gr2.cs` 编译为 x86 程序，引用本机 Nexus Buddy 2.5.3 的 Firaxis DLL；导出参考 BR2 和待机/跑动/攻击 NA2。采样必须保留完整帧序列。
3. Blender 4.4.3 后台打开原 Standalone.blend，执行 `prepare_game_model.py`，生成派生 BR2、PNG 贴图和预览工程。
4. `convert_game_model.cs` 编译为 x86，引用同一套库与 NexusBuddy2.exe，依次传入字符串库、原版模型、派生 BR2、输出 GR2。保存后使用另一路径重新加载以验证序列化结果。
5. Pillow 将 PNG 转为 DXT5 DDS；用诊断程序回读新 GR2 为 BR2；Blender 执行 `preview_game_animations.py` 检查真实动画采样。
6. 运行离线测试，用 `Tools/package_candidate.py` 按 `.modinfo` 白名单打包；不复制整个开发目录。

Nexus Buddy 参考源码：https://github.com/deliverator23/Nexus-Buddy-2 。原版参考资产只从本机游戏读取，不包含在候选包中。
