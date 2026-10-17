# v1.0 界面与生命周期执行记录

对应规格：docs/superpowers/specs/2026-10-17-v1-presentation-lifecycle-design.md。用户要求的改版直接实施，音乐选择已明确为游戏自带。

## 完成内容

- XML文明名启明之国、领袖卡提希娅；Mod显示卡提希娅—启明之国 v1.0，内部version6，同UUID。保留原生组合标题规则，不覆盖SP全局UI。
- 头像改为本人圆形透明头像，6尺寸，单位使用人物atlas；文明/旗帜保留原徽章。
- 地图360×412，适配原生360×410槽位；开场1024×768，人物在左、右侧低细节供面板覆盖。来自内置imagegen的六张源图在Art/Source/V1。
- 三动作分别为双向环流/书卷/风刃，64/45/32三列atlas，索引0/1/2。
- 三语言选择页说明3短行；数值和生命周期完整规则保留帮助/百科。
- SoundtrackTag=England，开场AS2D_LEADER_MUSIC_ELIZABETH_PEACE；复用本机音频，不加入新的播放器或音频拷贝。
- 新局未建首都也赠送智慧英雄；永久死亡改为T+10当前首都复活。快照保存名称、百分之一经验、等级、通用晋升与绝对冷却；保留新生智慧形态、满血和当回合行动锁。
- 无首都、首都被占/堵格顺延；旧死档一次迁移为等待10回合；重读不复制；延迟死亡双回调和单位ID复用不破坏快照。

## 验证

- 修改前备份 artifacts/backups/Before_V1_20261017.zip，77个文件校验。
- 图片回归先复现旧头像alpha255、地图512×512和无独立动作atlas的问题，修改后3项通过。
- 数据/展示6项先红后绿，包含实际Lua动作注册、本机音频定义及文件解析。
- 生命周期先红后绿；本机DLL/PDB核对Prekill早于deleteUnit、经验百分之一读写与真实回合移动重置。证据 artifacts/v1_lifecycle_api_evidence.txt，结果 artifacts/v1_lifecycle_result.md。
- 根代理与独立审阅均实际执行Tests/validate_all.py通过：3组Lua、19项Python数据/展示/资源、4项模型，138行玩法XML及模型SQL和288条三语言文本两次加载通过。
- 独立审阅 artifacts/v1_review.md：无Critical/Important；建议后续补充更多临时晋升字段回归。

## 范围与验收边界

本轮未改模型或第二形态外观，AI主动策略仍为后续工作。v1.0不代表游戏内所有项目已验收；开局、死亡复活、读档堵格、不同分辨率显示与开场音乐停止均需用户手动验证。原神启参数修复保留，用户此前已确认正常。

## 发布

已生成`artifacts/CartethyiaCivilization_V1.0_2026-10-17.zip`，80个运行文件逐一SHA256校验通过。游戏关闭后于2026-10-17 13:10（Asia/Shanghai）原位安装，游戏内显示“卡提希娅—启明之国 v1.0”，安装目录仍为原CartethyiaCivilization_V0.2以避免重复UUID。

更新前77个文件完整备份到`artifacts/backups/Installed-before-v1-20261017-131028.zip`，未修改存档或其他模组。安装后80个文件与发布清单一致；回执为`artifacts/V1_install_receipt_2026-10-17.json`。实际游戏验收仍待用户进行。
