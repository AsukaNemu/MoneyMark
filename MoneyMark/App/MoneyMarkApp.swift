import SwiftUI
import SwiftData

/// MoneyMark App 入口
@main
struct MoneyMarkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Transaction.self,
            Category.self,
            Account.self,
            Budget.self
        ])
    }
}

/// 主视图 - Tab 导航
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var showAddTransaction = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 首页 - 账单列表
            TransactionListView()
                .tabItem {
                    Label("账单", systemImage: "list.bullet.rectangle")
                }
                .tag(0)
            
            // 统计
            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.pie.fill")
                }
                .tag(1)
            
            // 自动记账（中心大按钮）
            AutoBookkeepingView()
                .tabItem {
                    Label("自动记账", systemImage: "doc.text.viewfinder")
                }
                .tag(2)
            
            // 预算
            BudgetView()
                .tabItem {
                    Label("预算", systemImage: "target")
                }
                .tag(3)
            
            // 更多
            MoreView()
                .tabItem {
                    Label("更多", systemImage: "ellipsis.circle.fill")
                }
                .tag(4)
        }
        .tint(AppColor.primary)
        .onAppear {
            initializeData()
        }
    }
    
    /// 初始化预置数据
    private func initializeData() {
        let categoryRepo = CategoryRepository(modelContext: modelContext)
        let accountRepo = AccountRepository(modelContext: modelContext)
        
        Task {
            try? await categoryRepo.initializePresetCategories()
            try? await accountRepo.initializePresetAccounts()
        }
    }
}

/// 更多页面（资产、设置等入口）
struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        AccountManageView()
                    } label: {
                        HStack {
                            Image(systemName: "wallet.bifold.fill")
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            Text("资产管理")
                        }
                    }
                    
                    NavigationLink {
                        BillImportView()
                    } label: {
                        HStack {
                            Image(systemName: "doc.badge.arrow.up")
                                .foregroundColor(.green)
                                .frame(width: 28)
                            Text("导入账单")
                        }
                    }
                }
                
                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.gray)
                                .frame(width: 28)
                            Text("设置")
                        }
                    }
                }
            }
            .navigationTitle("更多")
        }
    }
}
