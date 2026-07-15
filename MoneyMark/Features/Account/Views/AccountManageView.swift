import SwiftUI
import SwiftData

/// 资产账户管理视图
struct AccountManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Account> { !$0.isArchived },
           sortBy: [SortDescriptor(\.sortOrder)])
    private var accounts: [Account]
    
    @State private var showAddAccount = false
    @State private var editingAccount: Account?
    
    private var totalAssets: Double {
        accounts.filter { $0.isIncludedInTotal }.reduce(0) { $0 + $1.balance }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 总资产概览
                    totalAssetCard
                    
                    // 账户列表
                    accountList
                    
                    // 添加账户
                    Button(action: { showAddAccount = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加账户")
                        }
                        .font(.headline)
                        .foregroundColor(AppColor.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColor.cardBackground)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(AppColor.background)
            .navigationTitle("资产")
            .sheet(isPresented: $showAddAccount) {
                AddAccountView()
            }
            .sheet(item: $editingAccount) { account in
                EditAccountView(account: account)
            }
        }
    }
    
    // MARK: - 总资产卡片
    
    private var totalAssetCard: some View {
        VStack(spacing: 12) {
            Text("总资产")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(totalAssets.currencyString)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(totalAssets >= 0 ? AppColor.income : AppColor.expense)
            
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(accounts.count)")
                        .font(.title3.weight(.bold))
                    Text("账户数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text(accounts.filter { $0.type == .creditCard }.count.description)
                        .font(.title3.weight(.bold))
                    Text("信用卡")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .cardStyle()
    }
    
    // MARK: - 账户列表
    
    private var accountList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("我的账户")
                .font(.headline)
            
            ForEach(accounts, id: \.id) { account in
                HStack(spacing: 12) {
                    Image(systemName: account.icon)
                        .font(.system(size: 20))
                        .foregroundColor(AppColor.primary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(AppColor.primary.opacity(0.1)))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.name)
                            .font(.body)
                        Text(account.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(account.balance.currencyString)
                        .font(.body.weight(.medium))
                        .foregroundColor(account.balance >= 0 ? .primary : AppColor.expense)
                }
                .padding()
                .cardStyle()
                .onTapGesture { editingAccount = account }
            }
        }
    }
}

/// 添加账户视图
struct AddAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var type: AccountType = .cash
    @State private var balance = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("账户信息") {
                    TextField("账户名称", text: $name)
                    
                    Picker("账户类型", selection: $type) {
                        ForEach(AccountType.allCases, id: \.self) { accountType in
                            HStack {
                                Image(systemName: accountType.icon)
                                Text(accountType.displayName)
                            }
                            .tag(accountType)
                        }
                    }
                }
                
                Section("初始余额") {
                    HStack {
                        Text("¥")
                        TextField("0.00", text: $balance)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("备注") {
                    TextField("添加备注（可选）", text: $notes)
                }
            }
            .navigationTitle("添加账户")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveAccount() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveAccount() {
        let account = Account(
            name: name,
            type: type,
            balance: Double(balance) ?? 0,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(account)
        try? modelContext.save()
        dismiss()
    }
}

/// 编辑账户视图
struct EditAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let account: Account
    
    @State private var name: String
    @State private var balance: String
    
    init(account: Account) {
        self.account = account
        _name = State(initialValue: account.name)
        _balance = State(initialValue: String(format: "%.2f", account.balance))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("账户信息") {
                    TextField("账户名称", text: $name)
                    HStack {
                        Text("余额")
                        Spacer()
                        Text("¥")
                        TextField("0.00", text: $balance)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Button("删除账户", role: .destructive) {
                        account.isArchived = true
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .navigationTitle("编辑账户")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        account.name = name
                        account.balance = Double(balance) ?? account.balance
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
