# 《文明5》卡提希娅文明Mod - 目录结构说明

## Mod名称：鸣潮-卡提希娅文明(测试中，无法正常使用)
## 作者：Mod开发者
## 版本：1.0.0

## 完整目录结构

大卡小卡/
├── ModInfo.xml                     # Mod基本信息文件
├── Core/
│   └── Civilizations/
│       └── KatishaCivilization.xml # 文明核心定义
├── Assets/
│   ├── GamePlay/
│   │   ├── XML/
│   │   │   ├── Civilizations/      # 文明XML定义
│   │   │   │   └── KatishaCivilization.xml
│   │   │   ├── Leaders/            # 领袖XML定义
│   │   │   │   └── LeaderKatisha.xml
│   │   │   ├── Units/              # 单位XML定义
│   │   │   │   ├── Unit_Katisha.xml      # 小卡单位
│   │   │   │   └── Unit_KatishaBig.xml   # 大卡单位
│   │   │   └── Buildings_Katisha.xml     # 建筑定义
│   │   └── SQL/
│   │       ├── Civilizations/      # 文明相关SQL
│   │       │   └── Katisha.sql
│   │       └── Units/              # 单位相关SQL
│   │           └── KatishaUnitForms.sql
│   └── Lua/                        # Lua脚本
│       └── KatishaUnitLogic.lua    # 主逻辑脚本
└── Database/                       # 数据库文件（预留）

## 文件功能说明

### ModInfo.xml
定义Mod的基本信息，包括名称、版本、作者等，供ModBuddy和游戏识别此Mod。

### Core/Civilizations/KatishaCivilization.xml
定义卡提希娅文明的核心属性，包括文明标识、描述、领袖关联等。

### Assets/GamePlay/XML/Leaders/LeaderKatisha.xml
定义卡提希娅领袖的属性和AI倾向，包括外交偏好、游戏风格等。

### Assets/GamePlay/XML/Units/Unit_Katisha.xml
定义小卡形态（智慧形态）的属性，作为初始开拓者单位的替代。

### Assets/GamePlay/XML/Units/Unit_KatishaBig.xml
定义大卡形态（战争形态）的属性，具备更高的战斗力和战斗技能。

### Assets/GamePlay/XML/Buildings_Katisha.xml
定义小卡驻城时的加成效果，通过虚拟建筑实现城市增益。

### Assets/GamePlay/SQL/Civilizations/Katisha.sql
定义文明、领袖、单位的多语言文本，包括描述、策略提示等。

### Assets/GamePlay/SQL/Units/KatishaUnitForms.sql
定义单位形态切换相关的数据库条目和平衡信息。

### Assets/Lua/KatishaUnitLogic.lua
实现卡提希娅单位的完整游戏逻辑，包括：
- 双形态切换系统
- 小卡城市加成系统
- 文明推演技能
- 终焉洪流AOE技能
- 动态战斗力系统
- 冷却和平衡机制

## 主要功能特性

### 1. 双形态系统
- 小卡形态（智慧）：城市支援专用，提供科研+20%、生产+25%、粮食+30%、伟人点数+25%加成
- 大卡形态（战争）：战斗专用，拥有动态战斗力和终焉洪流AOE技能

### 2. 动态战斗力系统
- 战斗力公式：35 + 0.4 × 总人口 + 2 × 城市数量（上限135）
- 每3回合更新一次，更新后保持稳定直到下次更新

### 3. 技能系统
- 文明推演（小卡）：获得当前科技30%进度，少量文化与黄金
- 终焉洪流（大卡）：前方3格扇形范围AOE攻击

### 4. 平衡设计
- 各项技能有冷却时间
- 形态切换有限制
- 战斗力有上限防止过度强大

## 安装说明

1. 将整个"大卡小卡"文件夹复制到文明5的Mods目录
2. 在ModBuddy中打开此项目
3. 编译Mod
4. 在游戏中启用"鸣潮-卡提希娅文明"Mod

## 开发原则

本Mod严格按照"可运行、可逐步扩展、适合新手维护"的原则开发，代码结构清晰，注释完整。
