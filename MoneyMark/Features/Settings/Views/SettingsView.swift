import SwiftUI

/// 设置视图
struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode = 0
    @AppStorage("monthStartDay") private var monthStartDay = 1
    @AppStorage("currencySymbol") private var currencySymbol = "¥"
    @AppStorage("enableFaceID") private var enableFaceID = false
    
    @State private var showExportSheet = false
    @State private var showAbout = false
    
    var body: some View {
        NavigationStack {
            List {
                // 外观设置
                Section("外观") {
                    Picker("主题模式", selection: $appearanceMode) {
                        Text("跟随系统").tag(0)
                        Text("浅色").tag(1)
                        Text("深色").tag(2)
                    }
                }
                
                // 记账设置
                Section("记账设置") {
                    Stepper("每月起始日: \(monthStartDay)日", value: $monthStartDay, in: 1...28)
                    
                    HStack {
                        Text("货币符号")
                        Spacer()
                        TextField("¥", text: $currencySymbol)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }
                
                // 安全设置
                Section("安全") {
                    Toggle(isOn: $enableFaceID) {
                        HStack {
                            Image(systemName: "faceid")
                            Text("Face ID 锁定")
                        }
                    }
                }
                
                // 数据管理
                Section("数据管理") {
                    NavigationLink {
                        CategoryManageView()
                    } label: {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                            Text("分类管理")
                        }
                    }
                    
                    Button(action: { showExportSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("导出数据")
                        }
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "icloud")
                            Text("iCloud 同步")
                        }
                    }
                }
                
                // 自动记账设置
                Section("自动记账") {
                    NavigationLink {
                        AutoBookkeepingSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.viewfinder")
                            Text("自动记账设置")
                        }
                    }
                    
                    NavigationLink {
                        ShortcutsGuideView()
                    } label: {
                        HStack {
                            Image(systemName: "command")
                            Text("快捷指令配置")
                        }
                    }
                }
                
                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: { showAbout = true }) {
                        HStack {
                            Text("关于 MoneyMark")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

/// 分类管理视图
struct CategoryManageView: View {
    @Query(filter: #Predicate<Category> { !$0.isArchived && $0.parentId == nil },
           sortBy: [SortDescriptor(\.sortOrder)])
    private var rootCategories: [Category]
    
    @Query(filter: #Predicate<Category> { !$0.isArchived && $0.parentId != nil },
           sortBy: [SortDescriptor(\.sortOrder)])
    private var childCategories: [Category]
    
    var body: some View {
        List {
            Section("支出分类") {
                ForEach(rootCategories.filter { $0.typeRawValue == TransactionType.expense.rawValue }, id: \.id) { category in
                    DisclosureGroup {
                        ForEach(childCategories.filter { $0.parentId == category.id }, id: \.id) { child in
                            HStack {
                                Image(systemName: child.icon)
                                    .foregroundColor(AppColor.primary)
                                Text(child.name)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(AppColor.primary)
                                .frame(width: 28)
                            Text(category.name)
                                .font(.body.weight(.medium))
                        }
                    }
                }
            }
            
            Section("收入分类") {
                ForEach(rootCategories.filter { $0.typeRawValue == TransactionType.income.rawValue }, id: \.id) { category in
                    DisclosureGroup {
                        ForEach(childCategories.filter { $0.parentId == category.id }, id: \.id) { child in
                            HStack {
                                Image(systemName: child.icon)
                                    .foregroundColor(AppColor.primary)
                                Text(child.name)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(AppColor.primary)
                                .frame(width: 28)
                            Text(category.name)
                                .font(.body.weight(.medium))
                        }
                    }
                }
            }
        }
        .navigationTitle("分类管理")
    }
}

/// 自动记账设置视图
struct AutoBookkeepingSettingsView: View {
    @AppStorage("enableOCR") private var enableOCR = true
    @AppStorage("enableAIClassification") private var enableAIClassification = true
    @AppStorage("autoConfirmThreshold") private var autoConfirmThreshold = 0.9
    
    var body: some View {
        List {
            Section("识别设置") {
                Toggle("启用截图 OCR 识别", isOn: $enableOCR)
                Toggle("启用 AI 智能分类", isOn: $enableAIClassification)
            }
            
            Section("自动确认") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("置信度阈值: \(Int(autoConfirmThreshold * 100))%")
                    Slider(value: $autoConfirmThreshold, in: 0.5...1.0, step: 0.05)
                    Text("识别置信度高于此值时自动填充，否则需手动确认")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("隐私说明") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• 截图识别完全在设备本地处理")
                    Text("• 不会上传任何图片到服务器")
                    Text("• AI 分类仅发送商户名等文本信息")
                    Text("• 所有敏感信息会自动脱敏")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("自动记账设置")
    }
}

/// 快捷指令配置指南
struct ShortcutsGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("通过 iOS 快捷指令，你可以更快速地记账。")
                    .font(.body)
                
                Group {
                    Text("方式一：双击背面")
                        .font(.headline)
                    Text("1. 打开「设置」→「辅助功能」→「触控」→「轻点背面」\n2. 选择「轻点两下」\n3. 选择 MoneyMark 的自动记账快捷指令")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Group {
                    Text("方式二：Siri 语音")
                        .font(.headline)
                    Text("对 Siri 说「用 MoneyMark 记账」即可触发快捷指令")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Group {
                    Text("方式三：操作按钮")
                        .font(.headline)
                    Text("iPhone 15 Pro 及以上机型，可在设置中将操作按钮绑定到 MoneyMark 快捷指令")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("快捷指令配置")
    }
}
