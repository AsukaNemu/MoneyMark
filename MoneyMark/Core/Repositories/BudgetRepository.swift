import Foundation
import SwiftData

/// 预算数据仓库
actor BudgetRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD
    
    func add(_ budget: Budget) throws {
        modelContext.insert(budget)
        try modelContext.save()
    }
    
    func update(_ budget: Budget) throws {
        budget.updatedAt = .now
        try modelContext.save()
    }
    
    func delete(_ budget: Budget) throws {
        modelContext.delete(budget)
        try modelContext.save()
    }
    
    // MARK: - 查询
    
    func fetchActive(period: BudgetPeriod = .monthly) throws -> [Budget] {
        let periodRaw = period.rawValue
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate<Budget> { budget in
                budget.isActive && budget.periodRawValue == periodRaw
            }
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchTotalBudget(period: BudgetPeriod = .monthly) throws -> Budget? {
        let periodRaw = period.rawValue
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate<Budget> { budget in
                budget.isActive && budget.periodRawValue == periodRaw && budget.categoryId == nil
            }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func fetchCategoryBudget(categoryId: UUID, period: BudgetPeriod = .monthly) throws -> Budget? {
        let periodRaw = period.rawValue
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate<Budget> { budget in
                budget.isActive && budget.periodRawValue == periodRaw && budget.categoryId == categoryId
            }
        )
        return try modelContext.fetch(descriptor).first
    }
}
