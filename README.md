# 卡提希娅—启明之国 v1.0

《文明5：美丽新世界》Super Power 子模组。卡提希娅可以在辅助城市发展的智慧形态与上场作战的力量形态之间切换。

## 下载与安装

[下载 v1.0 安装包](https://github.com/yestingers/C5-ktxy-mod/raw/refs/heads/master/releases/CartethyiaCivilization_V1.0_2026-10-17.zip)

需要 Windows 版《文明5：美丽新世界》、CIV5MPDLL 62 和 Super Power - Rise of Hegemony 10FF。目前支持单人游戏。

1. 退出游戏，将旧版卡提希娅模组移出 MODS 目录，避免重复加载同一个模组 ID。
2. 解压安装包，将其中的 `CartethyiaCivilization_V1.0` 文件夹放入 `文档/My Games/Sid Meier's Civilization 5/MODS/`。
3. 在游戏的“模组”菜单启用前置模组和本模组，再进入游戏。

## 本版内容

- 启明之国：所有城市科研、文化、生产力 +10%，当前首都合计 +20%。
- 圣女的双生誓约：智慧形态驻己方城市时，六项基础产出各 +10，并额外 +30%；力量形态拥有 3 点移动力、随时代提升的战力和特殊晋升。
- 神启敕令立即完成城市当前建造；裁决之风攻击直线三格敌军。切换消耗剩余行动，不能借切换恢复生命或刷新攻击。
- 开局赠送唯一英雄；阵亡 10 回合后在当前首都复活。
- 独立人物模型与动画、圆形人物头像、独立技能图标、新地图与载入背景，以及游戏自带音乐。

[详细玩法与兼容说明](CartethyiaCivilization/README.md) · [设计文档](docs/superpowers/specs/) · [测试记录](CartethyiaCivilization/Tests/V1_IMPLEMENTATION_2026-10-17.md)

## 源码与验证

当前项目位于 `CartethyiaCivilization/`，可直接安装的成品包位于 `releases/`。历史版本保留在 Git 历史中。

发布前已通过 Lua 规则、运行时与 UI 测试、数据与资源验证；作者手动试玩暂未发现问题。手动试玩不等于所有边界场景均已覆盖。

`Tests/validate_all.py` 为本地验证入口；部分测试依赖本机游戏安装路径、Super Power 数据库和游戏 Lua 运行库，不能在未配置依赖的环境直接运行。仓库包含资源构建脚本和美术输入；完整 3D 重建还需要本地 Blender、Nexus Buddy/Firaxis 工具链及参考数据。

安装包 SHA-256：`961ae45abab3d8bd89539ec78ff6307fc817f78a7a2a68a5a2a3ac4e61bba44f`。
