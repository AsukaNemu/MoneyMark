import Foundation
import SwiftData

/// 账单类型
enum TransactionType: String, Codable, CaseIterable {
    case expense = "expense"   // 支出
    case income = "income"     // 收入
    case transfer = "transfer" // 转账
    case refund = "refund"     // 退款
    
    var displayName: String {
        switch self {
        case .expense: return "支出"
        case .income: return "收入"
        case .transfer: return "转账"
        case .refund: return "退款"
        }
    }
    
    var icon: String {
        switch self {
        case .expense: return "arrow.down.circle.fill"
        case .income: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .refund: return "arrow.uturn.backward.circle.fill"
        }
    }
}

/// 账单数据模型
@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var typeRawValue: String
    var categoryId: UUID?
    var categoryName: String?
    var categoryIcon: String?
    var accountId: UUID?
    var accountName: String?
    var note: String?
    var merchantName: String?
    var date: Date
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    var imageData: Data?
    var sourceRawValue: String // manual, ocr, import, shortcut
    
    var type: TransactionType {
        get { TransactionType(rawValue: typeRawValue) ?? .expense }
        set { typeRawValue = newValue.rawValue }
    }
    
    var source: TransactionSource {
        get { TransactionSource(rawValue: sourceRawValue) ?? .manual }
        set { sourceRawValue = newValue.rawValue }
    }
    
    /// 转账目标账户
    var toAccountId: UUID?
    var toAccountName: String?
    
    init(
        amount: Double,
        type: TransactionType = .expense,
        categoryId: UUID? = nil,
        categoryName: String? = nil,
        categoryIcon: String? = nil,
        accountId: UUID? = nil,
        accountName: String? = nil,
        note: String? = nil,
        merchantName: String? = nil,
        date: Date = .now,
        tags: [String] = [],
        source: TransactionSource = .manual,
        toAccountId: UUID? = nil,
        toAccountName: String? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.typeRawValue = type.rawValue
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.categoryIcon = categoryIcon
        self.accountId = accountId
        self.accountName = accountName
        self.note = note
        self.merchantName = merchantName
        self.date = date
        self.createdAt = .now
        self.updatedAt = .now
        self.tags = tags
        self.sourceRawValue = source.rawValue
        self.toAccountId = toAccountId
        self.toAccountName = toAccountName
    }
}

/// 账单来源
enum TransactionSource: String, Codable, CaseIterable {
    case manual = "manual"       // 手动记账
    case ocr = "ocr"             // 截图OCR识别
    case importCSV = "import"    // CSV导入
    case shortcut = "shortcut"   // 快捷指令
    case ai = "ai"               // AI自然语言
    
    var displayName: String {
        switch self {
        case .manual: return "手动记账"
        case .ocr: return "截图识别"
        case .importCSV: return "账单导入"
        case .shortcut: return "快捷指令"
        case .ai: return "AI记账"
        }
    }
}
