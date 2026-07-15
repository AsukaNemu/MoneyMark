import XCTest
@testable import MoneyMark

final class MoneyMarkTests: XCTestCase {
    func testReceiptParserAmount() throws {
        let parser = ReceiptParser()
        let result = parser.parse(text: "¥123.45\n商户：星巴克\n2024-01-15 14:30")
        XCTAssertEqual(result.amount, 123.45)
        XCTAssertEqual(result.merchantName, "星巴克")
    }
    
    func testReceiptParserWechatStyle() throws {
        let parser = ReceiptParser()
        let result = parser.parse(text: "支付 28.00 元\n微信支付\n肯德基")
        XCTAssertEqual(result.amount, 28.0)
    }
    
    func testCurrencyFormatter() throws {
        XCTAssertEqual(CurrencyFormatter.format(1234.56), "¥1,234.56")
        XCTAssertEqual(CurrencyFormatter.format(0), "¥0.00")
    }
}
