import Foundation
import SwiftData

/// 账单数据仓库
actor TransactionRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD
    
    /// 添加账单
    func add(_ transaction: Transaction) throws {
        modelContext.insert(transaction)
        try modelContext.save()
    }
    
    /// 批量添加账单
    func addBatch(_ transactions: [Transaction]) throws {
        for transaction in transactions {
            modelContext.insert(transaction)
        }
        try modelContext.save()
    }
    
    /// 更新账单
    func update(_ transaction: Transaction) throws {
        transaction.updatedAt = .now
        try modelContext.save()
    }
    
    /// 删除账单
    func delete(_ transaction: Transaction) throws {
        modelContext.delete(transaction)
        try modelContext.save()
    }
    
    /// 批量删除
    func deleteBatch(_ transactions: [Transaction]) throws {
        for transaction in transactions {
            modelContext.delete(transaction)
        }
        try modelContext.save()
    }
    
    // MARK: - 查询
    
    /// 获取所有账单（按日期降序）
    func fetchAll() throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 按日期范围查询
    func fetchByDateRange(from startDate: Date, to endDate: Date) throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { transaction in
                transaction.date >= startDate && transaction.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 按类型查询
    func fetchByType(_ type: TransactionType) throws -> [Transaction] {
        let typeRaw = type.rawValue
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { transaction in
                transaction.typeRawValue == typeRaw
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 按分类查询
    func fetchByCategory(_ categoryId: UUID) throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { transaction in
                transaction.categoryId == categoryId
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 按账户查询
    func fetchByAccount(_ accountId: UUID) throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { transaction in
                transaction.accountId == accountId
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 搜索账单（备注/商户名）
    func search(keyword: String) throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { transaction in
                transaction.note?.contains(keyword) == true ||
                transaction.merchantName?.contains(keyword) == true
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - 统计
    
    /// 计算指定时间范围内的总支出
    func totalExpense(from startDate: Date, to endDate: Date) throws -> Double {
        let typeRaw = TransactionType.expense.rawValue
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { transaction in
                transaction.date >= startDate && transaction.date <= endDate && transaction.typeRawValue == typeRaw
            }
        )
        let transactions = try modelContext.fetch(descriptor)
        return transactions.reduce(0) { $0 + $1.amount }
    }
    
    /// 计算指定时间范围内的总收入
    func totalIncome(from startDate: Date, to endDate: Date) throws -> Double {
        let typeRaw = TransactionType.income.rawValue
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { transaction in
                transaction.date >= startDate && transaction.date <= endDate && transaction.typeRawValue == typeRaw
            }
        )
        let transactions = try modelContext.fetch(descriptor)
        return transactions.reduce(0) { $0 + $1.amount }
    }
    
    /// 按分类汇总支出
    func expenseByCategory(from startDate: Date, to endDate: Date) throws -> [(categoryId: UUID?, categoryName: String?, total: Double)] {
        let typeRaw = TransactionType.expense.rawValue
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { transaction in
                transaction.date >= startDate && transaction.date <= endDate && transaction.typeRawValue == typeRaw
            }
        )
        let transactions = try modelContext.fetch(descriptor)
        
        var grouped: [UUID?: (name: String?, total: Double)] = [:]
        for t in transactions {
            let key = t.categoryId
            let existing = grouped[key] ?? (name: t.categoryName, total: 0)
            grouped[key] = (name: t.categoryName, total: existing.total + t.amount)
        }
        
        return grouped.map { (categoryId: $0.key, categoryName: $0.value.name, total: $0.value.total) }
            .sorted { $0.total > $1.total }
    }
    
    /// 按日汇总（用于趋势图）
    func dailySummary(from startDate: Date, to endDate: Date) throws -> [(date: Date, expense: Double, income: Double)] {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { transaction in
                transaction.date >= startDate && transaction.date <= endDate
            },
            sortBy: [SortDescriptor(\.date)]
        )
        let transactions = try modelContext.fetch(descriptor)
        
        let calendar = Calendar.current
        var grouped: [Date: (expense: Double, income: Double)] = [:]
        
        for t in transactions {
            let day = calendar.startOfDay(for: t.date)
            let existing = grouped[day] ?? (expense: 0, income: 0)
            if t.type == .expense {
                grouped[day] = (expense: existing.expense + t.amount, income: existing.income)
            } else if t.type == .income {
                grouped[day] = (expense: existing.expense, income: existing.income + t.amount)
            }
        }
        
        return grouped.map { (date: $0.key, expense: $0.value.expense, income: $0.value.income) }
            .sorted { $0.date < $1.date }
    }
}
