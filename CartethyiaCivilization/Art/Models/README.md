# 卡提希娅 3D 单位模型（Civ5 转换源）

此目录包含以用户提供的 `卡提希娅（修模绑骨后）/卡提希娅.pmx` 制作的 Civilization V 单位模型转换源。

## 文件

- `Cartethyia_Civ5_Standalone.blend`：推荐直接打开的 Blender 工作文件，含独立场景、骨架、降面网格和 24 张内嵌贴图。
- `Cartethyia_Civ5_Source.blend`：转换时生成的 Blender 库文件；需要将集合追加到其他工程时使用。
- `Cartethyia_Civ5_Source.fbx`：供 Nexus Buddy/GR2 转换流程使用的 FBX 交换文件。
- `Cartethyia_Civ5_Source.glb`：网格与骨架检查文件。2026-10-17 回读确认没有 images、textures 或动画，不能作为带贴图的完整备份；贴图以 Standalone.blend 内嵌资源为准。
- `Cartethyia_Civ5.gr2`：2026-07-30 生成的旧导出文件（791,148 字节），保留原样。2026-10-17 回读发现 794 根骨骼、0 材质、0 动画，不能直接复用长剑士动画；用户确认旧模型未成功在游戏中显示。
- `Cartethyia_Civ5_Preview.png`：降面后材质、比例和轮廓的渲染检查图。

## 已完成的适配

- 仅保留可渲染的角色主网格；排除了 606 个隐藏的 MMD 物理碰撞体。
- 三角面数从 93,985 降至 32,894，顶点数为 31,859。
- 删除 MMD 表情键以及 `mmd_edge_scale`、`mmd_vertex_order` 专用顶点组。
- 每个顶点的骨骼影响已限制为最多 4 个并重新归一化。
- 保留了 UV、32 个材质槽、骨骼绑定与原有贴图引用，供后续重定向动画时使用。

## 2026-10-17 游戏候选资产

后续状态：用户已确认首版模型在游戏中显示。最新候选将显示比例提高 50%，保持单人，新增 `Game/Animations/` 下 31 段挺立垂剑等调整后的动画。详见 `../../Tests/MODEL_STYLE_2026-10-17.md`；下方说明记录首次网格转换。

`Game/Cartethyia_Unit.gr2` 是本次新生成的候选模型，不覆盖旧源文件。通过本机 Nexus Buddy 2.5.3/Firaxis Granny 工具链生成，并回读验证：20,679 顶点、22,378 三角面、27 根原版长剑士骨骼、1 个蒙皮材质，每个顶点最多 4 个影响且整数权重合计 255。角色使用合并的 2048×2048 DDS 贴图，持剑网格取自本机原版长剑士参考。

`Game/Cartethyia_Unit.fxsxml` 关联游戏自带长剑士动作。`SQL/Cartethyia_UnitArt.sql` 定义单人队形，XML 引用 `ART_DEF_UNIT_CARTETHYIA`；GR2、FXSXML 和两张 DDS 均登记为 VFS 资源。PNG、BR2 和 audit.json 仅用于开发检查，不装入游戏包。

转换时仅在派生网格中去掉重叠的 MMD 高光/表情层，避免遮挡脸部和头发。头发跟随头部、裙摆跟随骨盆；布料物理和自定义动作不在本次范围内。

动画预览采用实际导出 GR2 回读网格与 Firaxis SampleBone 采样矩阵，覆盖待机 181 帧、跑动 21 帧、近战攻击 41 帧。它仍不能代替 Civ5 引擎实测；游戏内验收由用户继续进行。

历史恢复检查见 `../../Tests/PROJECT_STATUS_2026-10-17.md`，本次实现及验证见 `../../Tests/MODEL_INTEGRATION_2026-10-17.md`。
