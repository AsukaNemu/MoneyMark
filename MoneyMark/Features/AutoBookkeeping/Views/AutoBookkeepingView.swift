import SwiftUI
import PhotosUI

/// 自动记账视图（截图OCR识别）
struct AutoBookkeepingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var recognitionResult: ReceiptInfo?
    @State private var showResult = false
    @State private var errorMessage: String?
    @State private var showHistory = false
    
    private let ocrService = OCRRecognitionService()
    private let aiService = AIClassificationService()
    
    @Query(filter: #Predicate<Category> { !$0.isArchived && $0.parentId != nil },
           sortBy: [SortDescriptor(\.sortOrder)])
    private var categories: [Category]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 截图识别区域
                    imageRecognitionSection
                    
                    // 快捷操作
                    quickActionsSection
                    
                    // 使用说明
                    instructionsSection
                }
                .padding()
            }
            .background(AppColor.background)
            .navigationTitle("自动记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("识别历史") { showHistory = true }
                }
            }
            .sheet(isPresented: $showResult) {
                if let result = recognitionResult {
                    RecognitionResultSheet(
                        result: result,
                        image: selectedImage,
                        categories: categories,
                        onSave: { transaction in
                            modelContext.insert(transaction)
                            try? modelContext.save()
                            dismiss()
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - 截图识别区域
    
    private var imageRecognitionSection: some View {
        VStack(spacing: 16) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                
                if isProcessing {
                    LoadingView(message: "正在识别中...")
                } else {
                    Button(action: processImage) {
                        HStack {
                            Image(systemName: "doc.text.viewfinder")
                            Text("开始识别")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColor.primary)
                        .cornerRadius(12)
                    }
                }
            } else {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .screenshots,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(AppColor.primary)
                        
                        Text("选择支付截图")
                            .font(.headline)
                        
                        Text("支持支付宝、微信、云闪付的支付成功页面截图")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .cardStyle()
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImage = image
                        }
                    }
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - 快捷操作
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快捷操作")
                .font(.headline)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "camera.fill",
                    title: "拍照识别",
                    color: .blue
                ) {
                    // TODO: 调用相机
                }
                
                QuickActionButton(
                    icon: "doc.text.fill",
                    title: "导入账单",
                    color: .green
                ) {
                    // TODO: 跳转到导入页面
                }
                
                QuickActionButton(
                    icon: "mic.fill",
                    title: "语音记账",
                    color: .orange
                ) {
                    // TODO: 语音输入
                }
                
                QuickActionButton(
                    icon: "command",
                    title: "快捷指令",
                    color: .purple
                ) {
                    // TODO: 打开快捷指令
                }
            }
        }
    }
    
    // MARK: - 使用说明
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使用说明")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InstructionRow(number: "1", text: "支付完成后截图支付成功页面")
                InstructionRow(number: "2", text: "打开 MoneyMark 选择截图")
                InstructionRow(number: "3", text: "AI 自动识别金额、商户、分类")
                InstructionRow(number: "4", text: "确认信息后一键保存")
            }
            .padding()
            .cardStyle()
        }
    }
    
    // MARK: - 处理图片
    
    private func processImage() {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await ocrService.recognizeReceipt(from: image)
                await MainActor.run {
                    recognitionResult = result
                    showResult = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "识别失败: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - 快捷操作按钮

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .cardStyle()
        }
    }
}

// MARK: - 使用说明行

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(AppColor.primary))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 识别结果弹窗

struct RecognitionResultSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let result: ReceiptInfo
    let image: UIImage?
    let categories: [Category]
    let onSave: (Transaction) -> Void
    
    @State private var amount: String = ""
    @State private var merchantName: String = ""
    @State private var selectedCategory: Category?
    @State private var note: String = ""
    @State private var date: Date = .now
    
    var body: some View {
        NavigationStack {
            List {
                Section("识别结果") {
                    HStack {
                        Text("置信度")
                        Spacer()
                        Text("\(Int(result.confidence * 100))%")
                            .foregroundColor(result.confidence > 0.7 ? .green : .orange)
                    }
                    
                    HStack {
                        Text("金额")
                        Spacer()
                        TextField("¥0.00", text: $amount)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("商户")
                        Spacer()
                        TextField("商户名称", text: $merchantName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    HStack {
                        Text("备注")
                        Spacer()
                        TextField("添加备注", text: $note)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("选择分类") {
                    CategoryGridView(
                        categories: Array(categories.prefix(10)),
                        selectedCategory: $selectedCategory
                    )
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("确认账单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(amount.isEmpty)
                }
            }
            .onAppear {
                amount = result.amount.map { String(format: "%.2f", $0) } ?? ""
                merchantName = result.merchantName ?? ""
                note = result.note ?? ""
                date = result.date ?? .now
                
                if let categoryName = result.category {
                    selectedCategory = categories.first { $0.name == categoryName }
                }
            }
        }
    }
    
    private func save() {
        guard let amountValue = Double(amount) else { return }
        
        let transaction = Transaction(
            amount: amountValue,
            type: result.transactionType,
            categoryId: selectedCategory?.id,
            categoryName: selectedCategory?.name,
            categoryIcon: selectedCategory?.icon,
            note: note.isEmpty ? nil : note,
            merchantName: merchantName.isEmpty ? nil : merchantName,
            date: date,
            source: .ocr
        )
        
        onSave(transaction)
    }
}
