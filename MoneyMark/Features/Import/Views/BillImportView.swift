import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 账单导入视图
struct BillImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showFilePicker = false
    @State private var isProcessing = false
    @State private var importResult: BillImportService.ImportResult?
    @State private var showResult = false
    @State private var errorMessage: String?
    
    private let importService = BillImportService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 导入说明
                    importInstructions
                    
                    // 导入按钮
                    importButton
                    
                    // 支持平台
                    supportedPlatforms
                    
                    // 导入结果
                    if let result = importResult {
                        importResultCard(result)
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
                .padding()
            }
            .background(AppColor.background)
            .navigationTitle("导入账单")
            .navigationBarTitleDisplayMode(.inline)
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }
    
    // MARK: - 导入说明
    
    private var importInstructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("导入说明")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InstructionRow(number: "1", text: "从微信/支付宝导出账单 CSV 文件")
                InstructionRow(number: "2", text: "在此处选择导出的文件")
                InstructionRow(number: "3", text: "系统自动识别并导入账单")
            }
            .padding()
            .cardStyle()
        }
    }
    
    // MARK: - 导入按钮
    
    private var importButton: some View {
        Button(action: { showFilePicker = true }) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "doc.badge.arrow.up")
                }
                Text(isProcessing ? "导入中..." : "选择文件导入")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isProcessing ? Color.gray : AppColor.primary)
            .cornerRadius(12)
        }
        .disabled(isProcessing)
    }
    
    // MARK: - 支持平台
    
    private var supportedPlatforms: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支持平台")
                .font(.headline)
            
            HStack(spacing: 16) {
                PlatformCard(name: "微信", icon: "message.fill", color: .green)
                PlatformCard(name: "支付宝", icon: "a.circle.fill", color: .blue)
            }
        }
    }
    
    // MARK: - 导入结果
    
    private func importResultCard(_ result: BillImportService.ImportResult) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack {
                    Text("\(result.successCount)")
                        .font(.title.weight(.bold))
                        .foregroundColor(AppColor.income)
                    Text("成功")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                VStack {
                    Text("\(result.failedCount)")
                        .font(.title.weight(.bold))
                        .foregroundColor(AppColor.expense)
                    Text("失败")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            if result.successCount > 0 {
                Button("确认导入") {
                    saveTransactions(result.transactions)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColor.income)
                .cornerRadius(12)
            }
            
            if !result.errors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("错误详情:")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.red)
                    ForEach(result.errors.prefix(5), id: \.self) { error in
                        Text("• \(error)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
    
    // MARK: - 文件处理
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard let url = try? result.get().first else { return }
        
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                
                let content = try String(contentsOf: url, encoding: .utf8)
                let importResult = importService.autoParse(csvContent: content)
                
                await MainActor.run {
                    self.importResult = importResult
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "文件读取失败: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func saveTransactions(_ transactions: [Transaction]) {
        for transaction in transactions {
            modelContext.insert(transaction)
        }
        try? modelContext.save()
        dismiss()
    }
}

/// 平台卡片
struct PlatformCard: View {
    let name: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            Text(name)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .cardStyle()
    }
}
