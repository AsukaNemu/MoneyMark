# MoneyMark 💰

**iOS 智能自动记账应用** — 让记账像拍照一样简单

## 功能特色

### 🎯 自动记账（核心功能）
- **截图 OCR 识别**：支付完成后截图，AI 自动识别金额、商户、时间
- **快捷指令集成**：双击手机背面 / Siri 语音触发记账
- **AI 智能分类**：自动匹配消费分类，准确率 85%+
- **支持平台**：支付宝、微信支付、云闪付

### 📝 手动记账
- 支出/收入/转账/退款 多类型支持
- 15+ 一级分类、50+ 二级分类
- 自定义分类和图标
- 多账户管理（现金/银行卡/信用卡/电子钱包）

### 📊 统计报表
- 支出分类饼图
- 收支趋势折线图
- 分类排行柱状图
- 按日/周/月/年多维度分析

### 💳 账单导入
- 微信账单 CSV 一键导入
- 支付宝账单 CSV 一键导入
- 自动识别账单平台

### 🎯 预算管理
- 月度/年度总预算
- 分类预算精细控制
- 日均预算动态计算
- 超支提醒

### 🔒 隐私安全
- OCR 识别完全在设备本地处理
- AI 分类前自动脱敏敏感信息
- Face ID / Touch ID 应用锁
- 数据本地存储 + iCloud 加密同步

## 技术架构

- **语言**：Swift 5.9+
- **UI 框架**：SwiftUI
- **数据持久化**：SwiftData
- **云同步**：CloudKit
- **OCR 识别**：Apple Vision Framework
- **图表**：Swift Charts
- **快捷指令**：App Intents Framework
- **最低系统**：iOS 16.0

## 项目结构

```
MoneyMark/
├── App/                          # App 入口
│   └── MoneyMarkApp.swift
├── Core/
│   ├── Models/                   # 数据模型
│   │   ├── Transaction.swift     # 账单
│   │   ├── Category.swift        # 分类
│   │   ├── Account.swift         # 账户
│   │   └── Budget.swift          # 预算
│   ├── Repositories/             # 数据仓库
│   ├── Services/                 # 核心服务
│   │   ├── OCRRecognitionService.swift   # OCR 识别
│   │   ├── ReceiptParser.swift           # 账单解析
│   │   ├── AIClassificationService.swift # AI 分类
│   │   ├── BillImportService.swift       # 账单导入
│   │   └── StatisticsService.swift       # 统计分析
│   └── Intents/                  # App Intents
│       └── AutoBookkeepingIntent.swift
├── Features/
│   ├── Transaction/              # 手动记账
│   ├── AutoBookkeeping/          # 自动记账
│   ├── Statistics/               # 统计报表
│   ├── Budget/                   # 预算管理
│   ├── Account/                  # 资产管理
│   ├── Import/                   # 账单导入
│   └── Settings/                 # 设置
├── Shared/
│   ├── Components/               # 通用 UI 组件
│   ├── Extensions/               # Swift 扩展
│   └── Utils/                    # 工具类
└── Resources/                    # 资源文件
```

## 开发环境

1. Xcode 15.0+
2. iOS 16.0+ 部署目标
3. Swift 5.9+

## 使用方式

1. 在 Xcode 中打开 `MoneyMark.xcodeproj`
2. 选择 iOS 模拟器或真机设备
3. Build & Run (⌘R)

## 竞品对标

| 功能 | MoneyMark | 钱迹 | 一木记账 | 可乐记账 |
|------|-----------|------|----------|----------|
| 截图 OCR | ✅ | ✅ | ✅ | ✅ |
| 快捷指令 | ✅ | ✅ | ❌ | ❌ |
| AI 分类 | ✅ | ✅ | ❌ | ✅ |
| 本地优先 | ✅ | ✅ | ✅ | ❌ |
| 无广告 | ✅ | ✅ | ✅ | ❌ |
| 免费核心功能 | ✅ | 部分 | ✅ | 部分 |

## License

MIT License
