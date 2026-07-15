import Foundation
import SwiftData

/// 账户数据仓库
actor AccountRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD
    
    func add(_ account: Account) throws {
        modelContext.insert(account)
        try modelContext.save()
    }
    
    func update(_ account: Account) throws {
        account.updatedAt = .now
        try modelContext.save()
    }
    
    func delete(_ account: Account) throws {
        account.isArchived = true
        try modelContext.save()
    }
    
    // MARK: - 查询
    
    func fetchAll() throws -> [Account] {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate<Account> { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchById(_ id: UUID) throws -> Account? {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate<Account> { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func findByName(_ name: String) throws -> Account? {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate<Account> { $0.name == name && !$0.isArchived }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    /// 更新账户余额
    func updateBalance(accountId: UUID, amount: Double, isExpense: Bool) throws {
        guard let account = try fetchById(accountId) else { return }
        if isExpense {
            account.balance -= amount
        } else {
            account.balance += amount
        }
        account.updatedAt = .now
        try modelContext.save()
    }
    
    /// 计算总资产
    func totalAssets() throws -> Double {
        let accounts = try fetchAll()
        return accounts
            .filter { $0.isIncludedInTotal }
            .reduce(0) { $0 + $1.balance }
    }
    
    /// 初始化预置账户
    func initializePresetAccounts() throws {
        let count = try modelContext.fetchCount(FetchDescriptor<Account>())
        guard count == 0 else { return }
        
        for (index, preset) in Account.presetAccounts.enumerated() {
            let account = Account(
                name: preset.name,
                type: preset.type,
                icon: preset.icon,
                sortOrder: index
            )
            modelContext.insert(account)
        }
        
        try modelContext.save()
    }
}
