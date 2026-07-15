import SwiftUI

/// 自定义数字键盘
struct NumberPadView: View {
    @Binding var amount: String
    
    var body: some View {
        EmptyView()
    }
    
    // MARK: - 数字键盘按键
    
    static let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]
}

/// 金额输入视图
struct AmountInputView: View {
    @Binding var amount: String
    var currency: String = "¥"
    
    var body: some View {
        VStack(spacing: 16) {
            // 金额显示
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(currency)
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text(amount.isEmpty ? "0.00" : amount)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.vertical, 20)
            
            // 数字键盘
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(["1","2","3","4","5","6","7","8","9",".","0","⌫"], id: \.self) { key in
                    Button(action: { handleKeyPress(key) }) {
                        Text(key)
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(.tertiarySystemFill))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func handleKeyPress(_ key: String) {
        switch key {
        case "⌫":
            if !amount.isEmpty {
                amount.removeLast()
            }
        case ".":
            if !amount.contains(".") {
                amount += amount.isEmpty ? "0." : "."
            }
        default:
            // 限制小数点后2位
            if amount.contains(".") {
                let parts = amount.components(separatedBy: ".")
                if parts.count == 2 && parts[1].count >= 2 { return }
            }
            // 限制最大金额
            let newAmount = amount + key
            if let value = Double(newAmount), value <= 999_999_999 {
                amount = newAmount
            }
        }
    }
}

/// 分类网格选择器
struct CategoryGridView: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    let onSelect: ((Category) -> Void)?
    
    init(categories: [Category], selectedCategory: Binding<Category?>, onSelect: ((Category) -> Void)? = nil) {
        self.categories = categories
        self._selectedCategory = selectedCategory
        self.onSelect = onSelect
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 16) {
            ForEach(categories, id: \.id) { category in
                CategoryItemView(
                    category: category,
                    isSelected: selectedCategory?.id == category.id
                )
                .onTapGesture {
                    selectedCategory = category
                    onSelect?(category)
                }
            }
        }
        .padding(.horizontal)
    }
}

/// 单个分类项
struct CategoryItemView: View {
    let category: Category
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isSelected ? AppColor.primary : Color(.tertiarySystemFill))
                    .frame(width: 48, height: 48)
                
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            
            Text(category.name)
                .font(.caption2)
                .foregroundColor(isSelected ? AppColor.primary : .secondary)
                .lineLimit(1)
        }
    }
}

/// 账单列表项
struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            // 分类图标
            ZStack {
                Circle()
                    .fill(AppColor.categoryColor(at: abs(transaction.categoryId?.hashValue ?? 0) % AppColor.categoryColors.count).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: transaction.categoryIcon ?? "questionmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColor.categoryColor(at: abs(transaction.categoryId?.hashValue ?? 0) % AppColor.categoryColors.count))
            }
            
            // 分类名和备注
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.categoryName ?? "未分类")
                    .font(.body)
                    .foregroundColor(.primary)
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // 金额和时间
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.type == .expense ? "-" : "+")\(transaction.amount.currencyString)")
                    .font(.body.weight(.semibold))
                    .foregroundColor(transaction.type == .expense ? AppColor.expense : AppColor.income)
                
                Text(DateFormatter.formatTransactionDate(transaction.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// 统计卡片
struct StatCardView: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    
    init(title: String, value: String, subtitle: String? = nil, color: Color = .primary) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(color)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
    }
}

/// 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

/// 加载指示器
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }
}
