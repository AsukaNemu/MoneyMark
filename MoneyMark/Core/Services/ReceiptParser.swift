import Foundation

/// 收据/账单解析结果
struct ReceiptInfo {
    var amount: Double?
    var merchantName: String?
    var date: Date?
    var paymentMethod: String?   // 支付宝/微信/银行卡等
    var transactionType: TransactionType
    var category: String?        // 推荐分类名
    var note: String?
    var confidence: Double       // 解析置信度 0-1
}

/// 收据/账单文本解析器
/// 从 OCR 识别的文本中提取结构化账单信息
final class ReceiptParser {
    
    // MARK: - 金额匹配正则
    
    /// 金额模式（支持 ¥/￥/CNY/元 等前缀后缀）
    private let amountPatterns: [NSRegularExpression] = {
        let patterns = [
            // ¥123.45 / ￥123.45
            #"[¥￥]\s*(\d+\.?\d{0,2})"#,
            // 金额: 123.45 / 金额 123.45 元
            #"金额[：:\s]*(\d+\.?\d{0,2})\s*元?"#,
            // 支付 123.45 元 / 消费 123.45 元
            #"(?:支付|消费|付款|收款|花费|支出|收入)[：:\s]*(\d+\.?\d{0,2})\s*元?"#,
            // 123.45 元
            #"(\d+\.?\d{0,2})\s*元"#,
            // CNY 123.45
            #"CNY\s*(\d+\.?\d{0,2})"#,
            // 合计/总计/实付: 123.45
            #"(?:合计|总计|实付|实收|应付|应收)[：:\s]*(\d+\.?\d{0,2})"#,
            // 纯数字金额（最后匹配，避免误匹配）
            #"^(\d+\.?\d{0,2})$"#
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0, options: []) }
    }()
    
    // MARK: - 商户名匹配
    
    private let merchantPatterns: [NSRegularExpression] = {
        let patterns = [
            // 商户: xxx / 商户名: xxx
            #"商户(?:名)?[：:\s]*(.+?)(?:\n|$)"#,
            // 收款方: xxx
            #"收款方[：:\s]*(.+?)(?:\n|$)"#,
            // 转账给 xxx
            #"转账给[：:\s]*(.+?)(?:\n|$)"#,
            // 付款给 xxx
            #"付款给[：:\s]*(.+?)(?:\n|$)"#,
            // 支付宝 / 微信 支付 - xxx
            #"(?:支付宝|微信)\s*(?:支付|付款)[：:\s-]*(.+?)(?:\n|$)"#
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0, options: []) }
    }()
    
    // MARK: - 日期匹配
    
    private let datePatterns: [NSRegularExpression] = {
        let patterns = [
            // 2024-01-15 14:30:25 / 2024/01/15 14:30:25
            #"(\d{4}[-/]\d{1,2}[-/]\d{1,2}\s+\d{1,2}:\d{2}(?::\d{2})?)"#,
            // 2024-01-15
            #"(\d{4}[-/]\d{1,2}[-/]\d{1,2})"#,
            // 01月15日 14:30
            #"(\d{1,2}月\d{1,2}日\s*\d{1,2}:\d{2})"#,
            // 01-15 14:30
            #"(\d{1,2}-\d{1,2}\s+\d{1,2}:\d{2})"#
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0, options: []) }
    }()
    
    // MARK: - 支付方式匹配
    
    private let paymentMethodKeywords: [String: String] = [
        "支付宝": "支付宝",
        "微信": "微信",
        "云闪付": "云闪付",
        "Apple Pay": "Apple Pay",
        "银行卡": "银行卡",
        "信用卡": "信用卡",
        "储蓄卡": "储蓄卡",
        "现金": "现金",
        "花呗": "花呗",
        "余额宝": "余额宝",
        "零钱": "微信",
        "招商银行": "招商银行",
        "工商银行": "工商银行",
        "建设银行": "建设银行",
        "农业银行": "农业银行",
        "交通银行": "交通银行"
    ]
    
    // MARK: - 交易类型识别
    
    private let expenseKeywords = ["支付", "消费", "付款", "花费", "支出", "购买", "订单"]
    private let incomeKeywords = ["收款", "收入", "到账", "转入", "退款", "红包"]
    private let transferKeywords = ["转账", "转出", "转入"]
    
    // MARK: - 分类推断关键词
    
    private let categoryMapping: [String: String] = [
        // 餐饮
        "餐饮": "餐饮", "美食": "餐饮", "外卖": "餐饮", "美团": "餐饮", "饿了么": "餐饮",
        "肯德基": "餐饮", "麦当劳": "餐饮", "星巴克": "餐饮", "瑞幸": "餐饮", "奶茶": "餐饮",
        "火锅": "餐饮", "烧烤": "餐饮", "食堂": "餐饮",
        // 交通
        "打车": "交通", "滴滴": "交通", "出租": "交通", "地铁": "交通", "公交": "交通",
        "高铁": "交通", "火车": "交通", "机票": "交通", "航空": "交通", "加油": "交通",
        "停车": "交通", "ETC": "交通", "共享单车": "交通",
        // 购物
        "淘宝": "购物", "天猫": "购物", "京东": "购物", "拼多多": "购物", "唯品会": "购物",
        "超市": "购物", "便利店": "购物", "商场": "购物",
        // 娱乐
        "电影": "娱乐", "游戏": "娱乐", "KTV": "娱乐", "酒吧": "娱乐", "旅游": "娱乐",
        "酒店": "娱乐", "景区": "娱乐", "门票": "娱乐",
        // 居住
        "房租": "居住", "水费": "居住", "电费": "居住", "燃气": "居住", "物业": "居住",
        // 医疗
        "医院": "医疗", "药店": "医疗", "诊所": "医疗", "体检": "医疗",
        // 教育
        "书店": "教育", "培训": "教育", "学费": "教育",
        // 通讯
        "话费": "通讯", "流量": "通讯", "充值": "通讯", "会员": "通讯"
    ]
    
    // MARK: - 解析入口
    
    /// 解析文本，返回账单信息
    func parse(text: String) -> ReceiptInfo {
        let amount = extractAmount(from: text)
        let merchantName = extractMerchantName(from: text)
        let date = extractDate(from: text)
        let paymentMethod = extractPaymentMethod(from: text)
        let transactionType = detectTransactionType(from: text)
        let category = inferCategory(from: text, merchantName: merchantName)
        let confidence = calculateConfidence(amount: amount, merchant: merchantName, date: date)
        
        return ReceiptInfo(
            amount: amount,
            merchantName: merchantName,
            date: date,
            paymentMethod: paymentMethod,
            transactionType: transactionType,
            category: category,
            note: merchantName,
            confidence: confidence
        )
    }
    
    // MARK: - 金额提取
    
    private func extractAmount(from text: String) -> Double? {
        for pattern in amountPatterns {
            let range = NSRange(text.startIndex..., in: text)
            if let match = pattern.firstMatch(in: text, range: range),
               let amountRange = Range(match.range(at: 1), in: text),
               let amount = Double(text[amountRange]) {
                // 过滤明显不合理的金额
                if amount > 0 && amount < 1_000_000 {
                    return amount
                }
            }
        }
        return nil
    }
    
    // MARK: - 商户名提取
    
    private func extractMerchantName(from text: String) -> String? {
        for pattern in merchantPatterns {
            let range = NSRange(text.startIndex..., in: text)
            if let match = pattern.firstMatch(in: text, range: range),
               let merchantRange = Range(match.range(at: 1), in: text) {
                let merchant = String(text[merchantRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !merchant.isEmpty && merchant.count <= 50 {
                    return merchant
                }
            }
        }
        return nil
    }
    
    // MARK: - 日期提取
    
    private func extractDate(from text: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        
        for (index, pattern) in datePatterns.enumerated() {
            let range = NSRange(text.startIndex..., in: text)
            if let match = pattern.firstMatch(in: text, range: range),
               let dateRange = Range(match.range(at: 1), in: text) {
                let dateString = String(text[dateRange])
                
                switch index {
                case 0: // 完整日期时间
                    dateFormatter.dateFormat = dateString.contains("/") ? "yyyy/MM/dd HH:mm:ss" : "yyyy-MM-dd HH:mm:ss"
                    if let date = dateFormatter.date(from: dateString) { return date }
                    dateFormatter.dateFormat = dateString.contains("/") ? "yyyy/MM/dd HH:mm" : "yyyy-MM-dd HH:mm"
                    if let date = dateFormatter.date(from: dateString) { return date }
                case 1: // 仅日期
                    dateFormatter.dateFormat = dateString.contains("/") ? "yyyy/MM/dd" : "yyyy-MM-dd"
                    if let date = dateFormatter.date(from: dateString) { return date }
                case 2: // 月日时分
                    dateFormatter.dateFormat = "MM月dd日 HH:mm"
                    let yearPrefix = "\(Calendar.current.component(.year, from: Date()))年"
                    if let date = dateFormatter.date(from: yearPrefix + dateString) { return date }
                case 3: // 月-日 时分
                    dateFormatter.dateFormat = "MM-dd HH:mm"
                    let yearPrefix = "\(Calendar.current.component(.year, from: Date()))-"
                    if let date = dateFormatter.date(from: yearPrefix + dateString) { return date }
                default:
                    break
                }
            }
        }
        return nil
    }
    
    // MARK: - 支付方式提取
    
    private func extractPaymentMethod(from text: String) -> String? {
        for (keyword, method) in paymentMethodKeywords {
            if text.contains(keyword) {
                return method
            }
        }
        return nil
    }
    
    // MARK: - 交易类型检测
    
    private func detectTransactionType(from text: String) -> TransactionType {
        for keyword in incomeKeywords {
            if text.contains(keyword) { return .income }
        }
        for keyword in transferKeywords {
            if text.contains(keyword) { return .transfer }
        }
        return .expense // 默认为支出
    }
    
    // MARK: - 分类推断
    
    private func inferCategory(from text: String, merchantName: String?) -> String? {
        let searchText = text + " " + (merchantName ?? "")
        for (keyword, category) in categoryMapping {
            if searchText.contains(keyword) {
                return category
            }
        }
        return nil
    }
    
    // MARK: - 置信度计算
    
    private func calculateConfidence(amount: Double?, merchant: String?, date: Date?) -> Double {
        var score: Double = 0
        if amount != nil { score += 0.5 }
        if merchant != nil { score += 0.3 }
        if date != nil { score += 0.2 }
        return score
    }
}
