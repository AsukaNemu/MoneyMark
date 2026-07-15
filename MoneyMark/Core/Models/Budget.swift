import Foundation
import SwiftData

/// 预算周期
enum BudgetPeriod: String, Codable, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "月度"
        case .yearly: return "年度"
        }
    }
}

/// 预算数据模型
@Model
final class Budget {
    var id: UUID
    var categoryId: UUID?     // nil 表示总预算
    var categoryName: String?
    var amount: Double
    var periodRawValue: String
    var startDate: Date
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    var period: BudgetPeriod {
        get { BudgetPeriod(rawValue: periodRawValue) ?? .monthly }
        set { periodRawValue = newValue.rawValue }
    }
    
    init(
        categoryId: UUID? = nil,
        categoryName: String? = nil,
        amount: Double,
        period: BudgetPeriod = .monthly,
        startDate: Date = .now,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.amount = amount
        self.periodRawValue = period.rawValue
        self.startDate = startDate
        self.isActive = isActive
        self.createdAt = .now
        self.updatedAt = .now
    }
}
