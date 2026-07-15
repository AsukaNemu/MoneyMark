import Foundation
import Vision
import UIKit

/// OCR 文字识别服务
/// 使用 Apple Vision 框架在设备本地进行文字识别
final class OCRRecognitionService {
    
    /// 识别结果
    struct RecognitionResult {
        let text: String
        let confidence: Float
        let boundingBoxes: [CGRect]
    }
    
    /// 从图片中识别文字
    func recognizeText(from image: UIImage) async throws -> [RecognitionResult] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let results: [RecognitionResult] = observations.compactMap { observation in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    return RecognitionResult(
                        text: topCandidate.string,
                        confidence: topCandidate.confidence,
                        boundingBoxes: [observation.boundingBox]
                    )
                }
                
                continuation.resume(returning: results)
            }
            
            // 配置识别参数
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "en-US"]
            request.usesLanguageCorrection = true
            
            // 支持自动语言检测
            if #available(iOS 16.0, *) {
                request.automaticallyDetectsLanguage = true
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 从图片中识别并提取完整文本
    func extractFullText(from image: UIImage) async throws -> String {
        let results = try await recognizeText(from: image)
        return results.map { $0.text }.joined(separator: "\n")
    }
    
    /// 从支付截图中识别账单信息
    func recognizeReceipt(from image: UIImage) async throws -> ReceiptInfo {
        let fullText = try await extractFullText(from: image)
        let parser = ReceiptParser()
        return parser.parse(text: fullText)
    }
}

// MARK: - 错误定义

enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图片格式"
        case .recognitionFailed(let message):
            return "识别失败: \(message)"
        }
    }
}
