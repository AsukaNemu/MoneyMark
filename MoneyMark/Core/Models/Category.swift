import Foundation
import SwiftData

/// 分类数据模型
@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String
    var parentId: UUID?
    var typeRawValue: String // expense, income
    var sortOrder: Int
    var isArchived: Bool
    var colorHex: String?
    var createdAt: Date
    
    var type: TransactionType {
        get { TransactionType(rawValue: typeRawValue) ?? .expense }
        set { typeRawValue = newValue.rawValue }
    }
    
    init(
        name: String,
        icon: String,
        parentId: UUID? = nil,
        type: TransactionType = .expense,
        sortOrder: Int = 0,
        isArchived: Bool = false,
        colorHex: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.parentId = parentId
        self.typeRawValue = type.rawValue
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.colorHex = colorHex
        self.createdAt = .now
    }
}

// MARK: - 预置分类

extension Category {
    /// 预置支出一级分类
    static let presetExpenseCategories: [(name: String, icon: String, children: [(String, String)])] = [
        ("餐饮", "fork.knife", [
            ("早餐", "sunrise.fill"),
            ("午餐", "sun.max.fill"),
            ("晚餐", "moon.fill"),
            ("零食饮品", "cup.and.saucer.fill"),
            ("外卖", "bicycle"),
            ("聚餐", "person.3.fill")
        ]),
        ("交通", "car.fill", [
            ("公交地铁", "tram.fill"),
            ("打车", "taxi.side.fill"),
            ("火车高铁", "train.side.front.car"),
            ("飞机", "airplane"),
            ("加油", "fuelpump.fill"),
            ("停车", "parkingsign")
        ]),
        ("购物", "bag.fill", [
            ("日用品", "basket.fill"),
            ("服饰", "tshirt.fill"),
            ("数码", "laptopcomputer"),
            ("家居", "house.fill")
        ]),
        ("娱乐", "gamecontroller.fill", [
            ("电影", "film.fill"),
            ("游戏", "arcade.stick.console"),
            ("运动", "figure.run"),
            ("旅行", "airplane.departure")
        ]),
        ("居住", "house.fill", [
            ("房租", "building.2.fill"),
            ("水电燃", "bolt.fill"),
            ("物业", "building.fill"),
            ("维修", "wrench.and.screwdriver.fill")
        ]),
        ("医疗", "cross.case.fill", [
            ("门诊", "stethoscope"),
            ("药品", "pills.fill"),
            ("体检", "heart.text.square.fill")
        ]),
        ("教育", "book.fill", [
            ("书籍", "books.vertical.fill"),
            ("课程", "person.crop.rectangle.stack.fill"),
            ("培训", "graduationcap.fill")
        ]),
        ("通讯", "phone.fill", [
            ("话费", "phone.arrow.up.right"),
            ("流量", "wifi"),
            ("会员订阅", "star.fill")
        ]),
        ("社交", "person.2.fill", [
            ("礼物", "gift.fill"),
            ("红包", "envelope.open.fill"),
            ("请客", "wineglass.fill")
        ]),
        ("宠物", "pawprint.fill", [
            ("粮食", "bag.fill"),
            ("医疗", "cross.case.fill"),
            ("用品", "basket.fill")
        ]),
        ("其他", "ellipsis.circle.fill", [
            ("其他支出", "questionmark.circle.fill")
        ])
    ]
    
    /// 预置收入一级分类
    static let presetIncomeCategories: [(name: String, icon: String, children: [(String, String)])] = [
        ("工资", "banknote.fill", [
            ("薪资", "dollarsign.circle.fill"),
            ("奖金", "star.fill"),
            ("补贴", "hand.thumbsup.fill")
        ]),
        ("理财", "chart.line.uptrend.xyaxis", [
            ("利息", "percent"),
            ("股息", "chart.bar.fill"),
            ("投资收益", "arrow.up.right")
        ]),
        ("兼职", "person.fill.checkmark", [
            ("兼职", "briefcase.fill"),
            (" freelance", "laptopcomputer")
        ]),
        ("其他", "ellipsis.circle.fill", [
            ("红包", "envelope.open.fill"),
            ("退款", "arrow.uturn.backward"),
            ("其他收入", "questionmark.circle.fill")
        ])
    ]
}
