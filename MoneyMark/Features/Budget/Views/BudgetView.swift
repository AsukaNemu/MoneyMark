import SwiftUI
import SwiftData

/// 预算管理视图
struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Budget> { $0.isActive },
           sortBy: [SortDescriptor(\.createdAt)])
    private var budgets: [Budget]
    
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse)])
    private var allTransactions: [Transaction]
    
    @State private var showAddBudget = false
    
    private var currentMonthExpense: Double {
        let startOfMonth = Date().startOfMonth
        return allTransactions
            .filter { $0.date >= startOfMonth && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var totalBudget: Double {
        budgets.filter { $0.categoryId == nil }.first?.amount ?? 0
    }
    
    private let statsService = StatisticsService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 总预算概览
                    totalBudgetCard
                    
                    // 分类预算
                    categoryBudgetSection
                    
                    // 添加预算按钮
                    Button(action: { showAddBudget = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加预算")
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
            .navigationTitle("预算")
            .sheet(isPresented: $showAddBudget) {
                AddBudgetView()
            }
        }
    }
    
    // MARK: - 总预算卡片
    
    private var totalBudgetCard: some View {
        let usage = statsService.calculateBudgetUsage(budgetAmount: totalBudget, spentAmount: currentMonthExpense)
        
        return VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本月预算")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(totalBudget.currencyString)
                        .font(.title.weight(.bold))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("已支出")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(currentMonthExpense.currencyString)
                        .font(.title.weight(.bold))
                        .foregroundColor(AppColor.expense)
                }
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(usage.isOverBudget ? AppColor.expense : AppColor.primary)
                        .frame(width: min(CGFloat(usage.percentage / 100) * geometry.size.width, geometry.size.width), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("剩余 \(max(usage.remaining, 0).currencyString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if usage.dailyBudget > 0 {
                    Text("日均可用 \(usage.dailyBudget.currencyString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(usage.percentage.percentageString)
                    .font(.caption.weight(.medium))
                    .foregroundColor(usage.isOverBudget ? AppColor.expense : AppColor.primary)
            }
        }
        .padding()
        .cardStyle()
    }
    
    // MARK: - 分类预算
    
    private var categoryBudgetSection: some View {
        let categoryBudgets = budgets.filter { $0.categoryId != nil }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("分类预算")
                .font(.headline)
            
            if categoryBudgets.isEmpty {
                EmptyStateView(
                    icon: "target",
                    title: "暂无分类预算",
                    message: "添加分类预算，更精细地控制开支"
                )
            } else {
                ForEach(categoryBudgets, id: \.id) { budget in
                    CategoryBudgetRow(budget: budget, transactions: allTransactions)
                }
            }
        }
    }
}

/// 分类预算行
struct CategoryBudgetRow: View {
    let budget: Budget
    let transactions: [Transaction]
    
    private var spent: Double {
        let startOfMonth = Date().startOfMonth
        guard let categoryId = budget.categoryId else { return 0 }
        return transactions
            .filter { $0.date >= startOfMonth && $0.type == .expense && $0.categoryId == categoryId }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var percentage: Double {
        budget.amount > 0 ? spent / budget.amount * 100 : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(budget.categoryName ?? "未分类")
                    .font(.subheadline)
                Spacer()
                Text("\(spent.currencyString) / \(budget.amount.currencyString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(percentage > 100 ? AppColor.expense : AppColor.primary)
                        .frame(width: min(CGFloat(percentage / 100) * geometry.size.width, geometry.size.width), height: 6)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text(percentage.percentageString)
                    .font(.caption2)
                    .foregroundColor(percentage > 100 ? AppColor.expense : .secondary)
                Spacer()
                Text("剩余 \(max(budget.amount - spent, 0).currencyString)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .cardStyle()
    }
}

/// 添加预算视图
struct AddBudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(filter: #Predicate<Category> { !$0.isArchived && $0.parentId != nil })
    private var categories: [Category]
    
    @State private var amount: String = ""
    @State private var selectedCategory: Category?
    @State private var isTotalBudget = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("预算类型") {
                    Toggle("总预算", isOn: $isTotalBudget)
                    
                    if !isTotalBudget {
                        Picker("分类", selection: $selectedCategory) {
                            Text("选择分类").tag(nil as Category?)
                            ForEach(categories.filter { $0.typeRawValue == TransactionType.expense.rawValue }, id: \.id) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                    Text(category.name)
                                }
                                .tag(category as Category?)
                            }
                        }
                    }
                }
                
                Section("预算金额") {
                    HStack {
                        Text("¥")
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("添加预算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveBudget() }
                        .disabled(amount.isEmpty)
                }
            }
        }
    }
    
    private func saveBudget() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        let budget = Budget(
            categoryId: isTotalBudget ? nil : selectedCategory?.id,
            categoryName: isTotalBudget ? nil : selectedCategory?.name,
            amount: amountValue
        )
        
        modelContext.insert(budget)
        try? modelContext.save()
        dismiss()
    }
}
