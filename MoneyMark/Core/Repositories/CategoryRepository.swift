import Foundation
import SwiftData

/// 分类数据仓库
actor CategoryRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD
    
    func add(_ category: Category) throws {
        modelContext.insert(category)
        try modelContext.save()
    }
    
    func addBatch(_ categories: [Category]) throws {
        for category in categories {
            modelContext.insert(category)
        }
        try modelContext.save()
    }
    
    func update(_ category: Category) throws {
        try modelContext.save()
    }
    
    func delete(_ category: Category) throws {
        category.isArchived = true
        try modelContext.save()
    }
    
    // MARK: - 查询
    
    /// 获取所有未归档分类
    func fetchAll() throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 按类型获取一级分类
    func fetchRootCategories(type: TransactionType) throws -> [Category] {
        let typeRaw = type.rawValue
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { category in
                category.parentId == nil && category.typeRawValue == typeRaw && !category.isArchived
            },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取子分类
    func fetchChildren(parentId: UUID) throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { category in
                category.parentId == parentId && !category.isArchived
            },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 按名称查找分类
    func findByName(_ name: String) throws -> Category? {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { category in
                category.name == name && !category.isArchived
            }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    /// 初始化预置分类
    func initializePresetCategories() throws {
        // 检查是否已经初始化
        let count = try modelContext.fetchCount(FetchDescriptor<Category>())
        guard count == 0 else { return }
        
        // 支出分类
        for (index, preset) in Category.presetExpenseCategories.enumerated() {
            let parent = Category(
                name: preset.name,
                icon: preset.icon,
                type: .expense,
                sortOrder: index
            )
            modelContext.insert(parent)
            
            for (childIndex, child) in preset.children.enumerated() {
                let childCategory = Category(
                    name: child.0,
                    icon: child.1,
                    parentId: parent.id,
                    type: .expense,
                    sortOrder: childIndex
                )
                modelContext.insert(childCategory)
            }
        }
        
        // 收入分类
        for (index, preset) in Category.presetIncomeCategories.enumerated() {
            let parent = Category(
                name: preset.name,
                icon: preset.icon,
                type: .income,
                sortOrder: index
            )
            modelContext.insert(parent)
            
            for (childIndex, child) in preset.children.enumerated() {
                let childCategory = Category(
                    name: child.0,
                    icon: child.1,
                    parentId: parent.id,
                    type: .income,
                    sortOrder: childIndex
                )
                modelContext.insert(childCategory)
            }
        }
        
        try modelContext.save()
    }
}
