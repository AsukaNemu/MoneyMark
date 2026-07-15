import Foundation
import SwiftData

/// 账户类型
enum AccountType: String, Codable, CaseIterable {
    case cash = "cash"               // 现金
    case debitCard = "debitCard"     // 储蓄卡
    case creditCard = "creditCard"   // 信用卡
    case eWallet = "eWallet"         // 电子钱包
    case investment = "investment"   // 投资账户
    case other = "other"             // 其他
    
    var displayName: String {
        switch self {
        case .cash: return "现金"
        case .debitCard: return "储蓄卡"
        case .creditCard: return "信用卡"
        case .eWallet: return "电子钱包"
        case .investment: return "投资账户"
        case .other: return "其他"
        }
    }
    
    var icon: String {
        switch self {
        case .cash: return "banknote.fill"
        case .debitCard: return "creditcard.fill"
        case .creditCard: return "creditcard.and.1.forward"
        case .eWallet: return "wallet.bifold.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

/// 资产账户数据模型
@Model
final class Account {
    var id: UUID
    var name: String
    var typeRawValue: String
    var balance: Double
    var icon: String
    var colorHex: String?
    var currency: String
    var isIncludedInTotal: Bool
    var creditLimit: Double?       // 信用卡额度
    var billingDay: Int?           // 信用卡账单日
    var repaymentDay: Int?         // 信用卡还款日
    var sortOrder: Int
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date
    var notes: String?
    
    var type: AccountType {
        get { AccountType(rawValue: typeRawValue) ?? .cash }
        set { typeRawValue = newValue.rawValue }
    }
    
    init(
        name: String,
        type: AccountType = .cash,
        balance: Double = 0,
        icon: String? = nil,
        colorHex: String? = nil,
        currency: String = "CNY",
        isIncludedInTotal: Bool = true,
        creditLimit: Double? = nil,
        billingDay: Int? = nil,
        repaymentDay: Int? = nil,
        sortOrder: Int = 0,
        isArchived: Bool = false,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.typeRawValue = type.rawValue
        self.balance = balance
        self.icon = icon ?? type.icon
        self.colorHex = colorHex
        self.currency = currency
        self.isIncludedInTotal = isIncludedInTotal
        self.creditLimit = creditLimit
        self.billingDay = billingDay
        self.repaymentDay = repaymentDay
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.createdAt = .now
        self.updatedAt = .now
        self.notes = notes
    }
}

// MARK: - 预置账户

extension Account {
    /// 预置默认账户
    static let presetAccounts: [(name: String, type: AccountType, icon: String)] = [
        ("现金", .cash, "banknote.fill"),
        ("微信钱包", .eWallet, "message.fill"),
        ("支付宝", .eWallet, "a.circle.fill"),
        ("银行卡", .debitCard, "creditcard.fill"),
    ]
}
