import SwiftUI
import SwiftData
import Charts

/// 统计报表视图
struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse)])
    private var allTransactions: [Transaction]
    
    @State private var selectedPeriod: Period = .month
    @State private var selectedDate: Date = .now
    @State private var chartType: ChartType = .pie
    
    enum Period: String, CaseIterable {
        case week = "本周"
        case month = "本月"
        case year = "本年"
    }
    
    enum ChartType: String, CaseIterable {
        case pie = "饼图"
        case bar = "柱状图"
        case line = "趋势图"
    }
    
    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let startDate: Date
        let endDate: Date = selectedDate
        
        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        case .month:
            startDate = endDate.startOfMonth
        case .year:
            startDate = endDate.startOfYear
        }
        
        return allTransactions.filter { $0.date >= startDate && $0.date <= endDate }
    }
    
    private var totalExpense: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private let statsService = StatisticsService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 周期选择
                    periodSelector
                    
                    // 收支概览
                    overviewCards
                    
                    // 图表类型切换
                    chartTypeSelector
                    
                    // 图表
                    chartSection
                    
                    // 分类排行
                    categoryRanking
                }
                .padding()
            }
            .background(AppColor.background)
            .navigationTitle("统计")
        }
    }
    
    // MARK: - 周期选择
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(Period.allCases, id: \.self) { period in
                Button(action: { selectedPeriod = period }) {
                    Text(period.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(selectedPeriod == period ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedPeriod == period ? AppColor.primary : Color.clear)
                        .cornerRadius(8)
                }
            }
        }
        .padding(4)
        .background(Color(.tertiarySystemFill))
        .cornerRadius(12)
    }
    
    // MARK: - 收支概览
    
    private var overviewCards: some View {
        HStack(spacing: 12) {
            StatCardView(
                title: "总支出",
                value: totalExpense.currencyString,
                color: AppColor.expense
            )
            
            StatCardView(
                title: "总收入",
                value: totalIncome.currencyString,
                color: AppColor.income
            )
            
            StatCardView(
                title: "结余",
                value: (totalIncome - totalExpense).currencyString,
                color: totalIncome - totalExpense >= 0 ? AppColor.income : AppColor.expense
            )
        }
    }
    
    // MARK: - 图表类型
    
    private var chartTypeSelector: some View {
        HStack(spacing: 0) {
            ForEach(ChartType.allCases, id: \.self) { type in
                Button(action: { chartType = type }) {
                    Text(type.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundColor(chartType == type ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(chartType == type ? AppColor.primary : Color.clear)
                        .cornerRadius(6)
                }
            }
        }
        .padding(3)
        .background(Color(.tertiarySystemFill))
        .cornerRadius(10)
    }
    
    // MARK: - 图表
    
    @ViewBuilder
    private var chartSection: some View {
        let categoryStats = statsService.calculateCategoryStats(transactions: filteredTransactions)
        
        switch chartType {
        case .pie:
            pieChart(stats: categoryStats)
        case .bar:
            barChart(stats: categoryStats)
        case .line:
            lineChart
        }
    }
    
    /// 饼图
    private func pieChart(stats: [StatisticsService.CategoryStat]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支出分类占比")
                .font(.headline)
            
            if stats.isEmpty {
                EmptyStateView(icon: "chart.pie", title: "暂无数据", message: "本月还没有支出记录")
            } else {
                Chart(stats.prefix(8), id: \.categoryId) { stat in
                    SectorMark(
                        angle: .value("金额", stat.amount),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(AppColor.categoryColor(at: stats.firstIndex(where: { $0.categoryId == stat.categoryId }) ?? 0))
                    .annotation(position: .overlay) {
                        if stat.percentage > 5 {
                            Text(stat.percentage.percentageString)
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 250)
                
                // 图例
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(stats.prefix(6), id: \.categoryId) { stat in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(AppColor.categoryColor(at: stats.firstIndex(where: { $0.categoryId == stat.categoryId }) ?? 0))
                                .frame(width: 10, height: 10)
                            Text(stat.categoryName)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(stat.amount.currencyString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
    
    /// 柱状图
    private func barChart(stats: [StatisticsService.CategoryStat]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支出分类排行")
                .font(.headline)
            
            if stats.isEmpty {
                EmptyStateView(icon: "chart.bar", title: "暂无数据", message: "本月还没有支出记录")
            } else {
                Chart(stats.prefix(8), id: \.categoryId) { stat in
                    BarMark(
                        x: .value("金额", stat.amount),
                        y: .value("分类", stat.categoryName)
                    )
                    .foregroundStyle(AppColor.categoryColor(at: stats.firstIndex(where: { $0.categoryId == stat.categoryId }) ?? 0))
                    .annotation(position: .trailing) {
                        Text(stat.amount.currencyString)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(min(stats.count, 8)) * 40 + 40)
            }
        }
        .padding()
        .cardStyle()
    }
    
    /// 趋势折线图
    private var lineChart: some View {
        let dailyStats = statsService.calculateDailyStats(
            transactions: filteredTransactions,
            from: selectedDate.startOfMonth,
            to: selectedDate
        )
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("收支趋势")
                .font(.headline)
            
            if dailyStats.isEmpty {
                EmptyStateView(icon: "chart.line.uptrend.xyaxis", title: "暂无数据", message: "本月还没有记录")
            } else {
                Chart(dailyStats, id: \.date) { stat in
                    LineMark(
                        x: .value("日期", stat.date),
                        y: .value("支出", stat.expense),
                        series: .value("类型", "支出")
                    )
                    .foregroundStyle(AppColor.expense)
                    
                    LineMark(
                        x: .value("日期", stat.date),
                        y: .value("收入", stat.income),
                        series: .value("类型", "收入")
                    )
                    .foregroundStyle(AppColor.income)
                }
                .frame(height: 200)
                .chartLegend(position: .bottom)
            }
        }
        .padding()
        .cardStyle()
    }
    
    // MARK: - 分类排行
    
    private var categoryRanking: some View {
        let stats = statsService.calculateCategoryStats(transactions: filteredTransactions)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("分类明细")
                .font(.headline)
            
            if stats.isEmpty {
                EmptyStateView(icon: "list.bullet", title: "暂无数据", message: "本月还没有支出记录")
            } else {
                ForEach(stats, id: \.categoryId) { stat in
                    HStack(spacing: 12) {
                        Image(systemName: stat.categoryIcon ?? "questionmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColor.primary)
                            .frame(width: 36, height: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.categoryName)
                                .font(.subheadline)
                            Text("\(stat.count)笔")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(stat.amount.currencyString)
                                .font(.subheadline.weight(.medium))
                            Text(stat.percentage.percentageString)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if stat.categoryId != stats.last?.categoryId {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
}
