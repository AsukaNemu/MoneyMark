import Foundation

/// 账单导入服务
/// 支持导入微信、支付宝导出的 CSV 账单文件
final class BillImportService {
    
    /// 导入结果
    struct ImportResult {
        let successCount: Int
        let failedCount: Int
        let transactions: [Transaction]
        let errors: [String]
    }
    
    /// 账单来源平台
    enum Platform {
        case wechat
        case alipay
        case unknown
    }
    
    // MARK: - 微信账单导入
    
    /// 解析微信账单 CSV
    func parseWechatBill(from csvContent: String) -> ImportResult {
        let lines = csvContent.components(separatedBy: .newlines)
        var transactions: [Transaction] = []
        var errors: [String] = []
        var successCount = 0
        
        // 跳过头部信息（微信账单前16行左右是元数据）
        var dataStartIndex = 0
        for (index, line) in lines.enumerated() {
            if line.contains("交易时间") && line.contains("交易类型") {
                dataStartIndex = index + 1
                break
            }
        }
        
        guard dataStartIndex < lines.count else {
            return ImportResult(successCount: 0, failedCount: 0, transactions: [], errors: ["无效的微信账单格式"])
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "zh_CN")
        
        for i in dataStartIndex..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            
            let columns = parseCSVLine(line)
            guard columns.count >= 6 else {
                errors.append("第\(i + 1)行格式错误")
                continue
            }
            
            // 微信账单列：交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
            let dateString = columns[0]
            let transactionType = columns[1]
            let counterpart = columns[2]
            let product = columns[3]
            let direction = columns[4]  // 收入/支出/"/"
            let amountString = columns[5].replacingOccurrences(of: "¥", with: "")
            
            guard let amount = Double(amountString), amount > 0 else {
                errors.append("第\(i + 1)行金额解析失败")
                continue
            }
            
            let date = dateFormatter.date(from: dateString) ?? .now
            let type: TransactionType = direction == "收入" ? .income : .expense
            
            let transaction = Transaction(
                amount: amount,
                type: type,
                categoryName: type == .income ? "其他收入" : "其他",
                note: product.isEmpty ? counterpart : product,
                merchantName: counterpart,
                date: date,
                source: .importCSV
            )
            
            transactions.append(transaction)
            successCount += 1
        }
        
        return ImportResult(
            successCount: successCount,
            failedCount: errors.count,
            transactions: transactions,
            errors: errors
        )
    }
    
    // MARK: - 支付宝账单导入
    
    /// 解析支付宝账单 CSV
    func parseAlipayBill(from csvContent: String) -> ImportResult {
        let lines = csvContent.components(separatedBy: .newlines)
        var transactions: [Transaction] = []
        var errors: [String] = []
        var successCount = 0
        
        // 跳过头部信息
        var dataStartIndex = 0
        for (index, line) in lines.enumerated() {
            if line.contains("交易时间") && line.contains("交易分类") {
                dataStartIndex = index + 1
                break
            }
        }
        
        guard dataStartIndex < lines.count else {
            return ImportResult(successCount: 0, failedCount: 0, transactions: [], errors: ["无效的支付宝账单格式"])
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "zh_CN")
        
        for i in dataStartIndex..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            
            let columns = parseCSVLine(line)
            guard columns.count >= 7 else {
                errors.append("第\(i + 1)行格式错误")
                continue
            }
            
            // 支付宝账单列：交易时间,交易分类,交易对方,对方账号,商品说明,收/支,金额,收/付款方式,交易状态,交易订单号,商家订单号,备注
            let dateString = columns[0]
            let category = columns[1]
            let counterpart = columns[2]
            let product = columns[4]
            let direction = columns[5]
            let amountString = columns[6].replacingOccurrences(of: "¥", with: "")
            
            guard let amount = Double(amountString), amount > 0 else {
                errors.append("第\(i + 1)行金额解析失败")
                continue
            }
            
            let date = dateFormatter.date(from: dateString) ?? .now
            let type: TransactionType = direction.contains("收入") ? .income : .expense
            
            let transaction = Transaction(
                amount: amount,
                type: type,
                categoryName: type == .income ? "其他收入" : (category.isEmpty ? "其他" : category),
                note: product.isEmpty ? counterpart : product,
                merchantName: counterpart,
                date: date,
                source: .importCSV
            )
            
            transactions.append(transaction)
            successCount += 1
        }
        
        return ImportResult(
            successCount: successCount,
            failedCount: errors.count,
            transactions: transactions,
            errors: errors
        )
    }
    
    // MARK: - 自动检测平台
    
    /// 自动检测 CSV 来源平台
    func detectPlatform(from csvContent: String) -> Platform {
        if csvContent.contains("微信支付") || (csvContent.contains("交易对方") && csvContent.contains("商品")) {
            return .wechat
        }
        if csvContent.contains("支付宝") || (csvContent.contains("交易分类") && csvContent.contains("对方账号")) {
            return .alipay
        }
        return .unknown
    }
    
    /// 自动解析账单
    func autoParse(csvContent: String) -> ImportResult {
        let platform = detectPlatform(from: csvContent)
        switch platform {
        case .wechat:
            return parseWechatBill(from: csvContent)
        case .alipay:
            return parseAlipayBill(from: csvContent)
        case .unknown:
            return ImportResult(successCount: 0, failedCount: 0, transactions: [], errors: ["无法识别账单格式，请确认是微信或支付宝导出的CSV文件"])
        }
    }
    
    // MARK: - CSV 行解析
    
    /// 解析 CSV 行（处理引号内的逗号）
    private func parseCSVLine(_ line: String) -> [String] {
        var columns: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                columns.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        columns.append(current.trimmingCharacters(in: .whitespaces))
        
        return columns
    }
}
