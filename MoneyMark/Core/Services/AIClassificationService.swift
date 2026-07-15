import Foundation

/// AI 智能分类服务
/// 本地规则匹配优先，复杂场景降级到云端 AI
final class AIClassificationService {
    
    /// 分类匹配结果
    struct ClassificationResult {
        let categoryId: UUID?
        let categoryName: String
        let confidence: Double
        let isFromAI: Bool
    }
    
    // MARK: - 商户 → 分类映射（本地规则）
    
    private let merchantCategoryRules: [String: String] = [
        // 餐饮
        "美团外卖": "外卖", "饿了么": "外卖", "肯德基": "餐饮", "麦当劳": "餐饮",
        "星巴克": "零食饮品", "瑞幸咖啡": "零食饮品", "喜茶": "零食饮品",
        "海底捞": "聚餐", "西贝": "聚餐",
        // 交通
        "滴滴出行": "打车", "高德打车": "打车", "曹操出行": "打车",
        "中国铁路": "火车高铁", "12306": "火车高铁",
        "携程": "飞机", "飞猪": "飞机", "去哪儿": "飞机",
        "中国石化": "加油", "中国石油": "加油",
        // 购物
        "淘宝": "购物", "天猫": "购物", "京东": "购物", "拼多多": "购物",
        "唯品会": "购物", "苏宁易购": "购物",
        "沃尔玛": "日用品", "永辉": "日用品", "盒马": "日用品",
        // 娱乐
        "猫眼电影": "电影", "淘票票": "电影",
        "网易游戏": "游戏", "腾讯游戏": "游戏",
        // 居住
        "链家": "房租", "贝壳": "房租", "自如": "房租",
        // 通讯
        "中国移动": "话费", "中国联通": "话费", "中国电信": "话费"
    ]
    
    /// 智能分类匹配
    /// - Parameters:
    ///   - merchantName: 商户名
    ///   - amount: 金额
    ///   - existingCategories: 用户已有的分类列表
    /// - Returns: 匹配结果
    func classify(
        merchantName: String?,
        amount: Double,
        existingCategories: [Category]
    ) -> ClassificationResult? {
        guard let merchant = merchantName, !merchant.isEmpty else {
            return nil
        }
        
        // 1. 精确匹配商户名
        for (rule, categoryName) in merchantCategoryRules {
            if merchant.contains(rule) {
                if let category = findCategory(name: categoryName, in: existingCategories) {
                    return ClassificationResult(
                        categoryId: category.id,
                        categoryName: category.name,
                        confidence: 0.9,
                        isFromAI: false
                    )
                }
            }
        }
        
        // 2. 模糊匹配分类名
        for category in existingCategories where category.parentId != nil {
            if merchant.contains(category.name) {
                return ClassificationResult(
                    categoryId: category.id,
                    categoryName: category.name,
                    confidence: 0.7,
                    isFromAI: false
                )
            }
        }
        
        // 3. 金额推断
        if let result = classifyByAmount(amount, categories: existingCategories) {
            return result
        }
        
        return nil
    }
    
    // MARK: - 云端 AI 分类（预留接口）
    
    /// 使用云端 AI 进行分类（需要网络）
    /// - Parameters:
    ///   - text: 账单文本
    ///   - categories: 用户分类列表
    func classifyWithAI(
        text: String,
        categories: [Category]
    ) async throws -> ClassificationResult? {
        // TODO: 接入 DeepSeek/Qwen API
        // 1. 构造 prompt：发送账单文本 + 用户分类列表
        // 2. 调用 API 获取分类建议
        // 3. 解析返回结果
        // 4. 敏感信息脱敏
        
        // 目前返回 nil，降级到本地逻辑
        return nil
    }
    
    // MARK: - 敏感信息脱敏
    
    /// 脱敏处理文本中的敏感信息
    func sanitizeSensitiveInfo(_ text: String) -> String {
        var sanitized = text
        
        // 手机号脱敏：保留前3后4
        let phonePattern = try? NSRegularExpression(pattern: #"1[3-9]\d{9}"#)
        if let phoneMatch = phonePattern?.firstMatch(in: sanitized, range: NSRange(sanitized.startIndex..., in: sanitized)),
           let range = Range(phoneMatch.range, in: sanitized) {
            let phone = String(sanitized[range])
            let masked = String(phone.prefix(3)) + "****" + String(phone.suffix(4))
            sanitized = sanitized.replacingCharacters(in: range, with: masked)
        }
        
        // 银行卡号脱敏：只保留后4位
        let cardPattern = try? NSRegularExpression(pattern: #"\d{16,19}"#)
        if let cardMatch = cardPattern?.firstMatch(in: sanitized, range: NSRange(sanitized.startIndex..., in: sanitized)),
           let range = Range(cardMatch.range, in: sanitized) {
            let card = String(sanitized[range])
            let masked = String(repeating: "*", count: card.count - 4) + String(card.suffix(4))
            sanitized = sanitized.replacingCharacters(in: range, with: masked)
        }
        
        // 身份证号脱敏
        let idPattern = try? NSRegularExpression(pattern: #"\d{17}[\dXx]"#)
        if let idMatch = idPattern?.firstMatch(in: sanitized, range: NSRange(sanitized.startIndex..., in: sanitized)),
           let range = Range(idMatch.range, in: sanitized) {
            let id = String(sanitized[range])
            let masked = String(id.prefix(6)) + "********" + String(id.suffix(4))
            sanitized = sanitized.replacingCharacters(in: range, with: masked)
        }
        
        return sanitized
    }
    
    // MARK: - Private
    
    private func findCategory(name: String, in categories: [Category]) -> Category? {
        categories.first { $0.name == name }
    }
    
    /// 根据金额范围推断分类
    private func classifyByAmount(_ amount: Double, categories: [Category]) -> ClassificationResult? {
        // 小额高频 → 餐饮/交通
        if amount >= 1 && amount <= 50 {
            if let dining = categories.first(where: { $0.name == "餐饮" && $0.parentId != nil }) {
                return ClassificationResult(
                    categoryId: dining.id,
                    categoryName: dining.name,
                    confidence: 0.3,
                    isFromAI: false
                )
            }
        }
        return nil
    }
}
