import SwiftUI
import SwiftData

/// 账单列表视图
struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse)])
    private var allTransactions: [Transaction]
    
    @State private var searchText = ""
    @State private var filterType: TransactionType?
    @State private var showAddSheet = false
    @State private var selectedTransaction: Transaction?
    
    var filteredTransactions: [Transaction] {
        var result = allTransactions
        
        if let type = filterType {
            result = result.filter { $0.type == type }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                ($0.note?.localizedCaseInsensitiveContains(searchText) == true) ||
                ($0.merchantName?.localizedCaseInsensitiveContains(searchText) == true) ||
                ($0.categoryName?.localizedCaseInsensitiveContains(searchText) == true)
            }
        }
        
        return result
    }
    
    /// 按日期分组
    var groupedTransactions: [(date: String, transactions: [Transaction])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        
        let grouped = Dictionary(grouping: filteredTransactions) { formatter.string(from: $0.date) }
        return grouped.map { (date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if allTransactions.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "暂无账单",
                        message: "点击右下角 + 开始记账"
                    )
                } else {
                    transactionList
                }
            }
            .searchable(text: $searchText, prompt: "搜索账单")
            .navigationTitle("账单")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("全部", action: { filterType = nil })
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Button(type.displayName, action: { filterType = type })
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(filterType?.displayName ?? "全部")
                                .font(.subheadline)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTransactionView()
            }
        }
    }
    
    // MARK: - 交易列表
    
    private var transactionList: some View {
        List {
            ForEach(groupedTransactions, id: \.date) { group in
                Section {
                    ForEach(group.transactions, id: \.id) { transaction in
                        TransactionRowView(transaction: transaction)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteTransaction(transaction)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    TransactionDateHeader(dateString: group.date, transactions: group.transactions)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - 删除
    
    private func deleteTransaction(_ transaction: Transaction) {
        modelContext.delete(transaction)
        try? modelContext.save()
    }
}

/// 日期组头
struct TransactionDateHeader: View {
    let dateString: String
    let transactions: [Transaction]
    
    private var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        HStack {
            Text(formatDate(dateString))
                .font(.subheadline.weight(.medium))
            Spacer()
            if totalExpense > 0 {
                Text("支 \(totalExpense.currencyString)")
                    .font(.caption)
                    .foregroundColor(AppColor.expense)
            }
            if totalIncome > 0 {
                Text("收 \(totalIncome.currencyString)")
                    .font(.caption)
                    .foregroundColor(AppColor.income)
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        if date.isToday { return "今天" }
        if date.isYesterday { return "昨天" }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "M月d日 EEEE"
        displayFormatter.locale = Locale(identifier: "zh_CN")
        return displayFormatter.string(from: date)
    }
}
