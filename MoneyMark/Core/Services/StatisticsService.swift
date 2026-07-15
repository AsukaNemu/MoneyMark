import Foundation

/// 统计数据服务
final class StatisticsService {
    
    // MARK: - 数据结构
    
    /// 分类统计
    struct CategoryStat {
        let categoryId: UUID?
        let categoryName: String
        let categoryIcon: String?
        let amount: Double
        let percentage: Double
        let count: Int
    }
    
    /// 日统计
    struct DailyStat {
        let date: Date
        let expense: Double
        let income: Double
    }
    
    /// 月度概览
    struct MonthlyOverview {
        let month: Date
        let totalExpense: Double
        let totalIncome: Double
        let balance: Double
        let transactionCount: Int
        let topCategories: [CategoryStat]
        let dailyStats: [DailyStat]
    }
    
    // MARK: - 计算方法
    
    /// 计算分类占比统计
    func calculateCategoryStats(
        transactions: [Transaction],
        type: TransactionType = .expense
    ) -> [CategoryStat] {
        let filtered = transactions.filter { $0.type == type }
        let total = filtered.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }
        
        // 按分类分组
        var grouped: [UUID?: (name: String, icon: String?, amount: Double, count: Int)] = [:]
        for t in filtered {
            let key = t.categoryId
            let existing = grouped[key] ?? (name: t.categoryName ?? "未分类", icon: t.categoryIcon, amount: 0, count: 0)
            grouped[key] = (
                name: t.categoryName ?? "未分类",
                icon: t.categoryIcon,
                amount: existing.amount + t.amount,
                count: existing.count + 1
            )
        }
        
        return grouped.map { key, value in
            CategoryStat(
                categoryId: key,
                categoryName: value.name,
                categoryIcon: value.icon,
                amount: value.amount,
                percentage: value.amount / total * 100,
                count: value.count
            )
        }
        .sorted { $0.amount > $1.amount }
    }
    
    /// 计算日统计（用于趋势图）
    func calculateDailyStats(
        transactions: [Transaction],
        from startDate: Date,
        to endDate: Date
    ) -> [DailyStat] {
        let calendar = Calendar.current
        var dailyMap: [Date: (expense: Double, income: Double)] = [:]
        
        // 填充所有日期
        var currentDate = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        while currentDate <= end {
            dailyMap[currentDate] = (expense: 0, income: 0)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // 统计每日数据
        for t in transactions {
            let day = calendar.startOfDay(for: t.date)
            var stat = dailyMap[day] ?? (expense: 0, income: 0)
            if t.type == .expense {
                stat.expense += t.amount
            } else if t.type == .income {
                stat.income += t.amount
            }
            dailyMap[day] = stat
        }
        
        return dailyMap.map { DailyStat(date: $0.key, expense: $0.value.expense, income: $0.value.income) }
            .sorted { $0.date < $1.date }
    }
    
    /// 计算月度概览
    func calculateMonthlyOverview(
        transactions: [Transaction],
        for month: Date
    ) -> MonthlyOverview {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let monthTransactions = transactions.filter { $0.date >= startOfMonth && $0.date <= endOfMonth }
        
        let totalExpense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let totalIncome = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        
        return MonthlyOverview(
            month: month,
            totalExpense: totalExpense,
            totalIncome: totalIncome,
            balance: totalIncome - totalExpense,
            transactionCount: monthTransactions.count,
            topCategories: calculateCategoryStats(transactions: monthTransactions).prefix(5).map { $0 },
            dailyStats: calculateDailyStats(transactions: monthTransactions, from: startOfMonth, to: endOfMonth)
        )
    }
    
    /// 计算预算执行情况
    func calculateBudgetUsage(
        budgetAmount: Double,
        spentAmount: Double
    ) -> (percentage: Double, remaining: Double, dailyBudget: Double, isOverBudget: Bool) {
        let percentage = budgetAmount > 0 ? spentAmount / budgetAmount * 100 : 0
        let remaining = budgetAmount - spentAmount
        
        let calendar = Calendar.current
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
        let currentDay = calendar.component(.day, from: Date())
        let remainingDays = max(daysInMonth - currentDay, 1)
        
        let dailyBudget = remaining > 0 ? remaining / Double(remainingDays) : 0
        
        return (percentage: percentage, remaining: remaining, dailyBudget: dailyBudget, isOverBudget: spentAmount > budgetAmount)
    }
}
