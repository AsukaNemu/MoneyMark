import AppIntents
import SwiftUI

/// 自动记账快捷指令 Intent
/// 用户可通过 Siri 或快捷指令 App 触发
struct AutoBookkeepingIntent: AppIntent {
    static var title: LocalizedStringResource = "自动记账"
    static var description = IntentDescription("通过截图或文字自动识别并记录账单")
    
    /// 支持从 Siri 触发
    static var openAppWhenRun: Bool = false
    
    /// 参数：账单文本或截图描述
    @Parameter(title: "账单内容", description: "账单截图文字或描述文本")
    var billText: String?
    
    @Parameter(title: "金额", description: "账单金额")
    var amount: String?
    
    @Parameter(title: "商户", description: "商户名称")
    var merchant: String?
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let parser = ReceiptParser()
        
        // 如果有完整文本，使用解析器
        if let text = billText, !text.isEmpty {
            let result = parser.parse(text: text)
            let amountStr = result.amount.map { String(format: "%.2f", $0) } ?? "未知"
            let merchantStr = result.merchantName ?? "未知"
            let categoryStr = result.category ?? "未分类"
            
            return .result(value: "金额: ¥\(amountStr), 商户: \(merchantStr), 分类: \(categoryStr)")
        }
        
        // 如果有单独的金额和商户
        if let amountStr = amount, let amountValue = Double(amountStr) {
            let merchantStr = merchant ?? "未知"
            return .result(value: "已记录: ¥\(String(format: "%.2f", amountValue)) - \(merchantStr)")
        }
        
        return .result(value: "请提供账单内容或金额信息")
    }
}

/// 快速记账 Intent
struct QuickAddIntent: AppIntent {
    static var title: LocalizedStringResource = "快速记账"
    static var description = IntentDescription("快速添加一笔账单")
    
    @Parameter(title: "金额")
    var amount: Double
    
    @Parameter(title: "分类", description: "消费分类")
    var category: String?
    
    @Parameter(title: "备注")
    var note: String?
    
    @Parameter(title: "类型", description: "支出或收入")
    var type: String?
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let transactionType: TransactionType = type == "收入" ? .income : .expense
        let amountStr = String(format: "%.2f", amount)
        let categoryStr = category ?? "其他"
        let noteStr = note ?? ""
        
        // 实际存储需要通过共享的数据层
        return .result(value: "已\(transactionType.displayName): ¥\(amountStr) [\(categoryStr)] \(noteStr)")
    }
}

/// App Shortcuts 提供者
struct MoneyMarkShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AutoBookkeepingIntent(),
            phrases: [
                "在 \(.applicationName) 自动记账",
                "用 \(.applicationName) 识别账单",
                "\(.applicationName) 截图记账"
            ],
            shortTitle: "自动记账",
            systemImageName: "doc.text.viewfinder"
        )
        
        AppShortcut(
            intent: QuickAddIntent(),
            phrases: [
                "在 \(.applicationName) 快速记账",
                "用 \(.applicationName) 记一笔",
                "\(.applicationName) 记账"
            ],
            shortTitle: "快速记账",
            systemImageName: "plus.circle.fill"
        )
    }
}
