import SwiftUI

/// 金额格式化工具
struct CurrencyFormatter {
    /// 格式化金额显示
    static func format(_ amount: Double, currency: String = "¥") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let number = NSNumber(value: amount)
        return currency + (formatter.string(from: number) ?? String(format: "%.2f", amount))
    }
    
    /// 格式化金额（无符号）
    static func formatPlain(_ amount: Double) -> String {
        String(format: "%.2f", amount)
    }
    
    /// 格式化大数字（万/亿）
    static func formatCompact(_ amount: Double) -> String {
        if amount >= 100_000_000 {
            return String(format: "%.1f亿", amount / 100_000_000)
        } else if amount >= 10_000 {
            return String(format: "%.1f万", amount / 10_000)
        }
        return format(amount)
    }
}

/// 日期格式化工具
struct DateFormatter {
    /// 格式化为 "今天 14:30" / "昨天 14:30" / "01-15 14:30"
    static func formatTransactionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let timeFormatter = Foundation.DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeStr = timeFormatter.string(from: date)
        
        if calendar.isDateInToday(date) {
            return "今天 \(timeStr)"
        } else if calendar.isDateInYesterday(date) {
            return "昨天 \(timeStr)"
        } else if calendar.component(.year, from: date) == calendar.component(.year, from: Date()) {
            let formatter = Foundation.DateFormatter()
            formatter.dateFormat = "MM-dd"
            return "\(formatter.string(from: date)) \(timeStr)"
        } else {
            let formatter = Foundation.DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return "\(formatter.string(from: date)) \(timeStr)"
        }
    }
    
    /// 格式化为 "2024年1月"
    static func formatMonth(_ date: Date) -> String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    /// 格式化为 "1月15日"
    static func formatDay(_ date: Date) -> String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

/// 颜色工具
struct AppColor {
    /// 支出颜色（红色系）
    static let expense = Color.red
    /// 收入颜色（绿色系）
    static let income = Color.green
    /// 主题色
    static let primary = Color.blue
    /// 背景色
    static let background = Color(.systemGroupedBackground)
    /// 卡片背景
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    
    /// 分类颜色（按索引）
    static let categoryColors: [Color] = [
        .red, .orange, .yellow, .green, .mint,
        .teal, .cyan, .blue, .indigo, .purple,
        .pink, .brown, .gray
    ]
    
    /// 根据索引获取分类颜色
    static func categoryColor(at index: Int) -> Color {
        categoryColors[index % categoryColors.count]
    }
}
