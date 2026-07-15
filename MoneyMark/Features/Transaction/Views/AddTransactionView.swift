import SwiftUI
import SwiftData

/// 手动记账视图
struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var transactionType: TransactionType = .expense
    @State private var amount: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var note: String = ""
    @State private var merchantName: String = ""
    @State private var date: Date = .now
    @State private var showCategoryPicker = false
    @State private var showAccountPicker = false
    
    @Query(filter: #Predicate<Category> { !$0.isArchived && $0.parentId != nil },
           sortBy: [SortDescriptor(\.sortOrder)])
    private var categories: [Category]
    
    @Query(filter: #Predicate<Account> { !$0.isArchived },
           sortBy: [SortDescriptor(\.sortOrder)])
    private var accounts: [Account]
    
    var filteredCategories: [Category] {
        categories.filter { $0.typeRawValue == transactionType.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 类型切换
                    typeSelector
                    
                    // 金额输入
                    AmountInputView(amount: $amount)
                    
                    // 分类选择
                    categorySection
                    
                    // 详细信息
                    detailSection
                    
                    // 保存按钮
                    saveButton
                }
                .padding()
            }
            .background(AppColor.background)
            .navigationTitle("记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - 类型选择器
    
    private var typeSelector: some View {
        HStack(spacing: 0) {
            ForEach([TransactionType.expense, .income, .transfer], id: \.self) { type in
                Button(action: { transactionType = type }) {
                    Text(type.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(transactionType == type ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(transactionType == type ? AppColor.primary : Color.clear)
                        .cornerRadius(8)
                }
            }
        }
        .padding(4)
        .background(Color(.tertiarySystemFill))
        .cornerRadius(12)
    }
    
    // MARK: - 分类选择
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("分类")
                    .font(.headline)
                Spacer()
                Button("查看全部") { showCategoryPicker = true }
                    .font(.caption)
            }
            
            CategoryGridView(
                categories: Array(filteredCategories.prefix(10)),
                selectedCategory: $selectedCategory
            )
        }
        .padding()
        .cardStyle()
    }
    
    // MARK: - 详细信息
    
    private var detailSection: some View {
        VStack(spacing: 0) {
            // 账户选择
            HStack {
                Text("账户")
                    .foregroundColor(.primary)
                Spacer()
                Text(selectedAccount?.name ?? "选择账户")
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(AppColor.cardBackground)
            .onTapGesture { showAccountPicker = true }
            
            Divider().padding(.leading)
            
            // 商户名
            HStack {
                Text("商户")
                    .foregroundColor(.primary)
                TextField("输入商户名", text: $merchantName)
                    .multilineTextAlignment(.trailing)
            }
            .padding()
            .background(AppColor.cardBackground)
            
            Divider().padding(.leading)
            
            // 日期
            HStack {
                Text("日期")
                    .foregroundColor(.primary)
                Spacer()
                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }
            .padding()
            .background(AppColor.cardBackground)
            
            Divider().padding(.leading)
            
            // 备注
            HStack {
                Text("备注")
                    .foregroundColor(.primary)
                TextField("添加备注", text: $note)
                    .multilineTextAlignment(.trailing)
            }
            .padding()
            .background(AppColor.cardBackground)
        }
        .cornerRadius(12)
    }
    
    // MARK: - 保存按钮
    
    private var saveButton: some View {
        Button(action: saveTransaction) {
            Text("保存")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? AppColor.primary : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!isFormValid)
    }
    
    private var isFormValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return true
    }
    
    // MARK: - 保存逻辑
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let transaction = Transaction(
            amount: amountValue,
            type: transactionType,
            categoryId: selectedCategory?.id,
            categoryName: selectedCategory?.name,
            categoryIcon: selectedCategory?.icon,
            accountId: selectedAccount?.id,
            accountName: selectedAccount?.name,
            note: note.isEmpty ? nil : note,
            merchantName: merchantName.isEmpty ? nil : merchantName,
            date: date,
            source: .manual
        )
        
        modelContext.insert(transaction)
        
        // 更新账户余额
        if let account = selectedAccount {
            if transactionType == .expense {
                account.balance -= amountValue
            } else if transactionType == .income {
                account.balance += amountValue
            }
        }
        
        try? modelContext.save()
        dismiss()
    }
}
