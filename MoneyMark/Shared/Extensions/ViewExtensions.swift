import SwiftUI

// MARK: - Date Extensions

extension Date {
    /// 获取当月第一天
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
    }
    
    /// 获取当月最后一天
    var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
    }
    
    /// 获取当年第一天
    var startOfYear: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year], from: self))!
    }
    
    /// 是否是今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// 是否是昨天
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// 是否是本月
    var isCurrentMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// 月份字符串 "2024-01"
    var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions

extension String {
    /// 尝试解析为金额
    var asAmount: Double? {
        let cleaned = self
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "￥", with: "")
            .replacingOccurrences(of: "元", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }
    
    /// 是否包含中文
    var containsChinese: Bool {
        range(of: "\\p{Han}", options: .regularExpression) != nil
    }
}

// MARK: - View Extensions

extension View {
    /// 圆角卡片样式
    func cardStyle() -> some View {
        self
            .background(AppColor.cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    /// 条件修饰器
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Double Extensions

extension Double {
    /// 格式化为货币字符串
    var currencyString: String {
        CurrencyFormatter.format(self)
    }
    
    /// 格式化为百分比
    var percentageString: String {
        String(format: "%.1f%%", self)
    }
}
